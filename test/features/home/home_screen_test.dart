import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/app/router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/widgets/internship_card.dart';
import 'package:internly/core/widgets/skeleton.dart';
import 'package:internly/features/home/screens/home_screen.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/remote_config_service.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeInternshipService internships;
  late FakeRemoteConfigService remoteConfig;

  setUp(() {
    internships = FakeInternshipService();
    remoteConfig = FakeRemoteConfigService();
  });

  tearDown(() => remoteConfig.dispose());

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
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          internshipServiceProvider.overrideWithValue(internships),
          remoteConfigServiceProvider.overrideWithValue(remoteConfig),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
  }

  final page = [
    testInternship(
      '1',
      title: 'Software Engineering Intern - Mobile',
      salary: '8M–12M VND a month',
      postedText: '2 days ago',
    ),
    testInternship('2', title: 'Frontend Developer Intern'),
    testInternship(
      '3',
      title: 'Mobile Developer Intern',
      postedText: '17 hours ago',
    ),
  ];

  for (final width in checkWidths) {
    testWidgets('data: header, shortcuts and both lists at $width dp', (
      tester,
    ) async {
      remoteConfig.values[RemoteConfigKeys.homeRecommendedLimit] = 2;
      internships.results = page;
      await pumpHome(tester, width: width);
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Find your next internship'), findsOneWidget);
      expect(
        find.text('Search internships, companies, or skills'),
        findsOneWidget,
      );
      expect(find.text('Browse by skill'), findsOneWidget);
      for (final skill in ['Flutter', 'React', 'NestJS']) {
        expect(find.widgetWithText(FilterChip, skill), findsOneWidget);
      }
      expect(find.text('Recommended for you'), findsOneWidget);
      expect(find.text('Software Engineering Intern - Mobile'), findsOneWidget);
      expect(find.text('8M–12M VND a month'), findsOneWidget);
      expect(find.text('Frontend Developer Intern'), findsOneWidget);
      expect(find.text(InternshipCard.allowanceNotDisclosed), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('Mobile Developer Intern'),
        200,
        // The skill shortcuts scroll horizontally; scroll the page itself.
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Recently posted'), findsOneWidget);
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

  testWidgets('error shows the message and Retry loads again', (tester) async {
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
    expect(find.text('Find your next internship'), findsOneWidget);

    internships
      ..error = null
      ..results = page;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Software Engineering Intern - Mobile'), findsOneWidget);
    expect(internships.keywords, ['IT', 'IT']);
  });

  testWidgets('no results shows the empty state with a search action', (
    tester,
  ) async {
    await pumpHome(tester);
    await tester.pumpAndSettle();

    expect(find.text('No results found'), findsOneWidget);
    await tester.tap(find.text('Search internships'));
    await tester.pumpAndSettle();
    expect(find.text('Search tab'), findsOneWidget);
  });

  testWidgets('a skill shortcut selects with a check and searches it', (
    tester,
  ) async {
    internships.results = page;
    await pumpHome(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilterChip, 'React'));
    await tester.pumpAndSettle();
    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'React'),
    );
    expect(chip.selected, isTrue);
    expect(chip.showCheckmark, isNot(false));
    expect(internships.keywords, ['IT', 'React']);
  });

  testWidgets('the search field opens the Search tab', (tester) async {
    internships.results = page;
    await pumpHome(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search internships, companies, or skills'));
    await tester.pumpAndSettle();
    expect(find.text('Search tab'), findsOneWidget);
  });

  testWidgets('"View all" opens the Search tab', (tester) async {
    internships.results = page;
    await pumpHome(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('View all').first);
    await tester.pumpAndSettle();
    expect(find.text('Search tab'), findsOneWidget);
  });

  testWidgets('touch targets are at least 48 dp', (tester) async {
    internships.results = page;
    await pumpHome(tester);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
