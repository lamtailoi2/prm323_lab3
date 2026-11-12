import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/validators.dart';
import '../../../models/internship.dart' show WorkMode;
import '../../../models/user_profile.dart';
import '../../../services/analytics_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_profile_service.dart';
import 'profile_viewmodel.dart';

@immutable
class EditPreferencesState {
  const EditPreferencesState({
    this.targetRoles = const <TargetRole>{},
    this.experience,
    this.workModes = const <WorkMode>{},
    this.location = '',
    this.locationError,
    this.save = const AsyncData(null),
  });

  final Set<TargetRole> targetRoles;
  final ExperienceRange? experience;
  final Set<WorkMode> workModes;

  /// As typed; trimmed on save.
  final String location;
  final String? locationError;
  final AsyncValue<void> save;
}

final editPreferencesViewModelProvider =
    NotifierProvider.autoDispose<
      EditPreferencesViewModel,
      EditPreferencesState
    >(EditPreferencesViewModel.new);

/// Draft of the Update preferences sheet; nothing is stored until [save].
class EditPreferencesViewModel extends Notifier<EditPreferencesState> {
  /// Work modes in the order of the Update Preferences frame.
  static const List<WorkMode> workModeOptions = <WorkMode>[
    WorkMode.hybrid,
    WorkMode.remote,
    WorkMode.onSite,
  ];

  /// Quick-select locations from the design. Listings are synced for
  /// Vietnam only (G-25), so every option is in Vietnam.
  static const List<String> quickLocations = <String>[
    'Ho Chi Minh City',
    'Hanoi',
    'Da Nang',
    'All Vietnam',
  ];

  static const int maxLocationLength = 100;

  @override
  EditPreferencesState build() {
    // Seeded once; see EditSkillsViewModel.build.
    final profile = switch (ref.read(profileViewModelProvider)) {
      ViewData(:final data) => data.profile,
      _ => const UserProfile(),
    };
    final preferences = profile.preferences;
    return EditPreferencesState(
      targetRoles: Set.unmodifiable(preferences.targetRoles),
      experience: preferences.experience,
      workModes: Set.unmodifiable(preferences.workModes),
      // Both frames ask for a city; an empty internship location starts
      // from the current city of Edit profile. Stored only on save.
      location: preferences.location ?? profile.details.city ?? '',
    );
  }

  void toggleRole(TargetRole role) =>
      _update(targetRoles: _toggled(state.targetRoles, role));

  /// Single-select; tapping the selected band again clears the answer.
  void selectExperience(ExperienceRange range) {
    final next = state.experience == range ? null : range;
    _update(experience: next, hasExperience: true);
  }

  void toggleWorkMode(WorkMode mode) =>
      _update(workModes: _toggled(state.workModes, mode));

  void setLocation(String location) => _update(location: location);

  /// Returns `true` once the preferences are stored.
  Future<bool> save() async {
    if (state.save.isLoading) return false;
    final service = ref.read(userProfileServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return false;

    final location = state.location.trim();
    final locationError = Validators.maxLength(
      location,
      maxLocationLength,
      message: 'Use $maxLocationLength characters or fewer.',
    );
    if (locationError != null) {
      _update(locationError: locationError);
      return false;
    }

    final preferences = InternshipPreferences(
      targetRoles: List.unmodifiable(
        TargetRole.values.where(state.targetRoles.contains),
      ),
      experience: state.experience,
      workModes: List.unmodifiable(
        workModeOptions.where(state.workModes.contains),
      ),
      location: location.isEmpty ? null : location,
    );
    _update(save: const AsyncLoading());
    try {
      await service.updatePreferences(uid, preferences);
      await analytics.logEvent('profile_update', {
        'section': 'preferences',
        'item_count':
            preferences.targetRoles.length +
            (preferences.experience == null ? 0 : 1) +
            preferences.workModes.length +
            (preferences.location == null ? 0 : 1),
      });
      if (ref.mounted) _update(save: const AsyncData(null));
      return true;
    } on AppException catch (error, stack) {
      if (ref.mounted) _update(save: AsyncError(error, stack));
      return false;
    }
  }

  static Set<T> _toggled<T>(Set<T> values, T value) => Set.unmodifiable(
    values.contains(value)
        ? values.where((item) => item != value)
        : {...values, value},
  );

  /// [locationError] is cleared by every change unless it is passed.
  ///
  /// [hasExperience] distinguishes "leave the band unchanged" from an explicit
  /// `null` that clears the answer.
  void _update({
    Set<TargetRole>? targetRoles,
    ExperienceRange? experience,
    bool hasExperience = false,
    Set<WorkMode>? workModes,
    String? location,
    String? locationError,
    AsyncValue<void>? save,
  }) {
    state = EditPreferencesState(
      targetRoles: targetRoles ?? state.targetRoles,
      experience: hasExperience ? experience : state.experience,
      workModes: workModes ?? state.workModes,
      location: location ?? state.location,
      locationError: locationError,
      save: save ?? state.save,
    );
  }
}
