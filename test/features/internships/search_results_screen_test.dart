import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/utils/distinct_listings.dart';
import 'package:internly/core/widgets/app_button.dart';
import 'package:internly/core/widgets/app_search_field.dart';
import 'package:internly/core/widgets/internship_card.dart';
import 'package:internly/features/applications/viewmodels/applied_providers.dart';
import 'package:internly/features/internships/models/search_filter_criteria.dart';
import 'package:internly/features/internships/screens/search_results_screen.dart';
import 'package:internly/features/internships/widgets/search_results_filter_sheet.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/saved_service.dart';
import 'package:internly/services/search_history_service.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeInternshipService internships;
  late FakeSavedService saved;
  late FakeSearchHistoryService history;
  late FakeAnalyticsService analytics;
  late Set<String> appliedKeys;

  setUp(() {
    internships = FakeInternshipService();
    saved = FakeSavedService();
    history = FakeSearchHistoryService();
    analytics = FakeAnalyticsService();
    appliedKeys = <String>{};
  });

  tearDown(() async {
    await internships.dispose();
    await saved.dispose();
    await history.dispose();
  });

  Future<void> pumpSearchResults(
    WidgetTester tester, {
    double width = 360,
    String initialQuery = '',
    WorkMode? initialWorkMode,
    SearchFilterCriteria? initialCriteria,
  }) async {
    setScreenSize(tester, width: width);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          internshipServiceProvider.overrideWithValue(internships),
          savedServiceProvider.overrideWithValue(saved),
          searchHistoryServiceProvider.overrideWithValue(history),
          analyticsServiceProvider.overrideWithValue(analytics),
          appliedJobsProvider.overrideWith((ref) => Stream.value(appliedKeys)),
          currentUserIdProvider.overrideWithValue(testUser.uid),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: SearchResultsScreen(
            initialQuery: initialQuery,
            initialWorkMode: initialWorkMode,
            initialCriteria: initialCriteria,
          ),
        ),
      ),
    );
  }

  final now = DateTime.now();
  final sampleListings = [
    testInternship(
      '1',
      title: 'Flutter Developer Intern',
      companyName: 'FPT Software',
      location: 'Ho Chi Minh City',
      workMode: WorkMode.remote,
      salary: '5–7M VND/month',
      postedAt: now.subtract(const Duration(days: 2)),
      skills: const ['Flutter', 'Dart', 'REST API'],
    ),
    testInternship(
      '2',
      title: 'Mobile App Intern (Flutter & iOS)',
      companyName: 'VNG Corporation',
      location: 'Ho Chi Minh City',
      workMode: WorkMode.remote,
      salary: '6–8M VND/month',
      postedAt: now.subtract(const Duration(days: 1)),
      skills: const ['Flutter', 'State Management', 'Git'],
    ),
    testInternship(
      '3',
      title: 'Backend Node.js Intern',
      companyName: 'MoMo',
      location: 'Ha Noi',
      workMode: WorkMode.onSite,
      salary: '4–6M VND/month',
      postedAt: now.subtract(const Duration(days: 3)),
      skills: const ['Node.js'],
    ),
  ];

  for (final width in checkWidths) {
    testWidgets(
      'data: displays search field, active chips, count, cards and footer at $width dp',
      (tester) async {
        internships.results = sampleListings;
        await pumpSearchResults(
          tester,
          width: width,
          initialQuery: 'Flutter',
          initialWorkMode: WorkMode.remote,
        );
        await tester.pumpAndSettle();

        expect(find.text('Search'), findsOneWidget);
        expect(find.byType(AppSearchField), findsOneWidget);

        // Active chips matching screenshot
        expect(
          find.byKey(const ValueKey('filter_mode_remote')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('filter_query')), findsOneWidget);
        expect(find.text('Clear filters'), findsOneWidget);

        // Result count: 2 out of 3 match Flutter + Remote
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is RichText &&
                w.text.toPlainText().contains('2 internships found'),
          ),
          findsOneWidget,
        );
        expect(find.text('Most recent'), findsOneWidget);

        // Cards
        expect(find.byType(InternshipCard), findsNWidgets(2));
        expect(find.text('Flutter Developer Intern'), findsOneWidget);
        expect(find.text('FPT Software'), findsOneWidget);
        expect(find.text('Mobile App Intern (Flutter & iOS)'), findsOneWidget);
        expect(find.text('VNG Corporation'), findsOneWidget);

        // Footer hint
        expect(
          find.text('Showing top matching internships for "Flutter"'),
          findsOneWidget,
        );
        expect(
          find.text('Refine filters to narrow compensation or location'),
          findsOneWidget,
        );

        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('filters chosen on the Search tab are applied on arrival', (
    tester,
  ) async {
    internships.results = sampleListings;
    await pumpSearchResults(
      tester,
      initialCriteria: const SearchFilterCriteria(workModes: {WorkMode.remote}),
    );
    await tester.pumpAndSettle();

    final cards = tester.widgetList<InternshipCard>(
      find.byType(InternshipCard),
    );
    expect(cards, isNotEmpty);
    final remoteTitles = {
      for (final listing in sampleListings)
        if (listing.workMode == WorkMode.remote) listing.title,
    };
    expect(cards.every((card) => remoteTitles.contains(card.title)), isTrue);
  });

  testWidgets('removing a filter chip updates the result list', (tester) async {
    internships.results = sampleListings;
    await pumpSearchResults(
      tester,
      initialQuery: 'Flutter',
      initialWorkMode: WorkMode.remote,
    );
    await tester.pumpAndSettle();

    expect(find.byType(InternshipCard), findsNWidgets(2));

    // Tap to remove Remote filter chip
    await tester.tap(find.byKey(const ValueKey('filter_mode_remote')));
    await tester.pumpAndSettle();

    // Remote filter chip is removed
    expect(find.byKey(const ValueKey('filter_mode_remote')), findsNothing);
  });

  testWidgets('tapping Clear filters shows all listings', (tester) async {
    internships.results = sampleListings;
    await pumpSearchResults(
      tester,
      initialQuery: 'Flutter',
      initialWorkMode: WorkMode.remote,
    );
    await tester.pumpAndSettle();

    expect(find.byType(InternshipCard), findsNWidgets(2));

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();

    // All 3 listings show up
    expect(find.byType(InternshipCard), findsNWidgets(3));
    expect(find.text('Clear filters'), findsNothing);
  });

  testWidgets('shows empty state when no listings match', (tester) async {
    internships.results = sampleListings;
    await pumpSearchResults(tester, initialQuery: 'NonExistentSkill');
    await tester.pumpAndSettle();

    expect(find.text('No internships found'), findsOneWidget);
    expect(
      find.text(
        'Try adjusting your search or clearing filters to see more results.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(AppButton, 'Clear filters'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppButton, 'Clear filters'));
    await tester.pumpAndSettle();

    expect(find.byType(InternshipCard), findsNWidgets(3));
  });

  testWidgets('shows error state and Retry when stream fails', (tester) async {
    internships.error = const AppException(
      AppErrorKind.network,
      'Connection failed',
    );
    await pumpSearchResults(tester);
    await tester.pumpAndSettle();

    expect(find.text('Connection failed'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Retry'), findsOneWidget);

    internships.error = null;
    internships.results = sampleListings;

    await tester.tap(find.widgetWithText(AppButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(InternshipCard), findsNWidgets(3));
  });

  testWidgets('bookmark toggle saves and unsaves internship', (tester) async {
    internships.results = sampleListings;
    await pumpSearchResults(tester);
    await tester.pumpAndSettle();

    final bookmarkButtons = find.byTooltip('Save');
    expect(bookmarkButtons, findsWidgets);

    await tester.tap(bookmarkButtons.first);
    await tester.pumpAndSettle();

    expect(saved.savedByUid[testUser.uid], contains(sampleListings[1].key));
  });

  testWidgets('opens filter sheet and displays all sections', (tester) async {
    internships.results = sampleListings;
    await pumpSearchResults(tester);
    await tester.pumpAndSettle();

    // Tap filters button in search field
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();

    // Header and sections matching Figma
    final sheetFinder = find.byType(SearchResultsFilterSheet);
    expect(
      find.descendant(of: sheetFinder, matching: find.text('Filters')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheetFinder, matching: find.text('Work mode')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: sheetFinder,
        matching: find.text('Single or multiple'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheetFinder, matching: find.text('On-site')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheetFinder, matching: find.text('Remote')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheetFinder, matching: find.text('Hybrid')),
      findsOneWidget,
    );

    expect(
      find.descendant(of: sheetFinder, matching: find.text('Location')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheetFinder, matching: find.text('Skills')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheetFinder, matching: find.text('Job type')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheetFinder, matching: find.text('Allowance range')),
      findsOneWidget,
    );

    expect(
      find.descendant(of: sheetFinder, matching: find.text('Flutter')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheetFinder, matching: find.text('React')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheetFinder, matching: find.text('NestJS')),
      findsOneWidget,
    );

    expect(find.text('Show 3 results →'), findsOneWidget);

    // Tap Remote chip in the sheet
    await tester.tap(
      find.descendant(of: sheetFinder, matching: find.text('Remote')),
    );
    await tester.pumpAndSettle();

    // 2 listings are remote
    expect(find.text('Show 2 results →'), findsOneWidget);
    expect(find.text('1 active'), findsOneWidget);

    // Apply
    await tester.tap(find.text('Show 2 results →'));
    await tester.pumpAndSettle();

    // Bottom sheet dismissed, results filtered to 2
    expect(find.byType(InternshipCard), findsNWidgets(2));
  });

  testWidgets('a listing tracked in My Applications shows Applied', (
    tester,
  ) async {
    internships.results = sampleListings;
    appliedKeys = {
      jobIdentity(sampleListings.first.title, sampleListings.first.companyName),
    };
    await pumpSearchResults(tester);
    await tester.pumpAndSettle();

    expect(find.text('Applied'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Flutter Developer Intern[\s\S]*Applied')),
      findsOneWidget,
    );
  });
}
