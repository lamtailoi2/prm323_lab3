import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/display_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/cv_file_tile.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/internship.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/apply_confirm_viewmodel.dart';
import '../viewmodels/apply_form_viewmodel.dart';
import '../widgets/apply_form_parts.dart';
import '../widgets/detail_parts.dart';

/// Confirm Application step (Flow 4).
///
/// The student reviews the listing and CV, opens the employer's own
/// application page, and comes back to record the application with status
/// `submitted`; My Applications then shows it. When the listing shares no
/// employer page the application can still be recorded (G-25 #6).
class ApplyConfirmScreen extends ConsumerStatefulWidget {
  const ApplyConfirmScreen({
    super.key,
    required this.internshipKey,
    required this.source,
  });

  final String internshipKey;
  final String source;

  @override
  ConsumerState<ApplyConfirmScreen> createState() => _ApplyConfirmScreenState();
}

class _ApplyConfirmScreenState extends ConsumerState<ApplyConfirmScreen> {
  ApplyFormArgs get _args =>
      (internshipKey: widget.internshipKey, source: widget.source);

  ApplyConfirmViewModel get _viewModel =>
      ref.read(applyConfirmViewModelProvider(_args).notifier);

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      // The student came back from the employer website.
      onResume: _viewModel.onReturned,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _cancel() {
    context.go(AppRoutes.internshipDetail(widget.source, widget.internshipKey));
  }

  Future<void> _primary(Internship internship) async {
    switch (ref.read(applyConfirmViewModelProvider(_args)).phase) {
      case ApplyConfirmPhase.ready:
        final url = internship.employerApplyUrl;
        if (url == null) {
          await _submit();
        } else {
          await _viewModel.openEmployer(Uri.parse(url));
        }
      case ApplyConfirmPhase.awaitingReturn:
        await _submit();
      case ApplyConfirmPhase.saveFailed:
        await _submit();
      case ApplyConfirmPhase.redirectFailed:
        _viewModel.retry();
      case ApplyConfirmPhase.redirecting ||
          ApplyConfirmPhase.saving ||
          ApplyConfirmPhase.saved:
        break;
    }
  }

  Future<void> _submit() async {
    final saved = await _viewModel.submit();
    if (!saved || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Application saved to My Applications.')),
      );
    context.go(AppRoutes.applications);
  }

