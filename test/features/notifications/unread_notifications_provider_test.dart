import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/features/notifications/viewmodels/unread_notifications_provider.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/notification_service.dart';

import '../../helpers/notification_fakes.dart';

void main() {
  late FakeNotificationService notifications;

  setUp(() => notifications = FakeNotificationService());
  tearDown(() async => notifications.dispose());

  ProviderContainer build({String? uid = 'uid-123'}) {
    final container = ProviderContainer.test(
      overrides: [
        notificationServiceProvider.overrideWithValue(notifications),
        currentUserIdProvider.overrideWithValue(uid),
      ],
    );
    container.listen(unreadNotificationCountProvider, (_, _) {});
    return container;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('counts the unread notifications and follows new snapshots', () async {
    notifications.results = [
      testNotification('1'),
      testNotification('2', isRead: true),
      testNotification('3'),
    ];
    final container = build();
    await settle();
    expect(container.read(unreadNotificationCountProvider).value, 2);

    notifications.emit([testNotification('1', isRead: true)]);
    await settle();
    expect(container.read(unreadNotificationCountProvider).value, 0);
  });

  test('signed out: 0 without reading the history', () async {
    final container = build(uid: null);
    await settle();
    expect(container.read(unreadNotificationCountProvider).value, 0);
    expect(notifications.watchCalls, 0);
  });
}
