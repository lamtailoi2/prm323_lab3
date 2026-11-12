import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/distinct_listings.dart';
import '../../../models/internship.dart';
import '../../../services/analytics_service.dart';
import '../../../services/saved_internship_service.dart';
import 'saved_providers.dart';

/// Outcome of [SavedViewModel.toggleAndReport], [SavedViewModel.remove] and
/// [SavedViewModel.restore].
///
/// `done = false, error = null` means the tap was ignored because another
/// saved write was still running, so the screen shows nothing for it.
typedef SavedWriteResult = ({bool done, AppException? error});

/// Saves and unsaves internships; the Save Toggle on a card calls [toggle],
/// the Saved screen calls [remove] and [restore] for unsave with Undo.
///
/// The list itself is streamed by `savedInternshipsProvider`; this ViewModel
/// owns only the state of the [toggle] write, so a failure can be shown
/// without losing the current list.
final savedViewModelProvider =
    NotifierProvider.autoDispose<SavedViewModel, AsyncValue<void>>(
      SavedViewModel.new,
    );

class SavedViewModel extends Notifier<AsyncValue<void>> {
  /// Saved document keys per job ([jobIdentity]). The card may show another
  /// synced copy of the job than the one saved, and saves made before CR-07
  /// can hold two copies of one job, so [toggleAndReport] unsaves every copy.
  Map<String, List<String>> _savedKeysByJob = const <String, List<String>>{};

  /// Serialises saved writes across screens, so a double tap never creates
  /// two Firestore writes (and two SnackBars) for the same action.
  bool _writing = false;

  @override
  AsyncValue<void> build() {
    // Mirror the saved jobs so `toggle` knows which way to flip, and stay in
    // sync with the bookmark the card is showing (`savedJobsProvider`).
    ref.listen(savedInternshipsProvider, (previous, next) {
      final byJob = <String, List<String>>{};
      for (final internship in next.asData?.value ?? const <Internship>[]) {
        byJob
            .putIfAbsent(_jobOf(internship), () => <String>[])
            .add(internship.key);
      }
      _savedKeysByJob = byJob;
    }, fireImmediately: true);

    return const AsyncData(null);
  }

  /// Saves [internship] when it is not saved yet, removes it otherwise.
  ///
  /// [source] is the screen that started the action (`home`, `search`, `saved`)
  /// and is sent with the `internship_save` event
  /// (docs/analytics-plan.md row 7).
  Future<void> toggle(Internship internship, {required String source}) async {
    // Ignore repeated taps while the previous write is still running.
    if (_writing) return;
    state = const AsyncLoading();
    // One write path for both callers (CR-06).
    final result = await toggleAndReport(internship, source: source);
    if (!ref.mounted) return;
    state = switch (result.error) {
      final error? => AsyncError(error, StackTrace.current),
      null => const AsyncData(null),
    };
  }

  /// Same as [toggle], but returns the outcome instead of storing it in
  /// [state], for screens that show their own SnackBar (Internship Detail).
  ///
  /// `HomeScreen` stays mounted under a pushed detail route and listens to
  /// [state], so a failure stored there would show a second SnackBar.
  Future<SavedWriteResult> toggleAndReport(
    Internship internship, {
    required String source,
  }) async {
    if (_writing) return (done: false, error: null);

    final service = ref.read(savedInternshipServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final savedKeys = _savedKeysByJob[_jobOf(internship)] ?? const <String>[];

    _writing = true;
    try {
      if (savedKeys.isNotEmpty) {
        // Remove the saved copies, not the key of the copy on the card (CR-07).
        for (final key in savedKeys) {
          await service.remove(key);
        }
      } else {
        await service.save(internship);
        await analytics.logEvent('internship_save', {
          'internship_id': internship.key,
          'source': source,
        });
      }
      return (done: true, error: null);
    } on AppException catch (error) {
      return (done: false, error: error);
    } finally {
      _writing = false;
    }
  }

  /// Removes [internship] from the saved list (Flow 2e.1, unsave with Undo).
  ///
  /// The failure is returned instead of stored in [state]: the Saved screen
  /// shows it in its own SnackBar, and `HomeScreen` already listens to [state]
  /// for errors, so storing it would show the same message twice.
  Future<SavedWriteResult> remove(Internship internship) async {
    if (_writing) return (done: false, error: null);

    final service = ref.read(savedInternshipServiceProvider);

    _writing = true;
    try {
      await service.remove(internship.key);
      return (done: true, error: null);
    } on AppException catch (error) {
      return (done: false, error: error);
    } finally {
      _writing = false;
    }
  }

  /// Saves [internship] again after the student taps Undo (Flow 2e.1).
  ///
  /// Reuses the first-save path, including the `internship_save` event, so the
  /// restored item is counted exactly like any other save. Firestore writes the
  /// same `users/{uid}/savedInternships/{key}` document, so restoring twice
  /// never creates a duplicate record.
  Future<SavedWriteResult> restore(Internship internship) async {
    if (_writing) return (done: false, error: null);

    final service = ref.read(savedInternshipServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    _writing = true;
    try {
      await service.save(internship);
      await analytics.logEvent('internship_save', {
        'internship_id': internship.key,
        'source': 'saved',
      });
      return (done: true, error: null);
    } on AppException catch (error) {
      return (done: false, error: error);
    } finally {
      _writing = false;
    }
  }

  static String _jobOf(Internship internship) =>
      jobIdentity(internship.title, internship.companyName);
}
