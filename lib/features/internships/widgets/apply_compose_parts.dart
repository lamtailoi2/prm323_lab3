import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/display_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/cv_file_tile.dart';
import '../../../core/widgets/detail_section_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';

/// Banner above the draft: what the AI did, that it may be wrong, and the
/// failure message when the call itself failed.
class ApplyDraftBanner extends StatelessWidget {
  const ApplyDraftBanner({
    super.key,
    required this.isGenerating,
    required this.usedAi,
    required this.error,
    required this.onRetry,
  });

  final bool isGenerating;
  final bool usedAi;
  final AppException? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final error = this.error;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: error == null
              ? AppColors.primaryContainer
              : AppColors.surfaceVariant,
          borderRadius: AppRadii.mediumAll,
          border: error == null ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  error == null
                      ? Symbols.auto_awesome_rounded
                      : Symbols.info_rounded,
                  size: AppSizes.iconSmall,
                  color: error == null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: Text(
                    isGenerating
                        ? 'Drafting your email from the job description…'
                        : error != null
                        ? error.message
                        : usedAi
                        ? 'Drafted from the job description and your Profile. '
                              'AI can make mistakes, so check it before you '
                              'send.'
                        : 'The AI service was unavailable, so this is a '
                              'template. Edit it before you send.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.s4),
              AppButton(
                label: 'Retry',
                icon: Symbols.refresh_rounded,
                variant: AppButtonVariant.text,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The recipient (`To`) field, with the reason it was or was not prefilled.
class ApplyRecipientSection extends StatelessWidget {
  const ApplyRecipientSection({
    super.key,
    required this.controller,
    required this.foundInJobPost,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool foundInJobPost;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      icon: Symbols.alternate_email_rounded,
      title: 'To',
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'recruiter@company.com',
            helperText: foundInJobPost
                ? 'We found this address in the job post. Change it if needed.'
                : 'Add the recruiter email from the job post, or leave it '
                      'empty and pick a recipient in your email app.',
            errorText: error,
            helperMaxLines: 2,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// The subject line of the email.
class ApplySubjectSection extends StatelessWidget {
  const ApplySubjectSection({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      icon: Symbols.subject_rounded,
      title: 'Subject',
      children: [
        TextField(
          controller: controller,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'Application for …'),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// The cover letter, its character count and the explicit `Regenerate`.
class ApplyCoverLetterSection extends StatelessWidget {
  const ApplyCoverLetterSection({
    super.key,
    required this.controller,
    required this.isGenerating,
    required this.onChanged,
    required this.onRegenerate,
  });

  final TextEditingController controller;
  final bool isGenerating;
  final ValueChanged<String> onChanged;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DetailSectionCard(
      icon: Symbols.edit_note_rounded,
      title: 'Cover letter',
      action: AppButton(
        label: 'Regenerate',
        icon: Symbols.auto_awesome_rounded,
        variant: AppButtonVariant.text,
        isLoading: isGenerating,
        onPressed: onRegenerate,
      ),
      children: [
        TextField(
          controller: controller,
          minLines: 10,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText: 'Your cover letter for this internship',
            alignLabelWithHint: true,
          ),
          onChanged: onChanged,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${controller.text.length} characters',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// The CV from Profile, or the honest "add one" state. The email app has to
/// attach the file, so the block says so instead of pretending to attach it.
class ApplyCvSection extends StatelessWidget {
  const ApplyCvSection({super.key, required this.cv, required this.onAddCv});

  final CvFile? cv;
  final VoidCallback onAddCv;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cv = this.cv;
    return DetailSectionCard(
      icon: Symbols.description_rounded,
      title: 'CV / Resume',
      children: [
        if (cv != null) ...[
          CvFileTile(
            fileName: cv.fileName,
            details: '${formatFileSize(cv.sizeBytes)} · PDF',
            badge: Text(
              'From your Profile',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            'Attach this file in your email app before you send.',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ] else ...[
          Text(
            'You have no CV in your Profile yet. You can still send the '
            'email, or add one so it is ready to attach.',
            style: textTheme.bodyMedium,
          ),
          AppButton(
            label: 'Add a CV in Profile',
            icon: Symbols.upload_file_rounded,
            variant: AppButtonVariant.text,
            onPressed: onAddCv,
          ),
        ],
      ],
    );
  }
}

/// Optional CV checks, kept from Flow 2 so the advisory features stay
/// reachable without forcing them on every application.
class ApplyCheckCvRow extends StatelessWidget {
  const ApplyCheckCvRow({
    super.key,
    required this.showMatch,
    required this.onCheckMatch,
    required this.onValidate,
  });

  final bool showMatch;
  final VoidCallback onCheckMatch;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        if (showMatch)
          AppButton(
            label: 'Check CV match',
            icon: Symbols.compare_arrows_rounded,
            variant: AppButtonVariant.text,
            onPressed: onCheckMatch,
          ),
        AppButton(
          label: 'Validate CV',
          icon: Symbols.fact_check_rounded,
          variant: AppButtonVariant.text,
          onPressed: onValidate,
        ),
      ],
    );
  }
}

/// Sticky actions: open the mail app, then confirm the email was sent.
class ApplyComposeBottomBar extends StatelessWidget {
  const ApplyComposeBottomBar({
    super.key,
    required this.isGenerating,
    required this.isOpening,
    required this.isSending,
    required this.emailOpened,
    required this.error,
    required this.onOpenEmail,
    required this.onMarkSent,
  });

  final bool isGenerating;
  final bool isOpening;
  final bool isSending;
  final bool emailOpened;
  final AppException? error;
  final VoidCallback onOpenEmail;
  final VoidCallback onMarkSent;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
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
              if (error case final error?) ...[
                FormMessage(message: error.message, isInfo: error.isCancelled),
                const SizedBox(height: AppSpacing.s12),
              ],
              AppButton(
                label: 'Open email app',
                icon: Symbols.mail_rounded,
                isLoading: isOpening,
                onPressed: isGenerating ? null : onOpenEmail,
                expand: true,
              ),
              const SizedBox(height: AppSpacing.s8),
              AppButton(
                label: "I've sent it",
                icon: Symbols.send_rounded,
                variant: emailOpened
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                isLoading: isSending,
                onPressed: onMarkSent,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading layout of the compose screen.
class ApplyComposeSkeleton extends StatelessWidget {
  const ApplyComposeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Loading the application',
      child: ExcludeSemantics(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: const [
            SkeletonBox(height: AppSizes.companyLogoLarge + AppSpacing.s32),
            SizedBox(height: AppSpacing.s16),
            SkeletonBox(height: AppSizes.minTouchTarget + AppSpacing.s32),
            SizedBox(height: AppSpacing.s16),
            SkeletonBox(height: AppSizes.minTouchTarget * 4),
            SizedBox(height: AppSpacing.s16),
            SkeletonBox(height: AppSizes.minTouchTarget * 6),
          ],
        ),
      ),
    );
  }
}
