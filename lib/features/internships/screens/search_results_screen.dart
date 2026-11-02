import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/allowance.dart';
import '../../../core/utils/distinct_listings.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/internship_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/app_user.dart';
import '../../../models/internship.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../../applications/viewmodels/applied_providers.dart';
import '../models/search_filter_criteria.dart';
import '../viewmodels/search_results_viewmodel.dart';
import '../widgets/search_results_filter_sheet.dart';

/// Search Results screen (Figma Search Results, `docs/design/screen-spec.md` §Search Results).
///
/// Displays real internships from Firestore matching the query and active filters.
class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({
    super.key,
    this.initialQuery = '',
    this.initialWorkMode,
    this.initialCriteria,
  });

  final String initialQuery;
  final WorkMode? initialWorkMode;

  /// Filters chosen in the Search tab's filter sheet; wins over
  /// [initialWorkMode].
  final SearchFilterCriteria? initialCriteria;

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(searchResultsViewModelProvider.notifier)
          .init(
            query: widget.initialQuery,
            workMode: widget.initialWorkMode,
            criteria: widget.initialCriteria,
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQuerySubmitted(String query) {
    ref.read(searchResultsViewModelProvider.notifier).setQuery(query);
  }

  void _onQueryCleared() {
    _searchController.clear();
    ref.read(searchResultsViewModelProvider.notifier).clearQuery();
  }

  void _onFilterPressed() {
    final viewModel = ref.read(searchResultsViewModelProvider.notifier);
    final state = ref.read(searchResultsViewModelProvider);
    SearchResultsFilterSheet.show(
      context: context,
      currentCriteria: state.criteria,
      matchingCountCalculator: viewModel.countMatching,
      suggestedSkills: viewModel.suggestedSkills,
      onApply: viewModel.setCriteria,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchResultsViewModelProvider);
    final viewModel = ref.read(searchResultsViewModelProvider.notifier);
    final user = ref.watch(authStateChangesProvider).value;
    final appliedJobs =
        ref.watch(appliedJobsProvider).asData?.value ?? const <String>{};

    return Scaffold(
      appBar: AppTopBar.main(
        title: 'Search',
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Symbols.notifications_rounded),
            onPressed: () =>
                _showMessage(context, 'Notifications are coming soon.'),
          ),
          _ProfileAction(
            user: user,
            onPressed: () => context.go(AppRoutes.profile),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenHorizontal,
            AppSpacing.s16,
            AppSpacing.screenHorizontal,
            AppSpacing.s24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSearchField(
                controller: _searchController,
                filterCount: state.activeFilterCount,
                onSubmitted: _onQuerySubmitted,
                onCleared: _onQueryCleared,
                onFilterPressed: _onFilterPressed,
              ),
              if (state.activeFilterCount > 0) ...[
                const SizedBox(height: AppSpacing.s12),
                _ActiveFiltersRow(
                  state: state,
                  viewModel: viewModel,
                  onRemoveQuery: () {
                    _searchController.clear();
                    viewModel.clearQuery();
                  },
                  onClearAll: () {
                    _searchController.clear();
                    viewModel.clearFilters();
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.s16),
              switch (state.results) {
                ViewLoading<List<Internship>>() => const _LoadingView(),
                ViewError<List<Internship>>(:final error) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.section,
                  ),
                  child: StateView.error(
                    message: error.message,
                    onRetry: viewModel.retry,
                  ),
                ),
                ViewEmpty<List<Internship>>() => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.section,
                  ),
                  child: StateView.empty(
                    icon: Symbols.search_off_rounded,
                    title: 'No internships found',
                    message: 'Try adjusting your search or clearing filters to see more results.',
                    actionLabel: 'Clear filters',
                    onAction: () {
                      _searchController.clear();
                      viewModel.clearFilters();
                    },
                  ),
                ),
                ViewData<List<Internship>>(:final data) => _ResultsListView(
                  internships: data,
                  query: state.query,
                  sortBy: state.sortBy,
                  savedIds: state.savedIds,
                  appliedJobs: appliedJobs,
                  onSortChanged: viewModel.setSortBy,
                  onSaveToggle: viewModel.toggleSave,
                ),
              },
            ],
          ),
        ),
      ),
    );
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ActiveFiltersRow extends StatelessWidget {
  const _ActiveFiltersRow({
    required this.state,
    required this.viewModel,
    required this.onRemoveQuery,
    required this.onClearAll,
  });

  final SearchResultsState state;
  final SearchResultsViewModel viewModel;
  final VoidCallback onRemoveQuery;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final mode in state.criteria.workModes) ...[
            _ActiveFilterChip(
              key: ValueKey('filter_mode_${mode.name}'),
              label: mode.label,
              onDeleted: () => viewModel.removeWorkMode(mode),
            ),
            const SizedBox(width: AppSpacing.s8),
          ],
          for (final skill in state.criteria.skills) ...[
            _ActiveFilterChip(
              key: ValueKey('filter_skill_$skill'),
              label: skill,
              onDeleted: () => viewModel.removeSkill(skill),
            ),
            const SizedBox(width: AppSpacing.s8),
          ],
          if (state.criteria.location case final location?) ...[
            _ActiveFilterChip(
              key: const ValueKey('filter_location'),
              label: location,
              onDeleted: viewModel.clearLocation,
            ),
            const SizedBox(width: AppSpacing.s8),
          ],
          if (state.query.trim().isNotEmpty) ...[
            _ActiveFilterChip(
              key: const ValueKey('filter_query'),
              label: state.query.trim(),
              onDeleted: onRemoveQuery,
            ),
            const SizedBox(width: AppSpacing.s8),
          ],
          TextButton(
            onPressed: onClearAll,
            child: const Text(
              'Clear filters',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    super.key,
    required this.label,
    required this.onDeleted,
  });

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryContainer,
      borderRadius: AppRadii.fullAll,
      child: InkWell(
        borderRadius: AppRadii.fullAll,
        onTap: onDeleted,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Symbols.check_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.s4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              const Icon(
                Symbols.close_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultsListView extends StatelessWidget {
  const _ResultsListView({
    required this.internships,
    required this.query,
    required this.sortBy,
    required this.savedIds,
    required this.appliedJobs,
    required this.onSortChanged,
    required this.onSaveToggle,
  });

  final List<Internship> internships;
  final String query;
  final SearchSortBy sortBy;
  final Set<String> savedIds;

  /// Jobs ([jobIdentity]) tracked in My Applications, shown with the
  /// `Applied` badge.
  final Set<String> appliedJobs;
  final ValueChanged<SearchSortBy> onSortChanged;
  final ValueChanged<String> onSaveToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final count = internships.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$count ',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: count == 1
                            ? 'internship found'
                            : 'internships found',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
            PopupMenuButton<SearchSortBy>(
              initialValue: sortBy,
              tooltip: 'Sort options',
              onSelected: onSortChanged,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.s4,
                  horizontal: AppSpacing.s4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Symbols.swap_vert_rounded,
                      size: AppSizes.iconSmall,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.s4),
                    Text(
                      sortBy.label,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              itemBuilder: (context) => [
                for (final sort in SearchSortBy.values)
                  PopupMenuItem(
                    value: sort,
                    child: Row(
                      children: [
                        if (sort == sortBy)
                          const Icon(
                            Symbols.check_rounded,
                            size: 18,
                            color: AppColors.primary,
                          )
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: AppSpacing.s8),
                        Text(sort.label),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s12),
        for (final internship in internships) ...[
          InternshipCard(
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
            onSaveToggle: () => onSaveToggle(internship.key),
            // push keeps this results page (query, filters, scroll) under
            // the detail, so Back returns to the same results.
            onTap: () => context.push(
              AppRoutes.internshipDetail(AppRoutes.search, internship.key),
            ),
          ),
          const SizedBox(height: AppSpacing.betweenCards),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s24),
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppRadii.fullAll,
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Text(
                  query.trim().isNotEmpty
                      ? 'Showing top matching internships for "${query.trim()}"'
                      : 'Showing top matching internships',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Refine filters to narrow compensation or location',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.disabled,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        InternshipCardSkeleton(),
        SizedBox(height: AppSpacing.betweenCards),
        InternshipCardSkeleton(),
        SizedBox(height: AppSpacing.betweenCards),
        InternshipCardSkeleton(),
      ],
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({required this.user, required this.onPressed});

  final AppUser? user;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user?.photoUrl;
    return IconButton(
      tooltip: 'Profile',
      onPressed: onPressed,
      icon: ClipOval(
        child: SizedBox.square(
          dimension: AppSizes.profileAvatar,
          child: ColoredBox(
            color: AppColors.primaryContainer,
            child: photoUrl == null
                ? const Icon(
                    Symbols.person_rounded,
                    size: AppSizes.iconSmall,
                    color: AppColors.primary,
                  )
                : Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Symbols.person_rounded,
                      size: AppSizes.iconSmall,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
