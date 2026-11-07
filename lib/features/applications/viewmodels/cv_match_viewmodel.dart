import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../models/cv_match_result.dart';
import '../../../services/analytics_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/cv_match_service.dart';

/// Advisory CV Match Check for the internship being applied to (G-24/DC-09).
///
/// `ViewLoading` while the callable runs, `ViewData` for all outcomes
/// (including a rejected / partly matched CV), `ViewError` when the check
/// itself could not run. It never blocks: the screen keeps `Continue`
/// available in every state.
final cvMatchViewModelProvider =
    NotifierProvider.autoDispose<CvMatchViewModel, ViewState<CvMatchResult>>(
      CvMatchViewModel.new,
    );

class CvMatchViewModel extends Notifier<ViewState<CvMatchResult>> {
  @override
  ViewState<CvMatchResult> build() {
    // User-scoped (AGENTS.md rule 11): sign-out drops the result.
    ref.watch(currentUserIdProvider);
    return const ViewEmpty<CvMatchResult>();
  }

  /// Runs the check; returns the result, or `null` when it could not run.
  Future<CvMatchResult?> run({
    required String storagePath,
    required String internshipKey,
  }) async {
    // Ignore repeated taps while a check is in flight.
    if (state.isLoading) return null;

    final service = ref.read(cvMatchServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);
    if (ref.read(currentUserIdProvider) == null) {
      state = const ViewError(
        AppException(
          AppErrorKind.permissionDenied,
          'Sign in to check your CV.',
        ),
      );
      return null;
    }

    state = const ViewLoading();
    try {
      final result = await service.match(
        storagePath: storagePath,
        internshipKey: internshipKey,
      );
      if (result.hasRequirements) {
        unawaited(
          analytics.logEvent('cv_match_check', <String, Object>{
            'internship_id': internshipKey,
            'result': result.missing.isEmpty ? 'all_matched' : 'gaps',
            'matched_count': result.matchedCount,
            'missing_count': result.missing.length,
          }),
        );
      }
      if (!ref.mounted) return result;
      state = ViewData(result);
      return result;
    } on AppException catch (error) {
      unawaited(_logFailure(analytics, internshipKey));
      if (ref.mounted) state = ViewError(error);
      return null;
    } on Exception catch (error) {
      unawaited(_logFailure(analytics, internshipKey));
      if (ref.mounted) {
        state = ViewError(
          AppException(
            AppErrorKind.unknown,
            'We could not check your CV. Please try again.',
            cause: error,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _logFailure(AnalyticsService analytics, String internshipKey) {
    return analytics.logEvent('cv_match_check', <String, Object>{
      'internship_id': internshipKey,
      'result': 'failed',
      'matched_count': 0,
      'missing_count': 0,
    });
  }
}
