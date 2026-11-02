import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/distinct_listings.dart';
import '../../../core/utils/skill_suggestions.dart';
import '../../../models/internship.dart';
import '../../../models/user_profile.dart';
import '../../../services/analytics_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/internship_service.dart';
import '../../../services/saved_service.dart';
import '../../../services/search_history_service.dart';
import '../models/search_filter_criteria.dart';

/// Available sorting modes for Search Results.
enum SearchSortBy {
  mostRecent('Most recent'),
  bestMatch('Best match');

  const SearchSortBy(this.label);

  final String label;
}

@immutable
class SearchResultsState {
  const SearchResultsState({
    this.query = '',
    this.criteria = const SearchFilterCriteria(),
    this.sortBy = SearchSortBy.mostRecent,
    this.results = const ViewLoading(),
    this.savedIds = const <String>{},
  });

  final String query;
  final SearchFilterCriteria criteria;
  final SearchSortBy sortBy;
  final ViewState<List<Internship>> results;
  final Set<String> savedIds;

  /// Backward-compatible getter for single work mode.
  WorkMode? get workMode => criteria.workModes.firstOrNull;

  int get activeFilterCount {
    var count = criteria.criteriaCount;
    if (query.trim().isNotEmpty) count++;
    return count;
  }

  SearchResultsState copyWith({
    String? query,
    SearchFilterCriteria? criteria,
    SearchSortBy? sortBy,
    ViewState<List<Internship>>? results,
    Set<String>? savedIds,
  }) {
    return SearchResultsState(
      query: query ?? this.query,
      criteria: criteria ?? this.criteria,
      sortBy: sortBy ?? this.sortBy,
      results: results ?? this.results,
      savedIds: savedIds ?? this.savedIds,
    );
  }
}

final searchResultsViewModelProvider =
    NotifierProvider.autoDispose<SearchResultsViewModel, SearchResultsState>(
      SearchResultsViewModel.new,
    );

class SearchResultsViewModel extends Notifier<SearchResultsState> {
  StreamSubscription<List<Internship>>? _internshipsSubscription;
  StreamSubscription<List<String>>? _savedSubscription;
  List<Internship>? _rawList;
  bool _initialized = false;

  /// Search term and filter-sheet source waiting for their results, so
  /// `search` and `search_filter_apply` report the count the student sees
  /// even when the pool arrives after navigation.
  String? _pendingSearchTerm;
  String? _pendingFilterSource;

  @override
  SearchResultsState build() {
    final internshipService = ref.watch(internshipServiceProvider);
    final savedService = ref.watch(savedServiceProvider);
    final uid = ref.watch(currentUserIdProvider);

    ref.onDispose(() {
      unawaited(_internshipsSubscription?.cancel());
      unawaited(_savedSubscription?.cancel());
    });

    _subscribeInternships(internshipService);
    if (uid != null) {
      _subscribeSaved(savedService, uid);
    }

    return const SearchResultsState();
  }

  /// Seeds initial query and work arrangement from navigation arguments.
  void init({
    String query = '',
    WorkMode? workMode,
    SearchFilterCriteria? criteria,
  }) {
    if (_initialized) return;
    _initialized = true;

    final initialCriteria =
        criteria ??
        SearchFilterCriteria(
          workModes: workMode == null ? const {} : {workMode},
        );

    state = state.copyWith(query: query, criteria: initialCriteria);
    if (query.trim().isNotEmpty) _pendingSearchTerm = query.trim();
    // Criteria only arrive from the Search tab's filter sheet.
    if (criteria != null) _pendingFilterSource = 'search';
    _filterAndEmit();
  }

  void setQuery(String query) {
    final trimmed = query.trim();
    state = state.copyWith(query: trimmed);
    if (trimmed.isNotEmpty) {
      _pendingSearchTerm = trimmed;
      unawaited(_recordSearch(trimmed));
    }
    _filterAndEmit();
  }

  void clearQuery() {
    state = state.copyWith(query: '');
    _filterAndEmit();
  }

  void setCriteria(SearchFilterCriteria criteria) {
    state = state.copyWith(criteria: criteria);
    _pendingFilterSource = 'search_results';
    _filterAndEmit();
  }

  /// Backward-compatible helper for single work mode.
  void setWorkMode(WorkMode? mode) {
    final nextModes = mode == null ? const <WorkMode>{} : {mode};
    state = state.copyWith(
      criteria: state.criteria.copyWith(workModes: nextModes),
    );
    _filterAndEmit();
  }

  void removeWorkMode(WorkMode mode) {
    final nextModes = Set<WorkMode>.from(state.criteria.workModes)
      ..remove(mode);
    state = state.copyWith(
      criteria: state.criteria.copyWith(workModes: nextModes),
    );
    _filterAndEmit();
  }

  void clearWorkMode() {
    state = state.copyWith(
      criteria: state.criteria.copyWith(workModes: const {}),
    );
    _filterAndEmit();
  }

  void removeSkill(String skill) {
    final nextSkills = Set<String>.from(state.criteria.skills)..remove(skill);
    state = state.copyWith(
      criteria: state.criteria.copyWith(skills: nextSkills),
    );
    _filterAndEmit();
  }

  void clearLocation() {
    state = state.copyWith(
      criteria: state.criteria.copyWith(clearLocation: true),
    );
    _filterAndEmit();
  }

  void clearFilters() {
    state = state.copyWith(query: '', criteria: const SearchFilterCriteria());
    _filterAndEmit();
  }

  void setSortBy(SearchSortBy sortBy) {
    if (state.sortBy == sortBy) return;
    state = state.copyWith(sortBy: sortBy);
    _filterAndEmit();
  }

