import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/skill_matcher.dart';
import '../../../services/analytics_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_profile_service.dart';
import 'profile_viewmodel.dart';

@immutable
class EditSkillsState {
  const EditSkillsState({
    required this.selected,
    required this.suggestions,
    this.query = '',
    this.save = const AsyncData(null),
    this.ready = true,
  });

  /// In the order the student added them.
  final List<String> selected;

  /// Skills matching [query]: the opening selection first, then the rest
  /// of [knownSkills].
  final List<String> suggestions;
  final String query;
  final AsyncValue<void> save;

  /// `false` until the profile has loaded. The draft starts from the
  /// profile's skills, so editing or saving before then would replace them
  /// with an empty list (the sheet also opens from the Apply Form, where the
  /// Profile tab may not have loaded yet).
  final bool ready;
}

final editSkillsViewModelProvider =
    NotifierProvider.autoDispose<EditSkillsViewModel, EditSkillsState>(
      EditSkillsViewModel.new,
    );

/// Draft of the Edit skills sheet; nothing is stored until [save].
///
/// Suggestions come from [knownSkills], the vocabulary that tags listings,
/// so a profile skill can always be compared with a listing's skills
/// (G-23, G-24).
class EditSkillsViewModel extends Notifier<EditSkillsState> {
  /// [knownSkills] with the skills the sheet opened with first, as in the
  /// Edit Skills frame; fixed while the sheet is open so chips do not jump.
  List<String> _vocabulary = knownSkills;

  @override
  EditSkillsState build() {
    // Seeded once from the profile; later profile updates must not reset
    // the student's draft. Opened from the Apply Form before the Profile tab
    // ever loaded, the profile is still loading: the sheet then waits for
    // its first snapshot instead of starting from an empty list. Listening
    // also keeps the auto-dispose profile alive while the sheet is open.
    ref.listen(profileViewModelProvider, (_, next) {
      if (state.ready) return;
      if (next case ViewData(:final data)) {
        state = _seeded(data.profile.skills);
      }
    });
    return switch (ref.read(profileViewModelProvider)) {
      ViewData(:final data) => _seeded(data.profile.skills),
      _ => const EditSkillsState(
        selected: <String>[],
        suggestions: knownSkills,
        ready: false,
      ),
    };
  }

  EditSkillsState _seeded(List<String> skills) {
    _vocabulary = List.unmodifiable([
      ...skills.where(knownSkills.contains),
      ...knownSkills.where((skill) => !skills.contains(skill)),
    ]);
    return EditSkillsState(
      selected: List.unmodifiable(skills),
      suggestions: _vocabulary,
    );
  }

  void toggle(String skill) {
    if (!state.ready) return;
    final selected = state.selected.contains(skill)
        ? state.selected.where((item) => item != skill)
        : [...state.selected, skill];
    _update(selected: List.unmodifiable(selected));
  }

  void clearAll() {
    if (!state.ready) return;
    _update(selected: const <String>[]);
  }

  void search(String query) {
    final needle = query.trim().toLowerCase();
    _update(
      query: query,
      suggestions: needle.isEmpty
          ? _vocabulary
          : List.unmodifiable(
              _vocabulary.where(
                (skill) => skill.toLowerCase().contains(needle),
              ),
            ),
    );
  }

  /// Returns `true` once the skills are stored.
  Future<bool> save() async {
    if (state.save.isLoading || !state.ready) return false;
    final service = ref.read(userProfileServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return false;

    final skills = state.selected;
    _update(save: const AsyncLoading());
    try {
      await service.updateSkills(uid, skills);
      await analytics.logEvent('profile_update', {
        'section': 'skills',
        'item_count': skills.length,
      });
      if (ref.mounted) _update(save: const AsyncData(null));
      return true;
    } on AppException catch (error, stack) {
      if (ref.mounted) _update(save: AsyncError(error, stack));
      return false;
    }
  }

  void _update({
    List<String>? selected,
    List<String>? suggestions,
    String? query,
    AsyncValue<void>? save,
  }) {
    state = EditSkillsState(
      selected: selected ?? state.selected,
      suggestions: suggestions ?? state.suggestions,
      query: query ?? state.query,
      save: save ?? state.save,
      ready: state.ready,
    );
  }
}
