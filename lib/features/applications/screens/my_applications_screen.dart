import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/state/view_state.dart';
import '../../../core/widgets/main_tab_app_bar.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/internship_application.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/my_applications_viewmodel.dart';
import '../widgets/application_card.dart';

/// My Applications tab (`docs/design/screen-spec.md` › My Applications,
/// Figma `my-applications-final.png`).
///
/// Tracks the applications the Apply flow records under
/// `users/{uid}/applications`: position, company, submitted date and status.
/// The header is the shared [MainTabAppBar], so Home, Saved and Applications
/// differ only in the title.
class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  /// Enough placeholders to fill the first screen at 360 dp.
  static const int _skeletonCount = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myApplicationsViewModelProvider);
    final viewModel = ref.read(myApplicationsViewModelProvider.notifier);
    final user = ref.watch(authStateChangesProvider).value;

    return Scaffold(
      appBar: MainTabAppBar(
        title: 'Applications',
        user: user,
        onProfile: () => context.go(AppRoutes.profile),
      ),
      body: switch (state.applications) {
        ViewLoading<MyApplicationsFeed>() => const _LoadingBody(),
        ViewEmpty<MyApplicationsFeed>() => StateView.empty(
          icon: Symbols.description_rounded,
          title: 'You have not applied yet',
          message:
              'Find an internship that fits your skills and start your first '
              'application.',
          actionLabel: 'Find internships',
          onAction: () => context.go(AppRoutes.search),
        ),
        ViewError<MyApplicationsFeed>(:final error) => StateView.error(
          message: error.message,
          onRetry: viewModel.retry,
        ),
        ViewData<MyApplicationsFeed>(:final data) => _ApplicationsBody(
          feed: data,
          selected: state.selectedStatus,
          onSelectStatus: viewModel.selectStatus,
          onOpen: (application) =>
              context.push(AppRoutes.applicationDetail(application.jobKey)),
        ),
      },
    );
  }
}

/// Card-shaped skeletons (Figma "Loading"), so the list keeps its shape
/// instead of showing a spinner or a blank screen (design-system.md §2.9).
class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Loading applications',
      child: ExcludeSemantics(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.s16,
            AppSpacing.screenHorizontal,
            AppSpacing.s24,
          ),
          itemCount: MyApplicationsScreen._skeletonCount,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.s12),
            child: InternshipCardSkeleton(),
          ),
        ),
      ),
    );
  }
}

class _ApplicationsBody extends StatelessWidget {
  const _ApplicationsBody({
    required this.feed,
    required this.selected,
    required this.onSelectStatus,
    required this.onOpen,
  });

  final MyApplicationsFeed feed;
  final ApplicationStatus? selected;
  final ValueChanged<ApplicationStatus?> onSelectStatus;
  final ValueChanged<InternshipApplication> onOpen;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final total = feed.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.s16,
            AppSpacing.screenHorizontal,
            AppSpacing.s8,
          ),
          child: Text(
            total == 1 ? '1 application' : '$total applications',
            style: textTheme.bodyMedium,
          ),
        ),
        _statusFilters(),
        const SizedBox(height: AppSpacing.s8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              0,
              AppSpacing.screenHorizontal,
              AppSpacing.s24,
            ),
            itemCount: feed.visible.length,
            itemBuilder: (context, index) {
              final application = feed.visible[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                child: ApplicationCard(
                  application: application,
                  onTap: () => onOpen(application),
                  onPrimaryAction: () => onOpen(application),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Status shortcuts above the list: `All` plus one chip per status that
  /// actually occurs, each with its count (Figma shows the same pattern).
  ///
  /// Labels use the status labels (`Under review`, `Accepted`) instead of the
  /// frame's shortened `Review` / `Offered`, so a chip matches the badge it
  /// filters (DC-22).
  Widget _statusFilters() {
    return SizedBox(
      // Chip plus the padding that keeps the 48 dp tap target (Saved uses
      // the same row).
      height: AppSizes.minTouchTarget + AppSpacing.s12,
      // A plain row instead of a lazy list: there are at most six chips, and
      // every chip must exist for tests and screen readers even when it is
      // scrolled out of view.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenHorizontal,
        ),
        child: Row(
          children: [
            _chip(
              'All (${feed.total})',
              selected == null,
              () => onSelectStatus(null),
            ),
            for (final entry in feed.counts.entries)
              _chip(
                '${entry.key.label} (${entry.value})',
                selected == entry.key,
                () => onSelectStatus(entry.key),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool isSelected, VoidCallback onSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
