import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/core/utils/job_role.dart';
import 'package:internly/features/home/viewmodels/home_viewmodel.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/remote_config_service.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeInternshipService internships;
  late FakeRemoteConfigService remoteConfig;
  late FakeAnalyticsService analytics;
  late ProviderContainer container;

  setUp(() {
    internships = FakeInternshipService();
    remoteConfig = FakeRemoteConfigService();
    analytics = FakeAnalyticsService();
    container = ProviderContainer.test(
      overrides: [
        internshipServiceProvider.overrideWithValue(internships),
        remoteConfigServiceProvider.overrideWithValue(remoteConfig),
        analyticsServiceProvider.overrideWithValue(analytics),
      ],
    );
  });

  tearDown(() async {
    await internships.dispose();
    remoteConfig.dispose();
  });

  HomeViewModel listen() {
    // Keep the auto-dispose provider alive, as the screen would.
    container.listen(homeViewModelProvider, (_, _) {});
    return container.read(homeViewModelProvider.notifier);
  }

  HomeState read() => container.read(homeViewModelProvider);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  HomeFeed feed() => (read().feed as ViewData<HomeFeed>).data;

  test('starts loading, then shows the shared pool', () async {
    internships.results = [testInternship('1')];
    listen();
    expect(read().feed, isA<ViewLoading<HomeFeed>>());
    expect(read().selectedRole, isNull);

    await settle();
    expect(internships.watchCalls, 1);
    expect(read().feed, isA<ViewData<HomeFeed>>());
    expect(feed().recommended.single.jobId, 'job-1');
    expect(analytics.events, contains('search'));
  });

  test('splits the pool by the two Remote Config limits', () async {
    remoteConfig.values[RemoteConfigKeys.homeRecommendedLimit] = 2;
    remoteConfig.values[RemoteConfigKeys.homeRecentLimit] = 2;
    internships.results = [
      testInternship(
        '1',
        postedAt: DateTime.now().subtract(const Duration(days: 5)),
        searchRank: 0,
      ),
      testInternship(
        '2',
        postedAt: DateTime.now().subtract(const Duration(days: 1)),
        searchRank: 1,
      ),
      testInternship(
        '3',
        postedAt: DateTime.now().subtract(const Duration(days: 3)),
        searchRank: 2,
      ),
      testInternship(
        '4',
        postedAt: DateTime.now().subtract(const Duration(days: 4)),
        searchRank: 3,
      ),
      testInternship(
        '5',
        postedAt: DateTime.now().subtract(const Duration(hours: 10)),
        searchRank: 4,
      ),
    ];
    listen();
    await settle();

    expect(feed().recommended.map((i) => i.jobId), ['job-1', 'job-2']);
    expect(feed().recent.map((i) => i.jobId), ['job-5', 'job-3']);
  });

  test(
    'a Remote Config update re-splits without another subscription',
    () async {
      internships.results = [for (var i = 1; i <= 8; i++) testInternship('$i')];
      listen();
      await settle();
      expect(feed().recommended, hasLength(5));

      remoteConfig.publish(RemoteConfigKeys.homeRecommendedLimit, 3);
      remoteConfig.publish(RemoteConfigKeys.homeRecentLimit, 2);
      await settle();
      expect(feed().recommended, hasLength(3));
      expect(feed().recent, hasLength(2));
      expect(internships.watchCalls, 1);
    },
  );

  test('no listings is the empty state', () async {
    listen();
    await settle();
    expect(read().feed, isA<ViewEmpty<HomeFeed>>());
  });

  test('a stream failure is the error state; Retry subscribes again', () async {
    internships.error = const AppException(
      AppErrorKind.network,
      'We could not load internships. Check your connection and try again.',
    );
    final vm = listen();
    await settle();
    final error = read().feed as ViewError<HomeFeed>;
    expect(error.error.kind, AppErrorKind.network);

    internships
      ..error = null
      ..results = [testInternship('1')];
    await vm.retry();
    await settle();
    expect(read().feed, isA<ViewData<HomeFeed>>());
    expect(internships.watchCalls, 2);
  });

  test('Retry is ignored while loading', () async {
    internships.gate = Completer<void>();
    final vm = listen();
    await settle();
    unawaited(vm.retry());
    expect(internships.watchCalls, 1);
    internships.gate!.complete();
  });

  test(
    'selecting a role filters the pool; selecting it again clears it',
    () async {
      internships.results = [
        testInternship('1', title: 'Mobile Developer Intern'),
        testInternship('2', title: 'Frontend Developer Intern'),
      ];
      final vm = listen();
      await settle();

      vm.selectRole(JobRole.mobile);
      expect(read().selectedRole, JobRole.mobile);
      expect(feed().recommended.single.jobId, 'job-1');
      expect(internships.watchCalls, 1);

      vm.selectRole(JobRole.mobile);
      expect(read().selectedRole, isNull);
      expect(feed().recommended, hasLength(2));
    },
  );

  test('non-IT listings are left out of the Home feed', () async {
    internships.results = [
      testInternship('1', title: 'HR Intern'),
      testInternship('2', title: 'Frontend Developer Intern'),
    ];
    listen();
    await settle();

    expect(feed().recommended.single.jobId, 'job-2');
  });

  test('a Firestore update replaces the lists in place', () async {
    internships.results = [testInternship('1')];
    listen();
    await settle();

    internships.emit([testInternship('1'), testInternship('2')]);
    await settle();
    expect(feed().recommended.map((i) => i.jobId), ['job-1', 'job-2']);
    expect(internships.watchCalls, 1);
  });
}
