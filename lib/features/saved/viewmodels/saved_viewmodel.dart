import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../models/internship.dart';
import '../../../services/analytics_service.dart';
import '../../../services/saved_internship_service.dart';
import 'saved_providers.dart';

/// Saves and unsaves internships; the Save Toggle on a card calls [toggle].
///
/// The list itself is streamed by `savedInternshipsProvider`; this ViewModel
/// owns only the state of the write, so a failure can be shown without losing
/// the current list.
final savedViewModelProvider =
    NotifierProvider.autoDispose<SavedViewModel, AsyncValue<void>>(
      SavedViewModel.new,
    );

class SavedViewModel extends Notifier<AsyncValue<void>> {
  Set<String> _savedIds = const <String>{};

  @override
  AsyncValue<void> build() {
    // Mirror the saved keys so `toggle` knows which way to flip, and stay in
    // sync with the bookmark the card is showing.
    ref.listen(savedInternshipsProvider, (previous, next) {
      _savedIds = {
        for (final internship in next.asData?.value ?? const <Internship>[])
          internship.key,
      };
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
    if (state.isLoading) return;

    final service = ref.read(savedInternshipServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final isSaved = _savedIds.contains(internship.key);

    state = const AsyncLoading();
    try {
      if (isSaved) {
        await service.remove(internship.key);
      } else {
        await service.save(internship);
        await analytics.logEvent('internship_save', {
          'internship_id': internship.key,
          'source': source,
        });
      }
      if (ref.mounted) state = const AsyncData(null);
    } on AppException catch (error, stack) {
      if (ref.mounted) state = AsyncError(error, stack);
    }
  }
}
