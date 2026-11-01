import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../models/cv_validation_result.dart';
import '../../../services/analytics_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/cv_validation_service.dart';

/// State of the CV quality gate in the Apply flow.
///
/// `ViewEmpty` is the idle state before the step starts; `ViewLoading` is the
/// "Checking your CV…" step; `ViewData` carries both outcomes (a rejected CV
/// is data, not an app error); `ViewError` is a check that could not run.
final cvValidationViewModelProvider =
    NotifierProvider.autoDispose<
      CvValidationViewModel,
      ViewState<CvValidationResult>
    >(CvValidationViewModel.new);

class CvValidationViewModel extends Notifier<ViewState<CvValidationResult>> {
  @override
  ViewState<CvValidationResult> build() {
    // User-scoped (AGENTS.md rule 11): sign-out drops the result.
    ref.watch(currentUserIdProvider);
    return const ViewEmpty<CvValidationResult>();
  }

  /// Runs the check and returns its result, or `null` when it could not run.
  Future<CvValidationResult?> validate(String storagePath) async {
    // Ignore repeated taps while a check is in flight.
    if (state.isLoading) return null;

    final service = ref.read(cvValidationServiceProvider);
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
      final result = await service.validate(storagePath);
      await analytics.logEvent('cv_validation_result', <String, Object>{
        'is_valid': result.isValid,
      });
      if (!ref.mounted) return result;
      state = ViewData(result);
      return result;
    } on AppException catch (error) {
      if (ref.mounted) state = ViewError(error);
      return null;
    } on Exception catch (error) {
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
}
