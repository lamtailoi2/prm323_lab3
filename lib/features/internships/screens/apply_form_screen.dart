import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/state/view_state.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/state_view.dart';
import '../../../theme/app_spacing.dart';
import '../../profile/widgets/edit_skills_sheet.dart';
import '../viewmodels/apply_form_viewmodel.dart';
import '../widgets/apply_cv_sheet.dart';
import '../widgets/apply_form_parts.dart';
import 'internship_detail_screen.dart';

/// Apply Form (Lab 2 frames "Application Form", "Form · Empty", "Form · CV
/// uploading", "Form · CV upload failed", "Form · Validation error"),
/// limited to the CV step of Flow 1: Check CV → Upload / Select CV →
/// Pre-submit Complete (DC-26).
class ApplyFormScreen extends ConsumerWidget {
  const ApplyFormScreen({
    super.key,
    required this.internshipKey,
    required this.source,
  });

  final String internshipKey;

  /// Tab the Detail was opened from (`home`, `search` or `saved`).
  final String source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (internshipKey: internshipKey, source: source);
    final state = ref.watch(applyFormViewModelProvider(args));
    final viewModel = ref.read(applyFormViewModelProvider(args).notifier);

    return Scaffold(
      appBar: AppTopBar.back(
        title: 'Apply Form',
        actions: [
          IconButton(
            icon: const Icon(Symbols.notifications_rounded),
            tooltip: 'Notifications',
            // Same honest message as the other app bars until the
            // Notification Center exists (DC-11).
            onPressed: () =>
                _showMessage(context, 'Notifications are coming soon.'),
          ),
        ],
      ),
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
        ViewData(:final data) => Column(
          children: [
            const ApplyStepHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                children: [
                  ApplySummaryCard(internship: data),
                  if (_banner(context, state) case final banner?) ...[
                    const SizedBox(height: AppSpacing.s16),
                    banner,
                  ],
                  if (state.skillMatch case final match?) ...[
                    const SizedBox(height: AppSpacing.s16),
                    ApplySkillMatchLine(
                      match: match,
                      // The Profile Edit skills sheet opens over the form:
                      // going to the Profile tab would drop the form and a
                      // CV uploaded or uploading for this internship
                      // (CR-16). The match updates from the profile stream.
                      onEditSkills: () => unawaited(
                        showAppSheet(context, (_) => const EditSkillsSheet()),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s16),
                  ApplyCvSection(
                    state: state,
                    onChoose: () =>
                        unawaited(_openCvSheet(context, viewModel, args)),
                    onRetry: () => unawaited(viewModel.uploadSelected()),
                    onUseProfileCv: viewModel.useProfileCv,
                    onPreview: () => unawaited(_preview(context, viewModel)),
                    onRetryProfile: viewModel.retryProfile,
                  ),
                ],
              ),
            ),
          ],
        ),
      },
      bottomNavigationBar: state.internship is ViewData
          ? ApplyBottomBar(
              isUploading: state.isUploading,
              onContinue: () {
                // Pre-submit Complete. The review step (Validate CV →
                // Confirm, Flow 4) is not built yet, so the button says so
                // instead of faking a step; the CV section shows the error
                // when there is no CV.
                if (viewModel.continueToReview() != null) {
                  _showMessage(
                    context,
                    'Your CV is ready. The review step is coming soon.',
                  );
                } else if (state.uploadError != null) {
                  _showMessage(
                    context,
                    'Retry the upload or choose another CV first.',
                  );
                }
              },
            )
          : null,
    );
  }

  /// The Profile banner when the CV comes from Profile, the tip when
  /// Profile has no CV, and nothing while a CV uploads or failed, or when
  /// a CV was uploaded for this internship.
  static Widget? _banner(BuildContext context, ApplyFormState state) {
    if (!state.profileLoaded ||
        state.profileError != null ||
        state.isUploading ||
        state.uploadError != null) {
      return null;
    }
    void openProfile() => context.go(AppRoutes.profile);
    if (state.cv?.source == CvSource.profile) {
      return ApplyInfoBanner.fromProfile(onAction: openProfile);
    }
    // A CV uploaded for this internship needs no tip (CR-20).
    if (state.profileCv == null && state.uploadedCv == null) {
      return ApplyInfoBanner.tip(onAction: openProfile);
    }
    return null;
  }

  /// `Upload CV` / `Replace`: the same sheet as Profile › Update CV.
  Future<void> _openCvSheet(
    BuildContext context,
    ApplyFormViewModel viewModel,
    ApplyFormArgs args,
  ) async {
    await showAppSheet(context, (_) => ApplyCvSheet(args: args));
    viewModel.closeCvSheet();
  }

  Future<void> _preview(
    BuildContext context,
    ApplyFormViewModel viewModel,
  ) async {
    final error = await viewModel.previewCv();
    if (error != null && context.mounted) _showMessage(context, error.message);
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
