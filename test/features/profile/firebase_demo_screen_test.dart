import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/features/profile/screens/firebase_demo_screen.dart';
import 'package:internly/services/crashlytics_service.dart';
import 'package:internly/services/notification_service.dart';
import 'package:internly/services/remote_config_service.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/notification_fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeRemoteConfigService remoteConfig;
  late FakeCrashlyticsService crashlytics;
  late FakeNotificationService notifications;

  setUp(() {
    remoteConfig = FakeRemoteConfigService();
    crashlytics = FakeCrashlyticsService();
    notifications = FakeNotificationService();
  });

  tearDown(() async {
    remoteConfig.dispose();
    await notifications.dispose();
  });

  Future<void> pumpDemo(
    WidgetTester tester, {
    double width = 360,
    double height = 1400,
  }) async {
    setScreenSize(tester, width: width, height: height);
    final router = GoRouter(
      initialLocation: '/profile/firebase',
      routes: [
        GoRoute(
          path: '/profile/firebase',
          builder: (context, state) => const FirebaseDemoScreen(),
        ),
        GoRoute(
          path: '/profile/notifications',
          builder: (context, state) =>
              const Scaffold(body: Text('Notifications opened')),
        ),
        GoRoute(
          path: '/profile/export',
          builder: (context, state) =>
              const Scaffold(body: Text('Report export opened')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteConfigServiceProvider.overrideWithValue(remoteConfig),
          crashlyticsServiceProvider.overrideWithValue(crashlytics),
          notificationServiceProvider.overrideWithValue(notifications),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in checkWidths) {
    testWidgets('shows the values and test actions at $width dp', (
      tester,
    ) async {
      await pumpDemo(tester, width: width);

      expect(find.text('Firebase demo'), findsOneWidget);
      expect(find.text('Remote Config'), findsOneWidget);
      for (final key in [
        RemoteConfigKeys.homeRecommendedLimit,
        RemoteConfigKeys.homeRecentLimit,
        RemoteConfigKeys.cvMatchEnabled,
      ]) {
        expect(find.text(key), findsOneWidget);
      }
      expect(find.text('5 · In-app default'), findsOneWidget);
      expect(find.text('10 · In-app default'), findsOneWidget);
      expect(find.text('true · In-app default'), findsOneWidget);
      expect(find.text('Send a non-fatal error'), findsOneWidget);
      expect(find.text('Simulate app crash'), findsOneWidget);
      expect(find.text('Notification Center'), findsOneWidget);
      expect(find.text('Report export'), findsOneWidget);
      expect(find.text('A PDF of your applications.'), findsOneWidget);
      expect(find.text('Copy FCM token'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('every tap target is at least 48 dp', (tester) async {
    await pumpDemo(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  testWidgets('Remote Config updates appear without rebuilding', (
    tester,
  ) async {
    await pumpDemo(tester);

    remoteConfig.publish(RemoteConfigKeys.homeRecentLimit, 4);
    await tester.pumpAndSettle();

    expect(find.text('4 · In-app default'), findsOneWidget);
    expect(find.text('10 · In-app default'), findsNothing);
  });

  testWidgets('a value served by Firebase is labelled From Firebase', (
    tester,
  ) async {
    remoteConfig.sources[RemoteConfigKeys.homeRecommendedLimit] = 'remote';
    await pumpDemo(tester);

    expect(find.text('5 · From Firebase'), findsOneWidget);
    expect(find.text('10 · In-app default'), findsOneWidget);
  });

  testWidgets('non-fatal action records one handled error', (tester) async {
    await pumpDemo(tester);

    await tester.tap(find.text('Send a non-fatal error'));
    await tester.pumpAndSettle();

    expect(crashlytics.recordedErrors, hasLength(1));
    expect(
      find.text(
        'Non-fatal error sent. It appears in Crashlytics in a few minutes.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('crash action asks first, then forces the crash', (tester) async {
    await pumpDemo(tester);

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

  testWidgets('opens the Notification Center', (tester) async {
    await pumpDemo(tester);

    await tester.tap(find.text('Notification Center'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications opened'), findsOneWidget);
  });

  testWidgets('opens the Report export screen', (tester) async {
    await pumpDemo(tester);

    await tester.tap(find.text('Report export'));
    await tester.pumpAndSettle();

    expect(find.text('Report export opened'), findsOneWidget);
  });

  testWidgets('Copy FCM token copies the device token', (tester) async {
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

    await pumpDemo(tester);
    await tester.tap(find.text('Copy FCM token'));
    await tester.pumpAndSettle();

    expect(copied, ['fcm-test-token']);
    expect(find.text('FCM token copied.'), findsOneWidget);
  });
}
