import 'package:flutter_test/flutter_test.dart';
import 'package:internly/models/app_notification.dart';

void main() {
  group('AppNotification.fromFirestore', () {
    test('reads every stored field', () {
      final notification = AppNotification.fromFirestore('msg-1', {
        'title': 'New application',
        'body': 'Your application was received.',
        'route': '/applications/job-1',
        'receivedAt': DateTime(2026, 11, 5, 8),
        'read': true,
      });

      expect(notification.id, 'msg-1');
      expect(notification.title, 'New application');
      expect(notification.body, 'Your application was received.');
      expect(notification.route, '/applications/job-1');
      expect(notification.receivedAt, DateTime(2026, 11, 5, 8));
      expect(notification.isRead, isTrue);
      expect(notification.isUnread, isFalse);
    });

    test('optional fields default to empty body, no route and unread', () {
      final notification = AppNotification.fromFirestore('msg-2', {
        'title': 'Welcome',
        'receivedAt': DateTime(2026, 11, 5, 8),
      });

      expect(notification.body, '');
      expect(notification.route, isNull);
      expect(notification.isUnread, isTrue);
    });

    test('a missing title or date is malformed', () {
      expect(
        () => AppNotification.fromFirestore('msg-3', {
          'receivedAt': DateTime(2026, 11, 5, 8),
        }),
        throwsFormatException,
      );
      expect(
        () => AppNotification.fromFirestore('msg-4', {'title': 'Welcome'}),
        throwsFormatException,
      );
    });

    test('a wrong-typed route is ignored', () {
      final notification = AppNotification.fromFirestore('msg-5', {
        'title': 'Welcome',
        'receivedAt': DateTime(2026, 11, 5, 8),
        'route': 42,
      });

      expect(notification.route, isNull);
    });
  });

  test('toFirestore keeps the stored shape', () {
    final notification = AppNotification(
      id: 'msg-1',
      title: 'Welcome',
      body: 'Hello',
      receivedAt: DateTime(2026, 11, 5, 8),
      route: '/home',
    );

    expect(notification.toFirestore(), {
      'title': 'Welcome',
      'body': 'Hello',
      'route': '/home',
      'receivedAt': DateTime(2026, 11, 5, 8),
      'read': false,
    });
  });

  test('asRead keeps the content and flips the flag', () {
    final notification = AppNotification(
      id: 'msg-1',
      title: 'Welcome',
      body: 'Hello',
      receivedAt: DateTime(2026, 11, 5, 8),
      route: '/home',
    );

    final read = notification.asRead();
    expect(read.isRead, isTrue);
    expect(read.title, notification.title);
    expect(read.route, notification.route);
  });
}
