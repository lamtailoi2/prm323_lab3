import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/app/notification_coordinator.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/crashlytics_service.dart';
import 'package:internly/services/notification_service.dart';

import '../helpers/fakes.dart';
import '../helpers/notification_fakes.dart';

void main() {
  late FakeNotificationService notifications;

  setUp(() => notifications = FakeNotificationService());
  tearDown(() => notifications.dispose());

  test('a rotated token is stored for the signed-in student', () async {
    final container = ProviderContainer.test(
      overrides: [
        notificationServiceProvider.overrideWithValue(notifications),
        currentUserIdProvider.overrideWithValue(testUser.uid),
      ],
    );
    final coordinator = NotificationCoordinator(container)..start();
    addTearDown(coordinator.dispose);

    notifications.refreshToken('rotated-token');
    await pumpEventQueue();

    expect(notifications.savedToken, 'rotated-token');
    expect(notifications.savedTokenUid, testUser.uid);
  });

  test(
    'an admin crash command crashes without storing a notification',
    () async {
      final crashlytics = FakeCrashlyticsService();
      final container = ProviderContainer.test(
        overrides: [
          notificationServiceProvider.overrideWithValue(notifications),
          crashlyticsServiceProvider.overrideWithValue(crashlytics),
          currentUserIdProvider.overrideWithValue(testUser.uid),
        ],
      );
      final coordinator = NotificationCoordinator(container)..start();
      addTearDown(coordinator.dispose);

      notifications.requestTestCrash(
        target: 'all',
        requestedAt: '2026-11-06T12:00:00.000Z',
      );
      await pumpEventQueue();

      expect(crashlytics.crashCalls, 1);
      expect(crashlytics.customKeys['crash_source'], 'admin_dashboard');
      expect(crashlytics.customKeys['crash_target'], 'all');
      expect(
        crashlytics.customKeys['crash_requested_at'],
        '2026-11-06T12:00:00.000Z',
      );
      expect(notifications.saved, isEmpty);
    },
  );

  test('a rotated token while signed out is not stored', () async {
    final container = ProviderContainer.test(
      overrides: [
        notificationServiceProvider.overrideWithValue(notifications),
        currentUserIdProvider.overrideWithValue(null),
      ],
    );
    final coordinator = NotificationCoordinator(container)..start();
    addTearDown(coordinator.dispose);

    notifications.refreshToken('rotated-token');
    await pumpEventQueue();

    expect(notifications.savedToken, isNull);
  });
}
