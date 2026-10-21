import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/features/home/viewmodels/home_viewmodel.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/remote_config_service.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeInternshipService internships;
  late FakeRemoteConfigService remoteConfig;
  late ProviderContainer container;

  setUp(() {
    internships = FakeInternshipService();
    remoteConfig = FakeRemoteConfigService();
    container = ProviderContainer.test(
      overrides: [
        internshipServiceProvider.overrideWithValue(internships),
        remoteConfigServiceProvider.overrideWithValue(remoteConfig),
      ],
    );
  });

  tearDown(() => remoteConfig.dispose());

  HomeViewModel listen() {
    // Keep the auto-dispose provider alive, as the screen would.
    container.listen(homeViewModelProvider, (_, _) {});
    return container.read(homeViewModelProvider.notifier);
  }

  HomeState read() => container.read(homeViewModelProvider);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  HomeFeed feed() => (read().feed as ViewData<HomeFeed>).data;

  test('starts loading and searches IT internships once', () async {
    internships.results = [testInternship('1')];
    listen();
    expect(read().feed, isA<ViewLoading<HomeFeed>>());
    expect(read().selectedSkill, isNull);

    await settle();
    expect(read().feed, isA<ViewData<HomeFeed>>());
    expect(internships.keywords, ['IT']);
  });

  test(
    'splits one page by home_recommended_limit, the rest newest first',
    () async {
      remoteConfig.values[RemoteConfigKeys.homeRecommendedLimit] = 2;
      internships.results = [
        testInternship('1', postedText: '5 days ago'),
        testInternship('2', postedText: '1 day ago'),
        testInternship('3', postedText: '3 days ago'),
        testInternship('4'),
        testInternship('5', postedText: '10 hours ago'),
      ];
      listen();
      await settle();

      expect(feed().recommended.map((i) => i.jobId), ['job-1', 'job-2']);
      expect(feed().recent.map((i) => i.jobId), ['job-5', 'job-3', 'job-4']);
    },
  );

  test('a Remote Config update re-splits without another search', () async {
    internships.results = [for (var i = 1; i <= 6; i++) testInternship('$i')];
    listen();
    await settle();
    expect(feed().recommended, hasLength(5));

    remoteConfig.publish(RemoteConfigKeys.homeRecommendedLimit, 3);
    await settle();
    expect(feed().recommended, hasLength(3));
    expect(feed().recent, hasLength(3));
    expect(internships.keywords, hasLength(1));
  });

  test('no results is the empty state', () async {
    listen();
    await settle();
    expect(read().feed, isA<ViewEmpty<HomeFeed>>());
  });

  test('a failed search is the error state; Retry searches again', () async {
    internships.error = const AppException(
      AppErrorKind.network,
      'We could not load internships. Check your connection and try again.',
    );
    final vm = listen();
    await settle();
    final error = read().feed as ViewError<HomeFeed>;
    expect(error.error.kind, AppErrorKind.network);

    internships
      ..error = null
      ..results = [testInternship('1')];
    await vm.retry();
    expect(read().feed, isA<ViewData<HomeFeed>>());
    expect(internships.keywords, ['IT', 'IT']);
  });

  test('Retry is ignored while loading', () async {
    internships.gate = Completer<void>();
    final vm = listen();
    await settle();
    unawaited(vm.retry());
    unawaited(vm.retry());
    expect(internships.keywords, ['IT']);
    internships.gate!.complete();
  });

  test('selecting a skill searches it; selecting it again clears it', () async {
    final vm = listen();
    await settle();

    final loading = vm.selectSkill('Flutter');
    expect(read().selectedSkill, 'Flutter');
    expect(read().feed, isA<ViewLoading<HomeFeed>>());
    await loading;
    expect(internships.keywords.last, 'Flutter');

    await vm.selectSkill('Flutter');
    expect(read().selectedSkill, isNull);
    expect(internships.keywords.last, 'IT');
  });

  test('only the latest skill updates the lists', () async {
    final vm = listen();
    await settle();

    final flutterGate = Completer<void>();
    internships
      ..gate = flutterGate
      ..results = [testInternship('flutter')];
    final slowFlutter = vm.selectSkill('Flutter');

    internships
      ..gate = null
      ..results = [testInternship('react')];
    await vm.selectSkill('React');

    // The Flutter answer arrives last and must be ignored.
    flutterGate.complete();
    await slowFlutter;
    expect(read().selectedSkill, 'React');
    expect(feed().recommended.single.jobId, 'job-react');
  });
}
