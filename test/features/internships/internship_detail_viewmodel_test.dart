import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/features/internships/viewmodels/internship_detail_viewmodel.dart';
import 'package:internly/models/internship_application.dart';
import 'package:internly/models/user_profile.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/remote_config_service.dart';
import 'package:internly/services/saved_internship_service.dart';
import 'package:internly/services/user_profile_service.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeInternshipService internships;
  late FakeRemoteConfigService remoteConfig;
  late FakeAnalyticsService analytics;
  late FakeUserProfileService profiles;
  late FakeSavedInternshipService saved;
  late FakeApplicationService applications;
  late ProviderContainer container;

  final listing = testInternship(
    '1',
    title: 'Flutter Developer Intern',
    companyName: 'FPT Software',
    skills: const ['Flutter', 'Dart', 'Git', 'REST API'],
  );
  final args = (internshipKey: listing.key, source: 'home');

  setUp(() {
    internships = FakeInternshipService();
    remoteConfig = FakeRemoteConfigService();
    analytics = FakeAnalyticsService();
    profiles = FakeUserProfileService(
      profile: const UserProfile(skills: ['Flutter', 'Dart', 'Git']),
    );
    saved = FakeSavedInternshipService();
    applications = FakeApplicationService();
    container = ProviderContainer.test(
      overrides: [
        internshipServiceProvider.overrideWithValue(internships),
        remoteConfigServiceProvider.overrideWithValue(remoteConfig),
        analyticsServiceProvider.overrideWithValue(analytics),
        currentUserIdProvider.overrideWithValue(testUser.uid),
        userProfileServiceProvider.overrideWithValue(profiles),
        savedInternshipServiceProvider.overrideWithValue(saved),
        applicationServiceProvider.overrideWithValue(applications),
      ],
    );
  });

  tearDown(() async {
    await internships.dispose();
    await profiles.dispose();
    await saved.dispose();
    await applications.dispose();
    remoteConfig.dispose();
  });

  InternshipDetailViewModel listen() {
    // Keep the auto-dispose provider alive, as the screen would.
    container.listen(internshipDetailViewModelProvider(args), (_, _) {});
    return container.read(internshipDetailViewModelProvider(args).notifier);
  }

  ViewState<InternshipDetail> read() =>
      container.read(internshipDetailViewModelProvider(args));

  InternshipDetail data() => (read() as ViewData<InternshipDetail>).data;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('starts loading, then shows the listing with its skill match', () async {
    internships.byKey[listing.key] = listing;
    listen();
    expect(read(), isA<ViewLoading<InternshipDetail>>());

    await settle();
    expect(internships.watchByKeyCalls, 1);
    expect(data().internship.title, 'Flutter Developer Intern');
    final match = data().skillMatch!;
    expect(match.matched, ['Flutter', 'Dart', 'Git']);
    expect(match.missing, ['REST API']);
    expect(match.percent, 75);
  });

  test('logs view_internship once with the planned parameters', () async {
    internships.byKey[listing.key] = listing;
    listen();
    await settle();
    internships.emitOne(listing);
    await settle();

    expect(analytics.events.where((e) => e == 'view_internship'), hasLength(1));
    expect(analytics.parameters['view_internship'], {
      'internship_id': listing.key,
      'internship_title': 'Flutter Developer Intern',
      'company_name': 'FPT Software',
      'source': 'home',
    });
  });

  test('a listing that no longer exists is empty, not an error', () async {
    listen();
    await settle();
    expect(read(), isA<ViewEmpty<InternshipDetail>>());
    expect(analytics.events, isNot(contains('view_internship')));
  });

  test('an expired listing still opens from its saved copy', () async {
    saved.seed([listing]);
    listen();
    await settle();
    await settle();
    expect(data().internship.key, listing.key);
  });

  test(
    'an application to another synced copy of the job counts (CR-07)',
    () async {
      internships.byKey[listing.key] = listing;
      applications.results = [
        InternshipApplication(
          jobKey: 'other-copy-key',
          title: listing.title,
          companyName: listing.companyName,
          appliedAt: DateTime(2026, 11, 1),
          status: ApplicationStatus.submitted,
        ),
      ];
      listen();
      await settle();
      await settle();

      expect(data().application?.jobKey, 'other-copy-key');
    },
  );

  test('unsaving an expired listing keeps it on screen', () async {
    saved.seed([listing]);
    listen();
    await settle();
    await settle();
    expect(data().internship.key, listing.key);

    await saved.remove(listing.key);
    await settle();
    expect(read(), isA<ViewData<InternshipDetail>>());
  });

  test('a listing deleted while open becomes empty', () async {
    internships.byKey[listing.key] = listing;
    listen();
    await settle();
    expect(read(), isA<ViewData<InternshipDetail>>());

    internships.emitOne(null);
    await settle();
    expect(read(), isA<ViewEmpty<InternshipDetail>>());
  });

  test('a load error shows its message; retry listens again', () async {
    internships.byKeyError = const AppException(
      AppErrorKind.network,
      'We could not load this internship. Check your connection and try '
      'again.',
    );
    final viewModel = listen();
    await settle();
    final state = read();
    expect(state, isA<ViewError<InternshipDetail>>());
    expect(
      (state as ViewError<InternshipDetail>).error.message,
      startsWith('We could not load this internship'),
    );

    internships
      ..byKeyError = null
      ..byKey[listing.key] = listing;
    viewModel.retry();
    expect(read(), isA<ViewLoading<InternshipDetail>>());
    await settle();
    expect(internships.watchByKeyCalls, 2);
    expect(read(), isA<ViewData<InternshipDetail>>());
  });

  test('retry is ignored while the listing is still loading', () async {
    internships.byKeyGate = Completer<void>();
    final viewModel = listen();
    await settle();
    viewModel.retry();
    await settle();
    expect(internships.watchByKeyCalls, 1);
    expect(read(), isA<ViewLoading<InternshipDetail>>());
    internships.byKeyGate!.complete();
  });

  test(
    'Remote Config cv_match_enabled hides and shows the card live',
    () async {
      remoteConfig.values[RemoteConfigKeys.cvMatchEnabled] = false;
      internships.byKey[listing.key] = listing;
      listen();
      await settle();
      expect(data().skillMatch, isNull);

      remoteConfig.publish(RemoteConfigKeys.cvMatchEnabled, true);
      await settle();
      expect(data().skillMatch, isNotNull);
    },
  );

  test('the match follows Profile skill changes', () async {
    internships.byKey[listing.key] = listing;
    listen();
    await settle();
    expect(data().skillMatch!.percent, 75);

    await profiles.updateSkills(testUser.uid, [
      'Flutter',
      'Dart',
      'Git',
      'REST API',
    ]);
    await settle();
    expect(data().skillMatch!.percent, 100);
  });

  test('no card when the listing mentions no known skill', () async {
    final noSkills = testInternship('2');
    final otherArgs = (internshipKey: noSkills.key, source: 'saved');
    internships.byKey[noSkills.key] = noSkills;
    container.listen(internshipDetailViewModelProvider(otherArgs), (_, _) {});
    await settle();
    final state = container.read(
      internshipDetailViewModelProvider(otherArgs),
    ) as ViewData<InternshipDetail>;
    expect(state.data.skillMatch, isNull);
  });

  test('a profile that fails to load hides only the card', () async {
    profiles.loadError = const AppException(
      AppErrorKind.network,
      'Profile unavailable.',
    );
    internships.byKey[listing.key] = listing;
    listen();
    await settle();
    expect(data().internship.key, listing.key);
    expect(data().skillMatch, isNull);
  });

  test('an application for this listing marks it as applied', () async {
    applications.results = [
      testApplication('1', status: ApplicationStatus.interview),
      testApplication('9'),
    ];
    internships.byKey[listing.key] = listing;
    listen();
    await settle();

    expect(data().application?.jobKey, listing.key);
    expect(data().application?.status, ApplicationStatus.interview);
  });

  test(
    'an application tracked while the detail is open appears live',
    () async {
      internships.byKey[listing.key] = listing;
      listen();
      await settle();
      expect(data().application, isNull);

      applications.emit([testApplication('1')]);
      await settle();
      expect(data().application?.status, ApplicationStatus.submitted);
    },
  );

  test('failing applications leave the listing open as not applied', () async {
    applications.error = const AppException(
      AppErrorKind.network,
      'Applications unavailable.',
    );
    internships.byKey[listing.key] = listing;
    listen();
    await settle();

    expect(data().internship.key, listing.key);
    expect(data().application, isNull);
  });
}
