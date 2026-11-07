import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/app/router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/widgets/app_button.dart';
import 'package:internly/core/widgets/app_tag.dart';
import 'package:internly/core/widgets/app_text_field.dart';
import 'package:internly/features/profile/screens/edit_profile_screen.dart';
import 'package:internly/features/profile/screens/profile_screen.dart';
import 'package:internly/features/profile/viewmodels/edit_profile_viewmodel.dart';
import 'package:internly/features/profile/widgets/profile_sections.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/models/user_profile.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/crashlytics_service.dart';
import 'package:internly/services/document_picker_service.dart';
import 'package:internly/services/external_link_service.dart';
import 'package:internly/services/file_storage_service.dart';
import 'package:internly/services/notification_service.dart';
import 'package:internly/services/user_profile_service.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/notification_fakes.dart';
import '../../helpers/pump.dart';

final _cv = CvFile(
  fileName: 'Minh_Nguyen_CV_SE.pdf',
  url: 'https://storage.example/cvs/minh.pdf',
  storagePath: 'cvs/uid-123/minh.pdf',
  sizeBytes: 430080,
  uploadedAt: DateTime(2024, 10, 14),
);

final _complete = UserProfile(
  details: const ProfileDetails(
    fullName: 'Minh Nguyen',
    headline: 'Software Engineering Student',
    phone: '+84 908 123 456',
    university: 'University of Science, HCMC',
    major: 'Software Engineering',
    yearOfStudy: 3,
  ),
  skills: const ['Flutter', 'React', 'NestJS', 'MongoDB'],
  preferences: const InternshipPreferences(
    targetRoles: [TargetRole.softwareEngineer, TargetRole.mobile],
    workModes: [WorkMode.remote, WorkMode.hybrid],
    location: 'Ho Chi Minh City',
  ),
  cv: _cv,
);

