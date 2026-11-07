import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/features/internships/screens/internship_detail_screen.dart';
import 'package:internly/features/internships/widgets/detail_skeleton.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/models/internship_application.dart';
import 'package:internly/models/user_profile.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/remote_config_service.dart';
import 'package:internly/services/saved_internship_service.dart';
import 'package:internly/services/user_profile_service.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeInternshipService internships;
  late FakeRemoteConfigService remoteConfig;
  late FakeAnalyticsService analytics;
  late FakeUserProfileService profiles;
  late FakeSavedInternshipService saved;
  late FakeApplicationService applications;

  final longDescription = List.filled(
    12,
    'Build cross-platform features in Flutter with our mobile team.',
  ).join(' ');
  final listing = testInternship(
    '1',
    title: 'Flutter Developer Intern',
    companyName: 'FPT Software',
    location: 'Ho Chi Minh City, Vietnam',
    workMode: WorkMode.remote,
    salary: '5,000,000 VND a month',
    postedText: '2 days ago',
    skills: const ['Flutter', 'Dart', 'Git', 'REST API'],
    description: longDescription,
    scheduleType: 'Internship',
    via: 'LinkedIn',
    highlights: const [
      JobHighlight(
        title: 'Qualifications',
        items: ['3rd or 4th-year IT student', 'Basic Git and teamwork'],
      ),
      JobHighlight(
        title: 'Benefits',
        items: ['Monthly allowance', '1:1 mentor', 'Flexible hours', 'Laptop'],
      ),
    ],
  );

  setUp(() {
    internships = FakeInternshipService();
    remoteConfig = FakeRemoteConfigService();
    analytics = FakeAnalyticsService();
    profiles = FakeUserProfileService(
      profile: const UserProfile(skills: ['Flutter', 'Dart', 'Git']),
    );
    saved = FakeSavedInternshipService();
    applications = FakeApplicationService();
  });

  tearDown(() async {
    await internships.dispose();
    await profiles.dispose();
    await saved.dispose();
    await applications.dispose();
    remoteConfig.dispose();
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    double width = 360,
    String? key,
    bool settle = true,
  }) async {
    setScreenSize(tester, width: width, height: 900);
    final router = GoRouter(
      initialLocation: '/home/internships/${key ?? listing.key}',
      routes: [
        GoRoute(
          path: '/home',
          // A Scaffold, like the real tab, so SnackBars outlive the Detail.
          builder: (context, state) => const Scaffold(body: Text('Home tab')),
          routes: [
            GoRoute(
              path: 'internships/:jobKey',
              builder: (context, state) => InternshipDetailScreen(
                internshipKey: state.pathParameters['jobKey']!,
                source: 'home',
              ),
              routes: [
                GoRoute(
                  path: 'apply',
                  builder: (context, state) =>
                      Text('Apply form ${state.pathParameters['jobKey']}'),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/saved',
          builder: (context, state) => const Text('Saved tab'),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const Text('Profile tab'),
        ),
        GoRoute(
          path: '/applications',
          builder: (context, state) => const Text('Applications tab'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          internshipServiceProvider.overrideWithValue(internships),
          remoteConfigServiceProvider.overrideWithValue(remoteConfig),
          analyticsServiceProvider.overrideWithValue(analytics),
          currentUserIdProvider.overrideWithValue(testUser.uid),
          userProfileServiceProvider.overrideWithValue(profiles),
          savedInternshipServiceProvider.overrideWithValue(saved),
          applicationServiceProvider.overrideWithValue(applications),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // Leave room for the sticky bottom bar so the target can be tapped.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -120));
    await tester.pumpAndSettle();
  }

  for (final width in checkWidths) {
    testWidgets('shows the listing, key facts and sections at $width dp', (
      tester,
    ) async {
      internships.byKey[listing.key] = listing;
      await pumpDetail(tester, width: width);

      expect(find.text('Internship details'), findsOneWidget);
      expect(find.text('Flutter Developer Intern'), findsOneWidget);
      expect(find.bySemanticsLabel('Role: Mobile'), findsOneWidget);
      expect(find.bySemanticsLabel('Experience: Intern'), findsOneWidget);
      expect(find.text('FPT Software'), findsOneWidget);
      expect(find.text('Posted 2 days ago'), findsOneWidget);
      expect(find.text('via LinkedIn'), findsOneWidget);
      expect(find.text('Allowance'), findsOneWidget);
      expect(find.text('5,000,000 VND / mo'), findsOneWidget);
      expect(find.text('Remote'), findsOneWidget);
      expect(find.text('Job type'), findsOneWidget);
      expect(find.text('Internship'), findsOneWidget);
      expect(find.text('75% skill match'), findsOneWidget);
      expect(find.text('High match'), findsOneWidget);
      expect(find.text('You have 3 of 4 required skills'), findsOneWidget);
      expect(find.bySemanticsLabel('REST API, missing'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Flutter, you have this skill'),
        findsOneWidget,
      );
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Apply now'), findsOneWidget);

      await scrollTo(tester, find.text('About the company'));
      expect(find.text('About the role'), findsOneWidget);
      expect(find.text('Requirements'), findsOneWidget);
      expect(find.text('Basic Git and teamwork'), findsOneWidget);
      expect(find.text('What you will get'), findsOneWidget);
      expect(find.text('Show all 4 benefits'), findsOneWidget);
      expect(find.text('Laptop'), findsNothing);
      // The header has scrolled away; the company section shows the name.
      expect(find.text('FPT Software'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  }

  testWidgets('hides the level badge when the listing states no level', (
    tester,
  ) async {
    final roleOnly = testInternship('2', title: 'Backend Developer');
    internships.byKey[roleOnly.key] = roleOnly;
    await pumpDetail(tester, key: roleOnly.key);

    expect(find.bySemanticsLabel('Role: Backend'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Experience:')), findsNothing);
  });

  for (final width in checkWidths) {
    testWidgets('an applied listing shows the banner and View application '
        'at $width dp', (tester) async {
      applications.results = [
        testApplication(
          '1',
          appliedAt: DateTime(2026, 10, 11, 9),
          status: ApplicationStatus.interview,
        ),
      ];
      internships.byKey[listing.key] = listing;
      await pumpDetail(tester, width: width);

      expect(find.text('You applied on Oct 11, 2026'), findsOneWidget);
      expect(
        find.text(
          'Status: Interview. Update it in My Applications when the company '
          'replies.',
        ),
        findsOneWidget,
      );
      expect(find.text('Apply now'), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

      await tester.tap(find.text('View application'));
      await tester.pumpAndSettle();
      expect(find.text('Applications tab'), findsOneWidget);
    });
  }

  testWidgets('without Profile skills the card invites, not "0% match"', (
    tester,
  ) async {
    profiles.profile = const UserProfile();
    internships.byKey[listing.key] = listing;
    await pumpDetail(tester);

    expect(find.text('See how you match'), findsOneWidget);
    expect(find.textContaining('% skill match'), findsNothing);
    expect(find.text('Low match'), findsNothing);
    expect(find.text('This internship asks for 4 skills'), findsOneWidget);
    expect(find.bySemanticsLabel('REST API'), findsOneWidget);
    expect(find.bySemanticsLabel('REST API, missing'), findsNothing);

    await tester.tap(find.text('Add skills'));
    await tester.pumpAndSettle();
    expect(find.text('Profile tab'), findsOneWidget);
  });

  testWidgets('skills with no overlap still show the honest 0% match', (
    tester,
  ) async {
    profiles.profile = const UserProfile(skills: ['Java']);
    internships.byKey[listing.key] = listing;
    await pumpDetail(tester);

    expect(find.text('0% skill match'), findsOneWidget);
    expect(find.text('Low match'), findsOneWidget);
    expect(find.text('Based on the skills in your Profile.'), findsOneWidget);
    expect(find.text('Add skills'), findsNothing);
  });

  testWidgets('missing facts say "Not disclosed"; no skills, no card', (
    tester,
  ) async {
    final sparse = testInternship('2', location: null);
    internships.byKey[sparse.key] = Internship(
      jobId: sparse.jobId,
      key: sparse.key,
      title: sparse.title,
      companyName: sparse.companyName,
    );
    await pumpDetail(tester, key: sparse.key);

    expect(find.text('Not disclosed'), findsNWidgets(4));
    expect(find.textContaining('skill match'), findsNothing);
    expect(find.text('About the role'), findsNothing);
    expect(find.text('Requirements'), findsNothing);
  });

  testWidgets('shows the skeleton while the listing loads', (tester) async {
    internships.byKeyGate = Completer<void>();
    await pumpDetail(tester, settle: false);
    await tester.pump();

    expect(find.byType(DetailSkeleton), findsOneWidget);
    expect(find.bySemanticsLabel('Loading internship'), findsOneWidget);
    expect(find.text('Apply now'), findsNothing);
    internships.byKeyGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('an unavailable listing explains it and goes back', (
    tester,
  ) async {
    await pumpDetail(tester);

    expect(find.text(InternshipDetailScreen.notAvailableTitle), findsOneWidget);
    expect(find.text('Apply now'), findsNothing);
    await tester.tap(find.text('Back').last);
    await tester.pumpAndSettle();
    expect(find.text('Home tab'), findsOneWidget);
  });

  testWidgets('a load error shows its message, and Retry recovers', (
    tester,
  ) async {
    internships.byKeyError = const AppException(
      AppErrorKind.network,
      'We could not load this internship. Check your connection and try '
      'again.',
    );
    await pumpDetail(tester);
    expect(
      find.textContaining('We could not load this internship'),
      findsOneWidget,
    );

    internships
      ..byKeyError = null
      ..byKey[listing.key] = listing;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter Developer Intern'), findsOneWidget);
  });

  testWidgets('Save stores the listing, confirms it and links to Saved', (
    tester,
  ) async {
    internships.byKey[listing.key] = listing;
    await pumpDetail(tester);

    await tester.tap(find.bySemanticsLabel('Save internship'));
    await tester.pumpAndSettle();
    expect(saved.savedKeys, [listing.key]);
    expect(find.text('Saved to your list'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(analytics.parameters['internship_save'], {
      'internship_id': listing.key,
      'source': 'detail',
    });

    await tester.tap(find.text('View saved'));
    await tester.pumpAndSettle();
    expect(find.text('Saved tab'), findsOneWidget);
  });

  testWidgets('the Saved message hides on its own after a few seconds', (
    tester,
  ) async {
    internships.byKey[listing.key] = listing;
    await pumpDetail(tester);

    await tester.tap(find.bySemanticsLabel('Save internship'));
    await tester.pumpAndSettle();
    expect(find.text('Saved to your list'), findsOneWidget);

    // Theme duration is 4 s; with an action and no `persist: false` it
    // would stay until tapped.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Saved to your list'), findsNothing);
  });

  testWidgets('Retry after leaving the Detail does not use the closed screen', (
    tester,
  ) async {
    internships.byKey[listing.key] = listing;
    saved.error = const AppException(
      AppErrorKind.network,
      'We could not reach Internly. Check your connection and try again.',
    );
    await pumpDetail(tester);
    await tester.tap(find.bySemanticsLabel('Save internship'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);

    // Back to Home; the error SnackBar stays on the root messenger.
    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await tester.pumpAndSettle();
    expect(find.text('Home tab'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Save toggle can be activated by assistive technology', (
    tester,
  ) async {
    internships.byKey[listing.key] = listing;
    await pumpDetail(tester);

    expect(
      tester.getSemantics(find.bySemanticsLabel('Save internship')),
      isSemantics(isButton: true, hasTapAction: true),
    );
  });

  testWidgets('a failed save shows the reason with Retry', (tester) async {
    internships.byKey[listing.key] = listing;
    saved.error = const AppException(
      AppErrorKind.network,
      'We could not reach Internly. Check your connection and try again.',
    );
    await pumpDetail(tester);

    await tester.tap(find.bySemanticsLabel('Save internship'));
    await tester.pumpAndSettle();
    expect(find.textContaining('We could not reach Internly'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    saved.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(saved.savedKeys, [listing.key]);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('a synced listing shows its age in full words', (tester) async {
    internships.byKey[listing.key] = testInternship(
      '1',
      title: 'Flutter Developer Intern',
      postedAt: DateTime.now().subtract(const Duration(days: 3, hours: 1)),
    );
    await pumpDetail(tester);

    expect(find.text('Posted 3 days ago'), findsOneWidget);
  });

  testWidgets('Apply now opens the Apply Form above the Detail', (
    tester,
  ) async {
    internships.byKey[listing.key] = listing;
    await pumpDetail(tester);

    await tester.tap(find.text('Apply now'));
    await tester.pumpAndSettle();
    expect(find.text('Apply form ${listing.key}'), findsOneWidget);

    // Pushed, so Back returns to the same Detail.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('Flutter Developer Intern'), findsWidgets);
  });

  testWidgets('Show more and Show all expand their sections', (tester) async {
    internships.byKey[listing.key] = listing;
    await pumpDetail(tester);

    await scrollTo(tester, find.text('Show more'));
    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    expect(find.text('Show less'), findsOneWidget);

    await scrollTo(tester, find.text('Show all 4 benefits'));
    await tester.tap(find.text('Show all 4 benefits'));
    await tester.pumpAndSettle();
    expect(find.text('Laptop'), findsOneWidget);
    expect(find.text('Show fewer'), findsOneWidget);
  });

  testWidgets('cv_match_enabled = false hides the Skill match card', (
    tester,
  ) async {
    remoteConfig.values[RemoteConfigKeys.cvMatchEnabled] = false;
    internships.byKey[listing.key] = listing;
    await pumpDetail(tester);

    expect(find.text('Flutter Developer Intern'), findsOneWidget);
    expect(find.textContaining('skill match'), findsNothing);
  });

  testWidgets('the bell explains notifications are coming soon', (
    tester,
  ) async {
    internships.byKey[listing.key] = listing;
    await pumpDetail(tester);

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pump();
    expect(find.text('Notifications are coming soon.'), findsOneWidget);
  });
}
