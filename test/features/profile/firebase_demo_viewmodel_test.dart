import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/features/profile/viewmodels/firebase_demo_viewmodel.dart';
import 'package:internly/services/crashlytics_service.dart';
import 'package:internly/services/remote_config_service.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeRemoteConfigService remoteConfig;
  late FakeCrashlyticsService crashlytics;

  setUp(() {
    remoteConfig = FakeRemoteConfigService();
    crashlytics = FakeCrashlyticsService();
  });

  tearDown(() {
    remoteConfig.dispose();
  });

  ProviderContainer build() {
    final container = ProviderContainer.test(
      overrides: [
        remoteConfigServiceProvider.overrideWithValue(remoteConfig),
        crashlyticsServiceProvider.overrideWithValue(crashlytics),
      ],
    );
    container.listen(firebaseDemoViewModelProvider, (_, _) {});
    return container;
  }

  FirebaseDemoState read(ProviderContainer container) =>
      container.read(firebaseDemoViewModelProvider);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('starts from the in-app defaults', () {
    final state = read(build());

    expect(state.config[RemoteConfigKeys.homeRecommendedLimit]?.value, '5');
    expect(state.config[RemoteConfigKeys.homeRecentLimit]?.value, '10');
    expect(state.config[RemoteConfigKeys.cvMatchEnabled]?.value, 'true');
    expect(state.config.values.map((entry) => entry.source).toSet(), {
      'default',
    });
  });

  test('follows Remote Config updates without a rebuild', () async {
    final container = build();

    remoteConfig.publish(RemoteConfigKeys.homeRecentLimit, 4);
    await settle();

    expect(
      read(container).config[RemoteConfigKeys.homeRecentLimit]?.value,
      '4',
    );
  });

  test('records one non-fatal error and clears the busy flag', () async {
    final container = build();

    final sent = await container
        .read(firebaseDemoViewModelProvider.notifier)
        .recordNonFatal();

    expect(sent, isTrue);
    expect(crashlytics.recordedErrors, hasLength(1));
    expect(read(container).isSendingNonFatal, isFalse);
  });

  test('repeated taps while sending record only one error', () async {
    final container = build();
    final viewModel = container.read(firebaseDemoViewModelProvider.notifier);

    final results = await Future.wait([
      viewModel.recordNonFatal(),
      viewModel.recordNonFatal(),
    ]);

    expect(results.where((sent) => sent), hasLength(1));
    expect(crashlytics.recordedErrors, hasLength(1));
  });

  test('the crash control calls Crashlytics only when invoked', () {
    final container = build();
    expect(crashlytics.crashCalls, 0);

    container.read(firebaseDemoViewModelProvider.notifier).crashForTesting();

    expect(crashlytics.crashCalls, 1);
  });
}
