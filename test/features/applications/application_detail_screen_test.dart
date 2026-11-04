import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/app/router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/features/applications/screens/application_detail_screen.dart';
import 'package:internly/features/applications/viewmodels/application_detail_viewmodel.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/models/internship_application.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/external_link_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeApplicationService applications;
  late FakeInternshipService internships;
  late FakeAnalyticsService analytics;
  late FakeExternalLinkService links;

  final listing = testInternship(
    '1',
    title: 'Flutter Developer Intern',
    companyName: 'FPT Software',
    workMode: WorkMode.remote,
    location: 'Ho Chi Minh City',
    scheduleType: 'Internship',
    salary: '5-7M VND/month',
    postedAt: DateTime(2026, 11, 1),
  );
  final appliedAt = DateTime(2026, 10, 11, 9);
  final withdrawnAt = DateTime(2026, 10, 12, 9);

  InternshipApplication buildApplication({
    ApplicationStatus status = ApplicationStatus.underReview,
    bool withdrawn = false,
    bool withApplicant = true,
  }) {
    return InternshipApplication(
      jobKey: listing.key,
      title: listing.title,
      companyName: listing.companyName,
      appliedAt: appliedAt,
      status: status,
      withdrawnAt: withdrawn ? withdrawnAt : null,
      previousStatus: withdrawn ? ApplicationStatus.underReview : null,
      cvFileName: 'Profile_CV.pdf',
      cvUrl: 'https://storage.example/cvs/profile.pdf',
      cvStoragePath: 'cvs/uid-123/profile.pdf',
      applicant: withApplicant
          ? const ApplicationApplicant(
              fullName: 'Minh Nguyen',
              email: 'minh@example.com',
              phone: '0908 123 456',
              university: 'HCMUT',
              yearOfStudy: 3,
              skills: ['Flutter', 'Dart'],
            )
          : null,
    );
  }

  setUp(() {
    applications = FakeApplicationService()..results = [buildApplication()];
    internships = FakeInternshipService()..byKey[listing.key] = listing;
    analytics = FakeAnalyticsService();
    links = FakeExternalLinkService();
  });

  tearDown(() async {
    await applications.dispose();
    await internships.dispose();
  });

  Future<void> pumpDetail(WidgetTester tester, {double width = 360}) async {
    setScreenSize(tester, width: width, height: 900);
    final router = GoRouter(
      initialLocation: AppRoutes.applicationDetail(listing.key),
      routes: [
        GoRoute(
          path: AppRoutes.applications,
          builder: (context, state) => const Text('Applications tab'),
        ),
        GoRoute(
          path: '${AppRoutes.applications}/:jobKey',
          builder: (context, state) => ApplicationDetailScreen(
            internshipKey: state.pathParameters['jobKey']!,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          applicationServiceProvider.overrideWithValue(applications),
          internshipServiceProvider.overrideWithValue(internships),
          analyticsServiceProvider.overrideWithValue(analytics),
          externalLinkServiceProvider.overrideWithValue(links),
          currentUserIdProvider.overrideWithValue(testUser.uid),
          nowProvider.overrideWithValue(() => DateTime(2026, 10, 12, 10)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in checkWidths) {
    testWidgets('shows the application, tracker and CV at $width dp', (
      tester,
    ) async {
      await pumpDetail(tester, width: width);

      expect(find.text('Application Detail'), findsOneWidget);
      expect(find.text('Flutter Developer Intern'), findsOneWidget);
      expect(find.text('FPT Software'), findsOneWidget);
      expect(find.text('Submitted Oct 11, 2026'), findsWidgets);
      expect(find.text('5-7M VND / mo'), findsOneWidget);
      expect(find.text('Work mode Remote'), findsOneWidget);
      expect(find.text('Ho Chi Minh City'), findsOneWidget);

      // Status tracker, from the status the student set.
      expect(find.text('Status tracker', findRichText: true), findsOneWidget);
      expect(find.text('Submitted'), findsWidgets);
      expect(find.text('Under review'), findsWidgets);
      expect(find.text('Active step'), findsOneWidget);
      expect(find.text('Interview'), findsOneWidget);
      expect(find.text('Upcoming'), findsNothing);

      // Applicant snapshot, below the tracker.
      await tester.dragUntilVisible(
        find.text('Minh Nguyen'),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Applicant & Submitted CV', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Minh Nguyen'), findsOneWidget);
      expect(find.text('minh@example.com'), findsOneWidget);
      expect(find.text('HCMUT'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Withdraw application'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  }

  testWidgets('Withdraw asks first, then offers Undo for 24 hours', (
    tester,
  ) async {
    await pumpDetail(tester);

    await tester.tap(find.text('Withdraw application'));
    await tester.pumpAndSettle();
    expect(find.text('Withdraw application?'), findsOneWidget);
    expect(find.text('You can undo this within 24 hours.'), findsOneWidget);

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(applications.withdrawn, [
      (internshipKey: listing.key, previous: ApplicationStatus.underReview),
    ]);
    expect(find.text('Application withdrawn'), findsOneWidget);

    // The live document now reads Withdrawn.
    applications.emit([
      buildApplication(status: ApplicationStatus.withdrawn, withdrawn: true),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Withdrawn'), findsWidgets);
    expect(find.text('Undo withdrawal'), findsOneWidget);
    expect(find.text('Available until Oct 13, 2026, 09:00'), findsOneWidget);
  });

  testWidgets('Cancel in the dialog keeps the application', (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.text('Withdraw application'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(applications.withdrawn, isEmpty);
    expect(find.text('Withdraw application'), findsOneWidget);
  });

  testWidgets('Undo withdrawal restores the previous status', (tester) async {
    applications.results = [
      buildApplication(status: ApplicationStatus.withdrawn, withdrawn: true),
    ];
    await pumpDetail(tester);

    await tester.tap(find.text('Undo withdrawal'));
    await tester.pumpAndSettle();

    expect(applications.undone, [listing.key]);
  });

  testWidgets('Preview opens the submitted CV', (tester) async {
    await pumpDetail(tester);
    await tester.dragUntilVisible(
      find.text('Preview'),
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();

    expect(
      links.opened.single.toString(),
      'https://storage.example/cvs/profile.pdf',
    );
  });

  testWidgets('a load error shows the message and Retry', (tester) async {
    applications.error = const AppException(
      AppErrorKind.network,
      'We could not load your applications. Check your connection and try '
      'again.',
    );
    await pumpDetail(tester);

    expect(
      find.text(
        'We could not load your applications. Check your connection and try '
        'again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('a deleted application shows the empty state', (tester) async {
    applications.results = const <InternshipApplication>[];
    await pumpDetail(tester);

    expect(find.text('This application is not in your list'), findsOneWidget);
  });

  testWidgets('loading shows card skeletons', (tester) async {
    applications.gate = Completer<void>();
    await pumpDetail(tester);

    expect(find.bySemanticsLabel('Loading application'), findsOneWidget);
  });

  testWidgets('documents without the applicant snapshot hide that card', (
    tester,
  ) async {
    applications.results = [buildApplication(withApplicant: false)];
    await pumpDetail(tester);

    expect(
      find.text('Applicant & Submitted CV', findRichText: true),
      findsNothing,
    );
    expect(find.text('Status tracker', findRichText: true), findsOneWidget);
  });
}
