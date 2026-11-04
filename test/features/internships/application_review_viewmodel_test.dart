import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/features/internships/viewmodels/application_review_viewmodel.dart';
import 'package:internly/features/internships/viewmodels/apply_form_viewmodel.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/models/user_profile.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/crashlytics_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/user_profile_service.dart';

import '../../helpers/fakes.dart';

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
  );
  final args = (internshipKey: listing.key, source: 'home');
  final cvFile = CvFile(
    fileName: 'Profile_CV.pdf',
    url: 'https://storage.example/cvs/profile.pdf',
    storagePath: 'cvs/uid-123/profile.pdf',
    sizeBytes: 420 * 1024,
    uploadedAt: DateTime(2026, 10, 14),
  );
  final session = ApplySession(
    cv: ApplyCv(cvFile, CvSource.profile),
    startedAt: DateTime.now().subtract(const Duration(seconds: 90)),
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

  /// A container with the Review ViewModel kept alive by a listener.
  ProviderContainer build({bool signedIn = true}) {
    final container = ProviderContainer.test(
      overrides: [
        internshipServiceProvider.overrideWithValue(internships),
        userProfileServiceProvider.overrideWithValue(profiles),
        applicationServiceProvider.overrideWithValue(applications),
        analyticsServiceProvider.overrideWithValue(analytics),
        crashlyticsServiceProvider.overrideWithValue(crashlytics),
        currentUserIdProvider.overrideWithValue(signedIn ? testUser.uid : null),
      ],
    );
    container.listen(applicationReviewViewModelProvider(args), (_, _) {});
    return container;
  }

  ApplicationReviewState read(ProviderContainer container) =>
      container.read(applicationReviewViewModelProvider(args));

  ApplicationReviewViewModel viewModel(ProviderContainer container) =>
      container.read(applicationReviewViewModelProvider(args).notifier);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('loads the listing', () async {
    final container = build();
    expect(read(container).internship, isA<ViewLoading<Internship>>());

    await settle();

    expect(read(container).internship, isA<ViewData<Internship>>());
  });

  test('nothing is written until the listing is known', () async {
    final container = build();

    expect(await viewModel(container).submit(session), isNull);
    expect(applications.created, isEmpty);
  });

  test('Submit snapshots the applicant and logs application_create', () async {
    final container = build();
    await settle();

    final submittedAt = await viewModel(container).submit(session);

    expect(submittedAt, isNotNull);
    expect(applications.created, hasLength(1));
    final created = applications.created.single;
    expect(created.internshipKey, listing.key);
    expect(created.title, 'Flutter Developer Intern');
    expect(created.companyName, 'FPT Software');
    expect(created.cvStoragePath, 'cvs/uid-123/profile.pdf');
    expect(created.applicant.fullName, 'Minh Nguyen');
    expect(created.applicant.email, 'minh@example.com');
    expect(created.applicant.phone, '0908 123 456');
    expect(created.applicant.university, 'HCMUT');
    expect(created.applicant.yearOfStudy, 3);
    expect(created.applicant.skills, ['Flutter', 'Dart']);
    expect(created.applicant.introduction, 'I build Flutter apps.');
    expect(read(container).submit, isA<AsyncData<void>>());

    final parameters = analytics.parameters['application_create']!;
    expect(parameters['internship_id'], listing.key);
    expect(parameters['cv_source'], 'profile');
    expect(parameters['duration_sec'], greaterThanOrEqualTo(89));
  });

  test(
    'the Profile keeps what was sent, so the next form is prefilled',
    () async {
      final container = build();
      await settle();

      await viewModel(container).submit(session);

      expect(profiles.writes, ['apply details', 'skills']);
      expect(profiles.profile?.details.fullName, 'Minh Nguyen');
      expect(profiles.profile?.details.university, 'HCMUT');
      expect(profiles.profile?.skills, ['Flutter', 'Dart']);
    },
  );

  test('a Profile sync failure still counts as submitted', () async {
    profiles.saveError = const AppException(
      AppErrorKind.network,
      'We could not save your changes.',
    );
    final container = build();
    await settle();

    final submittedAt = await viewModel(container).submit(session);

    expect(submittedAt, isNotNull);
    expect(applications.created, hasLength(1));
    expect(crashlytics.recordedErrors, isNotEmpty);
    expect(read(container).submit, isA<AsyncData<void>>());
  });

  test(
    'a failed write stays on the screen; submitting again succeeds',
    () async {
      applications.createError = const AppException(
        AppErrorKind.network,
        'We could not submit your application. Check your connection and try '
        'again.',
      );
      final container = build();
      await settle();

      expect(await viewModel(container).submit(session), isNull);
      final failure = read(container).submit;
      expect(failure, isA<AsyncError<void>>());
      expect((failure as AsyncError<void>).error, isA<AppException>());
      expect(
        (failure.error as AppException).message,
        'We could not submit your application. Check your connection and try '
        'again.',
      );
      expect(analytics.events, isNot(contains('application_create')));

      applications.createError = null;
      expect(await viewModel(container).submit(session), isNotNull);
      expect(applications.created, hasLength(1));
    },
  );

  test('signed out: no write and a permission message', () async {
    final container = build(signedIn: false);
    await settle();

    expect(await viewModel(container).submit(session), isNull);
    expect(applications.created, isEmpty);
    final failure = read(container).submit as AsyncError<void>;
    expect((failure.error as AppException).kind, AppErrorKind.permissionDenied);
  });

  test('a second tap while the write runs is ignored', () async {
    applications.createGate = Completer<void>();
    final container = build();
    await settle();

    final first = viewModel(container).submit(session);
    await settle();
    expect(read(container).submit.isLoading, isTrue);

    expect(await viewModel(container).submit(session), isNull);
    expect(applications.created, isEmpty);

    applications.createGate!.complete();
    expect(await first, isNotNull);
    expect(applications.created, hasLength(1));
  });

  test(
    'a listing load error shows the error state; Retry listens again',
    () async {
      internships.byKeyError = const AppException(
        AppErrorKind.network,
        'We could not reach Internly.',
      );
      final container = build();
      await settle();
      expect(read(container).internship, isA<ViewError<Internship>>());

      internships.byKeyError = null;
      viewModel(container).retry();
      await settle();
      expect(read(container).internship, isA<ViewData<Internship>>());
      expect(internships.watchByKeyCalls, 2);
    },
  );
}
