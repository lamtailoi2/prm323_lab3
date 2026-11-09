import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/features/internships/screens/apply_compose_screen.dart';
import 'package:internly/models/app_user.dart';
import 'package:internly/models/cv_selection.dart';
import 'package:internly/models/user_profile.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/cover_letter_service.dart';
import 'package:internly/services/cv_select_service.dart';
import 'package:internly/services/external_link_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/remote_config_service.dart';
import 'package:internly/services/user_profile_service.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeInternshipService internships;
  late FakeUserProfileService profiles;
  late FakeApplicationService applications;
  late FakeCoverLetterService coverLetters;
  late FakeCvSelectService cvSelect;
  late FakeExternalLinkService links;
  late FakeAnalyticsService analytics;
  late FakeRemoteConfigService remoteConfig;

  final listing = testInternship(
    '1',
    title: 'Flutter Developer Intern',
    companyName: 'FPT Software',
    description: 'Send your CV to hr@fpt.com.vn. Flutter and Dart required.',
    skills: const ['Flutter', 'Dart'],
  );
  final profileCv = CvFile(
    fileName: 'Profile_CV.pdf',
    url: 'https://storage.example/cvs/profile.pdf',
    storagePath: 'cvs/uid-123/profile.pdf',
    sizeBytes: 420 * 1024,
    uploadedAt: DateTime(2026, 10, 14),
  );

  setUp(() {
    internships = FakeInternshipService()..byKey[listing.key] = listing;
    profiles = FakeUserProfileService(
      profile: UserProfile(
        cv: profileCv,
        details: const ProfileDetails(fullName: 'Minh Nguyen'),
        skills: const <String>['Flutter', 'Dart'],
      ),
    );
    applications = FakeApplicationService();
    coverLetters = FakeCoverLetterService();
    cvSelect = FakeCvSelectService();
    links = FakeExternalLinkService();
    analytics = FakeAnalyticsService();
    remoteConfig = FakeRemoteConfigService();
  });

  tearDown(() async {
    await internships.dispose();
    await profiles.dispose();
    await applications.dispose();
    remoteConfig.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester, {double width = 360}) async {
    setScreenSize(tester, width: width);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          internshipServiceProvider.overrideWithValue(internships),
          userProfileServiceProvider.overrideWithValue(profiles),
          applicationServiceProvider.overrideWithValue(applications),
          coverLetterServiceProvider.overrideWithValue(coverLetters),
          cvSelectServiceProvider.overrideWithValue(cvSelect),
          externalLinkServiceProvider.overrideWithValue(links),
          analyticsServiceProvider.overrideWithValue(analytics),
          remoteConfigServiceProvider.overrideWithValue(remoteConfig),
          authStateChangesProvider.overrideWith(
            (ref) => Stream<AppUser?>.value(testUser),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: ApplyComposeScreen(internshipKey: listing.key, source: 'home'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in checkWidths) {
    testWidgets('shows the drafted email and actions at $width dp', (
      tester,
    ) async {
      await pumpScreen(tester, width: width);

      expect(find.text('Apply by email'), findsOneWidget);
      expect(
        find.textContaining('We found this address in the job post'),
        findsOneWidget,
      );
      expect(find.text('hr@fpt.com.vn'), findsOneWidget);
      expect(find.text('Application for Flutter Intern'), findsOneWidget);
      expect(find.textContaining('Dear Hiring Team'), findsOneWidget);
      expect(find.text('Open email app'), findsOneWidget);
      expect(find.text("I've sent it"), findsOneWidget);

      // The CV card is below the fold on both widths.
      await tester.dragUntilVisible(
        find.text('Profile_CV.pdf'),
        find.byType(ListView),
        const Offset(0, -300),
      );
      expect(find.text('Profile_CV.pdf'), findsOneWidget);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  }

  for (final width in checkWidths) {
    testWidgets(
      'shows the suggested CV and lets the student change it at $width dp',
      (tester) async {
        final secondCv = CvFile(
          id: 'cv-2',
          fileName: 'Backend_CV.pdf',
          url: 'https://storage.example/cvs/backend.pdf',
          storagePath: 'cvs/uid-123/backend.pdf',
          sizeBytes: 300 * 1024,
          uploadedAt: DateTime(2026, 10, 20),
        );
        profiles.cvs.addAll([secondCv, profileCv]);
        cvSelect.result = CvSelection(
          storagePath: secondCv.storagePath,
          percent: 80,
          matchedCount: 1,
          totalRequired: 2,
          reason: 'This CV matches more of the internship requirements.',
          cvReadable: true,
        );
        await pumpScreen(tester, width: width);

        await tester.dragUntilVisible(
          find.textContaining('This is only a suggestion'),
          find.byType(ListView),
          const Offset(0, -300),
        );
        expect(find.text('Backend_CV.pdf'), findsOneWidget);
        expect(
          find.textContaining('This is only a suggestion'),
          findsOneWidget,
        );

        await tester.ensureVisible(find.text('Change CV'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Change CV'));
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        expect(find.text('Profile_CV.pdf'), findsWidgets);
        await tester.tap(find.text('Profile_CV.pdf').last);
        await tester.pumpAndSettle();

        expect(find.textContaining('This is only a suggestion'), findsNothing);
        expect(find.text('Profile_CV.pdf'), findsOneWidget);
      },
    );
  }

  testWidgets('says when the job post has no address', (tester) async {
    internships.byKey[listing.key] = testInternship(
      '1',
      description: 'Apply on our website.',
    );
    await pumpScreen(tester);

    expect(find.textContaining('Add the recruiter email'), findsOneWidget);
    expect(find.text('hr@fpt.com.vn'), findsNothing);
  });

  testWidgets('without a Profile CV it offers to add one', (tester) async {
    profiles.profile = const UserProfile(
      details: ProfileDetails(fullName: 'Minh Nguyen'),
    );
    await pumpScreen(tester);

    await tester.dragUntilVisible(
      find.text('Add a CV in Profile'),
      find.byType(ListView),
      const Offset(0, -300),
    );
    expect(find.text('Add a CV in Profile'), findsOneWidget);
    expect(find.text('Validate CV'), findsNothing);
  });

  testWidgets('a listing that cannot load shows an error with Retry', (
    tester,
  ) async {
    internships.byKeyError = const AppException(
      AppErrorKind.network,
      'We could not load this internship.',
    );
    await pumpScreen(tester);

    expect(find.text('We could not load this internship.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Open email app hands the draft to the mail app', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Open email app'));
    await tester.pumpAndSettle();

    expect(links.openedEmails, hasLength(1));
    expect(links.openedEmails.single.path, 'hr@fpt.com.vn');
    expect(
      find.text('Email app opened. Attach your CV there.'),
      findsOneWidget,
    );
  });
}
