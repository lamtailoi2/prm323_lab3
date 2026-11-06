import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/widgets/app_button.dart';
import 'package:internly/features/internships/screens/apply_form_screen.dart';
import 'package:internly/features/internships/viewmodels/apply_form_viewmodel.dart';
import 'package:internly/features/profile/widgets/edit_skills_sheet.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/models/user_profile.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/document_picker_service.dart';
import 'package:internly/services/external_link_service.dart';
import 'package:internly/services/file_storage_service.dart';
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
  late FakeAnalyticsService analytics;
  late FakeDocumentPickerService picker;
  late FakeFileStorageService storage;
  late FakeExternalLinkService links;
  late FakeRemoteConfigService remoteConfig;
  late FakeAuthService auth;

  final listing = testInternship(
    '1',
    title: 'Flutter Developer Intern',
    companyName: 'FPT Software',
    workMode: WorkMode.remote,
  );
  final profileCv = CvFile(
    fileName: 'Profile_CV.pdf',
    url: 'https://storage.example/cvs/profile.pdf',
    storagePath: 'cvs/uid-123/profile.pdf',
    sizeBytes: 420 * 1024,
    uploadedAt: DateTime(2026, 10, 14),
  );
  const details = ProfileDetails(
    fullName: 'Minh Nguyen',
    phone: '0908 123 456',
    university: 'HCM University of Technology',
    yearOfStudy: 3,
  );

  setUp(() {
    internships = FakeInternshipService()..byKey[listing.key] = listing;
    profiles = FakeUserProfileService(
      profile: UserProfile(cv: profileCv, details: details),
    );
    saved = FakeSavedInternshipService();
    analytics = FakeAnalyticsService();
    picker = FakeDocumentPickerService();
    storage = FakeFileStorageService();
    links = FakeExternalLinkService();
    remoteConfig = FakeRemoteConfigService();
    auth = FakeAuthService(initialUser: testUser);
  });

  tearDown(() async {
    await internships.dispose();
    await profiles.dispose();
    await saved.dispose();
    remoteConfig.dispose();
    await auth.dispose();
  });

  Future<void> pumpForm(WidgetTester tester, {double width = 360}) async {
    setScreenSize(tester, width: width, height: 900);
    final router = GoRouter(
      initialLocation: '/apply',
      routes: [
        GoRoute(
          path: '/apply',
          builder: (context, state) =>
              ApplyFormScreen(internshipKey: listing.key, source: 'home'),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const Text('Profile tab'),
        ),
        // Stands in for CvValidationScreen so the test only checks that the
        // form hands the data over (the real screens have their own tests).
        // The form builds `/{tab}/internships/:jobKey/apply/...` from its
        // `source`.
        GoRoute(
          path: '/home/internships/:jobKey/apply/match',
          builder: (context, state) {
            final session = state.extra;
            return Text(
              session is ApplySession
                  ? 'CV Match step: ${session.cv.file.fileName}'
                  : 'CV Match step',
            );
          },
        ),
        GoRoute(
          path: '/home/internships/:jobKey/apply/validation',
          builder: (context, state) {
            final session = state.extra;
            return Text(
              session is ApplySession
                  ? 'Validate CV step: ${session.cv.file.fileName}'
                  : 'Validate CV step',
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          internshipServiceProvider.overrideWithValue(internships),
          userProfileServiceProvider.overrideWithValue(profiles),
          savedInternshipServiceProvider.overrideWithValue(saved),
          analyticsServiceProvider.overrideWithValue(analytics),
          documentPickerServiceProvider.overrideWithValue(picker),
          fileStorageServiceProvider.overrideWithValue(storage),
          externalLinkServiceProvider.overrideWithValue(links),
          remoteConfigServiceProvider.overrideWithValue(remoteConfig),
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

  /// The form is long: scroll the section under test into view.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(
      finder,
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
  }

  AppButton continueButton(WidgetTester tester) => tester.widget<AppButton>(
    find.widgetWithText(AppButton, 'Continue to review'),
  );

  for (final width in checkWidths) {
    testWidgets('CV from Profile: summary, banner and CV at $width dp', (
      tester,
    ) async {
      await pumpForm(tester, width: width);

      expect(find.text('Apply Form'), findsOneWidget);
      expect(find.text('Step 1 of 2 · Your details'), findsOneWidget);
      expect(find.text('Flutter Developer Intern'), findsOneWidget);
      expect(find.text('FPT Software · Remote'), findsOneWidget);
      expect(
        find.text(
          'We filled this in from your Profile. Check it before you continue.',
        ),
        findsOneWidget,
      );

      // Personal information, prefilled from the Profile. The title carries
      // the ` *` of a required section, so match it by text.
      await scrollTo(tester, find.text('Minh Nguyen'));
      expect(
        find.textContaining('Personal information', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Minh Nguyen'), findsOneWidget);
      expect(find.text('student@example.com'), findsOneWidget);
      expect(
        find.text('The company will use this to arrange an interview'),
        findsOneWidget,
      );

      await scrollTo(tester, find.text('Profile_CV.pdf'));
      expect(find.text('Profile_CV.pdf'), findsOneWidget);
      expect(find.text('420 KB · PDF'), findsOneWidget);
      expect(find.text('From your Profile'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Replace'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Continue to review'));
      await tester.pumpAndSettle();
      expect(find.text('CV Match step: Profile_CV.pdf'), findsOneWidget);
    });

    testWidgets('empty Profile: tip and field errors at $width dp', (
      tester,
    ) async {
      profiles.profile = const UserProfile();
      await pumpForm(tester, width: width);

      expect(
        find.text(
          'Tip: complete your Profile once and we will fill this in for you '
          'next time.',
        ),
        findsOneWidget,
      );
      expect(find.text('Go to Profile'), findsOneWidget);

      await tester.tap(find.text('Continue to review'));
      await tester.pumpAndSettle();

      // The Google name fills the first field; the rest say what is missing
      // and nothing navigates.
      expect(find.text('Test Student'), findsOneWidget);
      expect(find.text('Enter a phone number to continue.'), findsOneWidget);
      expect(find.text('Select your university to continue.'), findsOneWidget);
      expect(
        find.text('Select your year of study to continue.'),
        findsOneWidget,
      );
      expect(find.textContaining('Validate CV step'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cv_match_enabled off skips CV Match and opens Validate CV', (
    tester,
  ) async {
    remoteConfig.publish(RemoteConfigKeys.cvMatchEnabled, false);
    await pumpForm(tester);
    await scrollTo(tester, find.text('Profile_CV.pdf'));

    await tester.tap(find.text('Continue to review'));
    await tester.pumpAndSettle();

    expect(find.text('Validate CV step: Profile_CV.pdf'), findsOneWidget);
    expect(find.textContaining('CV Match step'), findsNothing);
  });

  testWidgets('complete details without a CV: the CV section says so', (
    tester,
  ) async {
    profiles.profile = const UserProfile(details: details);
    await pumpForm(tester);
    await scrollTo(tester, find.text('PDF, up to 10 MB'));

    await tester.tap(find.text('Continue to review'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Add a CV to continue. Companies need it to review your application.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Validate CV step'), findsNothing);
  });

  testWidgets(
    'Upload CV opens the Profile CV sheet; the CV is uploaded for this job',
    (tester) async {
      profiles.profile = const UserProfile(details: details);
      picker.next = PickedDocument(name: 'Job_CV.pdf', bytes: pdfBytes());
      storage.gate = Completer<void>();
      await pumpForm(tester);
      await scrollTo(tester, find.text('Upload CV'));

      await tester.tap(find.text('Upload CV'));
      await tester.pumpAndSettle();
      expect(
        find.text('Add the CV you want to send for this internship'),
        findsOneWidget,
      );
      expect(find.text('Choose a PDF file'), findsOneWidget);
      expect(find.text('Browse phone storage or Google Drive'), findsOneWidget);
      expect(find.text('Accepted format: PDF, up to 10 MB'), findsOneWidget);

      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();
      expect(find.text('Selected for update'), findsOneWidget);
      expect(find.text('Job_CV.pdf'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Upload CV').last);
      await tester.pump();
      expect(find.text('Uploading… 50%'), findsWidgets);
      expect(continueButton(tester).onPressed, isNull);

      storage.gate!.complete();
      await tester.pumpAndSettle();
      expect(
        find.text('Add the CV you want to send for this internship'),
        findsNothing,
      );
      expect(find.text('Uploaded for this internship'), findsOneWidget);
      expect(continueButton(tester).onPressed, isNotNull);
      // No Profile tip once a CV is uploaded for this internship (CR-20).
      expect(
        find.textContaining('Tip: complete your Profile once'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Replace: a failed upload shows its error in the sheet; Cancel keeps '
    'the Profile CV',
    (tester) async {
      picker.next = PickedDocument(name: 'Job_CV.pdf', bytes: pdfBytes());
      storage.error = const AppException(
        AppErrorKind.network,
        'We could not upload the file. Check your connection and try again.',
      );
      await pumpForm(tester);
      await scrollTo(tester, find.text('Replace'));

      await tester.tap(find.text('Replace'));
      await tester.pumpAndSettle();
      expect(find.text('Update CV'), findsWidgets);
      expect(
        find.text('Use a different CV for this internship'),
        findsOneWidget,
      );
      expect(find.text('Current active CV'), findsOneWidget);

      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Update CV'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'We could not upload the file. Check your connection and try again.',
        ),
        findsWidgets,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Current active CV'), findsNothing);
      expect(find.text('CV could not be uploaded'), findsNothing);
      expect(find.text('From your Profile'), findsOneWidget);
    },
  );

  testWidgets(
    'an upload that fails after the sheet closed offers Retry and Use CV '
    'from Profile on the form',
    (tester) async {
      picker.next = PickedDocument(name: 'Job_CV.pdf', bytes: pdfBytes());
      storage.gate = Completer<void>();
      await pumpForm(tester);
      await scrollTo(tester, find.text('Replace'));

      await tester.tap(find.text('Replace'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Update CV'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Uploading… 50%'), findsOneWidget);

      storage.error = const AppException(AppErrorKind.network, 'Offline.');
      storage.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('CV could not be uploaded'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Continue does not quietly use the Profile CV instead (CR-15).
      await tester.tap(find.text('Continue to review'));
      await tester.pump();
      expect(
        find.text('Retry the upload or choose another CV first.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Use CV from Profile'));
      await tester.pumpAndSettle();
      expect(find.text('CV could not be uploaded'), findsNothing);
      expect(find.text('From your Profile'), findsOneWidget);
    },
  );

  testWidgets('a profile load error shows Retry instead of the tip (CR-18)', (
    tester,
  ) async {
    profiles.loadError = const AppException(
      AppErrorKind.network,
      'We could not load your Profile CV. Try again.',
    );
    await pumpForm(tester);
    await scrollTo(tester, find.text('Upload CV'));

    expect(
      find.text('We could not load your Profile CV. Try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Upload CV'), findsOneWidget);
    expect(
      find.textContaining('Tip: complete your Profile once'),
      findsNothing,
    );

    profiles.loadError = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('From your Profile'));
    expect(find.text('From your Profile'), findsOneWidget);
  });

  testWidgets('Edit profile opens the Profile tab', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile tab'), findsOneWidget);
  });

  testWidgets('a listing that left the pool shows the unavailable state', (
    tester,
  ) async {
    internships.byKey.clear();
    await pumpForm(tester);

    expect(find.text('This internship is no longer available'), findsOneWidget);
    expect(find.text('Continue to review'), findsNothing);
  });

  testWidgets('a load error shows the message and Retry', (tester) async {
    internships.byKeyError = const AppException(
      AppErrorKind.network,
      'We could not reach Internly.',
    );
    await pumpForm(tester);

    expect(find.text('We could not reach Internly.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('every tap target is at least 48 dp', (tester) async {
    await pumpForm(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  for (final width in checkWidths) {
    testWidgets('summary facts and the Skills section at $width dp', (
      tester,
    ) async {
      internships.byKey[listing.key] = testInternship(
        '1',
        title: 'Intern Dev',
        companyName: 'Techcombank',
        location: 'Việt Nam',
        salary: 'Negotiable',
        skills: const ['Flutter', 'Dart', 'Java', 'Kotlin', 'Swift', 'SQL'],
      );
      profiles.profile = UserProfile(
        cv: profileCv,
        details: details,
        skills: const ['Flutter', 'Dart'],
      );
      await pumpForm(tester, width: width);

      expect(find.text('Techcombank · Việt Nam'), findsOneWidget);
      expect(find.bySemanticsLabel('Allowance: Negotiable'), findsOneWidget);
      expect(find.bySemanticsLabel('Job type: Not disclosed'), findsOneWidget);

      await scrollTo(tester, find.text('You have 2 of 6 required skills'));
      expect(find.text('You have 2 of 6 required skills'), findsOneWidget);
      expect(find.text('Missing: Java, Kotlin, Swift, SQL'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The Edit skills sheet opens over the form, so nothing on it is lost
      // (CR-16).
      await tester.tap(find.text('Add skill'));
      await tester.pumpAndSettle();
      expect(find.text('Select your technical proficiencies'), findsOneWidget);
      expect(find.text('Profile tab'), findsNothing);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      // Still on the form, at the section the sheet was opened from.
      expect(find.text('You have 2 of 6 required skills'), findsOneWidget);
    });
  }

  testWidgets(
    'Add skill keeps the Profile skills when the Profile tab never loaded',
    (tester) async {
      // The form is opened straight from a listing, so nothing has loaded
      // the Profile tab's view model yet: the sheet used to start empty and
      // `Save changes` replaced every Profile skill with the new one.
      internships.byKey[listing.key] = testInternship('1');
      profiles.profile = const UserProfile(
        details: details,
        skills: ['Flutter', 'Dart'],
      );
      await pumpForm(tester);
      await scrollTo(tester, find.text('Add skill'));

      await tester.tap(find.text('Add skill'));
      await tester.pumpAndSettle();
      expect(find.text('2 chosen'), findsOneWidget);

      final git = find.descendant(
        of: find.byType(EditSkillsSheet),
        matching: find.text('Git'),
      );
      await tester.ensureVisible(git);
      await tester.pumpAndSettle();
      await tester.tap(git);
      await tester.pumpAndSettle();
      expect(find.text('3 chosen'), findsOneWidget);
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Select your technical proficiencies'), findsNothing);
      expect(profiles.profile?.skills, ['Flutter', 'Dart', 'Git']);
    },
  );

  testWidgets('without Profile skills the section asks to add them', (
    tester,
  ) async {
    internships.byKey[listing.key] = testInternship(
      '1',
      skills: const ['Flutter', 'Dart'],
    );
    profiles.profile = const UserProfile(details: details);
    await pumpForm(tester);
    await scrollTo(tester, find.text('This internship asks for 2 skills'));

    expect(find.text('This internship asks for 2 skills'), findsOneWidget);
    expect(find.text('Add skill'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    expect(find.text('Dart'), findsOneWidget);
  });
}
