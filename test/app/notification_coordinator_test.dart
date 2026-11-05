import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/app/notification_coordinator.dart';
import 'package:internly/services/auth_service.dart';
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
