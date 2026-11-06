import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/app/router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/utils/display_format.dart';
import 'package:internly/core/widgets/skeleton.dart';
import 'package:internly/features/applications/screens/my_applications_screen.dart';
import 'package:internly/features/applications/widgets/application_card.dart';
import 'package:internly/models/internship_application.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/theme/app_theme.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeApplicationService applications;
  late FakeAuthService auth;
  late FakeAnalyticsService analytics;

  setUp(() {
    applications = FakeApplicationService();
    auth = FakeAuthService(initialUser: testUser);
    analytics = FakeAnalyticsService();
  });

  tearDown(() async {
    await applications.dispose();
    await auth.dispose();
  });

  Future<void> pumpApplications(
    WidgetTester tester, {
    double width = 360,
    double height = 800,
  }) async {
    setScreenSize(tester, width: width, height: height);
    final router = GoRouter(
      initialLocation: AppRoutes.applications,
      routes: [
        GoRoute(
          path: AppRoutes.applications,
          builder: (context, state) => const MyApplicationsScreen(),
        ),
        GoRoute(
          path: '${AppRoutes.applications}/:jobKey',
          builder: (context, state) =>
              Text('Application ${state.pathParameters['jobKey']}'),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const Text('Profile tab'),
        ),
        GoRoute(
          path: AppRoutes.search,
          builder: (context, state) => const Text('Search tab'),
        ),
        GoRoute(
          path: AppRoutes.notificationCenter,
          builder: (context, state) => const Text('Notification Center'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          applicationServiceProvider.overrideWithValue(applications),
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

  // The five cards of the My Applications frame, with the same copy.
  final page = [
    testApplication(
      '1',
      title: 'Product Design Intern',
      companyName: 'Orbit Labs',
      appliedAt: DateTime(2026, 10, 1),
      status: ApplicationStatus.interview,
      nextStepAt: DateTime(2026, 10, 24, 14),
    ),
    testApplication(
      '2',
      title: 'Data Analyst Intern',
      companyName: 'Kite Analytics',
      appliedAt: DateTime(2026, 9, 24),
      status: ApplicationStatus.accepted,
      nextStepAt: DateTime(2026, 10, 30),
    ),
    testApplication(
      '3',
      title: 'Mobile Developer Intern',
      companyName: 'Lumen Studio',
      appliedAt: DateTime(2026, 10, 12),
      status: ApplicationStatus.submitted,
      nextStepAt: DateTime(2026, 10, 17),
    ),
    testApplication(
      '4',
      title: 'QA Engineer Intern',
      companyName: 'Brightpath',
      appliedAt: DateTime(2026, 10, 8),
      status: ApplicationStatus.underReview,
    ),
    testApplication(
      '5',
      title: 'Backend Engineer Intern',
      companyName: 'Harbor Tech',
      appliedAt: DateTime(2026, 9, 18),
      status: ApplicationStatus.rejected,
    ),
  ];

  for (final width in checkWidths) {
    testWidgets('header matches the other tabs at $width dp', (tester) async {
      applications.results = page;
      await pumpApplications(tester, width: width, height: 1400);
      await tester.pumpAndSettle();

      // The same bar as Home and Saved: title, bell, avatar, no brand mark.
      expect(find.text('Applications'), findsOneWidget);
      expect(find.byIcon(Symbols.school_rounded), findsNothing);
      expect(find.byTooltip('Notifications'), findsOneWidget);
      expect(find.byTooltip('Profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in checkWidths) {
    testWidgets('loading shows card skeletons at $width dp', (tester) async {
      applications.results = page;
      applications.gate = Completer<void>();
      await pumpApplications(tester, width: width);
      await tester.pump();

      // Card-shaped placeholders like Home and Saved, never a spinner.
      expect(find.byType(InternshipCardSkeleton), findsNWidgets(3));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ApplicationCard), findsNothing);
      expect(find.text('You have not applied yet'), findsNothing);
      expect(find.bySemanticsLabel('Loading applications'), findsOneWidget);
      expect(tester.takeException(), isNull);

      applications.gate!.complete();
      applications.gate = null;
      await tester.pumpAndSettle();

      expect(find.byType(InternshipCardSkeleton), findsNothing);
      expect(find.byType(ApplicationCard), findsNWidgets(5));
      expect(find.text('5 applications'), findsOneWidget);
    });
  }

  for (final width in checkWidths) {
    testWidgets('lists status, dates and offers at $width dp', (tester) async {
      applications.results = page;
      await pumpApplications(tester, width: width, height: 1400);
      await tester.pumpAndSettle();

      // Count, then one chip per status that occurs (DC-22 labels).
      expect(find.text('5 applications'), findsOneWidget);
      for (final label in [
        'All (5)',
        'Submitted (1)',
        'Under review (1)',
        'Interview (1)',
        'Accepted (1)',
        'Rejected (1)',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }

      // Company, submitted date, status and the next date to act on.
      expect(find.text('Orbit Labs · Applied 1 Oct'), findsOneWidget);
      expect(find.text('Oct 24, 2:00 PM'), findsOneWidget);
      expect(find.text(formatReplyBy(page[1].nextStepAt!)), findsOneWidget);
      expect(find.text(formatReplyBy(page[2].nextStepAt!)), findsOneWidget);
      for (final label in [
        'Submitted',
        'Under review',
        'Interview',
        'Accepted',
        'Rejected',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }

      // Only the accepted card offers the frame's primary action.
      expect(find.text(ApplicationCard.reviewOfferLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a status chip filters the cards', (tester) async {
    applications.results = page;
    await pumpApplications(tester, height: 1400);
    await tester.pumpAndSettle();

    final chip = find.text('Interview (1)');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    expect(find.byType(ApplicationCard), findsOneWidget);
    expect(find.text('Product Design Intern'), findsOneWidget);
    expect(find.text('Backend Engineer Intern'), findsNothing);
    // The count and the chips still describe all applications.
    expect(find.text('5 applications'), findsOneWidget);
    expect(find.text('All (5)'), findsOneWidget);

    final allChip = find.text('All (5)');
    await tester.ensureVisible(allChip);
    await tester.tap(allChip);
    await tester.pumpAndSettle();

    expect(find.byType(ApplicationCard), findsNWidgets(5));
  });

  testWidgets('no applications shows the empty state and finds internships', (
    tester,
  ) async {
    await pumpApplications(tester);
    await tester.pumpAndSettle();

    expect(find.text('Applications'), findsOneWidget);
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(find.text('You have not applied yet'), findsOneWidget);
    expect(
      find.text(
        'Find an internship that fits your skills and start your first '
        'application.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Find internships'));
    await tester.pumpAndSettle();

    expect(find.text('Search tab'), findsOneWidget);
  });

  testWidgets('a failed load explains why and Retry recovers', (tester) async {
    applications.error = const AppException(
      AppErrorKind.network,
      'We could not load your applications. Check your connection and try '
      'again.',
    );
    await pumpApplications(tester);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'We could not load your applications. Check your connection and try '
        'again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('You have not applied yet'), findsNothing);

    applications.error = null;
    applications.results = page;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(ApplicationCard), findsNWidgets(5));
    expect(find.text('5 applications'), findsOneWidget);
  });

  testWidgets('a card and Review offer open Application Detail', (
    tester,
  ) async {
    applications.results = page;
    await pumpApplications(tester, height: 1400);
    await tester.pumpAndSettle();

    await tester.tap(find.text(ApplicationCard.reviewOfferLabel));
    await tester.pumpAndSettle();

    expect(find.textContaining('Application '), findsOneWidget);

    // A card tap opens the same screen.
    await pumpApplications(tester, height: 1400);
    await tester.pumpAndSettle();
    await tester.tap(find.text('QA Engineer Intern'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Application '), findsOneWidget);
  });

  testWidgets('avatar opens Profile and the bell opens notifications', (
    tester,
  ) async {
    applications.results = page;
    await pumpApplications(tester, height: 1400);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile tab'), findsOneWidget);

    await pumpApplications(tester, height: 1400);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Notification Center'), findsOneWidget);
  });

  testWidgets('touch targets are at least 48 dp', (tester) async {
    applications.results = page;
    await pumpApplications(tester, height: 1400);
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
