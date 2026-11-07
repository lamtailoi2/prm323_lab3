import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/features/internships/viewmodels/apply_compose_viewmodel.dart';
import 'package:internly/models/app_user.dart';
import 'package:internly/models/internship_application.dart';
import 'package:internly/models/user_profile.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/cover_letter_service.dart';
import 'package:internly/services/external_link_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/remote_config_service.dart';
import 'package:internly/services/user_profile_service.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeInternshipService internships;
  late FakeUserProfileService profiles;
  late FakeApplicationService applications;
  late FakeCoverLetterService coverLetters;
  late FakeExternalLinkService links;
  late FakeAnalyticsService analytics;
  late FakeRemoteConfigService remoteConfig;
  late ProviderContainer container;

  final listing = testInternship(
    '1',
    title: 'Flutter Developer Intern',
    companyName: 'FPT Software',
    description:
        'Send your CV to hr@fpt.com.vn. Flutter and Dart are required.',
    skills: const ['Flutter', 'Dart'],
  );
  final args = (internshipKey: listing.key, source: 'search');
  final profileCv = CvFile(
    fileName: 'Profile_CV.pdf',
    url: 'https://storage.example/cvs/profile.pdf',
    storagePath: 'cvs/uid-123/profile.pdf',
    sizeBytes: 420 * 1024,
    uploadedAt: DateTime(2026, 10, 14),
  );

  List<Override> overridesFor(AppUser? user) => [
    internshipServiceProvider.overrideWithValue(internships),
    userProfileServiceProvider.overrideWithValue(profiles),
    applicationServiceProvider.overrideWithValue(applications),
    coverLetterServiceProvider.overrideWithValue(coverLetters),
    externalLinkServiceProvider.overrideWithValue(links),
    analyticsServiceProvider.overrideWithValue(analytics),
    remoteConfigServiceProvider.overrideWithValue(remoteConfig),
    authStateChangesProvider.overrideWith(
      (ref) => Stream<AppUser?>.value(user),
    ),
  ];

  setUp(() {
    internships = FakeInternshipService()..byKey[listing.key] = listing;
    profiles = FakeUserProfileService(
      profile: UserProfile(
        cv: profileCv,
        details: const ProfileDetails(
          fullName: 'Minh Nguyen',
          phone: '0908 123 456',
          university: 'HCMUT',
          yearOfStudy: 3,
        ),
        skills: const <String>['Flutter', 'Dart'],
      ),
    );
    applications = FakeApplicationService();
    coverLetters = FakeCoverLetterService();
    links = FakeExternalLinkService();
    analytics = FakeAnalyticsService();
    remoteConfig = FakeRemoteConfigService();
    container = ProviderContainer.test(overrides: overridesFor(testUser));
  });

  tearDown(() async {
    await internships.dispose();
    await profiles.dispose();
    await applications.dispose();
    remoteConfig.dispose();
  });

  ApplyComposeViewModel listen([ProviderContainer? scope]) {
    final target = scope ?? container;
    target.listen(applyComposeViewModelProvider(args), (_, _) {});
    return target.read(applyComposeViewModelProvider(args).notifier);
  }

  ApplyComposeState read([ProviderContainer? scope]) =>
      (scope ?? container).read(applyComposeViewModelProvider(args));

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('logs apply_start and drafts from the job post', () async {
    listen();
    await settle();

    expect(
      analytics.events.where((event) => event == 'apply_start'),
      hasLength(1),
    );
    expect(analytics.parameters['apply_start'], {
      'internship_id': listing.key,
      'source': 'search',
    });

    expect(coverLetters.calls, 1);
    expect(coverLetters.internshipKeys.single, listing.key);
    expect(coverLetters.studentNames.single, 'Minh Nguyen');
    expect(coverLetters.storagePaths.single, profileCv.storagePath);

    expect(read().recipientEmail, 'hr@fpt.com.vn');
    expect(read().subject, coverLetters.draft.subject);
    expect(read().body, coverLetters.draft.body);
    expect(read().draftVersion, 1);
    expect(analytics.parameters['cover_letter_generate'], {
      'internship_id': listing.key,
      'source': 'ai',
    });
  });

  test('opens the draft in the mail app and logs it', () async {
    final viewModel = listen();
    await settle();

    await viewModel.openEmail();

    expect(links.openedEmails, hasLength(1));
    final uri = links.openedEmails.single;
    expect(uri.scheme, 'mailto');
    expect(uri.path, 'hr@fpt.com.vn');
    expect(
      uri.query,
      contains(Uri.encodeComponent(coverLetters.draft.subject)),
    );
    expect(read().emailOpened, isTrue);
    expect(analytics.parameters['cover_letter_open_email'], {
      'internship_id': listing.key,
      'has_recipient': 'yes',
    });
  });

  test('rejects an invalid recipient without opening the mail app', () async {
    final viewModel = listen();
    await settle();

    viewModel.setRecipient('not-an-email');
    await viewModel.openEmail();

    expect(links.openedEmails, isEmpty);
    expect(read().recipientError, 'Enter a valid email address.');
    expect(read().emailOpened, isFalse);
  });

  test('an empty recipient still opens a draft without a To', () async {
    internships.byKey[listing.key] = testInternship(
      '1',
      description: 'No address in this post.',
    );
    final viewModel = listen();
    await settle();

    viewModel.setRecipient('');
    await viewModel.openEmail();

    expect(links.openedEmails.single.path, '');
    expect(read().emailOpened, isTrue);
  });

  test(
    "I've sent it records the application with the letter and channel",
    () async {
      final viewModel = listen();
      await settle();

      final sent = await viewModel.markSent();

      expect(sent, isNotNull);
      final created = applications.created.single;
      expect(created.internshipKey, listing.key);
      expect(created.recipientEmail, 'hr@fpt.com.vn');
      expect(created.appliedVia, ApplicationChannel.email);
      expect(created.cvStoragePath, profileCv.storagePath);
      expect(created.cvSizeBytes, profileCv.sizeBytes);
      expect(created.applicant.fullName, 'Minh Nguyen');
      expect(created.applicant.email, 'student@example.com');
      expect(created.applicant.introduction, coverLetters.draft.body);
      expect(analytics.parameters['application_create'], {
        'internship_id': listing.key,
        'channel': 'email',
        'cv_source': 'profile',
        'duration_sec': 0,
      });
    },
  );

  test(
    'without a Profile CV it records the application without a CV',
    () async {
      profiles.profile = UserProfile(
        details: const ProfileDetails(fullName: 'Minh Nguyen'),
      );
      final viewModel = listen();
      await settle();

      final sent = await viewModel.markSent();

      expect(sent, isNotNull);
      expect(applications.created.single.cvStoragePath, isNull);
      expect(analytics.parameters['application_create']?['cv_source'], 'none');
    },
  );

  test('taps while the record is being written are ignored', () async {
    applications.createGate = Completer<void>();
    final viewModel = listen();
    await settle();

    final first = viewModel.markSent();
    await settle();
    expect(read().isSending, isTrue);
    expect(await viewModel.markSent(), isNull);

    applications.createGate!.complete();
    expect(await first, isNotNull);
    expect(applications.created, hasLength(1));
  });

  test('a failed draft keeps the screen usable and shows the error', () async {
    coverLetters.error = const AppException(AppErrorKind.network, 'Offline.');
    final viewModel = listen();
    await settle();

    expect(read().generate, isA<AsyncError<void>>());
    expect(read().body, isEmpty);

    viewModel.setBody('My own letter');
    expect(await viewModel.markSent(), isNotNull);
    expect(applications.created.single.applicant.introduction, 'My own letter');
  });

  test(
    'records nothing without a name in the Profile or the account',
    () async {
      profiles.profile = const UserProfile();
      final other = ProviderContainer.test(
        overrides: overridesFor(
          const AppUser(uid: 'uid-123', email: 'student@example.com'),
        ),
      );
      final viewModel = listen(other);
      await settle();

      expect(await viewModel.markSent(), isNull);
      expect(applications.created, isEmpty);
      final error = switch (read(other).send) {
        AsyncError<void>(:final error) when error is AppException => error,
        _ => null,
      };
      expect(
        error?.message,
        'Add your name in Profile to record this application.',
      );
    },
  );

  test('a later Profile snapshot never overwrites the typed letter', () async {
    final viewModel = listen();
    await settle();

    viewModel.setBody('My own letter');
    await profiles.updateSkills(testUser.uid, const <String>[
      'Flutter',
      'Dart',
      'Git',
    ]);
    await settle();

    expect(read().body, 'My own letter');
  });

  test('Regenerate keeps the address the student typed', () async {
    final viewModel = listen();
    await settle();

    viewModel.setRecipient('me@example.com');
    await viewModel.regenerate();

    expect(read().recipientEmail, 'me@example.com');
    expect(coverLetters.calls, 2);
  });

  test('a Profile load error still drafts from the listing', () async {
    profiles.loadError = const AppException(AppErrorKind.network, 'Offline.');
    listen();
    await settle();

    expect(read().profileError?.kind, AppErrorKind.network);
    expect(coverLetters.calls, 1);
    expect(coverLetters.studentNames.single, 'Test Student');
    expect(read().body, isNotEmpty);
  });

  test('buildSession carries the Profile CV, details and letter', () async {
    final viewModel = listen();
    await settle();

    final session = viewModel.buildSession();
    expect(session?.cv.file.storagePath, profileCv.storagePath);
    expect(session?.details.fullName, 'Minh Nguyen');
    expect(session?.introduction, coverLetters.draft.body);
  });

  test('buildSession is null without a CV', () async {
    profiles.profile = const UserProfile();
    final viewModel = listen();
    await settle();

    expect(viewModel.buildSession(), isNull);
  });
}
