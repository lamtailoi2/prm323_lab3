import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/widgets/app_button.dart';
import 'package:internly/features/internships/screens/apply_form_screen.dart';
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

  setUp(() {
    internships = FakeInternshipService()..byKey[listing.key] = listing;
    profiles = FakeUserProfileService(profile: UserProfile(cv: profileCv));
    saved = FakeSavedInternshipService();
    analytics = FakeAnalyticsService();
    picker = FakeDocumentPickerService();
    storage = FakeFileStorageService();
    links = FakeExternalLinkService();
    remoteConfig = FakeRemoteConfigService();
  });

  tearDown(() async {
    await internships.dispose();
    await profiles.dispose();
    await saved.dispose();
    remoteConfig.dispose();
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
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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

  AppButton continueButton(WidgetTester tester) => tester.widget<AppButton>(
    find.widgetWithText(AppButton, 'Continue to review'),
  );

  for (final width in checkWidths) {
    testWidgets('CV from Profile: summary, banner and file at $width dp', (
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
      expect(find.text('Profile_CV.pdf'), findsOneWidget);
      expect(find.text('420 KB · PDF'), findsOneWidget);
      expect(find.text('From your Profile'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Replace'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Continue to review'));
      await tester.pump();
      expect(
        find.text('Your CV is ready. The review step is coming soon.'),
        findsOneWidget,
      );
    });

    testWidgets('no Profile CV: tip, upload area and its error at $width dp', (
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
      expect(find.text('PDF, up to 10 MB'), findsOneWidget);
      expect(find.text('Upload CV'), findsOneWidget);

      await tester.tap(find.text('Continue to review'));
      await tester.pump();
      expect(
        find.text(
          'Add a CV to continue. Companies need it to review your '
          'application.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Upload CV opens the Profile CV sheet; the CV is uploaded for this job',
    (tester) async {
      profiles.profile = const UserProfile();
      picker.next = PickedDocument(name: 'Job_CV.pdf', bytes: pdfBytes());
      storage.gate = Completer<void>();
      await pumpForm(tester);

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

      await tester.tap(find.text('Use CV from Profile'));
      await tester.pumpAndSettle();
      expect(find.text('CV could not be uploaded'), findsNothing);
      expect(find.text('From your Profile'), findsOneWidget);
    },
  );

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
    testWidgets('summary facts and the skill match line at $width dp', (
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
        skills: const ['Flutter', 'Dart'],
      );
      await pumpForm(tester, width: width);

      expect(find.text('Techcombank · Việt Nam'), findsOneWidget);
      expect(find.bySemanticsLabel('Allowance: Negotiable'), findsOneWidget);
      expect(find.bySemanticsLabel('Job type: Not disclosed'), findsOneWidget);
      expect(find.text('You have 2 of 6 required skills'), findsOneWidget);
      expect(find.text('Missing: Java, Kotlin, Swift +1 more'), findsOneWidget);
      expect(tester.takeException(), isNull);
      // The Profile banner sits above the skill match line.
      expect(
        tester
            .getTopLeft(
              find.text(
                'We filled this in from your Profile. Check it before you '
                'continue.',
              ),
            )
            .dy,
        lessThan(
          tester.getTopLeft(find.text('You have 2 of 6 required skills')).dy,
        ),
      );

      await tester.tap(find.text('Show all skills'));
      await tester.pump();
      expect(find.text('Missing: Java, Kotlin, Swift, SQL'), findsOneWidget);
      expect(find.text('You have: Flutter, Dart'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Show fewer'));
      await tester.pump();
      expect(find.text('Missing: Java, Kotlin, Swift +1 more'), findsOneWidget);
      expect(find.text('You have: Flutter, Dart'), findsNothing);

      await tester.tap(find.text('Edit skills'));
      await tester.pumpAndSettle();
      expect(find.text('Profile tab'), findsOneWidget);
    });
  }

  testWidgets('without Profile skills the line asks to add them', (
    tester,
  ) async {
    internships.byKey[listing.key] = testInternship(
      '1',
      skills: const ['Flutter', 'Dart'],
    );
    await pumpForm(tester);

    expect(find.text('This internship asks for 2 skills'), findsOneWidget);
    expect(
      find.text('Add your skills in Profile to see how you match.'),
      findsOneWidget,
    );
    expect(find.text('Add skills'), findsOneWidget);

    await tester.tap(find.text('Show all skills'));
    await tester.pump();
    expect(find.text('Skills: Flutter, Dart'), findsOneWidget);
  });
}
