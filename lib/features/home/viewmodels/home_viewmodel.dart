import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../models/internship.dart';
import '../../../services/internship_service.dart';
import '../../../services/remote_config_service.dart';

/// The two Home lists. Both come from one SerpAPI page, so opening Home
/// costs a single search of the free-plan quota (G-25).
@immutable
class HomeFeed {
  const HomeFeed({required this.recommended, required this.recent});

  /// The first `home_recommended_limit` results in Google's relevance order
  /// for the selected skill (interim rule until profile skills exist, G-23).
  final List<Internship> recommended;

  /// The other results, newest first.
  final List<Internship> recent;
}

@immutable
class HomeState {
  const HomeState({this.selectedSkill, this.feed = const ViewLoading()});

  /// The "Browse by skill" shortcut in use; `null` shows IT internships in
  /// general.
  final String? selectedSkill;
  final ViewState<HomeFeed> feed;
}

final homeViewModelProvider =
    NotifierProvider.autoDispose<HomeViewModel, HomeState>(HomeViewModel.new);

class HomeViewModel extends Notifier<HomeState> {
  /// "Browse by skill" shortcuts, in the order of the Lab 2 Home design.
  static const List<String> skills = <String>[
    'Flutter',
    'React',
    'NestJS',
    'MongoDB',
    'Python',
  ];

  /// Searched when no skill is selected ("IT internship").
  static const String defaultKeyword = 'IT';

  List<Internship> _results = const <Internship>[];

  /// Only the latest request may update the state, so a slow answer for a
  /// previously selected skill cannot overwrite the current one.
  int _requestId = 0;

  @override
  HomeState build() {
    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    // A new home_recommended_limit from the console re-splits the loaded
    // page without another search (TC-12).
    final updates = remoteConfig.onUpdated.listen((_) {
      if (state.feed is ViewData<HomeFeed>) _showResults();
    });
    ref.onDispose(updates.cancel);
    unawaited(Future.microtask(_load));
    return const HomeState();
  }

  /// Selects [skill], or clears it when it is already selected, and loads
  /// the matching internships.
  Future<void> selectSkill(String skill) async {
    final next = state.selectedSkill == skill ? null : skill;
    state = HomeState(selectedSkill: next);
    await _load();
  }

  Future<void> retry() async {
    if (state.feed.isLoading) return;
    state = HomeState(selectedSkill: state.selectedSkill);
    await _load();
  }

  Future<void> _load() async {
    if (!ref.mounted) return;
    final service = ref.read(internshipServiceProvider);
    final skill = state.selectedSkill;
    final requestId = ++_requestId;

    try {
      final results = await service.search(keyword: skill ?? defaultKeyword);
      if (!ref.mounted || requestId != _requestId) return;
      _results = results;
      _showResults();
    } on AppException catch (error) {
      if (!ref.mounted || requestId != _requestId) return;
      state = HomeState(selectedSkill: skill, feed: ViewError(error));
    }
  }

  void _showResults() {
    final limit = ref
        .read(remoteConfigServiceProvider)
        .getInt(RemoteConfigKeys.homeRecommendedLimit);
    final split = math.min(math.max(limit, 0), _results.length);
    final feed = HomeFeed(
      recommended: List.unmodifiable(_results.take(split)),
      recent: List.unmodifiable(_newestFirst(_results.skip(split))),
    );
    state = HomeState(
      selectedSkill: state.selectedSkill,
      feed: ViewState.fromData(feed, isEmpty: _results.isEmpty),
    );
  }

  /// Sorts by posted age; listings without a known age keep their relevance
  /// order after the dated ones.
  static List<Internship> _newestFirst(Iterable<Internship> items) {
    final indexed = items.indexed.toList();
    int byAge(Duration? a, Duration? b) {
      if (a == null || b == null) {
        return a == b ? 0 : (a == null ? 1 : -1);
      }
      return a.compareTo(b);
    }

    indexed.sort((a, b) {
      final age = byAge(a.$2.postedAge, b.$2.postedAge);
      return age != 0 ? age : a.$1.compareTo(b.$1);
    });
    return [for (final (_, internship) in indexed) internship];
  }
}
