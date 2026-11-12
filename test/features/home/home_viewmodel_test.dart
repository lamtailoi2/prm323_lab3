import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/core/utils/job_role.dart';
import 'package:internly/features/home/viewmodels/home_viewmodel.dart';
import 'package:internly/models/user_profile.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/remote_config_service.dart';
import 'package:internly/services/user_profile_service.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeInternshipService internships;
  late FakeRemoteConfigService remoteConfig;
  late FakeAnalyticsService analytics;
  late FakeUserProfileService profiles;
  late ProviderContainer container;

  setUp(() {
    internships = FakeInternshipService();
    remoteConfig = FakeRemoteConfigService();
    analytics = FakeAnalyticsService();
    profiles = FakeUserProfileService();
    container = ProviderContainer.test(
      overrides: [
        internshipServiceProvider.overrideWithValue(internships),
        remoteConfigServiceProvider.overrideWithValue(remoteConfig),
        analyticsServiceProvider.overrideWithValue(analytics),
        // Signed in before Home opens, as the router guarantees.
        currentUserIdProvider.overrideWithValue(testUser.uid),
        userProfileServiceProvider.overrideWithValue(profiles),
      ],
    );
  });

  tearDown(() async {
    await internships.dispose();
    await profiles.dispose();
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
    expect(analytics.parameters['search']?['source'], 'home');
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

  group('preferred location (Profile › Update preferences)', () {
    final pool = [
      testInternship('1', location: 'Thành phố Hồ Chí Minh, Hồ Chí Minh'),
      testInternship('2', location: 'Hà Nội'),
      testInternship('3', location: 'Việt Nam'),
      testInternship('4', location: 'Hồ Chí Minh'),
    ];

    UserProfile living(String location) =>
        UserProfile(preferences: InternshipPreferences(location: location));

    test(
      'Recommended keeps the preferred city; Recently Posted keeps all',
      () async {
        profiles.profile = living('Ho Chi Minh City');
        internships.results = pool;
        listen();
        await settle();

        expect(feed().recommended.map((i) => i.jobId), ['job-1', 'job-4']);
        expect(
          feed().recent.map((i) => i.jobId),
          containsAll(['job-2', 'job-3']),
        );
      },
    );

    test('no preference or "All Vietnam" recommends every location', () async {
      internships.results = pool;
      listen();
      await settle();
      expect(feed().recommended, hasLength(4));

      await profiles.updatePreferences(
        testUser.uid,
        const InternshipPreferences(location: 'All Vietnam'),
      );
      await settle();
      expect(feed().recommended, hasLength(4));
    });

    test(
      'changing the location re-filters without a new subscription',
      () async {
        profiles.profile = living('Ho Chi Minh City');
        internships.results = pool;
        listen();
        await settle();

        await profiles.updatePreferences(
          testUser.uid,
          const InternshipPreferences(location: 'Hanoi'),
        );
        await settle();
        expect(feed().recommended.map((i) => i.jobId), ['job-2']);
        expect(internships.watchCalls, 1);
      },
    );

    test('a profile that cannot load leaves Recommended unfiltered', () async {
      profiles.loadError = const AppException(
        AppErrorKind.network,
        'We could not load your profile. Check your connection and try again.',
      );
      internships.results = pool;
      listen();
      await settle();
      expect(feed().recommended, hasLength(4));
    });
  });

  group('profile match (target roles, then skills)', () {
    // Sync order 1..5; titles decide the listing role.
    final pool = [
      testInternship('1', title: 'Tester Intern', searchRank: 0),
      testInternship(
        '2',
        title: 'Fullstack Intern',
        searchRank: 1,
        skills: const ['React'],
      ),
      testInternship('3', title: 'Frontend Developer Intern', searchRank: 2),
      testInternship(
        '4',
        title: 'Frontend Developer Intern',
        searchRank: 3,
        skills: const ['React', 'Vue'],
      ),
      testInternship('5', title: 'Backend Intern', searchRank: 4),
    ];

    List<String> recommendedIds() =>
        feed().recommended.map((i) => i.jobId).toList();

    test('without a profile the sync order is kept', () async {
      internships.results = pool;
      listen();
      await settle();
      expect(recommendedIds(), ['job-1', 'job-2', 'job-3', 'job-4', 'job-5']);
    });

    test('best match first; equal scores keep the sync order', () async {
      profiles.profile = const UserProfile(
        skills: ['React', 'Vue'],
        preferences: InternshipPreferences(targetRoles: [TargetRole.frontend]),
      );
      internships.results = pool;
      listen();
      await settle();

      // 4: frontend + 2 skills (5) · 2: full-stack + React (3) and
      // 3: frontend (3), sync order · 1 and 5: no match (0), sync order.
      expect(recommendedIds(), ['job-4', 'job-2', 'job-3', 'job-1', 'job-5']);
    });

    test(
      'editing skills in Profile re-ranks without a new subscription',
      () async {
        profiles.profile = const UserProfile(
          skills: ['React', 'Vue'],
          preferences: InternshipPreferences(
            targetRoles: [TargetRole.frontend],
          ),
        );
        internships.results = pool;
        listen();
        await settle();

        await profiles.updateSkills(testUser.uid, ['Vue']);
        await settle();
        expect(recommendedIds(), ['job-4', 'job-3', 'job-2', 'job-1', 'job-5']);
        expect(internships.watchCalls, 1);
      },
    );

    test('matching reorders but never removes listings', () async {
      profiles.profile = const UserProfile(
        preferences: InternshipPreferences(targetRoles: [TargetRole.mobile]),
      );
      internships.results = pool;
      listen();
      await settle();
      expect(feed().recommended, hasLength(5));
    });
  });

  group('experience tiebreaker', () {
    // The same frontend role and no skills, so every score is 3; only the
    // title level differs.
    final pool = [
      testInternship('1', title: 'Junior Frontend Developer', searchRank: 0),
      testInternship('2', title: 'Fresher Frontend Developer', searchRank: 1),
      testInternship('3', title: 'Frontend Developer Intern', searchRank: 2),
    ];

    List<String> recommendedIds() =>
        feed().recommended.map((i) => i.jobId).toList();

    test('a matching level comes before a better sync rank', () async {
      profiles.profile = const UserProfile(
        preferences: InternshipPreferences(
          targetRoles: [TargetRole.frontend],
          experience: ExperienceRange.underOne,
        ),
      );
      internships.results = pool;
      listen();
      await settle();

      // job-1 shares the role but is junior, so it drops below the matching
      // fresher and intern listings even though it ranks first in the sync.
      expect(recommendedIds(), ['job-2', 'job-3', 'job-1']);
    });

    test('no experience answer keeps the sync order on equal scores', () async {
      profiles.profile = const UserProfile(
        preferences: InternshipPreferences(targetRoles: [TargetRole.frontend]),
      );
      internships.results = pool;
      listen();
      await settle();

      expect(recommendedIds(), ['job-1', 'job-2', 'job-3']);
    });

    test(
      'a level never lifts a lower role score above a better match',
      () async {
        profiles.profile = const UserProfile(
          skills: ['React'],
          preferences: InternshipPreferences(
            targetRoles: [TargetRole.frontend],
            experience: ExperienceRange.underOne,
          ),
        );
        internships.results = [
          testInternship(
            '1',
            title: 'Fresher Backend Developer',
            searchRank: 0,
            skills: const ['React'],
          ),
          testInternship(
            '2',
            title: 'Junior Frontend Developer',
            searchRank: 1,
          ),
        ];
        listen();
        await settle();

        // The frontend listing scores 3 and the backend one 0 + 1 skill, so the
        // better role/skill match stays first even though only the backend
        // listing matches the experience band.
        expect(recommendedIds(), ['job-2', 'job-1']);
      },
    );
  });

  test('the same job under several sync keywords is shown once', () async {
    internships.results = [
      testInternship(
        'a',
        title: 'Thực Tập Sinh Lập Trình (Backend + Frontend Web)',
        companyName: 'Công ty Cổ phần ABC',
        searchRank: 3,
      ),
      testInternship(
        'b',
        title: 'Thực tập sinh lập trình (Backend + Frontend Web)',
        companyName: 'CÔNG TY CỔ PHẦN ABC',
        searchRank: 1,
      ),
      testInternship('c', title: 'Frontend Developer Intern', searchRank: 2),
    ];
    listen();
    await settle();

    // The copy with the best sync rank (b) is kept; nothing is repeated in
    // Recently Posted either.
    expect(feed().recommended.map((i) => i.jobId), ['job-b', 'job-c']);
    expect(feed().recent, isEmpty);
  });
}
