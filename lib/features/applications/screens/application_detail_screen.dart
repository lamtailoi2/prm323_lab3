import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/display_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/company_logo.dart';
import '../../../core/widgets/detail_section_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/internship.dart';
import '../../../models/internship_application.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_theme.dart';
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
        // Always back to My Applications, however this screen was opened
        // (My Applications or `View application` on Internship Detail) —
        // `Navigator.maybePop` returned to Internship Detail instead.
        onBack: () => context.go(AppRoutes.applications),
        actions: [
          IconButton(
            icon: const Icon(Symbols.notifications_rounded),
            tooltip: 'Notifications',
            onPressed: () => context.push(AppRoutes.notificationCenter),
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
              title: 'Application not found',
              message: 'It may have been removed from this account.',
              actionLabel: 'Back to Applications',
              onAction: () => context.go(AppRoutes.applications),
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
                listing: data.listing,
                onPreview: () => unawaited(_preview(context, ref)),
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
        ViewData(:final data)
            when data.application.status.canWithdraw ||
                data.application.status == ApplicationStatus.withdrawn =>
          _WithdrawBar(
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
  /// longer be replaced (DC-29). The ViewModel owns the service call.
  Future<void> _preview(BuildContext context, WidgetRef ref) async {
    final error = await ref
        .read(applicationDetailViewModelProvider(internshipKey).notifier)
        .previewCv();
    if (error != null && context.mounted) _showMessage(context, error.message);
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
      title: 'About ${listing.companyName}',
      children: [
        Row(
          children: [
            CompanyLogo(
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
                _DestructiveWithdrawButton(
                  isLoading: action.isLoading,
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

/// `Withdraw application`: the frame's one destructive action, styled with
/// `AppColors.error` in place of the shared secondary button's `primary`
/// color (DC-29). `AppButtonVariant` has no destructive specimen
/// (design-system.md §2.1), so this overrides the outlined button's theme
/// locally instead of adding a one-off variant to the shared component.
class _DestructiveWithdrawButton extends StatelessWidget {
  const _DestructiveWithdrawButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.outlinedButtonTheme.style;
    final destructiveStyle = baseStyle?.copyWith(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppColors.disabled;
        if (states.contains(WidgetState.pressed)) {
          return AppColors.error.withValues(alpha: AppTheme.pressedOpacity);
        }
        return AppColors.error;
      }),
      iconColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppColors.disabled;
        if (states.contains(WidgetState.pressed)) {
          return AppColors.error.withValues(alpha: AppTheme.pressedOpacity);
        }
        return AppColors.error;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return const BorderSide(color: AppColors.border);
        }
        if (states.contains(WidgetState.pressed)) {
          return BorderSide(
            color: AppColors.error.withValues(alpha: AppTheme.pressedOpacity),
          );
        }
        return const BorderSide(color: AppColors.error);
      }),
    );

    return Theme(
      data: theme.copyWith(
        outlinedButtonTheme: OutlinedButtonThemeData(style: destructiveStyle),
      ),
      child: AppButton(
        label: 'Withdraw application',
        icon: Symbols.block_rounded,
        variant: AppButtonVariant.secondary,
        isLoading: isLoading,
        expand: true,
        onPressed: onPressed,
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
