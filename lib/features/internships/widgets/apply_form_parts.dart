import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/allowance.dart';
import '../../../core/utils/display_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/cv_file_tile.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../models/internship.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/apply_form_viewmodel.dart';
import 'detail_parts.dart';

/// "Step 1 of 2 · Your details" with the two-segment progress of the Apply
/// Form frames, and "Step 2 of 2 · Review & submit" on Application Review
/// (both segments filled).
class ApplyStepHeader extends StatelessWidget {
  const ApplyStepHeader({super.key}) : _step = 1;

  const ApplyStepHeader.review({super.key}) : _step = 2;

  final int _step;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isReview = _step == 2;
    final upcoming = isReview ? AppColors.primary : AppColors.border;
    return Semantics(
      container: true,
      label: isReview
          ? 'Step 2 of 2, review and submit'
          : 'Step 1 of 2, your details. Next: review',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s4,
            AppSpacing.s16,
            AppSpacing.s12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isReview
                          ? 'Step 2 of 2 · Review & submit'
                          : 'Step 1 of 2 · Your details',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (!isReview)
                    Text(
                      'Review',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Row(
                children: [
                  const Expanded(child: _StepBar(color: AppColors.primary)),
                  const SizedBox(width: AppSpacing.s8),
                  Expanded(child: _StepBar(color: upcoming)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.s4,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, borderRadius: AppRadii.fullAll),
      ),
    );
  }
}

/// Internship summary card at the top of the Apply Form: logo, title,
/// `Company · Work mode` (or the location when Google gives no work mode)
/// and the allowance and job type from the Detail key facts.
class ApplySummaryCard extends StatelessWidget {
  const ApplySummaryCard({super.key, required this.internship});

  final Internship internship;

  static const String _notDisclosed = 'Not disclosed';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final subtitle = [
      internship.companyName,
      ?(internship.workMode?.label ?? internship.location),
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.largeAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DetailCompanyLogo(
                companyName: internship.companyName,
                size: AppSizes.companyLogoLarge,
                url: internship.logoUrl,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      internship.title,
                      style: textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s16,
            runSpacing: AppSpacing.s8,
            children: [
              _SummaryFact(
                icon: Symbols.payments_rounded,
                label: 'Allowance',
                value: formatAllowance(internship.salary),
              ),
              _SummaryFact(
                icon: Symbols.work_history_rounded,
                label: 'Job type',
                value: internship.scheduleType ?? _notDisclosed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One Detail key fact in the summary card: icon and value, read with its
/// label (e.g. "Allowance: Negotiable").
class _SummaryFact extends StatelessWidget {
  const _SummaryFact({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSmall, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.s4),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

/// Figma "Info Banner" of the Apply Form: `We filled this in from your
/// Profile…` + `Edit profile` when the CV comes from Profile, or the
/// neutral tip + `Go to Profile` when Profile has no CV yet.
class ApplyInfoBanner extends StatelessWidget {
  const ApplyInfoBanner.fromProfile({super.key, required this.onAction})
    : _tip = false;

  const ApplyInfoBanner.tip({super.key, required this.onAction}) : _tip = true;

  final VoidCallback onAction;
  final bool _tip;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s12,
        AppSpacing.s16,
        AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: _tip ? AppColors.surfaceVariant : AppColors.primaryContainer,
        borderRadius: AppRadii.mediumAll,
        border: _tip ? Border.all(color: AppColors.border) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _tip ? Symbols.lightbulb_rounded : Symbols.info_rounded,
                size: AppSizes.iconSmall,
                color: _tip ? AppColors.textSecondary : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  _tip
                      ? 'Tip: complete your Profile once and we will fill '
                            'this in for you next time.'
                      : 'We filled this in from your Profile. Check it '
                            'before you continue.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          // On its own line (not inline as in Figma) so the link keeps a
          // 48 dp target.
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.s16),
            child: AppButton(
              label: _tip ? 'Go to Profile' : 'Edit profile',
              variant: AppButtonVariant.text,
              onPressed: onAction,
            ),
          ),
        ],
      ),
    );
  }
}

/// The CV / Resume section of the Apply Form frames: waiting for the
/// profile, CV ready (from Profile or uploaded), no CV (with the "Add a CV to
/// continue" error), and the uploading / failed states for an upload that
/// keeps running after the CV sheet is closed (the sheet shows its own
/// progress and error while it is open).
class ApplyCvSection extends StatelessWidget {
  const ApplyCvSection({
    super.key,
    required this.state,
    required this.onChoose,
    required this.onRetry,
    required this.onUseProfileCv,
    required this.onPreview,
    required this.onRetryProfile,
  });

  final ApplyFormState state;
  final VoidCallback onChoose;
  final VoidCallback onRetry;
  final VoidCallback onUseProfileCv;
  final VoidCallback onPreview;
  final VoidCallback onRetryProfile;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      icon: Symbols.description_rounded,
      title: 'CV / Resume',
      isRequired: true,
      children: [_content()],
    );
  }

  Widget _content() {
    if (!state.profileLoaded) {
      return const SkeletonBox(
        height: AppSizes.minTouchTarget + AppSpacing.s24,
        borderRadius: AppRadii.mediumAll,
      );
    }
    if (state.progress case final progress?) {
      return _UploadingCard(
        fileName: state.pending?.name ?? '',
        progress: progress,
      );
    }
    if (state.uploadError case final error?) {
      return _UploadFailed(
        message: error.message,
        canRetry: state.canRetry,
        hasProfileCv: state.profileCv != null,
        onRetry: onRetry,
        onChoose: onChoose,
        onUseProfileCv: onUseProfileCv,
      );
    }
    if (state.cv case final cv?) {
      return _SelectedCv(cv: cv, onPreview: onPreview, onReplace: onChoose);
    }
    if (state.profileError case final error?) {
      return _ProfileFailed(
        message: error.message,
        onRetry: onRetryProfile,
        onUpload: onChoose,
      );
    }
    return _CvDropzone(showError: state.missingCv, onUpload: onChoose);
  }
}

