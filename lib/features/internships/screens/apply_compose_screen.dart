import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/contact_email.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/detail_section_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/internship.dart';
import '../../../services/remote_config_service.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/apply_compose_viewmodel.dart';
import '../widgets/apply_compose_parts.dart';
import '../widgets/apply_summary_card.dart';
import 'internship_detail_screen.dart';

/// Compose application (Flow 2, replacing the six-field Apply Form).
///
/// The recipient is read from the job post, the subject and cover letter are
/// drafted from the listing + Profile (+ CV), and `Open email app` hands the
/// draft to the device's mail app. `I've sent it` records the application so
/// My Applications keeps working.
class ApplyComposeScreen extends ConsumerStatefulWidget {
  const ApplyComposeScreen({
    super.key,
    required this.internshipKey,
    required this.source,
  });

  final String internshipKey;

  /// Tab the Detail was opened from (`home`, `search` or `saved`).
  final String source;

  @override
  ConsumerState<ApplyComposeScreen> createState() => _ApplyComposeScreenState();
}

class _ApplyComposeScreenState extends ConsumerState<ApplyComposeScreen> {
  late final TextEditingController _recipient;
  late final TextEditingController _subject;
  late final TextEditingController _body;

  /// The draft version last copied into the controllers, so the screen never
  /// overwrites what the student typed.
  int _syncedVersion = -1;

  @override
  void initState() {
    super.initState();
    _recipient = TextEditingController();
    _subject = TextEditingController();
    _body = TextEditingController();
  }

  @override
  void dispose() {
    _recipient.dispose();
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  ApplyComposeArgs get _args =>
      (internshipKey: widget.internshipKey, source: widget.source);

  @override
  Widget build(BuildContext context) {
    final provider = applyComposeViewModelProvider(_args);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    // Copy a freshly drafted subject/letter into the fields. The callback
    // runs outside build, so changing the controllers is safe.
    ref.listen(provider.select((s) => s.draftVersion), (previous, next) {
      if (next == _syncedVersion) return;
      _syncedVersion = next;
      final current = ref.read(provider);
      _recipient.text = current.recipientEmail;
      _subject.text = current.subject;
      _body.text = current.body;
    });

    final generateError = switch (state.generate) {
      AsyncError(:final error) when error is AppException => error,
      _ => null,
    };
    final sendError = switch (state.send) {
      AsyncError(:final error) when error is AppException => error,
      _ => null,
    };

    return Scaffold(
      appBar: const AppTopBar.back(title: 'Apply by email'),
      body: switch (state.internship) {
        ViewLoading() => const ApplyComposeSkeleton(),
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
        ViewData(:final data) => _ComposeBody(
          internship: data,
          state: state,
          viewModel: viewModel,
          recipient: _recipient,
          subject: _subject,
          body: _body,
          generateError: generateError,
          onRegenerate: () => unawaited(viewModel.regenerate()),
          onCheckMatch: () =>
              unawaited(_openCvStep(match: true, viewModel: viewModel)),
          onValidate: () =>
              unawaited(_openCvStep(match: false, viewModel: viewModel)),
        ),
      },
      bottomNavigationBar: switch (state.internship) {
        ViewData(:final data) => ApplyComposeBottomBar(
          isGenerating: state.isGenerating,
          isOpening: state.openingEmail,
          isSending: state.isSending,
          emailOpened: state.emailOpened,
          error: sendError ?? state.openError,
          onOpenEmail: () => unawaited(_openEmail(viewModel)),
          onMarkSent: () => unawaited(_markSent(data, viewModel)),
        ),
        _ => null,
      },
    );
  }

  Future<void> _openEmail(ApplyComposeViewModel viewModel) async {
    await viewModel.openEmail();
    if (!mounted) return;
    final state = ref.read(applyComposeViewModelProvider(_args));
    if (state.openError != null || !state.emailOpened) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Email app opened. Attach your CV there.'),
          persist: false,
        ),
      );
  }

  Future<void> _markSent(
    Internship internship,
    ApplyComposeViewModel viewModel,
  ) async {
    final sent = await viewModel.markSent();
    if (sent == null || !mounted) return;
    context.pushReplacement(
      AppRoutes.applicationSuccess('/${widget.source}', sent.internship.key),
      extra: (
        internshipTitle: sent.internship.title,
        companyName: sent.internship.companyName,
        workMode: sent.internship.workMode,
        logoUrl: sent.internship.logoUrl,
        submittedAt: sent.submittedAt,
      ),
    );
  }

  Future<void> _openCvStep({
    required bool match,
    required ApplyComposeViewModel viewModel,
  }) async {
    final session = viewModel.buildSession();
    if (session == null) return;
    final path = match
        ? AppRoutes.applyMatch('/${widget.source}', widget.internshipKey)
        : AppRoutes.applyValidation('/${widget.source}', widget.internshipKey);
    final result = await context.push<bool>(path, extra: session);
    if (!mounted || match) return;
    _showMessage(
      result == true
          ? 'Your CV passed the check.'
          : 'Update your CV and try again.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), persist: false));
  }
}

