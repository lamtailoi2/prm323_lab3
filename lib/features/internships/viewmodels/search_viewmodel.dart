import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/distinct_listings.dart';
import '../../../core/utils/skill_matcher.dart';
import '../../../models/internship.dart';
import '../../../services/auth_service.dart';
import '../../../services/internship_service.dart';
import '../../../services/search_history_service.dart';
import '../models/search_filter_criteria.dart';
import '../models/search_history_entry.dart';

/// How many trending skills the Search screen shows, matching the Figma
/// "Trending skills for undergraduates" row (5 chips).
const int trendingSkillLimit = 5;

/// How many past searches the Search screen shows.
const int recentSearchLimit = 10;

/// A known skill and how many active listings in the shared pool mention it.
@immutable
class SkillCount {
  const SkillCount(this.skill, this.count);

  final String skill;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is SkillCount && other.skill == skill && other.count == count;

  @override
  int get hashCode => Object.hash(skill, count);
}

@immutable
class SearchState {
  const SearchState({
    this.workMode,
    this.trending = const ViewLoading(),
    this.recentSearches = const ViewLoading(),
  });

  /// The "Work mode" chip in use; `null` means "All".
  final WorkMode? workMode;

  /// Top skills by how many active listings mention them, computed from the
  /// shared pool (never static/fabricated counts).
  final ViewState<List<SkillCount>> trending;

  /// This student's past searches, newest first.
  final ViewState<List<SearchHistoryEntry>> recentSearches;
}

final searchViewModelProvider =
    NotifierProvider.autoDispose<SearchViewModel, SearchState>(
      SearchViewModel.new,
    );

class SearchViewModel extends Notifier<SearchState> {
  StreamSubscription<List<Internship>>? _internshipsSubscription;
  StreamSubscription<List<SearchHistoryEntry>>? _historySubscription;

  /// The shared pool already streamed for "Trending skills", reused so the
  /// filter sheet can preview its match count without another listener.
  /// Every copy is kept; jobs are merged after filtering (CR-08).
  List<Internship> _pool = const <Internship>[];

  @override
  SearchState build() {
    final internships = ref.watch(internshipServiceProvider);
    final history = ref.watch(searchHistoryServiceProvider);
    final uid = ref.watch(currentUserIdProvider);

    ref.onDispose(() {
      unawaited(_internshipsSubscription?.cancel());
      unawaited(_historySubscription?.cancel());
    });

    _subscribeTrending(internships);
    if (uid == null) return const SearchState(recentSearches: ViewEmpty());
    _subscribeHistory(history, uid);
    return const SearchState();
  }

  /// Selects [mode], or clears it (back to "All") when already selected.
  void selectWorkMode(WorkMode? mode) {
    final next = state.workMode == mode ? null : mode;
    state = SearchState(
      workMode: next,
      trending: state.trending,
      recentSearches: state.recentSearches,
    );
  }

  /// How many listings in the pool match [criteria] and [query], for the
  /// filter sheet's `Show N results` button.
  int countMatching(SearchFilterCriteria criteria, {String query = ''}) {
    // Merged after filtering, as on Search Results (CR-08).
    return distinctListings(
      _pool.where((internship) => criteria.matches(internship, query: query)),
    ).length;
  }

  /// Records [term] in this student's search history. Called when the
  /// student submits the search field or picks a recent/trending term, so
  /// "Recent searches" always reflects what was actually searched.
  Future<void> recordSearch(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    final service = ref.read(searchHistoryServiceProvider);
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    try {
      await service.record(uid, trimmed);
    } on AppException {
      // Recording history must never block the search itself.
    }
  }

  Future<void> clearRecentSearches() async {
    final service = ref.read(searchHistoryServiceProvider);
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) return;
    try {
      await service.clear(uid);
    } on AppException {
      // Best-effort: the next snapshot will show the real state either way.
    }
  }

  Future<void> retryTrending() async {
    if (state.trending.isLoading) return;
    state = SearchState(
      workMode: state.workMode,
      recentSearches: state.recentSearches,
    );
    _subscribeTrending(ref.read(internshipServiceProvider));
  }

  Future<void> retryRecentSearches() async {
    if (state.recentSearches.isLoading) return;
    state = SearchState(
      workMode: state.workMode,
      trending: state.trending,
      recentSearches: const ViewLoading(),
    );
    _subscribeHistory(
      ref.read(searchHistoryServiceProvider),
      ref.read(currentUserIdProvider),
    );
  }

  void _subscribeTrending(InternshipService service) {
    unawaited(_internshipsSubscription?.cancel());
    _internshipsSubscription = service.watchActive().listen(
      (internships) {
        if (!ref.mounted) return;
        _pool = internships;
        state = SearchState(
          workMode: state.workMode,
          trending: ViewState.fromData(
            _topSkills(distinctListings(internships)),
            isEmpty: internships.isEmpty,
          ),
          recentSearches: state.recentSearches,
        );
      },
      onError: (Object error, StackTrace stack) {
        if (!ref.mounted) return;
        state = SearchState(
          workMode: state.workMode,
          trending: ViewError(_toAppException(error)),
          recentSearches: state.recentSearches,
        );
      },
    );
  }

  void _subscribeHistory(SearchHistoryService service, String? uid) {
    unawaited(_historySubscription?.cancel());
    if (uid == null) {
      state = SearchState(
        workMode: state.workMode,
        trending: state.trending,
        recentSearches: const ViewEmpty(),
      );
      return;
    }
    _historySubscription = service
        .watchRecent(uid, limit: recentSearchLimit)
        .listen(
          (entries) {
            if (!ref.mounted) return;
            state = SearchState(
              workMode: state.workMode,
              trending: state.trending,
              recentSearches: ViewState.fromData(
                entries,
                isEmpty: entries.isEmpty,
              ),
            );
          },
          onError: (Object error, StackTrace stack) {
            if (!ref.mounted) return;
            state = SearchState(
              workMode: state.workMode,
              trending: state.trending,
              recentSearches: ViewError(_toAppException(error)),
            );
          },
        );
  }

  static List<SkillCount> _topSkills(List<Internship> internships) {
    final counts = <String, int>{};
    for (final internship in internships) {
      for (final skill in internship.skills) {
        counts[skill] = (counts[skill] ?? 0) + 1;
      }
    }
    final ranked =
        knownSkills
            .where(counts.containsKey)
            .map((skill) => SkillCount(skill, counts[skill]!))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));
    return List.unmodifiable(ranked.take(trendingSkillLimit));
  }

  static AppException _toAppException(Object error) {
    return error is AppException
        ? error
        : AppException(
            AppErrorKind.unknown,
            'We could not load this. Try again in a moment.',
            cause: error,
          );
  }
}