  Future<void> _preview() async {
    final error = await ref
        .read(applyFormViewModelProvider(_args).notifier)
        .previewCv();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(applyFormViewModelProvider(_args));
    final confirm = ref.watch(applyConfirmViewModelProvider(_args));
    final internship = switch (form.internship) {
      ViewData(:final data) => data,
      _ => null,
    };
    final cv = form.cv;

    return Scaffold(
      appBar: AppTopBar.back(
        title: 'Confirm Application',
        actions: [TextButton(onPressed: _cancel, child: const Text('Cancel'))],
      ),
      body: internship == null || cv == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: StateView.empty(
                  icon: Symbols.description_rounded,
                  title: 'Your CV is not ready',
                  message:
                      'Go back to the Apply Form and choose a CV to '
                      'continue.',
                  actionLabel: 'Back',
                  onAction: () => Navigator.maybePop(context),
                ),
              ),
            )
          : Column(
              children: [
                const ApplyStepHeader.confirm(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    children: [
                      ApplySummaryCard(internship: internship),
                      const SizedBox(height: AppSpacing.s16),
                      DetailSectionCard(
                        icon: Symbols.description_rounded,
                        title: 'CV / Resume',
                        children: [
                          CvFileTile(
                            fileName: cv.file.fileName,
                            details:
                                '${formatFileSize(cv.file.sizeBytes)} · PDF',
                            badge: Text(
                              cv.source == CvSource.profile
                                  ? 'From your Profile'
                                  : 'Uploaded for this internship',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppSizes.fileTile,
                            ),
                            child: AppButton(
                              label: 'Preview',
                              icon: Symbols.visibility_rounded,
                              variant: AppButtonVariant.text,
                              onPressed: () => unawaited(_preview()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      _EmployerCard(
                        internship: internship,
                        phase: confirm.phase,
                        returned: confirm.returned,
                      ),
                      if (confirm.error case final error?) ...[
                        const SizedBox(height: AppSpacing.s16),
                        _ErrorCard(message: error.message),
                      ],
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: internship == null || cv == null
          ? null
          : _bottomBar(internship, confirm),
    );
  }

  Widget _bottomBar(Internship internship, ApplyConfirmState confirm) {
    final hasEmployerLink = internship.employerApplyUrl != null;
    final hasShareLink = internship.shareUrl != null;
    final (label, loading) = switch (confirm.phase) {
      ApplyConfirmPhase.ready => (
        hasEmployerLink ? 'Continue to employer website' : 'Mark as applied',
        false,
      ),
      ApplyConfirmPhase.redirecting => ('Opening employer website…', true),
      ApplyConfirmPhase.redirectFailed => ('Try again', false),
      ApplyConfirmPhase.awaitingReturn => (
        "I've submitted my application",
        false,
      ),
      ApplyConfirmPhase.saving => ('Saving your application…', true),
      ApplyConfirmPhase.saved => ('Saved', true),
      ApplyConfirmPhase.saveFailed => ('Retry', false),
    };
    final canPress =
        confirm.phase != ApplyConfirmPhase.redirecting &&
        confirm.phase != ApplyConfirmPhase.saving &&
        confirm.phase != ApplyConfirmPhase.saved;

    final Widget? secondary;
    if (confirm.phase == ApplyConfirmPhase.ready &&
        !hasEmployerLink &&
        hasShareLink) {
      secondary = AppButton(
        label: 'Open listing on Google Jobs',
        variant: AppButtonVariant.text,
        onPressed: () {
          final url = internship.shareUrl;
          if (url != null) {
            unawaited(_viewModel.openListing(Uri.parse(url)));
          }
        },
      );
    } else if (confirm.phase == ApplyConfirmPhase.awaitingReturn &&
        hasEmployerLink) {
      secondary = AppButton(
        label: 'Open the website again',
        variant: AppButtonVariant.text,
        onPressed: _viewModel.reopen,
      );
    } else {
      secondary = null;
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppButton(
                label: label,
                isLoading: loading,
                onPressed: canPress
                    ? () => unawaited(_primary(internship))
                    : null,
                expand: true,
              ),
              if (secondary != null) ...[
                const SizedBox(height: AppSpacing.s4),
                secondary,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The employer / Google Jobs row: where the application continues and what
/// to do when the listing shares no link.
class _EmployerCard extends StatelessWidget {
  const _EmployerCard({
    required this.internship,
    required this.phase,
    required this.returned,
  });

  final Internship internship;
  final ApplyConfirmPhase phase;
  final bool returned;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasEmployerLink = internship.employerApplyUrl != null;
    final company = internship.companyName;
    final awaiting = phase == ApplyConfirmPhase.awaitingReturn;

    final String message;
    if (!hasEmployerLink) {
      message =
          'This listing does not share an employer application link. You '
          'can still record it in My Applications.';
    } else if (awaiting && returned) {
      message =
          'Welcome back. Confirm once you have submitted your application '
          "on $company's website.";
    } else if (awaiting) {
      message =
          "Finish your application on $company's website, then come back "
          'here.';
    } else {
      message =
          "You will finish this application on $company's website. Internly "
          'keeps it in My Applications so you can track it.';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.largeAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Symbols.open_in_new_rounded,
            size: AppSizes.iconSmall,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Application website', style: textTheme.labelLarge),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadii.mediumAll,
          border: Border.all(color: AppColors.error),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Symbols.error_rounded,
              size: AppSizes.iconSmall,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
