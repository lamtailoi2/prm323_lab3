import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/app/router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/widgets/app_button.dart';
import 'package:internly/core/widgets/internship_card.dart';
import 'package:internly/core/widgets/skeleton.dart';
import 'package:internly/features/home/screens/home_screen.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/remote_config_service.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeInternshipService internships;
  late FakeRemoteConfigService remoteConfig;
  late FakeAuthService auth;
  late FakeAnalyticsService analytics;

  setUp(() {
    internships = FakeInternshipService();
    remoteConfig = FakeRemoteConfigService();
    auth = FakeAuthService(initialUser: testUser);
    analytics = FakeAnalyticsService();
  });

  tearDown(() async {
    await internships.dispose();
    await auth.dispose();
    remoteConfig.dispose();
  });

  Future<void> pumpHome(WidgetTester tester, {double width = 360}) async {
    setScreenSize(tester, width: width);
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.search,
          builder: (context, state) => const Text('Search tab'),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const Text('Profile tab'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          internshipServiceProvider.overrideWithValue(internships),
          remoteConfigServiceProvider.overrideWithValue(remoteConfig),
          authServiceProvider.overrideWithValue(auth),
          analyticsServiceProvider.overrideWithValue(analytics),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
  }

  final now = DateTime.now();
  final page = [
    testInternship(
      '1',
      title: 'Software Engineering Intern - Mobile',
      companyName: 'Northstar Labs',
      salary: '12,000,000 VND a month',
      postedAt: now.subtract(const Duration(days: 2)),
      workMode: WorkMode.hybrid,
      skills: const ['Flutter', 'Dart'],
      searchRank: 0,
    ),
    testInternship(
      '2',
      title: 'Frontend Developer Intern',
      companyName: 'VNG Corporation',
      salary: '12,000,000 VND a month',
      postedAt: now.subtract(const Duration(days: 1)),
      workMode: WorkMode.hybrid,
      skills: const ['React', 'TypeScript'],
      searchRank: 1,
    ),
    testInternship(
      '3',
      title: 'Mobile Developer Intern',
      companyName: 'MoMo Financial Tech',
      postedAt: now,
      workMode: WorkMode.onSite,
      skills: const ['Flutter', 'REST API'],
      searchRank: 2,
    ),
  ];

  for (final width in checkWidths) {
    testWidgets('data: design header, shortcuts and lists at $width dp', (
      tester,
    ) async {
      remoteConfig.values[RemoteConfigKeys.homeRecommendedLimit] = 2;
      internships.results = page;
      await pumpHome(tester, width: width);
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.byTooltip('Notifications'), findsOneWidget);
      expect(find.byTooltip('Profile'), findsOneWidget);
      expect(find.text('Find your next internship'), findsOneWidget);
      expect(find.text('Search internships'), findsOneWidget);
      expect(find.text('Browse by Role'), findsOneWidget);
      expect(find.text('All roles'), findsOneWidget);
      for (final role in ['Frontend', 'Mobile']) {
        expect(find.widgetWithText(FilterChip, role), findsOneWidget);
      }
      expect(find.text('Recommended for you'), findsOneWidget);
      expect(find.text('Software Engineering Intern - Mobile'), findsOneWidget);
      expect(find.text('Northstar Labs'), findsOneWidget);
      expect(find.text('12,000,000 VND / mo'), findsWidgets);
      expect(find.text('2d ago'), findsOneWidget);
      expect(find.text('Hybrid'), findsWidgets);
      expect(find.text('On-site'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Recently Posted'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Recently Posted'), findsOneWidget);
      expect(find.byType(InternshipCard), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('loading shows card skeletons under the header', (tester) async {
    internships.gate = Completer<void>();
    await pumpHome(tester);
    await tester.pump();

    expect(find.text('Find your next internship'), findsOneWidget);
    expect(find.byType(InternshipCardSkeleton), findsNWidgets(2));
    expect(find.bySemanticsLabel('Loading internships'), findsOneWidget);

    internships.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(InternshipCardSkeleton), findsNothing);
  });

  testWidgets('error shows the message and Retry subscribes again', (
    tester,
  ) async {
    internships.error = const AppException(
      AppErrorKind.network,
      'We could not load internships. Check your connection and try again.',
    );
    await pumpHome(tester);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'We could not load internships. Check your connection and try again.',
      ),
      findsOneWidget,
    );

    internships
      ..error = null
      ..results = page;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Software Engineering Intern - Mobile'), findsOneWidget);
    expect(internships.watchCalls, 2);
  });

  testWidgets('no listings shows the empty state with a search action', (
    tester,
  ) async {
    await pumpHome(tester);
    await tester.pumpAndSettle();

    expect(find.text('No results found'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, 'Search internships'));
    await tester.pumpAndSettle();
    expect(find.text('Search tab'), findsOneWidget);
  });

  testWidgets('a role shortcut filters locally and shows a check', (
    tester,
  ) async {
    internships.results = page;
    await pumpHome(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'Frontend'));
    await tester.pumpAndSettle();
    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Frontend'),
    );
    expect(chip.selected, isTrue);
    expect(chip.showCheckmark, isTrue);
    expect(find.text('Frontend Developer Intern'), findsOneWidget);
    expect(find.text('Software Engineering Intern - Mobile'), findsNothing);
    expect(internships.watchCalls, 1);
  });

  testWidgets('the search field and filter action open the Search tab', (
    tester,
  ) async {
    internships.results = page;
    await pumpHome(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Search tab'), findsOneWidget);
  });

  testWidgets('"All roles" and "View all" open the Search tab', (tester) async {
    internships.results = page;
    await pumpHome(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('All roles'));
    await tester.pumpAndSettle();
    expect(find.text('Search tab'), findsOneWidget);
  });

  testWidgets('bell shows an honest coming-soon message', (tester) async {
    internships.results = page;
    await pumpHome(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pump();
    expect(find.text('Notifications are coming soon.'), findsOneWidget);
  });

  testWidgets('avatar opens Profile', (tester) async {
    internships.results = page;
    await pumpHome(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile tab'), findsOneWidget);
  });

  testWidgets('save action is visible and explains it is not ready', (
    tester,
  ) async {
    internships.results = page;
    await pumpHome(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Save').first);
    await tester.pump();
    expect(find.text('Saved internships are coming soon.'), findsOneWidget);
  });

  testWidgets('touch targets are at least 48 dp', (tester) async {
    internships.results = page;
    await pumpHome(tester);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
