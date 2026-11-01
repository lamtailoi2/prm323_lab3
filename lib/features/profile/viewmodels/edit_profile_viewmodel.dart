import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/validators.dart';
import '../../../models/user_profile.dart';
import '../../../services/analytics_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_profile_service.dart';
import 'profile_viewmodel.dart';

/// Raw text of the Edit profile text fields, as typed. Year of study and
/// graduation year are chosen in a picker and live in [EditProfileState].
typedef ProfileForm = ({
  String fullName,
  String headline,
  String university,
  String major,
  String phone,
  String city,
  String bio,
});

/// Validation messages shown under each field; `null` when valid.
@immutable
class ProfileFieldErrors {
  const ProfileFieldErrors({
    this.fullName,
    this.headline,
    this.university,
    this.major,
    this.phone,
    this.city,
    this.bio,
  });

  final String? fullName;
  final String? headline;
  final String? university;
  final String? major;
  final String? phone;
  final String? city;
  final String? bio;

  bool get isEmpty =>
      fullName == null &&
      headline == null &&
      university == null &&
      major == null &&
      phone == null &&
      city == null &&
      bio == null;
}

@immutable
class EditProfileState {
  const EditProfileState({
    this.yearOfStudy,
    this.graduationYear,
    this.errors = const ProfileFieldErrors(),
    this.save = const AsyncData(null),
  });

  final int? yearOfStudy;
  final int? graduationYear;
  final ProfileFieldErrors errors;

  /// `AsyncError` carries an [AppException] with a message safe to show.
  final AsyncValue<void> save;
}

final editProfileViewModelProvider =
    NotifierProvider.autoDispose<EditProfileViewModel, EditProfileState>(
      EditProfileViewModel.new,
    );

class EditProfileViewModel extends Notifier<EditProfileState> {
  static const int maxNameLength = 80;
  static const int maxTextLength = 100;
  static const int maxBioLength = 300;
  static const int maxYearOfStudy = 6;

  /// Years from now to the furthest graduation offered: up to
  /// [maxYearOfStudy] years of study plus two years for delays.
  static const int graduationYearsAhead = maxYearOfStudy + 2;

  /// Graduation years offered by the picker: this year to
  /// [graduationYearsAhead] years ahead (2026–2034 in 2026).
  static List<int> graduationYears(DateTime now) => List.unmodifiable([
    for (var i = 0; i <= graduationYearsAhead; i++) now.year + i,
  ]);

  /// "Year 3 · Graduating 2026", as in the Edit profile frame; empty when
  /// neither is set.
  static String academicStanding(int? yearOfStudy, int? graduationYear) => [
    if (yearOfStudy != null) 'Year $yearOfStudy',
    if (graduationYear != null) 'Graduating $graduationYear',
  ].join(' · ');

  @override
  EditProfileState build() {
    // Seeded once from the profile the form was opened on (see
    // EditSkillsViewModel.build).
    final details = switch (ref.read(profileViewModelProvider)) {
      ViewData(:final data) => data.profile.details,
      _ => const ProfileDetails(),
    };
    return EditProfileState(
      yearOfStudy: details.yearOfStudy,
      graduationYear: details.graduationYear,
    );
  }

  /// Selects [year], or clears it when it is already selected.
  void selectYearOfStudy(int year) => state = EditProfileState(
    yearOfStudy: state.yearOfStudy == year ? null : year,
    graduationYear: state.graduationYear,
    errors: state.errors,
  );

  /// Selects [year], or clears it when it is already selected.
  void selectGraduationYear(int year) => state = EditProfileState(
    yearOfStudy: state.yearOfStudy,
    graduationYear: state.graduationYear == year ? null : year,
    errors: state.errors,
  );

  /// Trimmed values plus the picked years; empty optional fields become
  /// `null`.
  ProfileDetails details(ProfileForm form) {
    String? text(String value) => value.trim().isEmpty ? null : value.trim();
    return ProfileDetails(
      fullName: text(form.fullName),
      headline: text(form.headline),
      university: text(form.university),
      major: text(form.major),
      yearOfStudy: state.yearOfStudy,
      graduationYear: state.graduationYear,
      phone: text(form.phone),
      city: text(form.city),
      bio: text(form.bio),
    );
  }

  static ProfileFieldErrors validate(ProfileForm form) {
    String? tooLong(String value, int max) => Validators.maxLength(
      value.trim(),
      max,
      message: 'Use $max characters or fewer.',
    );
    final phone = form.phone.trim();
    return ProfileFieldErrors(
      fullName:
          Validators.required(
            form.fullName,
            message: 'Enter your full name to continue.',
          ) ??
          tooLong(form.fullName, maxNameLength),
      headline:
          Validators.required(
            form.headline,
            message: 'Enter a headline to continue.',
          ) ??
          tooLong(form.headline, maxNameLength),
      university: tooLong(form.university, maxTextLength),
      major: tooLong(form.major, maxTextLength),
      phone: phone.isEmpty
          ? null
          : Validators.phone(
              phone,
              message: 'Enter a valid phone number, e.g. 0908 123 456.',
            ),
      city: tooLong(form.city, maxTextLength),
      bio: tooLong(form.bio, maxBioLength),
    );
  }

  /// Validates and saves. Returns `true` once the profile is stored, so the
  /// View can close the form.
  Future<bool> save(ProfileForm form) async {
    if (state.save.isLoading) return false;
    final service = ref.read(userProfileServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final uid = ref.read(currentUserIdProvider);

    final errors = validate(form);
    if (!errors.isEmpty) {
      _update(errors: errors);
      return false;
    }
    if (uid == null) {
      _update(
        save: AsyncError(
          const AppException(
            AppErrorKind.permissionDenied,
            'Sign in to save your profile.',
          ),
          StackTrace.current,
        ),
      );
      return false;
    }

    final details = this.details(form);
    _update(save: const AsyncLoading());
    try {
      await service.updateDetails(uid, details);
      await analytics.logEvent('profile_update', {
        'section': 'details',
        'item_count': details
            .toFirestore()
            .values
            .where((value) => value != null)
            .length,
      });
      if (ref.mounted) _update();
      return true;
    } on AppException catch (error, stack) {
      if (ref.mounted) _update(save: AsyncError(error, stack));
      return false;
    }
  }

  /// Keeps the picked years; replaces errors and the save state.
  void _update({
    ProfileFieldErrors errors = const ProfileFieldErrors(),
    AsyncValue<void> save = const AsyncData(null),
  }) {
    state = EditProfileState(
      yearOfStudy: state.yearOfStudy,
      graduationYear: state.graduationYear,
      errors: errors,
      save: save,
    );
  }
}