class _SelectedCv extends StatelessWidget {
  const _SelectedCv({
    required this.cv,
    required this.onPreview,
    required this.onReplace,
  });

  final ApplyCv cv;
  final VoidCallback onPreview;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CvFileTile(
          fileName: cv.file.fileName,
          details: '${formatFileSize(cv.file.sizeBytes)} · PDF',
          badge: Text(
            cv.source == CvSource.profile
                ? 'From your Profile'
                : 'Uploaded for this internship',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Padding(
          padding: const EdgeInsets.only(left: AppSizes.fileTile),
          child: Wrap(
            children: [
              AppButton(
                label: 'Preview',
                icon: Symbols.visibility_rounded,
                variant: AppButtonVariant.text,
                onPressed: onPreview,
              ),
              AppButton(
                label: 'Replace',
                icon: Symbols.upload_file_rounded,
                variant: AppButtonVariant.text,
                onPressed: onReplace,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadingCard extends StatelessWidget {
  const _UploadingCard({required this.fileName, required this.progress});

  final String fileName;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.mediumAll,
        border: Border.all(color: AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Symbols.upload_file_rounded,
                size: AppSizes.icon,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: textTheme.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ExcludeSemantics(
                      child: Text(
                        'Uploading… $percent%',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Semantics(
            label: 'Uploading CV',
            value: '$percent%',
            child: ClipRRect(
              borderRadius: AppRadii.fullAll,
              child: LinearProgressIndicator(value: progress),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadFailed extends StatelessWidget {
  const _UploadFailed({
    required this.message,
    required this.canRetry,
    required this.hasProfileCv,
    required this.onRetry,
    required this.onChoose,
    required this.onUseProfileCv,
  });

  final String message;
  final bool canRetry;
  final bool hasProfileCv;
  final VoidCallback onRetry;
  final VoidCallback onChoose;
  final VoidCallback onUseProfileCv;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // White with an error border: the design system has no error container
    // color ("never invented semantic tints").
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Symbols.error_rounded,
                  size: AppSizes.iconSmall,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    'CV could not be uploaded',
                    style: textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                // Sending the same file again only helps after a network
                // failure; a file that is not a PDF or too large needs
                // another file.
                if (canRetry)
                  AppButton(
                    label: 'Retry',
                    icon: Symbols.refresh_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: onRetry,
                  )
                else
                  AppButton(
                    label: 'Upload CV',
                    icon: Symbols.attach_file_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: onChoose,
                  ),
                if (hasProfileCv)
                  AppButton(
                    label: 'Use CV from Profile',
                    variant: AppButtonVariant.text,
                    onPressed: onUseProfileCv,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The Profile CV could not be loaded (CR-18): the reason, `Retry`, and
/// `Upload CV` so the student is not stuck.
class _ProfileFailed extends StatelessWidget {
  const _ProfileFailed({
    required this.message,
    required this.onRetry,
    required this.onUpload,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onUpload;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                AppButton(
                  label: 'Retry',
                  icon: Symbols.refresh_rounded,
                  variant: AppButtonVariant.secondary,
                  onPressed: onRetry,
                ),
                AppButton(
                  label: 'Upload CV',
                  icon: Symbols.attach_file_rounded,
                  variant: AppButtonVariant.text,
                  onPressed: onUpload,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// No CV yet. A solid border stands in for the dashed "Upload Dropzone"
/// outline, as in the Profile Update CV sheet; after `Continue to review`
/// without a CV it turns red with the frame's message.
class _CvDropzone extends StatelessWidget {
  const _CvDropzone({required this.showError, required this.onUpload});

  final bool showError;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.mediumAll,
            border: Border.all(
              color: showError ? AppColors.error : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              ExcludeSemantics(
                child: FileTileIcon(icon: Symbols.upload_file_rounded),
              ),
              const SizedBox(height: AppSpacing.s12),
              Text(
                'PDF, up to 10 MB',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              AppButton(
                label: 'Upload CV',
                icon: Symbols.attach_file_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: onUpload,
              ),
            ],
          ),
        ),
        if (showError) ...[
          const SizedBox(height: AppSpacing.s8),
          Semantics(
            liveRegion: true,
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
                    'Add a CV to continue. Companies need it to review your '
                    'application.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Bottom action bar: `Continue to review`, disabled with `Wait for your CV
/// to finish uploading` while a CV uploads (Form · CV uploading).
class ApplyBottomBar extends StatelessWidget {
  const ApplyBottomBar({
    super.key,
    required this.isUploading,
    required this.onContinue,
  });

  final bool isUploading;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
              if (isUploading) ...[
                Text(
                  'Wait for your CV to finish uploading',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
              ],
              AppButton(
                label: 'Continue to review',
                onPressed: isUploading ? null : onContinue,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading layout of the Apply Form: summary card and CV section outlines.
class ApplyFormSkeleton extends StatelessWidget {
  const ApplyFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: const [
        SkeletonBox(height: AppSizes.companyLogoLarge + AppSpacing.s32),
        SizedBox(height: AppSpacing.s16),
        SkeletonBox(height: AppSizes.minTouchTarget + AppSpacing.s32),
        SizedBox(height: AppSpacing.s16),
        SkeletonBox(height: AppSizes.minTouchTarget * 3),
      ],
    );
  }
}