  /// Skills the current pool mentions, for the Filter sheet's chips.
  List<String> get suggestedSkills {
    final raw = _rawList;
    return raw == null
        ? const <String>[]
        : suggestedFilterSkills(distinctListings(raw));
  }

  /// Counts how many listings would match [testCriteria] and current [state.query].
  int countMatching(SearchFilterCriteria testCriteria) {
    final raw = _rawList;
    if (raw == null) return 0;
    return _applyFilters(raw, state.query, testCriteria).length;
  }

  Future<void> toggleSave(String internshipKey) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    final savedService = ref.read(savedServiceProvider);

    final isSaved = state.savedIds.contains(internshipKey);
    final nextSaved = Set<String>.from(state.savedIds);
    if (isSaved) {
      nextSaved.remove(internshipKey);
    } else {
      nextSaved.add(internshipKey);
    }
    state = state.copyWith(savedIds: nextSaved);

    try {
      if (isSaved) {
        await savedService.unsave(uid, internshipKey);
      } else {
        await savedService.save(uid, internshipKey);
      }
    } on AppException catch (_) {
      if (ref.mounted) {
        state = state.copyWith(savedIds: state.savedIds);
      }
    }
  }

  void retry() {
    final service = ref.read(internshipServiceProvider);
    state = state.copyWith(results: const ViewLoading());
    _subscribeInternships(service);
  }

  void _subscribeInternships(InternshipService service) {
    unawaited(_internshipsSubscription?.cancel());
    _internshipsSubscription = service.watchActive().listen(
      _onInternshipsData,
      onError: _onInternshipsError,
    );
  }

  void _subscribeSaved(SavedService service, String uid) {
    unawaited(_savedSubscription?.cancel());
    _savedSubscription = service.watchSavedIds(uid).listen((ids) {
      if (!ref.mounted) return;
      state = state.copyWith(savedIds: ids.toSet());
    }, onError: (Object _) {});
  }

  void _onInternshipsData(List<Internship> data) {
    if (!ref.mounted) return;
    _rawList = data;
    _filterAndEmit();
  }

  void _onInternshipsError(Object error, StackTrace stack) {
    if (!ref.mounted) return;
    final appError = error is AppException
        ? error
        : AppException(
            AppErrorKind.unknown,
            'We could not load internships. Try again in a moment.',
            cause: error,
          );
    state = state.copyWith(results: ViewError(appError));
  }

  List<Internship> _applyFilters(
    List<Internship> raw,
    String query,
    SearchFilterCriteria criteria,
  ) {
    // Copies of one job carry different sync keywords, so they are merged
    // after filtering; merging first could drop the copy that matched
    // (CR-08).
    return distinctListings(
      raw.where((internship) => criteria.matches(internship, query: query)),
    );
  }

  void _filterAndEmit() {
    final raw = _rawList;
    if (raw == null) return;

    final filtered = _applyFilters(raw, state.query, state.criteria);
    _logPending(filtered.length);
    final sorted = [...filtered];

    switch (state.sortBy) {
      case SearchSortBy.mostRecent:
        sorted.sort((a, b) {
          final aDate = a.postedAt;
          final bDate = b.postedAt;
          if (aDate != null && bDate != null) {
            return bDate.compareTo(aDate);
          }
          if (aDate != null) return -1;
          if (bDate != null) return 1;
          return (a.searchRank ?? 999).compareTo(b.searchRank ?? 999);
        });
      case SearchSortBy.bestMatch:
        sorted.sort((a, b) {
          final aRank = a.searchRank ?? 999;
          final bRank = b.searchRank ?? 999;
          if (aRank != bRank) return aRank.compareTo(bRank);
          final aDate = a.postedAt;
          final bDate = b.postedAt;
          if (aDate != null && bDate != null) return bDate.compareTo(aDate);
          return 0;
        });
    }

    if (sorted.isEmpty) {
      state = state.copyWith(results: const ViewEmpty());
    } else {
      state = state.copyWith(results: ViewData(sorted));
    }
  }

  void _logPending(int resultCount) {
    final term = _pendingSearchTerm;
    final filterSource = _pendingFilterSource;
    if (term == null && filterSource == null) return;
    _pendingSearchTerm = null;
    _pendingFilterSource = null;
    final analytics = ref.read(analyticsServiceProvider);
    if (term != null) {
      unawaited(
        analytics.logEvent('search', {
          'search_term': term.length <= 100 ? term : term.substring(0, 100),
          'result_count': resultCount,
          'source': 'search',
        }),
      );
    }
    if (filterSource != null) {
      final criteria = state.criteria;
      final modes = [
        for (final mode in criteria.workModes)
          InternshipPreferences.storageValue(mode),
      ]..sort();
      final location = criteria.location;
      final jobType = criteria.jobType;
      final allowance = criteria.allowanceRange;
      unawaited(
        analytics.logEvent('search_filter_apply', {
          'work_mode': modes.isEmpty ? 'any' : modes.join(','),
          'location': location == null || location == 'Any location'
              ? 'any'
              : location,
          'skill_count': criteria.skills.length,
          // Every option that filters is logged, so a Job type or allowance
          // that narrows results to zero can be told apart (CR-13).
          'job_type': jobType == null || jobType == 'Any job type'
              ? 'any'
              : jobType,
          'allowance': allowance == null || allowance == 'Any allowance'
              ? 'any'
              : allowance,
          'result_count': resultCount,
          'source': filterSource,
        }),
      );
    }
  }

  Future<void> _recordSearch(String term) async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    final historyService = ref.read(searchHistoryServiceProvider);
    await historyService.record(uid, term);
  }
}