class _ComposeBody extends ConsumerWidget {
  const _ComposeBody({
    required this.internship,
    required this.state,
    required this.viewModel,
    required this.recipient,
    required this.subject,
    required this.body,
    required this.generateError,
    required this.onRegenerate,
    required this.onCheckMatch,
    required this.onValidate,
  });

  final Internship internship;
  final ApplyComposeState state;
  final ApplyComposeViewModel viewModel;
  final TextEditingController recipient;
  final TextEditingController subject;
  final TextEditingController body;
  final AppException? generateError;
  final VoidCallback onRegenerate;
  final VoidCallback onCheckMatch;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobText = [
      ?internship.description,
      for (final highlight in internship.highlights) ...highlight.items,
    ].join('\n');
    final found = findApplicationEmail(jobText);
    final foundInJobPost =
        found != null &&
        state.recipientEmail.trim().toLowerCase() == found.toLowerCase();
    final showMatch = ref
        .read(remoteConfigServiceProvider)
        .getBool(RemoteConfigKeys.cvMatchEnabled);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s16),
      children: [
        ApplySummaryCard(internship: internship),
        const SizedBox(height: AppSpacing.s16),
        ApplyDraftBanner(
          isGenerating: state.isGenerating,
          usedAi: state.usedAi,
          error: generateError,
          onRetry: onRegenerate,
        ),
        const SizedBox(height: AppSpacing.section),
        ApplyRecipientSection(
          controller: recipient,
          foundInJobPost: foundInJobPost,
          error: state.recipientError,
          onChanged: viewModel.setRecipient,
        ),
        const SizedBox(height: AppSpacing.section),
        ApplySubjectSection(
          controller: subject,
          onChanged: viewModel.setSubject,
        ),
        const SizedBox(height: AppSpacing.section),
        ApplyCoverLetterSection(
          controller: body,
          isGenerating: state.isGenerating,
          onChanged: viewModel.setBody,
          onRegenerate: onRegenerate,
        ),
        const SizedBox(height: AppSpacing.section),
        _CvBlock(state: state, onRetryProfile: viewModel.retryProfile),
        if (state.profile?.cv != null) ...[
          const SizedBox(height: AppSpacing.s8),
          ApplyCheckCvRow(
            showMatch: showMatch,
            onCheckMatch: onCheckMatch,
            onValidate: onValidate,
          ),
        ],
        const SizedBox(height: AppSpacing.section),
        Text(
          'This is a self-tracked record. After you send the email, tap '
          '"I\'ve sent it" so it appears in My Applications.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _CvBlock extends StatelessWidget {
  const _CvBlock({required this.state, required this.onRetryProfile});

  final ApplyComposeState state;
  final VoidCallback onRetryProfile;

  @override
  Widget build(BuildContext context) {
    if (!state.profileLoaded) {
      return const DetailSectionCard(
        icon: Symbols.description_rounded,
        title: 'CV / Resume',
        children: [
          SkeletonBox(
            height: AppSizes.minTouchTarget,
            borderRadius: AppRadii.mediumAll,
          ),
        ],
      );
    }
    if (state.profileError case final error?) {
      return DetailSectionCard(
        icon: Symbols.description_rounded,
        title: 'CV / Resume',
        children: [
          FormMessage(message: error.message),
          AppButton(
            label: 'Retry',
            icon: Symbols.refresh_rounded,
            variant: AppButtonVariant.text,
            onPressed: onRetryProfile,
          ),
        ],
      );
    }
    return ApplyCvSection(
      cv: state.profile?.cv,
      onAddCv: () => context.go(AppRoutes.profile),
    );
  }
}