void main() {
  late FakeAuthService auth;
  late FakeUserProfileService profiles;
  late FakeAnalyticsService analytics;
  late FakeDocumentPickerService picker;
  late FakeFileStorageService storage;
  late FakeExternalLinkService links;
  late FakeCrashlyticsService crashlytics;
  late FakeNotificationService notificationService;
  late FakeApplicationService applications;

  setUp(() {
    auth = FakeAuthService(initialUser: testUser);
    profiles = FakeUserProfileService();
    applications = FakeApplicationService();
    analytics = FakeAnalyticsService();
    picker = FakeDocumentPickerService();
    storage = FakeFileStorageService();
    links = FakeExternalLinkService();
    crashlytics = FakeCrashlyticsService();
    notificationService = FakeNotificationService();
  });

  tearDown(() async {
    await profiles.dispose();
    await applications.dispose();
    await auth.dispose();
    await notificationService.dispose();
  });

  Future<void> pumpProfile(
    WidgetTester tester, {
    double width = 360,
    double height = 800,
  }) async {
    setScreenSize(tester, width: width, height: height);
    final router = GoRouter(
      navigatorKey: GlobalKey<NavigatorState>(),
      initialLocation: AppRoutes.profile,
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => const EditProfileScreen(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          userProfileServiceProvider.overrideWithValue(profiles),
          applicationServiceProvider.overrideWithValue(applications),
          analyticsServiceProvider.overrideWithValue(analytics),
          documentPickerServiceProvider.overrideWithValue(picker),
          fileStorageServiceProvider.overrideWithValue(storage),
          externalLinkServiceProvider.overrideWithValue(links),
          crashlyticsServiceProvider.overrideWithValue(crashlytics),
          notificationServiceProvider.overrideWithValue(notificationService),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder scrollable() => find.byType(Scrollable).first;

  /// Builds the item (lazy list) and then scrolls it fully into view.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200, scrollable: scrollable());
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  for (final width in checkWidths) {
    testWidgets('complete profile: every section at $width dp', (tester) async {
      profiles.profile = _complete;
      await pumpProfile(tester, width: width);

      expect(find.text('Profile'), findsOneWidget);
      expect(find.byTooltip('Notifications'), findsOneWidget);
      expect(find.text('Minh Nguyen'), findsOneWidget);
      expect(find.text('Software Engineering Student'), findsOneWidget);
      expect(find.text('Year 3 · Software Engineering'), findsOneWidget);
      expect(find.text('University of Science, HCMC'), findsOneWidget);
      expect(find.text('student@example.com'), findsOneWidget);
      expect(find.text('+84 908 123 456'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Edit profile'), findsOneWidget);

      await scrollTo(tester, find.text('Add CV'));
      expect(find.text('CV library'), findsOneWidget);
      expect(find.text('1 file'), findsOneWidget);
      expect(find.text('Minh_Nguyen_CV_SE.pdf'), findsOneWidget);
      expect(find.text('Oct 14, 2024 · 420 KB'), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Status: Default for applications')),
        findsOneWidget,
      );
      expect(find.byTooltip('CV actions'), findsOneWidget);

      await scrollTo(tester, find.text('MongoDB'));
      expect(find.text('Technical skills'), findsOneWidget);
      expect(find.text('Add skill'), findsOneWidget);
      for (final skill in ['Flutter', 'React', 'NestJS', 'MongoDB']) {
        expect(find.widgetWithText(AppTag, skill), findsOneWidget);
      }
      expect(tester.getSize(find.widgetWithText(AppTag, 'Flutter')).height, 44);

      await scrollTo(tester, find.text('Ho Chi Minh City'));
      expect(find.text('Internship preferences'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
      for (final tag in [
        'Software Engineer Intern',
        'Mobile Intern',
        'Remote',
        'Hybrid',
      ]) {
        expect(find.widgetWithText(AppTag, tag), findsOneWidget);
      }

      await scrollTo(tester, find.text('Sign out'));
      expect(find.text('Settings & support'), findsOneWidget);
      expect(find.text('Notification preferences'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Help & support'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('every tap target is at least 48 dp at $width dp', (
      tester,
    ) async {
      profiles.profile = _complete;
      // Tall enough that nothing is clipped by scrolling.
      await pumpProfile(tester, width: width, height: 2400);

      expect(find.text('Sign out'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets(
      'new profile: Google account and calls to action at $width dp',
      (tester) async {
        await pumpProfile(tester, width: width);

        expect(find.text('Test Student'), findsOneWidget);
        expect(find.text('Add your university and major.'), findsOneWidget);
        await scrollTo(tester, find.text('Add CV'));
        expect(
          find.text('No CV yet. Add a PDF to use when you apply.'),
          findsOneWidget,
        );
        expect(find.text('1 file'), findsNothing);
        await scrollTo(
          tester,
          find.text('Add the skills you have, such as Flutter or SQL.'),
        );
        await scrollTo(tester, find.text('Sign out'));
        expect(find.text('Not set'), findsNWidgets(3));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('loading shows the profile skeleton and keeps Sign out', (
    tester,
  ) async {
    profiles.loadGate = Completer<void>();
    await pumpProfile(tester);

    expect(find.byType(ProfileSkeleton), findsOneWidget);
    expect(find.bySemanticsLabel('Loading your profile'), findsOneWidget);
    await scrollTo(tester, find.text('Sign out'));

    profiles.loadGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ProfileSkeleton), findsNothing);
  });

  testWidgets('error shows the message, Retry loads, Sign out stays', (
    tester,
  ) async {
    profiles.loadError = const AppException(
      AppErrorKind.network,
      'We could not load your profile. Check your connection and try again.',
    );
    await pumpProfile(tester);

    expect(
      find.text(
        'We could not load your profile. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Sign out'), findsOneWidget);

    profiles
      ..loadError = null
      ..profile = _complete;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Minh Nguyen'), findsOneWidget);
    expect(profiles.watchCalls, 2);
  });

  testWidgets('Sign out signs the user out', (tester) async {
    await pumpProfile(tester);
    await scrollTo(tester, find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    expect(auth.signOutCalls, 1);
    expect(analytics.events, contains('logout'));
  });

  testWidgets('crash test control asks first, then forces the crash', (
    tester,
  ) async {
    await pumpProfile(tester);
    await scrollTo(tester, find.text('Simulate app crash'));
    expect(find.text('Diagnostics'), findsOneWidget);

    await tester.tap(find.text('Simulate app crash'));
    await tester.pumpAndSettle();
    expect(find.text('Simulate a crash?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(crashlytics.crashCalls, 0);

    await tester.tap(find.text('Simulate app crash'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crash now'));
    await tester.pumpAndSettle();
    expect(crashlytics.crashCalls, 1);
  });

  testWidgets('FCM token tile copies the device token', (tester) async {
    final copied = <String?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied.add(
              (call.arguments as Map<Object?, Object?>)['text'] as String?,
            );
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await pumpProfile(tester);
    await scrollTo(tester, find.text('Copy FCM token'));
    await tester.tap(find.text('Copy FCM token'));
    await tester.pumpAndSettle();

    expect(copied, ['fcm-test-token']);
    expect(find.text('FCM token copied.'), findsOneWidget);
  });

  testWidgets('settings rows without a screen say so honestly', (tester) async {
    await pumpProfile(tester);
    await scrollTo(tester, find.text('Language'));
    await tester.tap(find.text('Language'));
    await tester.pump();

    expect(
      find.text('Internly is available in English only for now.'),
      findsOneWidget,
    );
  });

  testWidgets('View CV opens the stored download URL', (tester) async {
    profiles.profile = _complete;
    await pumpProfile(tester);
    await scrollTo(tester, find.byTooltip('CV actions'));
    await tester.tap(find.byTooltip('CV actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    expect(links.opened, [Uri.parse(_cv.url)]);
  });

  group('Edit skills sheet', () {
    testWidgets('select, remove and save updates the section', (tester) async {
      profiles.profile = const UserProfile(skills: ['Flutter', 'React']);
      await pumpProfile(tester);
      await scrollTo(tester, find.text('Add skill'));
      await tester.tap(find.text('Add skill'));
      await tester.pumpAndSettle();

      expect(find.text('Edit skills'), findsOneWidget);
      expect(find.text('2 chosen'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'React'), findsOneWidget);
      // Same 44 dp height as the Profile tags; tap targets stay 48 dp.
      double chipHeight(Finder chip) => tester
          .getSize(
            find.descendant(of: chip, matching: find.byType(Material)).first,
          )
          .height;
      expect(chipHeight(find.widgetWithText(InputChip, 'React')), 44);
      expect(chipHeight(find.widgetWithText(FilterChip, 'React')), 44);
      expect(chipHeight(find.widgetWithText(FilterChip, 'Dart')), 44);

      await tester.tap(find.widgetWithText(InputChip, 'React'));
      await tester.enterText(find.byType(TextField), 'dock');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilterChip, 'Docker'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Docker'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Docker'))
            .selected,
        isTrue,
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Edit skills'), findsNothing);
      expect(profiles.profile?.skills, ['Flutter', 'Docker']);
      expect(find.widgetWithText(AppTag, 'Docker'), findsOneWidget);
      expect(find.widgetWithText(AppTag, 'React'), findsNothing);
    });

    testWidgets('a failed save keeps the sheet open with the message', (
      tester,
    ) async {
      profiles
        ..profile = const UserProfile(skills: ['Flutter'])
        ..saveError = const AppException(
          AppErrorKind.network,
          'We could not save your changes. Check your connection and try '
          'again.',
        );
      await pumpProfile(tester);
      await scrollTo(tester, find.text('Add skill'));
      await tester.tap(find.text('Add skill'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Edit skills'), findsOneWidget);
      expect(
        find.text(
          'We could not save your changes. Check your connection and try '
          'again.',
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('Update preferences sheet saves chips and a quick location', (
    tester,
  ) async {
    await pumpProfile(tester);
    await scrollTo(tester, find.text('Update'));
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();

    expect(find.text('Update preferences'), findsOneWidget);
    expect(find.text('TARGET ROLES'), findsOneWidget);
    expect(
      find.widgetWithText(FilterChip, 'QA / Tester Intern'),
      findsOneWidget,
    );
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    for (final chip in ['Frontend Intern', 'Hybrid']) {
      expect(
        tester
            .getSize(
              find
                  .descendant(
                    of: find.widgetWithText(FilterChip, chip),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .height,
        44,
        reason: chip,
      );
    }
    await tester.tap(find.widgetWithText(FilterChip, 'Mobile Intern'));
    await tester.tap(find.widgetWithText(FilterChip, 'Remote'));
    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Da Nang'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Da Nang'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Da Nang'), findsOneWidget);
    // Quick select: 36 dp, outline without a check (the field shows the city).
    final quick = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Da Nang'),
    );
    expect(quick.selected, isTrue);
    expect(quick.showCheckmark, isFalse);
    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: find.widgetWithText(FilterChip, 'Da Nang'),
                  matching: find.byType(Material),
                )
                .first,
          )
          .height,
      36,
    );

    await tester.tap(find.text('Save preferences'));
    await tester.pumpAndSettle();

    expect(
      profiles.profile?.preferences,
      const InternshipPreferences(
        targetRoles: [TargetRole.mobile],
        workModes: [WorkMode.remote],
        location: 'Da Nang',
      ),
    );
    await scrollTo(tester, find.text('Da Nang'));
    expect(find.widgetWithText(AppTag, 'Mobile Intern'), findsOneWidget);
  });

  group('CV library', () {
    testWidgets('first upload: choose a PDF, add it, the library shows it', (
      tester,
    ) async {
      picker.next = PickedDocument(name: 'Lan_CV.pdf', bytes: pdfBytes(4096));
      await pumpProfile(tester);
      await scrollTo(tester, find.text('Add CV'));
      await tester.tap(find.text('Add CV'));
      await tester.pumpAndSettle();

      expect(find.text('Add a CV to your library'), findsOneWidget);
      expect(find.text('Choose a PDF file'), findsOneWidget);
      final add = find.widgetWithText(AppButton, 'Add CV').last;
      expect(tester.widget<AppButton>(add).onPressed, isNull);

      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();
      expect(find.text('Selected for update'), findsOneWidget);
      expect(find.text('Lan_CV.pdf'), findsOneWidget);
      expect(find.text('4 KB · PDF'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Add CV').last);
      await tester.pumpAndSettle();

      expect(find.text('Choose a PDF file'), findsNothing);
      expect(storage.uploadedNames, ['Lan_CV.pdf']);
      expect(find.text('Lan_CV.pdf'), findsOneWidget);
      expect(find.text('1 file'), findsOneWidget);
      expect(profiles.cvs.single.fileName, 'Lan_CV.pdf');
      expect(profiles.defaultCvId, profiles.cvs.single.id);
      expect(analytics.events, contains('cv_library_change'));
    });

    testWidgets('add: an upload error is recoverable and keeps the library', (
      tester,
    ) async {
      final existing = CvFile(
        id: 'cv-existing',
        fileName: 'Minh_CV.pdf',
        url: 'https://storage.example/cvs/existing.pdf',
        storagePath: 'cvs/uid-123/existing.pdf',
        sizeBytes: 2048,
        uploadedAt: DateTime(2026, 10, 1),
      );
      profiles
        ..cvs.add(existing)
        ..defaultCvId = existing.id
        ..profile = UserProfile(cv: existing, defaultCvId: existing.id);
      picker.next = PickedDocument(name: 'new.pdf', bytes: pdfBytes());
      storage.error = const AppException(
        AppErrorKind.network,
        'We could not upload the file. Check your connection and try again.',
      );
      await pumpProfile(tester);
      await scrollTo(tester, find.text('Add CV'));
      await tester.tap(find.text('Add CV'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Add CV').last);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'We could not upload the file. Check your connection and try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('new.pdf'), findsOneWidget);
      expect(profiles.cvs, hasLength(1));

      storage.error = null;
      await tester.tap(find.widgetWithText(AppButton, 'Add CV').last);
      await tester.pumpAndSettle();
      expect(find.text('Choose a PDF file'), findsNothing);
      expect(profiles.cvs, hasLength(2));
      await scrollTo(tester, find.text('2 files'));
      expect(find.text('Minh_CV.pdf'), findsOneWidget);
      expect(find.text('new.pdf'), findsOneWidget);
      expect(profiles.defaultCvId, existing.id);
    });

    testWidgets('Set as default moves the badge and the mirror', (
      tester,
    ) async {
      final first = CvFile(
        id: 'cv-first',
        fileName: 'First_CV.pdf',
        url: 'https://storage.example/cvs/first.pdf',
        storagePath: 'cvs/uid-123/first.pdf',
        sizeBytes: 2048,
        uploadedAt: DateTime(2026, 10, 1),
      );
      final second = CvFile(
        id: 'cv-second',
        fileName: 'Second_CV.pdf',
        url: 'https://storage.example/cvs/second.pdf',
        storagePath: 'cvs/uid-123/second.pdf',
        sizeBytes: 2048,
        uploadedAt: DateTime(2026, 10, 2),
      );
      profiles
        ..cvs.addAll([second, first])
        ..defaultCvId = second.id
        ..profile = UserProfile(cv: second, defaultCvId: second.id);
      await pumpProfile(tester);
      await scrollTo(tester, find.byTooltip('CV actions').last);
      await tester.tap(find.byTooltip('CV actions').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Set as default'));
      await tester.pumpAndSettle();

      expect(profiles.defaultCvId, first.id);
      expect(profiles.profile?.cv?.fileName, 'First_CV.pdf');
      expect(profiles.writes, contains('cv setDefault'));
    });

    testWidgets('Remove asks first, then removes and deletes the file', (
      tester,
    ) async {
      final cv = CvFile(
        id: 'cv-remove',
        fileName: 'Old_CV.pdf',
        url: 'https://storage.example/cvs/old.pdf',
        storagePath: 'cvs/uid-123/old.pdf',
        sizeBytes: 2048,
        uploadedAt: DateTime(2026, 10, 1),
      );
      profiles
        ..cvs.add(cv)
        ..defaultCvId = cv.id
        ..profile = UserProfile(cv: cv, defaultCvId: cv.id);
      await pumpProfile(tester);
      await scrollTo(tester, find.byTooltip('CV actions'));
      await tester.tap(find.byTooltip('CV actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();

      expect(find.text('Remove this CV?'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, 'Remove'));
      await tester.pumpAndSettle();

      expect(profiles.cvs, isEmpty);
      expect(storage.deletedPaths, [cv.storagePath]);
      expect(profiles.writes, contains('cv remove'));
    });

    testWidgets('a CV used by a submitted application keeps its file', (
      tester,
    ) async {
      final cv = CvFile(
        id: 'cv-used',
        fileName: 'Used_CV.pdf',
        url: 'https://storage.example/cvs/used.pdf',
        storagePath: 'cvs/uid-123/used.pdf',
        sizeBytes: 2048,
        uploadedAt: DateTime(2026, 10, 1),
      );
      profiles
        ..cvs.add(cv)
        ..defaultCvId = cv.id
        ..profile = UserProfile(cv: cv, defaultCvId: cv.id);
      applications.cvPaths.add(cv.storagePath);
      await pumpProfile(tester);
      await scrollTo(tester, find.byTooltip('CV actions'));
      await tester.tap(find.byTooltip('CV actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Remove'));
      await tester.pumpAndSettle();

      expect(profiles.cvs, isEmpty);
      expect(storage.deletedPaths, isEmpty);
      expect(analytics.parameters['cv_library_change'], {
        'action': 'remove',
        'cv_count': 0,
        'kept_file': 1,
      });
    });
  });

  group('Edit profile', () {
    Future<void> openEdit(WidgetTester tester, {double width = 360}) async {
      await pumpProfile(tester, width: width);
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();
    }

    /// The text input of the [AppTextField] labelled [label].
    Finder field(String label) => find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(AppTextField),
      ),
      matching: find.byType(TextField),
    );

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.scrollUntilVisible(finder, 200, scrollable: scrollable());
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    for (final width in checkWidths) {
      testWidgets('frame sections, prefilled from Google, at $width dp', (
        tester,
      ) async {
        await openEdit(tester, width: width);

        expect(
          find.text('Your photo comes from your Google account.'),
          findsOneWidget,
        );
        expect(find.text('Academic & personal details'), findsOneWidget);
        expect(find.text('Full name, required'), findsOneWidget);
        expect(find.text('Headline, required'), findsOneWidget);
        expect(find.widgetWithText(TextField, 'Test Student'), findsOneWidget);
        expect(find.byTooltip('Clear full name'), findsOneWidget);
        await tester.ensureVisible(find.text('Contact & location'));
        expect(
          find.widgetWithText(TextField, 'student@example.com'),
          findsOneWidget,
        );
        expect(find.text('From your Google account'), findsOneWidget);
        await tester.ensureVisible(find.text('Short bio / introduction'));
        await tester.pumpAndSettle();
        expect(find.text('0/300'), findsOneWidget);
        expect(find.text('VNU V-Career Sync Enabled'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('every tap target is at least 48 dp', (tester) async {
      setScreenSize(tester, height: 2400);
      await pumpProfile(tester, height: 2400);
      await tester.tap(find.text('Edit profile'));
      await tester.pumpAndSettle();
      expect(find.text('Save changes'), findsOneWidget);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('validation messages appear next to the fields', (
      tester,
    ) async {
      await openEdit(tester);
      await tester.tap(find.byTooltip('Clear full name'));
      await tester.enterText(field('Phone number'), '123');
      await tapVisible(tester, find.text('Save changes'));

      await tester.ensureVisible(find.text('Full name, required'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your full name to continue.'), findsOneWidget);
      expect(find.text('Enter a headline to continue.'), findsOneWidget);
      await tester.ensureVisible(field('Phone number'));
      expect(
        find.text('Enter a valid phone number, e.g. 0908 123 456.'),
        findsOneWidget,
      );
      expect(profiles.writes, isEmpty);
    });

    testWidgets('academic standing picker fills the field', (tester) async {
      await openEdit(tester);
      await tapVisible(tester, field('Academic standing & graduation'));

      expect(find.text('Academic standing'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilterChip, 'Year 3'));
      final graduation = '${DateTime.now().year + 1}';
      await tester.tap(find.widgetWithText(FilterChip, graduation));
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(TextField, 'Year 3 · Graduating $graduation'),
        findsOneWidget,
      );
    });

    testWidgets('graduation years scroll to the stored year on open', (
      tester,
    ) async {
      final stored = DateTime.now().year + 7;
      profiles.profile = UserProfile(
        details: ProfileDetails(graduationYear: stored),
      );
      await openEdit(tester);
      await tapVisible(tester, field('Academic standing & graduation'));

      final chip = find.widgetWithText(FilterChip, '$stored');
      expect(tester.widget<FilterChip>(chip).selected, isTrue);
      final rect = tester.getRect(chip);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(360));
      expect(
        find.widgetWithText(FilterChip, '${DateTime.now().year}'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(
          FilterChip,
          '${DateTime.now().year + EditProfileViewModel.graduationYearsAhead}',
        ),
        findsOneWidget,
      );
    });

    testWidgets('save returns to Profile with the new details', (tester) async {
      await openEdit(tester);
      await tester.enterText(
        field('Headline, required'),
        'Software Engineering Student',
      );
      await tester.enterText(field('University / institution'), 'HCMUT');
      await tester.enterText(
        field('Major / degree program'),
        'Computer Science',
      );
      await tapVisible(tester, field('Academic standing & graduation'));
      await tester.tap(find.widgetWithText(FilterChip, 'Year 2'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(field('Location / current city'));
      await tester.enterText(field('Location / current city'), 'Thu Duc');
      await tapVisible(tester, find.text('Save changes'));

      expect(find.text('Year 2 · Computer Science'), findsOneWidget);
      expect(find.text('HCMUT'), findsOneWidget);
      expect(
        profiles.profile?.details.headline,
        'Software Engineering Student',
      );
      expect(profiles.profile?.details.city, 'Thu Duc');
      expect(analytics.events, contains('profile_update'));
    });

    testWidgets('Cancel with unsaved changes asks before discarding', (
      tester,
    ) async {
      await openEdit(tester);
      await tester.enterText(field('Major / degree program'), 'Data Science');
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Discard your changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Full name, required'), findsOneWidget);

      // The app-bar Cancel asks the same question.
      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Edit profile'), findsOneWidget);
      expect(find.text('Full name, required'), findsNothing);
      expect(profiles.writes, isEmpty);
    });

    testWidgets('back without changes leaves straight away', (tester) async {
      await openEdit(tester);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Discard your changes?'), findsNothing);
      expect(find.text('Full name, required'), findsNothing);
    });
  });
}
