import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/features/internships/viewmodels/apply_confirm_viewmodel.dart';
import 'package:internly/features/internships/viewmodels/apply_form_viewmodel.dart';
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

import '../../helpers/fakes.dart';

const _applyUrl = 'https://careers.example.com/apply/flutter-intern';

void main() {
  late FakeAuthService auth;
  late FakeInternshipService internships;
  late FakeUserProfileService profiles;
  late FakeSavedInternshipService saved;
  late FakeRemoteConfigService remoteConfig;
  late FakeExternalLinkService links;
  late FakeApplicationService applications;
  late FakeAnalyticsService analytics;
  late Internship listing;
  late ApplyFormArgs args;

  CvFile profileCv() => CvFile(
    fileName: 'Profile_CV.pdf',
    url: 'https://storage.example/cvs/profile.pdf',
    storagePath: 'cvs/uid-123/profile.pdf',
    sizeBytes: 420 * 1024,
    uploadedAt: DateTime(2026, 10, 14),
  );

  setUp(() {
    auth = FakeAuthService(initialUser: testUser);
    internships = FakeInternshipService();
    profiles = FakeUserProfileService(profile: UserProfile(cv: profileCv()));
    saved = FakeSavedInternshipService();
    remoteConfig = FakeRemoteConfigService();
    links = FakeExternalLinkService();
    applications = FakeApplicationService();
    analytics = FakeAnalyticsService();
    listing = testInternship(
      '1',
      title: 'Flutter Developer Intern',
      companyName: 'FPT Software',
      employerApplyUrl: _applyUrl,
    );
    internships.byKey[listing.key] = listing;
    args = (internshipKey: listing.key, source: 'home');
  });

  tearDown(() async {
    await auth.dispose();
    await internships.dispose();
    await profiles.dispose();
    await saved.dispose();
    await applications.dispose();
    remoteConfig.dispose();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer.test(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        currentUserIdProvider.overrideWithValue(testUser.uid),
        internshipServiceProvider.overrideWithValue(internships),
        userProfileServiceProvider.overrideWithValue(profiles),
        savedInternshipServiceProvider.overrideWithValue(saved),
        remoteConfigServiceProvider.overrideWithValue(remoteConfig),
        externalLinkServiceProvider.overrideWithValue(links),
        applicationServiceProvider.overrideWithValue(applications),
        analyticsServiceProvider.overrideWithValue(analytics),
      ],
    );
  }

  /// Keeps both auto-dispose providers alive and waits for the listing and
  /// profile streams the Confirm step reads.
  Future<ProviderContainer> loaded() async {
    final container = makeContainer();
    container.listen(applyFormViewModelProvider(args), (_, _) {});
    container.listen(applyConfirmViewModelProvider(args), (_, _) {});
    await pumpEventQueue();
    return container;
  }

  ApplyConfirmState stateOf(ProviderContainer container) =>
      container.read(applyConfirmViewModelProvider(args));

  ApplyConfirmViewModel viewModelOf(ProviderContainer container) =>
      container.read(applyConfirmViewModelProvider(args).notifier);

  test('opening the employer page waits for the return', () async {
    final container = await loaded();

    await viewModelOf(container).openEmployer(Uri.parse(_applyUrl));

    expect(stateOf(container).phase, ApplyConfirmPhase.awaitingReturn);
    expect(stateOf(container).returned, isFalse);
    expect(links.opened, [Uri.parse(_applyUrl)]);
  });

  test('a failed redirect can be retried', () async {
    links.error = const AppException(
      AppErrorKind.unknown,
      'No app on this device can open this file.',
    );
    final container = await loaded();

    await viewModelOf(container).openEmployer(Uri.parse(_applyUrl));
    expect(stateOf(container).phase, ApplyConfirmPhase.redirectFailed);
    expect(stateOf(container).error?.message, contains('No app'));

    links.error = null;
    viewModelOf(container).retry();
    await pumpEventQueue();

    expect(stateOf(container).phase, ApplyConfirmPhase.awaitingReturn);
    expect(links.opened, [Uri.parse(_applyUrl)]);
  });

  test('onReturned only changes the waiting state', () async {
    final container = await loaded();

    viewModelOf(container).onReturned();
    expect(stateOf(container).returned, isFalse);

    await viewModelOf(container).openEmployer(Uri.parse(_applyUrl));
    viewModelOf(container).onReturned();
    expect(stateOf(container).returned, isTrue);
  });

  test(
    'submitting records the application and logs application_create',
    () async {
      final container = await loaded();

      final recorded = await viewModelOf(container).submit();

      expect(recorded, isTrue);
      expect(stateOf(container).phase, ApplyConfirmPhase.saved);
      expect(applications.submissions, hasLength(1));
      expect(applications.submissions.single.jobKey, listing.key);
      expect(applications.submissions.single.title, listing.title);
      expect(applications.submissions.single.companyName, listing.companyName);
      expect(analytics.events, contains('application_create'));
      final parameters = analytics.parameters['application_create']!;
      expect(parameters['internship_id'], listing.key);
      expect(parameters['cv_source'], 'profile');
      expect(parameters['duration_sec'], isA<int>());
    },
  );

  test('a failed write can be retried', () async {
    applications.submitError = const AppException(
      AppErrorKind.network,
      'We could not save your application. Check your connection and try again.',
    );
    final container = await loaded();

    final recorded = await viewModelOf(container).submit();

    expect(recorded, isFalse);
    expect(stateOf(container).phase, ApplyConfirmPhase.saveFailed);
    expect(stateOf(container).error?.kind, AppErrorKind.network);
    expect(applications.submissions, isEmpty);

    applications.submitError = null;
    viewModelOf(container).retry();
    await pumpEventQueue();
    expect(stateOf(container).phase, ApplyConfirmPhase.saved);
    expect(applications.submissions, hasLength(1));
  });

  test('a repeated tap while saving writes once', () async {
    applications.submitGate = Completer<void>();
    final container = await loaded();

    final first = viewModelOf(container).submit();
    await pumpEventQueue();
    final second = await viewModelOf(container).submit();

    expect(second, isFalse);
    applications.submitGate!.complete();
    expect(await first, isTrue);
    expect(applications.submissions, hasLength(1));
  });

  test('without a CV nothing is written', () async {
    profiles.profile = const UserProfile();
    final container = await loaded();

    final recorded = await viewModelOf(container).submit();

    expect(recorded, isFalse);
    expect(stateOf(container).phase, ApplyConfirmPhase.ready);
    expect(applications.submissions, isEmpty);
    expect(analytics.events, isNot(contains('application_create')));
  });
}
