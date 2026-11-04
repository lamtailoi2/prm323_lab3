import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/display_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/internship.dart';
import '../../../models/internship_application.dart';
import '../../../services/external_link_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../../internships/widgets/detail_parts.dart';
import '../viewmodels/application_detail_viewmodel.dart';
import '../widgets/applicant_card.dart';
import '../widgets/application_identity_card.dart';
import '../widgets/application_status_tracker.dart';

/// Application Detail (Lab 2 frames "Application Detail": submitted, under
/// review, withdraw dialog, withdrawn, loading, error), reached from My
/// Applications and from `View application` (Flow 3c/3d).
class ApplicationDetailScreen extends ConsumerWidget {
  const ApplicationDetailScreen({super.key, required this.internshipKey});

  final String internshipKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = applicationDetailViewModelProvider(internshipKey);
    final state = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppTopBar.back(
        title: 'Application Detail',
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
      body: switch (state.detail) {
        ViewLoading() => const _DetailSkeleton(),
        ViewEmpty() => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: StateView.empty(
              icon: Symbols.description_rounded,
              title: 'This application is not in your list',
              message: 'It may have been deleted on another device.',
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
        ViewData(:final data) => ListView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: [
            ApplicationIdentityCard(
              application: data.application,
              listing: data.listing,
            ),
            const SizedBox(height: AppSpacing.section),
            ApplicationStatusTracker(application: data.application),
            if (data.application.applicant != null) ...[
              const SizedBox(height: AppSpacing.section),
              ApplicantCard(
                application: data.application,
                onPreview: () =>
                    unawaited(_preview(context, ref, data.application)),
              ),
            ],
            if (data.listing case final listing?) ...[
              const SizedBox(height: AppSpacing.section),
              _CompanyCard(listing: listing),
            ],
          ],
        ),
      },
      bottomNavigationBar: switch (state.detail) {
        ViewData(:final data) => _WithdrawBar(
          application: data.application,
          action: state.action,
          canUndo: state.canUndoWithdrawal,
          undoDeadline: state.undoDeadline,
          onWithdraw: () => unawaited(_withdraw(context, ref)),
          onUndo: () => unawaited(_undo(ref)),
        ),
        _ => null,
      },
    );
  }

  /// `Withdraw application` → confirmation dialog (Flow 3d).
  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppDialog(
      context,
      title: 'Withdraw application?',
      message: 'You can undo this within 24 hours.',
      primaryLabel: 'Confirm',
      secondaryLabel: 'Cancel',
    );
    if (confirmed != true || !context.mounted) return;

    final notifier = ref.read(
      applicationDetailViewModelProvider(internshipKey).notifier,
    );
    final done = await notifier.withdraw();
    if (!done || !context.mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Application withdrawn'),
          // The action stays 4 s (design-system), as on Saved.
          persist: false,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => unawaited(notifier.undoWithdrawal()),
          ),
        ),
      );
  }

  Future<void> _undo(WidgetRef ref) async {
    await ref
        .read(applicationDetailViewModelProvider(internshipKey).notifier)
        .undoWithdrawal();
  }

  /// `Preview`: the submitted CV opens in the device's viewer; it can no
  /// longer be replaced (DC-29).
  Future<void> _preview(
    BuildContext context,
    WidgetRef ref,
    InternshipApplication application,
  ) async {
    final url = application.cvUrl;
    if (url == null) return;
    try {
      await ref.read(externalLinkServiceProvider).open(Uri.parse(url));
    } on AppException catch (error) {
      if (context.mounted) _showMessage(context, error.message);
    }
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// `About the company`: what the listing gives (no size, description or
/// address — DC-10).
class _CompanyCard extends StatelessWidget {
  const _CompanyCard({required this.listing});

  final Internship listing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DetailSectionCard(
      icon: Symbols.apartment_rounded,
      title: 'About the company',
      children: [
        Row(
          children: [
            DetailCompanyLogo(
              companyName: listing.companyName,
              url: listing.logoUrl,
              size: AppSizes.companyLogo,
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(listing.companyName, style: textTheme.titleMedium),
                  if (listing.location case final location?)
                    Text(
                      location,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bottom bar: `Withdraw application`, or `Undo withdrawal` while the
/// 24-hour window lasts, with the write's failure above the button.
class _WithdrawBar extends StatelessWidget {
  const _WithdrawBar({
    required this.application,
    required this.action,
    required this.canUndo,
    required this.undoDeadline,
    required this.onWithdraw,
    required this.onUndo,
  });

  final InternshipApplication application;
  final AsyncValue<void> action;
  final bool canUndo;
  final DateTime? undoDeadline;
  final VoidCallback onWithdraw;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final withdrawn = application.status == ApplicationStatus.withdrawn;
    final error = switch (action) {
      AsyncError(:final error) when error is AppException => error,
      _ => null,
    };

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
              if (withdrawn && canUndo) ...[
                Text(
                  'Available until ${formatShortDateTime(undoDeadline!)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s8),
                AppButton(
                  label: 'Undo withdrawal',
                  icon: Symbols.undo_rounded,
                  isLoading: action.isLoading,
                  expand: true,
                  onPressed: onUndo,
                ),
              ] else if (withdrawn) ...[
                Text(
                  'This withdrawal is permanent.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Text(
                  'You can undo a withdrawal within 24 hours.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s8),
                AppButton(
                  label: 'Withdraw application',
                  icon: Symbols.block_rounded,
                  variant: AppButtonVariant.secondary,
                  isLoading: action.isLoading,
                  expand: true,
                  onPressed: onWithdraw,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Card-shaped placeholders while the document loads (design-system §2.9).
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Loading application',
      child: ExcludeSemantics(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: const [
            SkeletonBox(
              height: AppSpacing.s32 * 4,
              borderRadius: AppRadii.largeAll,
            ),
            SizedBox(height: AppSpacing.section),
            SkeletonBox(
              height: AppSpacing.s32 * 6,
              borderRadius: AppRadii.largeAll,
            ),
            SizedBox(height: AppSpacing.section),
            SkeletonBox(
              height: AppSpacing.s32 * 5,
              borderRadius: AppRadii.largeAll,
            ),
          ],
        ),
      ),
    );
  }
}
