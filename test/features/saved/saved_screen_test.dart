import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/app/router.dart';
import 'package:internly/core/widgets/internship_card.dart';
import 'package:internly/features/saved/screens/saved_screen.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/saved_internship_service.dart';
import 'package:internly/theme/app_theme.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeSavedInternshipService saved;
  late FakeAuthService auth;

  setUp(() {
    saved = FakeSavedInternshipService();
    auth = FakeAuthService(initialUser: testUser);
  });

  tearDown(() async {
    await saved.dispose();
    await auth.dispose();
  });

  Future<void> pumpSaved(WidgetTester tester, {double width = 360}) async {
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
          authServiceProvider.overrideWithValue(auth),
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

      // Same bar as Home: title, bell, avatar — no brand mark (DC-15).
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
}
