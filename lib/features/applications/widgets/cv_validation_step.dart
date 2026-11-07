import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/state/view_state.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/cv_validation_result.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/cv_validation_viewmodel.dart';

/// The "Validate CV" step between the Application Form and Confirm
/// Application.
///
/// Generic quality gate: a rejected CV blocks submission and offers
/// `Update CV` + `Retry`; a check that cannot run does the same without
/// pretending the CV is invalid. The future Apply screen embeds this widget
/// and passes the CV path plus its navigation callbacks.
class CvValidationStep extends ConsumerStatefulWidget {
  const CvValidationStep({
    super.key,
    required this.storagePath,
    this.onValid,
    this.onUpdateCv,
  });

  /// `cvs/{uid}/…` object path of the default CV.
  final String storagePath;

  /// Called once when the CV passes, so the flow can continue automatically.
  final VoidCallback? onValid;

  /// Opens the existing replace-CV flow (`update_cv_sheet.dart`).
  final VoidCallback? onUpdateCv;

  @override
  ConsumerState<CvValidationStep> createState() => _CvValidationStepState();
}

class _CvValidationStepState extends ConsumerState<CvValidationStep> {
  ProviderSubscription<String?>? _authSubscription;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // The Apply flow is signed-in only; run as soon as the auth state is known
    // instead of racing the first auth event.
    _authSubscription = ref.listenManual<String?>(currentUserIdProvider, (
      previous,
      next,
    ) {
      if (next != null && !_started) _start();
    }, fireImmediately: true);
  }

  /// Starts the check after the current frame. `fireImmediately` runs inside
  /// `initState`, and Riverpod forbids a provider change while the widget
  /// tree is building (the signed-in uid is already known when the step
  /// opens from the Apply flow).
  void _start() {
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_run());
    });
  }

  @override
  void dispose() {
    _authSubscription?.close();
    super.dispose();
  }

  Future<void> _run() async {
    await ref
        .read(cvValidationViewModelProvider.notifier)
        .validate(widget.storagePath);
  }

  void _retry() => unawaited(_run());

  @override
  Widget build(BuildContext context) {
    ref.listen<ViewState<CvValidationResult>>(cvValidationViewModelProvider, (
      previous,
      next,
    ) {
      if (next is ViewData<CvValidationResult> && next.data.isValid) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onValid?.call();
        });
      }
    });

    final state = ref.watch(cvValidationViewModelProvider);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
        vertical: AppSpacing.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (state) {
            ViewLoading<CvValidationResult>() ||
            ViewEmpty<CvValidationResult>() => const StateView.loading(
              message: 'Checking your CV…',
            ),
            ViewData<CvValidationResult>(:final data) when data.isValid =>
              const _ValidPanel(),
            ViewData<CvValidationResult>(:final data) => _FailurePanel(
              title: 'We could not use this CV',
              message:
                  data.reason ??
                  'This file does not look like a usable CV. '
                      'Update your CV and try again.',
              onRetry: _retry,
              onUpdateCv: widget.onUpdateCv,
            ),
            ViewError<CvValidationResult>(:final error) => _FailurePanel(
              title: 'We could not check your CV',
              message: error.message,
              onRetry: _retry,
              onUpdateCv: widget.onUpdateCv,
            ),
          },
          const SizedBox(height: AppSpacing.s24),
          // Transparency required by G-24 item 3: the PDF text leaves the
          // device for this check.
          Text(
            'For this check, text from your CV is sent to our server.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ValidPanel extends StatelessWidget {
  const _ValidPanel();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Symbols.check_circle_rounded,
            size: AppSizes.icon,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'Your CV looks good',
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'You can continue to confirm your application.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FailurePanel extends StatelessWidget {
  const _FailurePanel({
    required this.title,
    required this.message,
    required this.onRetry,
    required this.onUpdateCv,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onUpdateCv;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Symbols.error_rounded,
            size: AppSizes.icon,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(
            title,
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            message,
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.s24),
          AppButton(
            label: 'Update CV',
            icon: Symbols.upload_file_rounded,
            expand: true,
            onPressed: onUpdateCv,
          ),
          const SizedBox(height: AppSpacing.s8),
          AppButton(
            label: 'Retry',
            icon: Symbols.refresh_rounded,
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
