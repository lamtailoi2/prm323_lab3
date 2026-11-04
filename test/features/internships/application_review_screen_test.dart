import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/app/router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/widgets/app_button.dart';
import 'package:internly/features/internships/screens/application_review_screen.dart';
import 'package:internly/features/internships/screens/application_success_screen.dart';
import 'package:internly/features/internships/viewmodels/apply_form_viewmodel.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/models/user_profile.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/crashlytics_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/user_profile_service.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeInternshipService internships;
  late FakeUserProfileService profiles;
  late FakeApplicationService applications;
  late FakeAnalyticsService analytics;
  late FakeCrashlyticsService crashlytics;

  final listing = testInternship(
    '1',
    title: 'Flutter Developer Intern',
    companyName: 'FPT Software',
    workMode: WorkMode.remote,
  );
  final cvFile = CvFile(
    fileName: 'Profile_CV.pdf',
    url: 'https://storage.example/cvs/profile.pdf',
    storagePath: 'cvs/uid-123/profile.pdf',
    sizeBytes: 420 * 1024,
    uploadedAt: DateTime(2026, 10, 14),
  );
  final session = ApplySession(
    cv: ApplyCv(cvFile, CvSource.profile),
    startedAt: DateTime(2026, 11, 3, 9),
    email: 'minh@example.com',
    details: const ProfileDetails(
      fullName: 'Minh Nguyen',
      phone: '0908 123 456',
      university: 'HCMUT',
      yearOfStudy: 3,
    ),
    skills: const ['Flutter', 'Dart'],
    introduction: 'I build Flutter apps.',
  );

  setUp(() {
    internships = FakeInternshipService()..byKey[listing.key] = listing;
    profiles = FakeUserProfileService();
    applications = FakeApplicationService();
    analytics = FakeAnalyticsService();
    crashlytics = FakeCrashlyticsService();
  });

  tearDown(() async {
    await internships.dispose();
    await profiles.dispose();
    await applications.dispose();
  });

  Future<void> pumpReview(
    WidgetTester tester, {
    double width = 360,
    bool withSession = true,
  }) async {
    setScreenSize(tester, width: width, height: 900);
    final router = GoRouter(
      initialLocation: AppRoutes.applicationReview('/home', listing.key),
      routes: [
        GoRoute(
          path: '/home/internships/:jobKey/apply',
          builder: (context, state) => const Scaffold(body: Text('Apply Form')),
          routes: [
            GoRoute(
              path: 'review',
              builder: (context, state) => ApplicationReviewScreen(
                internshipKey: state.pathParameters['jobKey']!,
                source: 'home',
                // The form hands these over in the route `extra`; here the
                // test decides whether they are present.
                session: withSession ? session : null,
              ),
              routes: [
                GoRoute(
                  path: 'success',
                  builder: (context, state) {
                    final args = state.extra;
                    return Text(
                      args is ApplicationSuccessArgs
                          ? 'Success: ${args.internshipTitle} · '
                                '${args.companyName}'
                          : 'Success',
                    );
                  },
                ),
              ],
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
          userProfileServiceProvider.overrideWithValue(profiles),
          applicationServiceProvider.overrideWithValue(applications),
          analyticsServiceProvider.overrideWithValue(analytics),
          crashlyticsServiceProvider.overrideWithValue(crashlytics),
          currentUserIdProvider.overrideWithValue(testUser.uid),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppButton submitButton(WidgetTester tester) => tester.widget<AppButton>(
    find.widgetWithText(AppButton, 'Submit application'),
  );

  for (final width in checkWidths) {
    testWidgets('shows every section of the application at $width dp', (
      tester,
    ) async {
      await pumpReview(tester, width: width);

      expect(find.text('Review application'), findsOneWidget);
      expect(find.text('Step 2 of 2 · Review & submit'), findsOneWidget);
      expect(find.text('Application summary'), findsOneWidget);
      expect(
        find.text(
          "Everything you've filled in so far is shown here so you can "
          'double-check before submitting.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ready to submit'), findsOneWidget);
      expect(find.text('All required details are complete.'), findsOneWidget);

      expect(
        find.text('Personal information', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Minh Nguyen'), findsOneWidget);
      expect(find.text('minh@example.com'), findsOneWidget);
      expect(find.text('0908 123 456'), findsOneWidget);
      expect(find.text('HCMUT'), findsOneWidget);
      expect(find.text('Year 3'), findsNWidgets(2));

      expect(find.text('Skills', findRichText: true), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('Edit'), findsWidgets);

      // The page scrolls: the CV and the introduction sit further down.
      await tester.dragUntilVisible(
        find.text('Profile_CV.pdf'),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(find.text('CV / Resume', findRichText: true), findsOneWidget);
      expect(find.text('Profile_CV.pdf'), findsOneWidget);
      expect(find.text('420 KB · PDF'), findsOneWidget);
      expect(find.text('From your Profile'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('I build Flutter apps.'),
        find.byType(Scrollable).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Short introduction', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Submit application'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  }

  testWidgets('Edit goes back to the Apply Form', (tester) async {
    await pumpReview(tester);

    await tester.tap(find.text('Edit').first);
    await tester.pumpAndSettle();

    expect(find.text('Apply Form'), findsOneWidget);
    expect(find.text('Review application'), findsNothing);
  });

  testWidgets('Submit opens the success screen with the recap', (tester) async {
    await pumpReview(tester);

    await tester.tap(find.text('Submit application'));
    await tester.pumpAndSettle();

    expect(applications.created, hasLength(1));
    expect(applications.created.single.applicant.fullName, 'Minh Nguyen');
    expect(
      find.text('Success: Flutter Developer Intern · FPT Software'),
      findsOneWidget,
    );
  });

  testWidgets('a failed submission shows the message and stays', (
    tester,
  ) async {
    applications.createError = const AppException(
      AppErrorKind.network,
      'We could not submit your application. Check your connection and try '
      'again.',
    );
    await pumpReview(tester);

    await tester.tap(find.text('Submit application'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'We could not submit your application. Check your connection and try '
        'again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Review application'), findsOneWidget);

    // The message clears on the next attempt.
    applications.createError = null;
    await tester.tap(find.text('Submit application'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Success:'), findsOneWidget);
  });

  testWidgets('the button shows its loading state and ignores a second tap', (
    tester,
  ) async {
    applications.createGate = Completer<void>();
    await pumpReview(tester);

    await tester.tap(find.text('Submit application'));
    await tester.pump();
    expect(submitButton(tester).isLoading, isTrue);

    await tester.tap(find.text('Submit application'));
    await tester.pump();

    applications.createGate!.complete();
    await tester.pumpAndSettle();
    expect(applications.created, hasLength(1));
  });

  testWidgets('opened without the form data, it points back to the form', (
    tester,
  ) async {
    await pumpReview(tester, withSession: false);

    expect(find.text('Your application is not ready'), findsOneWidget);
    expect(find.text('Submit application'), findsNothing);
  });
}
