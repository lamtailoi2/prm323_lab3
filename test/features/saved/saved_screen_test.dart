import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/app/router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/widgets/internship_card.dart';
import 'package:internly/core/widgets/skeleton.dart';
import 'package:internly/features/saved/screens/saved_screen.dart';
import 'package:internly/features/saved/viewmodels/saved_providers.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/saved_internship_service.dart';
import 'package:internly/theme/app_theme.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeSavedInternshipService saved;
  late FakeAuthService auth;
  late FakeAnalyticsService analytics;

  setUp(() {
    saved = FakeSavedInternshipService();
    auth = FakeAuthService(initialUser: testUser);
    analytics = FakeAnalyticsService();
  });

  tearDown(() async {
    await saved.dispose();
    await auth.dispose();
  });

  Future<void> pumpSaved(
    WidgetTester tester, {
    double width = 360,
    Stream<List<Internship>>? savedStream,
  }) async {
    setScreenSize(tester, width: width);
    final router = GoRouter(
      initialLocation: AppRoutes.saved,
      routes: [
        GoRoute(
          path: AppRoutes.saved,
          builder: (context, state) => const SavedScreen(),
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
          savedInternshipServiceProvider.overrideWithValue(saved),
          // Lets a test hold the first snapshot, to see the loading state.
          if (savedStream != null)
            savedInternshipsProvider.overrideWith((ref) => savedStream),
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
    ),
    testInternship(
      '2',
      title: 'Frontend Developer Intern',
      companyName: 'VNG Corporation',
      postedAt: now.subtract(const Duration(days: 1)),
      workMode: WorkMode.remote,
      skills: const ['React', 'TypeScript'],
    ),
  ];

  for (final width in checkWidths) {
    testWidgets('header matches the other tabs at $width dp', (tester) async {
      saved.seed(page);
      await pumpSaved(tester, width: width);
      await tester.pumpAndSettle();

      // Same bar as Home: title, bell, avatar — no brand mark (DC-20).
      expect(find.text('Saved'), findsOneWidget);
      expect(find.byIcon(Symbols.school_rounded), findsNothing);
      expect(find.byTooltip('Notifications'), findsOneWidget);
      expect(find.byTooltip('Profile'), findsOneWidget);
      expect(find.text('2 saved'), findsOneWidget);
      expect(find.text('Software Engineering Intern - Mobile'), findsOneWidget);
      expect(find.byType(InternshipCard), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in checkWidths) {
    testWidgets('loading shows card skeletons at $width dp', (tester) async {
      final controller = StreamController<List<Internship>>();
      addTearDown(controller.close);

      await pumpSaved(tester, width: width, savedStream: controller.stream);
      await tester.pump();

      // Same shape as the loaded list: the filter shortcuts plus card-shaped
      // placeholders, never a spinner or a blank screen (design-system §2.9).
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Hybrid'), findsOneWidget);
      expect(find.byType(InternshipCardSkeleton), findsNWidgets(3));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(InternshipCard), findsNothing);
      expect(find.text('No saved internships yet'), findsNothing);
      expect(
        find.bySemanticsLabel('Loading saved internships'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      expect(tester, meetsGuideline(androidTapTargetGuideline));

      controller.add(page);
      await tester.pumpAndSettle();

      expect(find.byType(InternshipCardSkeleton), findsNothing);
      expect(find.byType(InternshipCard), findsNWidgets(2));
      expect(find.text('2 saved'), findsOneWidget);
    });
  }

  testWidgets('bell shows an honest coming-soon message', (tester) async {
    saved.seed(page);
    await pumpSaved(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pump();
    expect(find.text('Notifications are coming soon.'), findsOneWidget);
  });

  testWidgets('avatar opens Profile', (tester) async {
    saved.seed(page);
    await pumpSaved(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile tab'), findsOneWidget);
  });

  testWidgets('no saved items keeps the header and shows the empty state', (
    tester,
  ) async {
    await pumpSaved(tester);
    await tester.pumpAndSettle();

    expect(find.text('Saved'), findsOneWidget);
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(find.text('No saved internships yet'), findsOneWidget);
  });

  testWidgets('touch targets are at least 48 dp', (tester) async {
    saved.seed(page);
    await pumpSaved(tester);
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  /// The filled bookmark of the card with [title], as the student taps it.
  Finder bookmarkOf(String title) => find.descendant(
    of: find.widgetWithText(InternshipCard, title),
    matching: find.byTooltip('Remove from saved'),
  );

  Future<void> unsaveFirstCard(WidgetTester tester) async {
    await tester.tap(bookmarkOf('Software Engineering Intern - Mobile'));
    await tester.pumpAndSettle();
  }

  for (final width in checkWidths) {
    testWidgets('unsave removes the card and offers Undo at $width dp', (
      tester,
    ) async {
      saved.seed(page);
      await pumpSaved(tester, width: width);
      await tester.pumpAndSettle();

      await unsaveFirstCard(tester);

      expect(find.text('Software Engineering Intern - Mobile'), findsNothing);
      expect(find.byType(InternshipCard), findsOneWidget);
      expect(saved.savedKeys, [page.last.key]);

      expect(find.text('Removed from Saved'), findsOneWidget);
      expect(find.byIcon(Symbols.check_circle_rounded), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Undo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Undo puts the internship back and dismisses the Snackbar', (
    tester,
  ) async {
    saved.seed(page);
    await pumpSaved(tester);
    await tester.pumpAndSettle();

    await unsaveFirstCard(tester);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.text('Software Engineering Intern - Mobile'), findsOneWidget);
    expect(saved.savedKeys, [page.last.key, page.first.key]);
    expect(saved.saveCalls, 1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('the removal is final when the Snackbar times out', (
    tester,
  ) async {
    saved.seed(page);
    await pumpSaved(tester);
    await tester.pumpAndSettle();

    await unsaveFirstCard(tester);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('Removed from Saved'), findsNothing);
    expect(find.text('Software Engineering Intern - Mobile'), findsNothing);
    expect(saved.savedKeys, [page.last.key]);
    expect(saved.saveCalls, 0);
  });

  testWidgets('a failed unsave keeps the card and explains why', (
    tester,
  ) async {
    saved.seed(page);
    saved.error = const AppException(
      AppErrorKind.network,
      'We could not reach Internly. Check your connection and try again.',
    );
    await pumpSaved(tester);
    await tester.pumpAndSettle();

    await unsaveFirstCard(tester);

    expect(find.byType(InternshipCard), findsNWidgets(2));
    expect(
      find.text(
        'We could not reach Internly. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(SnackBarAction, 'Retry'), findsOneWidget);
    expect(find.text('Removed from Saved'), findsNothing);
  });

  testWidgets('a second unsave replaces the Snackbar and Undo restores it', (
    tester,
  ) async {
    saved.seed(page);
    await pumpSaved(tester);
    await tester.pumpAndSettle();

    await unsaveFirstCard(tester);
    await tester.tap(bookmarkOf('Frontend Developer Intern'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Removed from Saved'), findsOneWidget);
    expect(saved.savedKeys, isEmpty);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    // Only the second internship comes back; the first stays removed.
    expect(find.text('Frontend Developer Intern'), findsOneWidget);
    expect(find.text('Software Engineering Intern - Mobile'), findsNothing);
    expect(saved.savedKeys, [page.last.key]);
  });
}
