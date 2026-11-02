import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/app/router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/features/internships/models/search_filter_criteria.dart';
import 'package:internly/features/internships/models/search_history_entry.dart';
import 'package:internly/features/internships/screens/search_screen.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/search_history_service.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeInternshipService internships;
  late FakeSearchHistoryService history;

  setUp(() {
    internships = FakeInternshipService();
    history = FakeSearchHistoryService();
  });

  tearDown(() async {
    await internships.dispose();
    await history.dispose();
  });

  Future<void> pumpSearch(
    WidgetTester tester, {
    double width = 360,
    String? uid,
  }) async {
    uid ??= testUser.uid;
    setScreenSize(tester, width: width);
    final router = GoRouter(
      initialLocation: AppRoutes.search,
      routes: [
        GoRoute(
          path: AppRoutes.search,
          name: 'search',
          builder: (context, state) => const SearchScreen(),
          routes: [
            GoRoute(
              path: 'results',
              name: 'search_results',
              builder: (context, state) {
                final criteria = state.extra;
                final filters = criteria is SearchFilterCriteria
                    ? ' · ${criteria.workModes.map((m) => m.label).join(',')}'
                    : '';
                return Text(
                  'Results: ${state.uri.queryParameters['q'] ?? ''}$filters',
                );
              },
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          internshipServiceProvider.overrideWithValue(internships),
          searchHistoryServiceProvider.overrideWithValue(history),
          currentUserIdProvider.overrideWithValue(uid),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
  }

  for (final width in checkWidths) {
    testWidgets(
      'data: shows work mode, trending skills and recent searches at $width dp',
      (tester) async {
        internships.results = [
          testInternship('1', skills: const ['Flutter', 'Dart']),
          testInternship('2', skills: const ['Flutter']),
        ];
        history.entriesByUid[testUser.uid] = [
          SearchHistoryEntry(
            id: 'a',
            term: 'Flutter intern',
            searchedAt: DateTime.now(),
          ),
        ];
        await pumpSearch(tester, width: width);
        await tester.pumpAndSettle();

        expect(find.text('Search'), findsOneWidget);
        expect(find.text('Work mode'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Remote'), findsOneWidget);
        expect(find.text('Hybrid'), findsOneWidget);
        expect(find.text('On-site'), findsOneWidget);
        expect(find.text('Trending skills for undergraduates'), findsOneWidget);
        expect(find.text('Flutter 2+'), findsOneWidget);
        expect(find.text('Recent searches'), findsOneWidget);
        expect(find.text('Flutter intern'), findsOneWidget);
        expect(find.text('Clear'), findsOneWidget);
        expect(
          find.widgetWithText(ElevatedButton, 'Find Internships'),
          findsNothing,
        );
        expect(find.text('Find Internships'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('no listings and no history hides both sections', (tester) async {
    await pumpSearch(tester);
    await tester.pumpAndSettle();

    expect(find.text('Trending skills for undergraduates'), findsNothing);
    expect(find.text('Recent searches'), findsNothing);
    expect(find.text('Find Internships'), findsOneWidget);
  });

  testWidgets('submitting the search field navigates to results', (
    tester,
  ) async {
    await pumpSearch(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Backend intern');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Results: Backend intern'), findsOneWidget);
  });

  testWidgets('Find Internships navigates to results', (tester) async {
    await pumpSearch(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Backend intern');
    await tester.tap(find.text('Find Internships'));
    await tester.pumpAndSettle();

    expect(find.text('Results: Backend intern'), findsOneWidget);
  });

  testWidgets('tapping a trending skill records it and navigates to results', (
    tester,
  ) async {
    internships.results = [
      testInternship('1', skills: const ['Flutter']),
    ];
    await pumpSearch(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Flutter 1+'));
    await tester.pumpAndSettle();

    expect(find.text('Results: Flutter'), findsOneWidget);
    expect(history.entriesByUid[testUser.uid]!.single.term, 'Flutter');
  });

  testWidgets('the filter action opens the filter sheet and shows results', (
    tester,
  ) async {
    internships.results = [
      testInternship('1', workMode: WorkMode.remote),
      testInternship('2', workMode: WorkMode.onSite),
      testInternship('3'),
    ];
    await pumpSearch(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Show 3 results →'), findsOneWidget);
    expect(find.text('More filters are coming soon.'), findsNothing);

    // The sheet's chip (the Search tab has its own "Remote" chip behind it).
    await tester.tap(find.text('Remote').last);
    await tester.pumpAndSettle();
    expect(find.text('Show 1 results →'), findsOneWidget);

    await tester.tap(find.text('Show 1 results →'));
    await tester.pumpAndSettle();
    expect(find.text('Results:  · Remote'), findsOneWidget);
  });

  testWidgets('the sheet starts from the selected work mode and the query', (
    tester,
  ) async {
    internships.results = [
      testInternship('1', title: 'Flutter Intern', workMode: WorkMode.hybrid),
      testInternship('2', title: 'Java Intern', workMode: WorkMode.hybrid),
      testInternship('3', title: 'Flutter Dev', workMode: WorkMode.remote),
    ];
    await pumpSearch(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.tap(find.text('Hybrid'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Show 1 results →'), findsOneWidget);

    await tester.tap(find.text('Show 1 results →'));
    await tester.pumpAndSettle();
    expect(find.text('Results: flutter · Hybrid'), findsOneWidget);
    expect(history.entriesByUid[testUser.uid]!.single.term, 'flutter');
  });

  testWidgets(
    'selecting a work mode shows a check; selecting again clears it',
    (tester) async {
      await pumpSearch(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Remote'));
      await tester.pumpAndSettle();
      var chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Remote'),
      );
      expect(chip.selected, isTrue);
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilterChip, 'Remote'));
      await tester.pumpAndSettle();
      chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Remote'),
      );
      expect(chip.selected, isFalse);
      expect(find.text('1 selected'), findsNothing);
    },
  );

  testWidgets('Clear removes recent searches', (tester) async {
    history.entriesByUid[testUser.uid] = [
      SearchHistoryEntry(id: 'a', term: 'Flutter', searchedAt: DateTime.now()),
    ];
    await pumpSearch(tester);
    await tester.pumpAndSettle();
    expect(find.text('Flutter'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Recent searches'), findsNothing);
  });

  testWidgets(
    'tapping a recent search records it again and navigates to results',
    (tester) async {
      history.entriesByUid[testUser.uid] = [
        SearchHistoryEntry(
          id: 'a',
          term: 'Flutter',
          searchedAt: DateTime.now(),
        ),
      ];
      await pumpSearch(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Flutter'));
      await tester.pumpAndSettle();

      expect(find.text('Results: Flutter'), findsOneWidget);
    },
  );

  testWidgets('a trending-skills failure shows the message and Retry', (
    tester,
  ) async {
    internships.error = const AppException(
      AppErrorKind.network,
      'We could not load internships. Check your connection and try again.',
    );
    await pumpSearch(tester);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'We could not load internships. Check your connection and try again.',
      ),
      findsOneWidget,
    );

    internships
      ..error = null
      ..results = [
        testInternship('1', skills: const ['Flutter']),
      ];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter 1+'), findsOneWidget);
  });

  testWidgets('a recent-searches failure shows the message and Retry', (
    tester,
  ) async {
    history.fail(
      const AppException(
        AppErrorKind.unknown,
        'We could not load recent searches. Try again in a moment.',
      ),
    );
    await pumpSearch(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('We could not load recent searches. Try again in a moment.'),
      findsOneWidget,
    );

    history.error = null;
    history.entriesByUid[testUser.uid] = [
      SearchHistoryEntry(id: 'a', term: 'Flutter', searchedAt: DateTime.now()),
    ];
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Flutter'), findsOneWidget);
  });

  testWidgets('touch targets are at least 48 dp', (tester) async {
    internships.results = [
      testInternship('1', skills: const ['Flutter']),
    ];
    history.entriesByUid[testUser.uid] = [
      SearchHistoryEntry(id: 'a', term: 'Flutter', searchedAt: DateTime.now()),
    ];
    await pumpSearch(tester);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
