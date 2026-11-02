import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/allowance.dart';
import '../../../core/utils/distinct_listings.dart';
import '../../../core/utils/job_role.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/internship_card.dart';
import '../../../core/widgets/main_tab_app_bar.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/internship.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_spacing.dart';
import '../../applications/viewmodels/applied_providers.dart';
import '../../saved/viewmodels/saved_providers.dart';
import '../../saved/viewmodels/saved_viewmodel.dart';
import '../viewmodels/home_viewmodel.dart';
import '../widgets/home_section_header.dart';
import '../widgets/role_shortcuts.dart';

/// Home tab (Figma Home, `docs/design/screen-spec.md` §Home).
///
/// Listings come from the shared Firestore pool that the scheduled sync
/// function fills from SerpAPI. "Recommended for you" uses the sync rank and
/// "Recently Posted" uses the newest posting dates; the limits come from
/// Remote Config.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeViewModelProvider);
    final viewModel = ref.read(homeViewModelProvider.notifier);
    final user = ref.watch(authStateChangesProvider).value;

    // A failed save / unsave keeps the list as it is and explains why.
    ref.listen<AsyncValue<void>>(savedViewModelProvider, (previous, next) {
      final error = next.error;
      if (error is AppException) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    });

    return Scaffold(
      appBar: MainTabAppBar(
        title: 'Home',
        user: user,
        onProfile: () => context.go(AppRoutes.profile),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HomeHeader(
              state: state,
              onSelectRole: viewModel.selectRole,
              onOpenSearch: () => context.go(AppRoutes.search),
            ),
          ),
          ..._feed(context, state: state, onRetry: viewModel.retry),
        ],
      ),
    );
  }

  List<Widget> _feed(
    BuildContext context, {
    required HomeState state,
    required Future<void> Function() onRetry,
  }) {
    return switch (state.feed) {
      ViewLoading<HomeFeed>() => [
        SliverToBoxAdapter(
          child: Semantics(
            container: true,
            label: 'Loading internships',
            child: ExcludeSemantics(
              child: Column(
                children: [
                  for (var i = 0; i < 2; i++)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.screenHorizontal,
                        AppSpacing.s16,
                        AppSpacing.screenHorizontal,
                        0,
                      ),
                      child: InternshipCardSkeleton(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
      ViewEmpty<HomeFeed>() => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: StateView.empty(
            icon: Symbols.search_off_rounded,
            title: 'No results found',
            message: 'Try another role or search for something else.',
            actionLabel: 'Search internships',
            onAction: () => context.go(AppRoutes.search),
          ),
        ),
      ],
      ViewError<HomeFeed>(:final error) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: StateView.error(
            message: error.message,
            onRetry: () => onRetry(),
          ),
        ),
      ],
      ViewData<HomeFeed>(:final data) => [
        SliverToBoxAdapter(
          child: _FeedLists(
            feed: data,
            onOpenSearch: () => context.go(AppRoutes.search),
          ),
        ),
      ],
    };
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.state,
    required this.onSelectRole,
    required this.onOpenSearch,
  });

  final HomeState state;
  final ValueChanged<JobRole> onSelectRole;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.s16,
            AppSpacing.screenHorizontal,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Find your next internship', style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.s16),
              AppSearchField(
                hintText: 'Search internships',
                readOnly: true,
                onTap: onOpenSearch,
                onFilterPressed: onOpenSearch,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
          ),
          child: HomeSectionHeader(
            title: 'Browse by Role',
            actionLabel: 'All roles',
            onAction: onOpenSearch,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        RoleShortcuts(
          roles: state.availableRoles.isEmpty
              ? HomeViewModel.roles
              : state.availableRoles,
          selected: state.selectedRole,
          onSelected: onSelectRole,
        ),
      ],
    );
  }
}

class _FeedLists extends ConsumerWidget {
  const _FeedLists({required this.feed, required this.onOpenSearch});

  final HomeFeed feed;
  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedInternshipIdsProvider);
    final appliedJobs =
        ref.watch(appliedJobsProvider).asData?.value ?? const <String>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (feed.recommended.isNotEmpty) ...[
          _sectionHeader('Recommended for you'),
          _cards(context, ref, feed.recommended, savedIds, appliedJobs),
        ],
        if (feed.recent.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.section),
          _sectionHeader('Recently Posted'),
          _cards(context, ref, feed.recent, savedIds, appliedJobs),
        ],
        const SizedBox(height: AppSpacing.section),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        0,
        AppSpacing.screenHorizontal,
        AppSpacing.s8,
      ),
      child: HomeSectionHeader(
        title: title,
        actionLabel: 'View all',
        onAction: onOpenSearch,
      ),
    );
  }

  Widget _cards(
    BuildContext context,
    WidgetRef ref,
    List<Internship> internships,
    Set<String> savedIds,
    Set<String> appliedJobs,
  ) {
    return Column(
      children: [
        for (final internship in internships)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenHorizontal,
              0,
              AppSpacing.screenHorizontal,
              AppSpacing.betweenCards,
            ),
            child: InternshipCard(
              title: internship.title,
              companyName: internship.companyName,
              location: internship.location,
              workMode: internship.workMode?.label,
              logoUrl: internship.logoUrl,
              tags: internship.skills,
              allowanceText: formatAllowance(internship.salary),
              postedText: internship.postedText,
              isSaved: savedIds.contains(internship.key),
              isApplied: appliedJobs.contains(
                jobIdentity(internship.title, internship.companyName),
              ),
              onTap: () => context.go(
                AppRoutes.internshipDetail(AppRoutes.home, internship.key),
              ),
              onSaveToggle: () => unawaited(
                ref
                    .read(savedViewModelProvider.notifier)
                    .toggle(internship, source: 'home'),
              ),
            ),
          ),
      ],
    );
  }
}
