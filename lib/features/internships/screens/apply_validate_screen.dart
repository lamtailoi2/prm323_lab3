import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/state/view_state.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_view.dart';
import '../../../theme/app_spacing.dart';
import '../../applications/widgets/cv_validation_step.dart';
import '../viewmodels/apply_form_viewmodel.dart';
import '../widgets/apply_form_parts.dart';

/// Validate CV step (Flow 4): the generic LLM quality gate between the
/// Apply Form (Pre-submit Complete) and Confirm Application.
///
/// A rejected CV sends the student back to the form to replace it; a valid
/// CV continues automatically. Cancelling returns to Internship Detail.
class ApplyValidateScreen extends ConsumerStatefulWidget {
  const ApplyValidateScreen({
    super.key,
    required this.internshipKey,
    required this.source,
  });

  final String internshipKey;
  final String source;

  @override
  ConsumerState<ApplyValidateScreen> createState() =>
      _ApplyValidateScreenState();
}

class _ApplyValidateScreenState extends ConsumerState<ApplyValidateScreen> {
  ApplyFormArgs get _args =>
      (internshipKey: widget.internshipKey, source: widget.source);

  /// The valid result can be delivered more than once while the route
  /// changes; `pushReplacement` must only run once.
  bool _continued = false;

  void _continue() {
    if (_continued || !mounted) return;
    _continued = true;
    context.pushReplacement(
      AppRoutes.applyConfirm(widget.source, widget.internshipKey),
    );
  }

  void _cancel() {
    context.go(AppRoutes.internshipDetail(widget.source, widget.internshipKey));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(applyFormViewModelProvider(_args));
    final viewModel = ref.read(applyFormViewModelProvider(_args).notifier);

    return Scaffold(
      appBar: AppTopBar.back(
        title: 'Validate CV',
        actions: [TextButton(onPressed: _cancel, child: const Text('Cancel'))],
      ),
      body: switch (state.internship) {
        ViewLoading() => const Center(
          child: StateView.loading(message: 'Loading this internship…'),
        ),
        ViewEmpty() => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: StateView.empty(
              icon: Symbols.work_off_rounded,
              title: 'This internship is no longer available',
              message: 'It may have closed or been removed from Google Jobs.',
              actionLabel: 'Back',
              onAction: () => Navigator.maybePop(context),
            ),
          ),
        ),
        ViewError(:final error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: StateView.error(
              message: error.message,
              onRetry: viewModel.retry,
            ),
          ),
        ),
        ViewData(:final data) => Column(
          children: [
            const ApplyStepHeader.cvCheck(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                children: [
                  ApplySummaryCard(internship: data),
                  if (state.cv case final cv?) ...[
                    const SizedBox(height: AppSpacing.s16),
                    CvValidationStep(
                      storagePath: cv.file.storagePath,
                      onValid: _continue,
                      // Back to the Apply Form, where the CV section offers
                      // Replace / Upload; the next Continue runs this check
                      // again (Flow 4: CV Invalid → Update CV → Retry).
                      onUpdateCv: () => Navigator.maybePop(context),
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.s16),
                    StateView.empty(
                      icon: Symbols.description_rounded,
                      title: 'Your CV is not ready',
                      message:
                          'Go back to the Apply Form and choose a CV to '
                          'continue.',
                      actionLabel: 'Back',
                      onAction: () => Navigator.maybePop(context),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      },
    );
  }
}
