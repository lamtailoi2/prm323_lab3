import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/app/router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/features/internships/screens/apply_validate_screen.dart';
import 'package:internly/models/cv_validation_result.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/models/user_profile.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/cv_validation_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/remote_config_service.dart';
import 'package:internly/services/saved_internship_service.dart';
import 'package:internly/services/user_profile_service.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeInternshipService internships;
  late FakeUserProfileService profiles;
  late FakeSavedInternshipService saved;
  late FakeRemoteConfigService remoteConfig;
  late FakeCvValidationService cv;
  late Internship listing;

  CvFile profileCv() => CvFile(
    fileName: 'Profile_CV.pdf',
    url: 'https://storage.example/cvs/profile.pdf',
    storagePath: 'cvs/uid-123/profile.pdf',
    sizeBytes: 420 * 1024,
    uploadedAt: DateTime(2026, 10, 14),
  );

  setUp(() {
    internships = FakeInternshipService();
    profiles = FakeUserProfileService(profile: UserProfile(cv: profileCv()));
    saved = FakeSavedInternshipService();
    remoteConfig = FakeRemoteConfigService();
    cv = FakeCvValidationService();
    listing = testInternship(
      '1',
      title: 'Flutter Developer Intern',
      companyName: 'FPT Software',
    );
    internships.byKey[listing.key] = listing;
  });

  tearDown(() async {
    await internships.dispose();
    await profiles.dispose();
    await saved.dispose();
    remoteConfig.dispose();
  });

  Future<void> pumpValidate(WidgetTester tester, {double width = 360}) async {
    setScreenSize(tester, width: width, height: 900);
    final router = GoRouter(
      initialLocation: AppRoutes.applyValidate('home', listing.key),
      routes: [
        GoRoute(
          path: '/home/internships/:jobKey',
          builder: (context, state) =>
              const Scaffold(body: Text('Detail stub')),
          routes: [
            GoRoute(
              path: 'apply',
              builder: (context, state) =>
                  const Scaffold(body: Text('Apply Form stub')),
              routes: [
                GoRoute(
                  path: 'validate',
                  builder: (context, state) => ApplyValidateScreen(
                    internshipKey: listing.key,
                    source: 'home',
                  ),
                ),
                GoRoute(
                  path: 'confirm',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Confirm stub')),
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
          currentUserIdProvider.overrideWithValue(testUser.uid),
          internshipServiceProvider.overrideWithValue(internships),
          userProfileServiceProvider.overrideWithValue(profiles),
          savedInternshipServiceProvider.overrideWithValue(saved),
          remoteConfigServiceProvider.overrideWithValue(remoteConfig),
          cvValidationServiceProvider.overrideWithValue(cv),
          analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
  }

  testWidgets('shows the checking state until the callable resolves', (
    tester,
  ) async {
    cv.gate = Completer<void>();
    await pumpValidate(tester);
    await tester.pump();
    await tester.pump();

    expect(find.text('Checking your CV…'), findsOneWidget);
    expect(find.text('Validate CV'), findsOneWidget);
    expect(find.text('Step 2 of 3 · CV check'), findsOneWidget);
    expect(cv.calls, 1);

    cv.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Confirm stub'), findsOneWidget);
  });

  testWidgets('a valid CV continues to Confirm Application', (tester) async {
    await pumpValidate(tester);
    await tester.pumpAndSettle();

    expect(find.text('Confirm stub'), findsOneWidget);
  });

  testWidgets('an invalid CV goes back to the form to update it', (
    tester,
  ) async {
    cv.result = const CvValidationResult(
      isValid: false,
      reason: 'This file has no contact details.',
    );
    await pumpValidate(tester);
    await tester.pumpAndSettle();

    expect(find.text('We could not use this CV'), findsOneWidget);
    expect(find.text('This file has no contact details.'), findsOneWidget);
    expect(find.text('Update CV'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester, meetsGuideline(androidTapTargetGuideline));

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(cv.calls, 2);

    await tester.tap(find.text('Update CV'));
    await tester.pumpAndSettle();
    expect(find.text('Apply Form stub'), findsOneWidget);
  });

  testWidgets('a failed check shows its message', (tester) async {
    cv.error = const AppException(
      AppErrorKind.network,
      'We could not check your CV. Check your connection and try again.',
    );
    await pumpValidate(tester);
    await tester.pumpAndSettle();

    expect(find.text('We could not check your CV'), findsOneWidget);
    expect(
      find.text(
        'We could not check your CV. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Cancel returns to Internship Detail', (tester) async {
    cv.result = const CvValidationResult(
      isValid: false,
      reason: 'This file has no contact details.',
    );
    await pumpValidate(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Detail stub'), findsOneWidget);
  });

  testWidgets('without a CV the step explains what is missing', (tester) async {
    profiles.profile = const UserProfile();
    await pumpValidate(tester);
    await tester.pumpAndSettle();

    expect(find.text('Your CV is not ready'), findsOneWidget);
    expect(find.text('Confirm stub'), findsNothing);
  });

  for (final width in checkWidths) {
    testWidgets('no overflow and 48 dp targets at $width dp', (tester) async {
      cv.result = const CvValidationResult(
        isValid: false,
        reason: 'This file has no contact details.',
      );
      await pumpValidate(tester, width: width);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester, meetsGuideline(androidTapTargetGuideline));
    });
  }
}
