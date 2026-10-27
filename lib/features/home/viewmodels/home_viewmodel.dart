import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/job_role.dart';
import '../../../models/internship.dart';
import '../../../services/analytics_service.dart';
import '../../../services/internship_service.dart';
import '../../../services/remote_config_service.dart';

/// The two Home lists, built from the shared Firestore listing pool.
@immutable
class HomeFeed {
  const HomeFeed({required this.recommended, required this.recent});

  /// The first `home_recommended_limit` listings by sync rank / recency,
  /// optionally filtered by the selected skill.
  final List<Internship> recommended;

  /// The remaining listings, newest first, capped by `home_recent_limit`.
  final List<Internship> recent;
}

@immutable
class HomeState {
  const HomeState({
    this.selectedRole,
    this.availableRoles = const <JobRole>[],
    this.feed = const ViewLoading(),
  });

  /// The "Browse by Role" shortcut in use; `null` shows all IT listings.
  final JobRole? selectedRole;

  /// Roles with at least one current listing; empty while loading so the
  /// header can fall back to the full list.
  final List<JobRole> availableRoles;
  final ViewState<HomeFeed> feed;
}

final homeViewModelProvider =
    NotifierProvider.autoDispose<HomeViewModel, HomeState>(HomeViewModel.new);

class HomeViewModel extends Notifier<HomeState> {
  /// IT job families shown by "Browse by Role", in a stable order.
  static const List<JobRole> roles = JobRole.values;

  List<Internship> _results = const <Internship>[];
  StreamSubscription<List<Internship>>? _subscription;
  DateTime _openedAt = DateTime.now();

  @override
  HomeState build() {
    final service = ref.watch(internshipServiceProvider);
    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    _openedAt = DateTime.now();

    final updates = remoteConfig.onUpdated.listen((_) {
      if (state.feed is ViewData<HomeFeed>) _showResults();
    });
    ref.onDispose(() {
      unawaited(updates.cancel());
      unawaited(_subscription?.cancel());
    });

    _subscribe(service);
    return const HomeState();
  }

  /// Selects [role], or clears it when it is already selected. The shared
  /// pool is already in memory, so filtering is immediate and costs no
  /// network request.
  void selectRole(JobRole role) {
    final next = state.selectedRole == role ? null : role;
    state = HomeState(
      selectedRole: next,
      availableRoles: state.availableRoles,
      feed: state.feed,
    );
    if (state.feed is ViewData<HomeFeed> || state.feed is ViewEmpty<HomeFeed>) {
      _showResults();
    }
  }

  Future<void> retry() async {
    if (state.feed.isLoading) return;
    final service = ref.read(internshipServiceProvider);
    state = HomeState(
      selectedRole: state.selectedRole,
      availableRoles: state.availableRoles,
    );
    _subscribe(service);
  }

  void _subscribe(InternshipService service) {
    unawaited(_subscription?.cancel());
    _subscription = service.watchActive().listen(_onData, onError: _onError);
  }

  void _onData(List<Internship> results) {
    if (!ref.mounted) return;
    _results = results;
    _showResults();
  }

  void _onError(Object error, StackTrace stack) {
    if (!ref.mounted) return;
    final appError = error is AppException
        ? error
        : AppException(
            AppErrorKind.unknown,
            'We could not load internships. Try again in a moment.',
            cause: error,
          );
    state = HomeState(
      selectedRole: state.selectedRole,
      availableRoles: state.availableRoles,
      feed: ViewError(appError),
    );
  }

  void _showResults() {
    final selected = state.selectedRole;
    final itJobs = _results
        .where((internship) => internship.role != null)
        .toList(growable: false);
    final available = <JobRole>[
      for (final role in roles)
        if (itJobs.any((internship) => internship.role == role)) role,
    ];
    if (selected != null && !available.contains(selected)) {
      available.add(selected);
    }
    final filtered = selected == null
        ? itJobs
        : itJobs
              .where((internship) => internship.role == selected)
              .toList(growable: false);

    final remoteConfig = ref.read(remoteConfigServiceProvider);
    final recommendedLimit = math.max(
      0,
      remoteConfig.getInt(RemoteConfigKeys.homeRecommendedLimit),
    );
    final recentLimit = math.max(
      0,
      remoteConfig.getInt(RemoteConfigKeys.homeRecentLimit),
    );

    final ranked = [...filtered]..sort(_byRecommendation);
    final recommended = ranked.take(recommendedLimit).toList(growable: false);
    final recommendedKeys = {
      for (final internship in recommended) internship.key,
    };
    final recent =
        filtered
            .where((internship) => !recommendedKeys.contains(internship.key))
            .toList()
          ..sort(_byNewest);

    final feed = HomeFeed(
      recommended: List.unmodifiable(recommended),
      recent: List.unmodifiable(recent.take(recentLimit)),
    );
    state = HomeState(
      selectedRole: selected,
      availableRoles: List.unmodifiable(available),
      feed: ViewState.fromData(feed, isEmpty: filtered.isEmpty),
    );
    _logSearch(selected, filtered.length);
  }

  void _logSearch(JobRole? role, int resultCount) {
    final analytics = ref.read(analyticsServiceProvider);
    unawaited(
      analytics.logEvent('search', {
        'search_term': role?.label ?? 'IT',
        'result_count': resultCount,
        'elapsed_sec': DateTime.now().difference(_openedAt).inSeconds,
      }),
    );
  }

  static int _byRecommendation(Internship a, Internship b) {
    const unknownRank = 1 << 30;
    final rank = (a.searchRank ?? unknownRank).compareTo(
      b.searchRank ?? unknownRank,
    );
    return rank != 0 ? rank : _byNewest(a, b);
  }

  static int _byNewest(Internship a, Internship b) {
    final first = a.postedAt;
    final second = b.postedAt;
    if (first == null && second == null) return 0;
    if (first == null) return 1;
    if (second == null) return -1;
    return second.compareTo(first);
  }
}
