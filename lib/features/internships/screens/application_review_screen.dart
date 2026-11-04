import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/display_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/cv_file_tile.dart';
import '../../../core/widgets/detail_row.dart';
import '../../../core/widgets/detail_section_card.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/internship.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/application_review_viewmodel.dart';
import '../viewmodels/apply_form_viewmodel.dart';
import '../widgets/application_review_parts.dart';
import '../widgets/apply_form_parts.dart';
import 'internship_detail_screen.dart';

/// Application Review (Flow 2 frames "Review Application"): everything the
/// student is about to send, each section with `Edit` back to the form, then
/// `Submit application`.
///
/// Reached from the Apply Form through Validate CV; the CV, details and
/// introduction arrive in the route `extra` ([ApplySession]).
class ApplicationReviewScreen extends ConsumerWidget {
  const ApplicationReviewScreen({
    super.key,
    required this.internshipKey,
    required this.source,
    this.session,
  });

  final String internshipKey;

  /// Tab the Detail was opened from (`home`, `search` or `saved`).
  final String source;

  /// `null` when the route is opened without going through the form.
  final ApplySession? session;

  static const String _notAdded = 'Not added';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (internshipKey: internshipKey, source: source);
    final state = ref.watch(applicationReviewViewModelProvider(args));
    final viewModel = ref.read(
      applicationReviewViewModelProvider(args).notifier,
    );
    final session = this.session;

    if (session == null) {
      return Scaffold(
        appBar: const AppTopBar.back(title: 'Review application'),
        body: StateView.empty(
          icon: Symbols.description_rounded,
          title: 'Your application is not ready',
          message:
              'Start from the Apply Form so we know which details and CV to '
              'send.',
          actionLabel: 'Back to the form',
          onAction: () =>
              context.go(AppRoutes.applyForm('/$source', internshipKey)),
        ),
      );
    }

    void edit() {
      // The Apply Form is still under this screen.
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.applyForm('/$source', internshipKey));
      }
    }

    return Scaffold(
      appBar: const AppTopBar.back(title: 'Review application'),
      body: switch (state.internship) {
        ViewLoading() => const ApplyFormSkeleton(),
        ViewEmpty() => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: StateView.empty(
              icon: Symbols.work_off_rounded,
              title: InternshipDetailScreen.notAvailableTitle,
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
        ViewData() => Column(
          children: [
            const ApplyStepHeader.review(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                children: [
                  ReviewInfoPanel(
                    title: 'Application summary',
                    message:
                        "Everything you've filled in so far is shown here so "
                        'you can double-check before submitting.',
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  const ReviewReadyPanel(
                    title: 'Ready to submit',
                    message: 'All required details are complete.',
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _PersonalInformation(
                    details: session.details,
                    email: session.email,
                    onEdit: edit,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  _SkillsSection(skills: session.skills, onEdit: edit),
                  const SizedBox(height: AppSpacing.section),
                  _CvSection(cv: session.cv, onEdit: edit),
                  const SizedBox(height: AppSpacing.section),
                  _IntroductionSection(
                    text: session.introduction,
                    onEdit: edit,
                  ),
                  const SizedBox(height: AppSpacing.section),
                  Text(
                    'You can still edit your application until you submit it. '
                    "After you send it, we'll add this application to My "
                    'Applications.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      },
      bottomNavigationBar: switch (state.internship) {
        ViewData(:final data) => _ReviewBottomBar(
          isSubmitting: state.submit.isLoading,
          error: switch (state.submit) {
            AsyncError(:final error) when error is AppException => error,
            _ => null,
          },
          onSubmit: () => _submit(context, ref, data, session),
        ),
        _ => null,
      },
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    Internship internship,
    ApplySession session,
  ) async {
    final args = (internshipKey: internshipKey, source: source);
    final submittedAt = await ref
        .read(applicationReviewViewModelProvider(args).notifier)
        .submit(session);
    if (submittedAt == null || !context.mounted) return;

    // Replaces this step, so Back cannot send the application twice.
    context.pushReplacement(
      AppRoutes.applicationSuccess('/$source', internship.key),
      extra: (
        internshipTitle: internship.title,
        companyName: internship.companyName,
        workMode: internship.workMode,
        logoUrl: internship.logoUrl,
        submittedAt: submittedAt,
      ),
    );
  }
}

/// `Edit` at the end of a review section's header.
class _EditButton extends StatelessWidget {
  const _EditButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'Edit',
      icon: Symbols.edit_rounded,
      variant: AppButtonVariant.text,
      onPressed: onPressed,
    );
  }
}

/// `Personal information` of the review: exactly what the form sends.
class _PersonalInformation extends StatelessWidget {
  const _PersonalInformation({
    required this.details,
    required this.email,
    required this.onEdit,
  });

  final ProfileDetails details;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final year = details.yearOfStudy;
    return DetailSectionCard(
      icon: Symbols.person_rounded,
      title: 'Personal information',
      action: _EditButton(onPressed: onEdit),
      children: [
        DetailRow(
          label: 'Full name',
          value: details.fullName ?? ApplicationReviewScreen._notAdded,
        ),
        DetailRow(
          label: 'Email',
          value: email.isEmpty ? ApplicationReviewScreen._notAdded : email,
        ),
        DetailRow(
          label: 'Phone number',
          value: details.phone ?? ApplicationReviewScreen._notAdded,
        ),
        DetailRow(
          label: 'University',
          value: details.university ?? ApplicationReviewScreen._notAdded,
        ),
        DetailRow(
          label: 'Year of study',
          value: year == null
              ? ApplicationReviewScreen._notAdded
              : 'Year $year',
        ),
        DetailRow(
          label: 'Academic standing',
          value: year == null
              ? ApplicationReviewScreen._notAdded
              : 'Year $year',
        ),
      ],
    );
  }
}

class _SkillsSection extends StatelessWidget {
  const _SkillsSection({required this.skills, required this.onEdit});

  final List<String> skills;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      icon: Symbols.code_rounded,
      title: 'Skills',
      action: _EditButton(onPressed: onEdit),
      children: [
        if (skills.isEmpty)
          Text(
            ApplicationReviewScreen._notAdded,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [for (final skill in skills) AppTag(label: skill)],
          ),
      ],
    );
  }
}

class _CvSection extends StatelessWidget {
  const _CvSection({required this.cv, required this.onEdit});

  final ApplyCv cv;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      icon: Symbols.description_rounded,
      title: 'CV / Resume',
      action: _EditButton(onPressed: onEdit),
      children: [
        CvFileTile(
          fileName: cv.file.fileName,
          details: '${formatFileSize(cv.file.sizeBytes)} · PDF',
          badge: Text(
            cv.source == CvSource.profile
                ? 'From your Profile'
                : 'Uploaded for this internship',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _IntroductionSection extends StatelessWidget {
  const _IntroductionSection({required this.text, required this.onEdit});

  final String text;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return DetailSectionCard(
      icon: Symbols.notes_rounded,
      title: 'Short introduction',
      action: _EditButton(onPressed: onEdit),
      children: [
        Text(
          text.isEmpty ? ApplicationReviewScreen._notAdded : text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// Bottom bar of the review step: the failure message and
/// `Submit application`, which becomes a spinner while the write runs.
class _ReviewBottomBar extends StatelessWidget {
  const _ReviewBottomBar({
    required this.isSubmitting,
    required this.error,
    required this.onSubmit,
  });

  final bool isSubmitting;
  final AppException? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
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
                label: 'Submit application',
                isLoading: isSubmitting,
                expand: true,
                onPressed: onSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
