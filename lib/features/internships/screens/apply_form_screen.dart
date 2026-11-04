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
import '../../../services/auth_service.dart';
import '../../../theme/app_spacing.dart';
import '../../profile/widgets/edit_skills_sheet.dart';
import '../viewmodels/apply_form_viewmodel.dart';
import '../widgets/apply_cv_sheet.dart';
import '../widgets/apply_form_parts.dart';
import '../widgets/apply_personal_parts.dart';
import '../widgets/personal_details_sheet.dart';
import 'internship_detail_screen.dart';

/// Apply Form (Flow 2 frames "Application Form", "Form · Empty", "Form · CV
/// uploading", "Form · CV upload failed", "Form · Validation error").
///
/// Personal information, skills and the introduction the company receives,
/// then `Continue to review` → Validate CV → Review.
class ApplyFormScreen extends ConsumerStatefulWidget {
  const ApplyFormScreen({
    super.key,
    required this.internshipKey,
    required this.source,
  });

  final String internshipKey;

  /// Tab the Detail was opened from (`home`, `search` or `saved`).
  final String source;

  @override
  ConsumerState<ApplyFormScreen> createState() => _ApplyFormScreenState();
}

class _ApplyFormScreenState extends ConsumerState<ApplyFormScreen> {
  final TextEditingController _fullName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _university = TextEditingController();
  final TextEditingController _yearOfStudy = TextEditingController();
  final TextEditingController _introduction = TextEditingController();

  /// Scrolls the personal information into view when `Continue` finds an
  /// error (the section sits under the summary card).
  final GlobalKey _personalKey = GlobalKey();

  /// The Profile values reached the controllers; later snapshots must not
  /// overwrite what the student typed.
  bool _seeded = false;

  ApplyFormArgs get _args =>
      (internshipKey: widget.internshipKey, source: widget.source);

  @override
  void initState() {
    super.initState();
    // The profile may already be loaded (coming back from Review); seed on
    // the first frame so no controller changes during build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedIfReady());
  }

  @override
  void dispose() {
    for (final controller in [
      _fullName,
      _email,
      _phone,
      _university,
      _yearOfStudy,
      _introduction,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _seedIfReady() {
    if (!mounted || _seeded) return;
    final state = ref.read(applyFormViewModelProvider(_args));
    final account = ref.read(authStateChangesProvider).value;
    // Both the Profile prefill and the Google account feed the form, and
    // they can arrive in either order.
    if (!state.profileLoaded || account == null) return;
    final fullName = state.fullName.trim();
    setState(() {
      _seeded = true;
      _fullName.text = fullName.isNotEmpty
          ? fullName
          : account.displayName ?? '';
      _email.text = account.email ?? '';
      _phone.text = state.phone;
      _university.text = state.university ?? '';
      _yearOfStudy.text = _yearLabel(state.yearOfStudy);
      _introduction.text = state.introduction;
    });
  }

  static String _yearLabel(int? year) => year == null ? '' : 'Year $year';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(applyFormViewModelProvider(_args));
    final viewModel = ref.read(applyFormViewModelProvider(_args).notifier);

    ref.listen(applyFormViewModelProvider(_args), (previous, next) {
      if (next.profileLoaded && !_seeded) _seedIfReady();
    });
    // The Google account can arrive after the profile.
    ref.listen(authStateChangesProvider, (previous, next) {
      if (next.hasValue && !_seeded) _seedIfReady();
    });

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
              // A plain scroll view: every section stays built, so `Continue`
              // can scroll the first personal-information error into view
              // wherever the student is on the form.
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ApplySummaryCard(internship: data),
                    if (_banner(context, state) case final banner?) ...[
                      const SizedBox(height: AppSpacing.s16),
                      banner,
                    ],
                    const SizedBox(height: AppSpacing.section),
                    ApplyPersonalSection(
                      key: _personalKey,
                      fullName: _fullName,
                      email: _email,
                      phone: _phone,
                      university: _university,
                      yearOfStudy: _yearOfStudy,
                      errors: state.errors,
                      onSelectUniversity: () => unawaited(
                        _pickUniversity(state.university, viewModel),
                      ),
                      onSelectYear: () =>
                          unawaited(_pickYear(state.yearOfStudy, viewModel)),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    ApplySkillsSection(
                      skills: state.profileSkills,
                      match: state.skillMatch,
                      // The Profile Edit skills sheet opens over the form:
                      // going to the Profile tab would drop the form and a CV
                      // uploaded or uploading for this internship (CR-16). The
                      // match updates from the profile stream.
                      onAddSkill: () => unawaited(
                        showAppSheet<void>(
                          context,
                          (_) => const EditSkillsSheet(),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.section),
                    ApplyCvSection(
                      state: state,
                      onChoose: () =>
                          unawaited(_openCvSheet(context, viewModel, _args)),
                      onRetry: () => unawaited(viewModel.uploadSelected()),
                      onUseProfileCv: viewModel.useProfileCv,
                      onPreview: () => unawaited(_preview(context, viewModel)),
                      onRetryProfile: viewModel.retryProfile,
                    ),
                    const SizedBox(height: AppSpacing.section),
                    ApplyIntroductionSection(controller: _introduction),
                  ],
                ),
              ),
            ),
          ],
        ),
      },
      bottomNavigationBar: state.internship is ViewData
          ? ApplyBottomBar(
              isUploading: state.isUploading,
              onContinue: () => _continue(context, viewModel),
            )
          : null,
    );
  }

  /// `Continue to review`: validates the personal information and the CV,
  /// then hands everything to Validate CV.
  void _continue(BuildContext context, ApplyFormViewModel viewModel) {
    final valid = viewModel.validateFields((
      fullName: _fullName.text,
      email: _email.text,
      phone: _phone.text,
      introduction: _introduction.text,
    ));
    // Also flags a missing CV, which the CV section then explains.
    final session = viewModel.continueToReview();

    if (!valid) {
      final personal = _personalKey.currentContext;
      if (personal != null) {
        unawaited(
          Scrollable.ensureVisible(
            personal,
            alignment: 0,
            duration: const Duration(milliseconds: 200),
          ),
        );
      }
    }

    if (valid && session != null) {
      context.push(
        AppRoutes.applyValidation('/${widget.source}', widget.internshipKey),
        extra: session,
      );
    } else if (session == null &&
        ref.read(applyFormViewModelProvider(_args)).uploadError != null) {
      _showMessage(context, 'Retry the upload or choose another CV first.');
    }
  }

  Future<void> _pickUniversity(
    String? selected,
    ApplyFormViewModel viewModel,
  ) async {
    final name = await showAppSheet<String>(
      context,
      (_) => UniversitySheet(selected: selected),
    );
    if (name == null || !mounted) return;
    viewModel.selectUniversity(name);
    _university.text = name;
  }

  Future<void> _pickYear(int? selected, ApplyFormViewModel viewModel) async {
    final year = await showAppSheet<int>(
      context,
      (_) => YearOfStudySheet(selected: selected),
    );
    if (year == null || !mounted) return;
    viewModel.selectYearOfStudy(year);
    _yearOfStudy.text = _yearLabel(year);
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
    await showAppSheet<void>(context, (_) => ApplyCvSheet(args: args));
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
