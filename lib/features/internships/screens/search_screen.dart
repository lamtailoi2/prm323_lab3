import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/router.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/posted_age.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/internship.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radii.dart';
import '../../../theme/app_sizes.dart';
import '../../../theme/app_spacing.dart';
import '../models/search_filter_criteria.dart';
import '../models/search_history_entry.dart';
import '../viewmodels/search_viewmodel.dart';
import '../widgets/search_results_filter_sheet.dart';
import '../widgets/search_section_header.dart';

/// Search tab (Figma Search, `docs/design/screen-spec.md` §Search).
///
/// Submitting, a trending skill, a recent search or the filter sheet opens
/// Search Results (Flow 1: Search Jobs → Filter & Sort → Job Listing).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchViewModelProvider);
    final viewModel = ref.read(searchViewModelProvider.notifier);

    return Scaffold(
      appBar: const AppTopBar.main(title: 'Search'),
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
                controller: _controller,
                onSubmitted: (value) => _submit(context, viewModel, value),
                onFilterPressed: () => _openFilters(context, viewModel),
              ),
              const SizedBox(height: AppSpacing.section),
              SearchSectionHeader(
                title: 'Work mode',
                subtitle: state.workMode == null ? null : '1 selected',
              ),
              const SizedBox(height: AppSpacing.s8),
              _WorkModeChips(
                selected: state.workMode,
                onSelected: viewModel.selectWorkMode,
              ),
              ..._trendingSection(context, state, viewModel),
              ..._recentSearchesSection(context, state, viewModel),
              const SizedBox(height: AppSpacing.s8),
              AppButton(
                label: 'Find Internships',
                icon: Symbols.search_rounded,
                expand: true,
                onPressed: () => _submit(context, viewModel, _controller.text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    SearchViewModel viewModel,
    String term,
  ) async {
    final trimmed = term.trim();
    final mode = ref.read(searchViewModelProvider).workMode;
    if (trimmed.isEmpty && mode == null) return;
    if (trimmed.isNotEmpty) {
      _controller.text = trimmed;
      // Recorded in the background: an offline Firestore write only
      // completes once the server confirms it, and the search must not wait
      // for it (CR-10).
      unawaited(viewModel.recordSearch(trimmed));
    }
    if (!context.mounted) return;
    final uri = Uri(
      path: '/search/results',
      queryParameters: {
        if (trimmed.isNotEmpty) 'q': trimmed,
        if (mode != null) 'mode': mode.name,
      },
    );
    try {
      context.go(uri.toString());
    } catch (_) {
      // Allows standalone tests without GoRouter
    }
  }

  /// Opens the same filter sheet as Search Results, seeded with the selected
  /// work mode; `Show N results` goes to Search Results with those filters.
  Future<void> _openFilters(
    BuildContext context,
    SearchViewModel viewModel,
  ) async {
    final mode = ref.read(searchViewModelProvider).workMode;
    SearchFilterCriteria? applied;
    await SearchResultsFilterSheet.show(
      context: context,
      currentCriteria: SearchFilterCriteria(
        workModes: mode == null ? const {} : {mode},
      ),
      matchingCountCalculator: (criteria) =>
          viewModel.countMatching(criteria, query: _controller.text),
      suggestedSkills: viewModel.suggestedSkills,
      onApply: (criteria) => applied = criteria,
    );
    final criteria = applied;
    // Navigate only once the sheet has closed, so its route is gone.
    if (criteria == null || !context.mounted) return;
    final term = _controller.text.trim();
    if (term.isNotEmpty) unawaited(viewModel.recordSearch(term));
    context.go(
      Uri(
        path: AppRoutes.searchResults,
        queryParameters: {if (term.isNotEmpty) 'q': term},
      ).toString(),
      extra: criteria,
    );
  }

  List<Widget> _trendingSection(
    BuildContext context,
    SearchState state,
    SearchViewModel viewModel,
  ) {
    final trending = state.trending;
    if (trending is ViewData<List<SkillCount>> && trending.data.isEmpty) {
      return const [];
    }
    if (trending is ViewEmpty<List<SkillCount>>) return const [];

    return [
      const SizedBox(height: AppSpacing.section),
      const SearchSectionHeader(title: 'Trending skills for undergraduates'),
      const SizedBox(height: AppSpacing.s8),
      switch (trending) {
        ViewLoading<List<SkillCount>>() => const Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            SkeletonBox(width: 90, height: 32, borderRadius: AppRadii.fullAll),
            SkeletonBox(width: 110, height: 32, borderRadius: AppRadii.fullAll),
            SkeletonBox(width: 80, height: 32, borderRadius: AppRadii.fullAll),
          ],
        ),
        ViewEmpty<List<SkillCount>>() => const SizedBox.shrink(),
        ViewError<List<SkillCount>>(:final error) => StateView.error(
          message: error.message,
          onRetry: viewModel.retryTrending,
        ),
        ViewData<List<SkillCount>>(:final data) => Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          children: [
            for (final skillCount in data)
              ActionChip(
                label: Text('${skillCount.skill} ${skillCount.count}+'),
                onPressed: () => _submit(context, viewModel, skillCount.skill),
              ),
          ],
        ),
      },
    ];
  }

  List<Widget> _recentSearchesSection(
    BuildContext context,
    SearchState state,
    SearchViewModel viewModel,
  ) {
    final recent = state.recentSearches;
    if (recent is ViewData<List<SearchHistoryEntry>> && recent.data.isEmpty) {
      return const [];
    }
    if (recent is ViewEmpty<List<SearchHistoryEntry>>) return const [];

    final showClear = recent is ViewData<List<SearchHistoryEntry>>;
    return [
      const SizedBox(height: AppSpacing.section),
      SearchSectionHeader(
        title: 'Recent searches',
        actionLabel: showClear ? 'Clear' : null,
        onAction: showClear ? viewModel.clearRecentSearches : null,
      ),
      const SizedBox(height: AppSpacing.s8),
      switch (recent) {
        ViewLoading<List<SearchHistoryEntry>>() => const Column(
          children: [
            SkeletonBox(height: 20),
            SizedBox(height: AppSpacing.s12),
            SkeletonBox(height: 20),
          ],
        ),
        ViewEmpty<List<SearchHistoryEntry>>() => const SizedBox.shrink(),
        ViewError<List<SearchHistoryEntry>>(:final error) => StateView.error(
          message: error.message,
          onRetry: viewModel.retryRecentSearches,
        ),
        ViewData<List<SearchHistoryEntry>>(:final data) => Column(
          children: [
            for (final entry in data)
              _RecentSearchRow(
                entry: entry,
                onTap: () => _submit(context, viewModel, entry.term),
              ),
          ],
        ),
      },
    ];
  }
}

class _WorkModeChips extends StatelessWidget {
  const _WorkModeChips({required this.selected, required this.onSelected});

  final WorkMode? selected;
  final ValueChanged<WorkMode?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        _chip(context, label: 'All', value: null),
        for (final mode in WorkMode.values)
          _chip(context, label: mode.label, value: mode),
      ],
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required WorkMode? value,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected == value,
      showCheckmark: true,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _RecentSearchRow extends StatelessWidget {
  const _RecentSearchRow({required this.entry, required this.onTap});

  final SearchHistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${entry.term}, searched ${formatPostedAge(entry.searchedAt)}',
      child: InkWell(
        onTap: onTap,
        child: ExcludeSemantics(
          child: SizedBox(
            height: AppSizes.minTouchTarget,
            child: Row(
              children: [
                const Icon(
                  Symbols.history_rounded,
                  size: AppSizes.iconSmall,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(child: Text(entry.term, style: textTheme.bodyLarge)),
                Text(
                  formatPostedAge(entry.searchedAt),
                  style: textTheme.bodySmall,
                ),
                const SizedBox(width: AppSpacing.s8),
                const Icon(
                  Symbols.north_east_rounded,
                  size: AppSizes.iconSmall,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
