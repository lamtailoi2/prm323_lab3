import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/app/router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/features/applications/screens/application_detail_screen.dart';
import 'package:internly/features/applications/viewmodels/application_detail_viewmodel.dart';
import 'package:internly/features/applications/widgets/application_status_badge.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/models/internship_application.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/external_link_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/theme/app_colors.dart';
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
    skills: const ['Flutter', 'Dart'],
  );
  final appliedAt = DateTime(2026, 10, 11, 9);
  final withdrawnAt = DateTime(2026, 10, 12, 9);

  InternshipApplication buildApplication({
    ApplicationStatus status = ApplicationStatus.underReview,
    bool withdrawn = false,
    bool withApplicant = true,
    int? cvSizeBytes = 430080,
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
      cvSizeBytes: cvSizeBytes,
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
      // The city joins the company line (DC-31).
      expect(find.text('FPT Software · Ho Chi Minh City'), findsOneWidget);
      expect(find.text('Submitted Oct 11, 2026'), findsWidgets);
      expect(find.text('5-7M VND / mo'), findsOneWidget);
      expect(find.text('Work mode Remote'), findsOneWidget);

      // Status tracker, from the status the student set: 4 steps, with
      // progress (`underReview` = step 2 of 4, 50%).
      expect(find.text('Status tracker', findRichText: true), findsOneWidget);
      expect(find.text('Step 2 of 4 (50% completed)'), findsOneWidget);
      expect(find.text('Submitted'), findsWidgets);
      expect(find.text('Under review'), findsWidgets);
      expect(find.text('Active step'), findsOneWidget);
      expect(find.text('Technical interview'), findsOneWidget);
      expect(find.text('Offer decision'), findsOneWidget);
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
      expect(find.text('420 KB • Uploaded Oct 11, 2026'), findsOneWidget);
      expect(find.text('Minh Nguyen'), findsOneWidget);
      expect(find.text('University email'), findsOneWidget);
      expect(find.text('minh@example.com'), findsOneWidget);
      expect(find.text('Matched candidate skills'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Withdraw application'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  }

  testWidgets('the status badge appears once, not duplicated', (tester) async {
    await pumpDetail(tester);

    // Only the tracker header carries the badge; the identity card does not
    // repeat it (DC-29).
    expect(find.byType(ApplicationStatusBadge), findsOneWidget);
  });

  testWidgets(
    'a document saved before cvSizeBytes existed shows the generic details',
    (tester) async {
      applications.results = [buildApplication(cvSizeBytes: null)];
      await pumpDetail(tester);
      await tester.dragUntilVisible(
        find.text('PDF · Submitted Oct 11, 2026'),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      expect(find.text('PDF · Submitted Oct 11, 2026'), findsOneWidget);
    },
  );

  testWidgets('the app-bar back button goes to My Applications', (
    tester,
  ) async {
    await pumpDetail(tester);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Applications tab'), findsOneWidget);
  });

  testWidgets('the withdraw button uses the destructive (error) color', (
    tester,
  ) async {
    await pumpDetail(tester);

    // AppButton leaves its own `style` null outside the loading state; the
    // button is actually colored by the ambient OutlinedButtonTheme that
    // _DestructiveWithdrawButton installs (DC-29).
    final buttonFinder = find.ancestor(
      of: find.text('Withdraw application'),
      matching: find.byType(OutlinedButton),
    );
    final context = tester.element(buttonFinder);
    final themeStyle = Theme.of(context).outlinedButtonTheme.style;
    final foreground = themeStyle?.foregroundColor?.resolve(
      const <WidgetState>{},
    );
    expect(foreground, AppColors.error);
  });

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

    expect(find.text('Application not found'), findsOneWidget);
    expect(find.text('Back to Applications'), findsOneWidget);

    // Goes to My Applications regardless of where this screen was opened
    // from, unlike the old `Navigator.maybePop` (DC-29).
    await tester.tap(find.text('Back to Applications'));
    await tester.pumpAndSettle();
    expect(find.text('Applications tab'), findsOneWidget);
  });

  testWidgets('a rejected application has no Withdraw action', (tester) async {
    applications.results = [
      buildApplication(status: ApplicationStatus.rejected),
    ];
    await pumpDetail(tester);

    expect(find.text('Withdraw application'), findsNothing);
    expect(find.text('Not selected'), findsOneWidget);
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
