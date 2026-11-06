import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/services/notification_service.dart';

void main() {
  final sentTime = DateTime(2026, 11, 5, 8, 30);

  test('maps the notification payload and the route', () {
    final notification = notificationFromMessage(
      RemoteMessage(
        messageId: 'msg-1',
        sentTime: sentTime,
        data: const <String, dynamic>{
          'route': '/applications/job-1',
          'uid': 'uid-123',
        },
        notification: const RemoteNotification(
          title: 'New application',
          body: 'Your application was received.',
        ),
      ),
    );

    expect(notification.id, 'msg-1');
    expect(notification.title, 'New application');
    expect(notification.body, 'Your application was received.');
    expect(notification.route, '/applications/job-1');
    expect(notification.receivedAt, sentTime);
    expect(notification.isUnread, isTrue);
  });

  test('a data-only message falls back to the data entries', () {
    final notification = notificationFromMessage(
      RemoteMessage(
        messageId: 'msg-2',
        sentTime: sentTime,
        data: const <String, dynamic>{
          'title': 'Reminder',
          'body': 'Interview tomorrow',
        },
      ),
    );

    expect(notification.title, 'Reminder');
    expect(notification.body, 'Interview tomorrow');
    expect(notification.route, isNull);
  });

  test('a message without a title still has one, and no ID uses the time', () {
    final notification = notificationFromMessage(
      RemoteMessage(sentTime: sentTime),
    );

    expect(notification.title, 'Internly');
    expect(notification.body, '');
    expect(notification.id, 'notification-${sentTime.millisecondsSinceEpoch}');
  });

  test('a document ID never contains a slash', () {
    final notification = notificationFromMessage(
      RemoteMessage(messageId: 'a/b/c', sentTime: sentTime),
    );

    expect(notification.id, 'a_b_c');
  });
}
