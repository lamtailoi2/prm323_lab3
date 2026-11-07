import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/app/router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/features/internships/screens/apply_confirm_screen.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/models/user_profile.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/external_link_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/remote_config_service.dart';
import 'package:internly/services/saved_internship_service.dart';
import 'package:internly/services/user_profile_service.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

const _applyUrl = 'https://careers.example.com/apply/flutter-intern';

void main() {
  late FakeInternshipService internships;
  late FakeUserProfileService profiles;
  late FakeSavedInternshipService saved;
  late FakeRemoteConfigService remoteConfig;
  late FakeExternalLinkService links;
  late FakeApplicationService applications;
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
    links = FakeExternalLinkService();
    applications = FakeApplicationService();
    listing = testInternship(
      '1',
      title: 'Flutter Developer Intern',
      companyName: 'FPT Software',
      employerApplyUrl: _applyUrl,
    );
    internships.byKey[listing.key] = listing;
  });

  tearDown(() async {
    await internships.dispose();
    await profiles.dispose();
    await saved.dispose();
    await applications.dispose();
    remoteConfig.dispose();
  });

  Future<void> pumpConfirm(WidgetTester tester, {double width = 360}) async {
    setScreenSize(tester, width: width, height: 900);
    final router = GoRouter(
      initialLocation: AppRoutes.applyConfirm('home', listing.key),
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
                  path: 'confirm',
                  builder: (context, state) => ApplyConfirmScreen(
                    internshipKey: listing.key,
                    source: 'home',
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/applications',
          builder: (context, state) =>
              const Scaffold(body: Text('My Applications stub')),
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
          externalLinkServiceProvider.overrideWithValue(links),
          applicationServiceProvider.overrideWithValue(applications),
          analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Sends a lifecycle state through the platform channel, as the OS does.
  Future<void> setLifecycle(
    WidgetTester tester,
    AppLifecycleState state,
  ) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/lifecycle',
      const StringCodec().encodeMessage(state.toString()),
      (_) {},
    );
    await tester.pump();
  }

  testWidgets('shows the listing, the CV and the employer website', (
    tester,
  ) async {
    await pumpConfirm(tester);

    expect(find.text('Confirm Application'), findsOneWidget);
    expect(find.text('Step 3 of 3 · Confirm'), findsOneWidget);
    expect(find.text('Flutter Developer Intern'), findsOneWidget);
    expect(
      find.text('FPT Software · Ho Chi Minh City, Vietnam'),
      findsOneWidget,
    );
    expect(find.text('CV / Resume'), findsOneWidget);
    expect(find.text('Profile_CV.pdf'), findsOneWidget);
    expect(find.text('From your Profile'), findsOneWidget);
    expect(find.text('Application website'), findsOneWidget);
    expect(
      find.textContaining('You will finish this application on FPT Software'),
      findsOneWidget,
    );
    expect(find.text('Continue to employer website'), findsOneWidget);
  });

  testWidgets('opening the employer page and coming back records the '
      'application', (tester) async {
    await pumpConfirm(tester);

    await tester.tap(find.text('Continue to employer website'));
    await tester.pumpAndSettle();

    expect(links.opened, [Uri.parse(_applyUrl)]);
    expect(
      find.textContaining('Finish your application on FPT Software'),
      findsOneWidget,
    );

    await setLifecycle(tester, AppLifecycleState.paused);
    await setLifecycle(tester, AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.textContaining('Welcome back.'), findsOneWidget);

    await tester.tap(find.text("I've submitted my application"));
    await tester.pumpAndSettle();

    expect(applications.submissions, hasLength(1));
    expect(applications.submissions.single.jobKey, listing.key);
    expect(find.text('My Applications stub'), findsOneWidget);
  });

  testWidgets('a failed redirect can be retried', (tester) async {
    links.error = const AppException(
      AppErrorKind.unknown,
      'No app on this device can open this file.',
    );
    await pumpConfirm(tester);

    await tester.tap(find.text('Continue to employer website'));
    await tester.pumpAndSettle();

    expect(
      find.text('No app on this device can open this file.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);

    links.error = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(links.opened, [Uri.parse(_applyUrl)]);
    expect(find.text("I've submitted my application"), findsOneWidget);
  });

  testWidgets('a listing without an employer link can still be recorded', (
    tester,
  ) async {
    listing = testInternship(
      '1',
      title: 'Flutter Developer Intern',
      companyName: 'FPT Software',
      shareUrl: 'https://www.google.com/search?ibp=htl;jobs&q=flutter',
    );
    internships.byKey[listing.key] = listing;
    await pumpConfirm(tester);

    expect(
      find.textContaining('does not share an employer application link'),
      findsOneWidget,
    );
    expect(find.text('Mark as applied'), findsOneWidget);

    await tester.tap(find.text('Open listing on Google Jobs'));
    await tester.pumpAndSettle();
    expect(links.opened, hasLength(1));

    await tester.tap(find.text('Mark as applied'));
    await tester.pumpAndSettle();
    expect(applications.submissions, hasLength(1));
    expect(find.text('My Applications stub'), findsOneWidget);
  });

  testWidgets('a failed write offers Retry and writes nothing until then', (
    tester,
  ) async {
    applications.submitError = const AppException(
      AppErrorKind.network,
      'We could not save your application. Check your connection and try '
      'again.',
    );
    await pumpConfirm(tester);

    await tester.tap(find.text('Continue to employer website'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("I've submitted my application"));
    await tester.pumpAndSettle();

    expect(applications.submissions, isEmpty);
    expect(
      find.textContaining('We could not save your application.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);

    applications.submitError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(applications.submissions, hasLength(1));
    expect(find.text('My Applications stub'), findsOneWidget);
  });

  for (final width in checkWidths) {
    testWidgets('no overflow and 48 dp targets at $width dp', (tester) async {
      await pumpConfirm(tester, width: width);

      expect(tester.takeException(), isNull);
      expect(tester, meetsGuideline(androidTapTargetGuideline));
    });
  }
}
