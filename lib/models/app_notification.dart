import 'package:flutter/foundation.dart';

import '../core/utils/firestore_reader.dart';

/// One message received through Firebase Cloud Messaging, stored at
/// `users/{uid}/notifications/{messageId}` (G-13).
///
/// The client writes the document from the foreground, background and
/// opened-app handlers, so the Notification Center has the same history in
/// every app state. Required fields throw [FormatException]; services skip
/// and log malformed documents.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.route,
    this.isRead = false,
  });

  factory AppNotification.fromFirestore(String id, Map<String, Object?>? data) {
    final reader = FirestoreReader('notifications/$id', data);
    return AppNotification(
      id: id,
      title: reader.requireString('title').trim(),
      // A title-only notification is valid; the body is then empty.
      body: reader.optionalString('body') ?? '',
      receivedAt: reader.requireDateTime('receivedAt'),
      // In-app destination sent by the console / backend, e.g.
      // `/applications/<jobKey>`; `null` when the message names none.
      route: reader.optionalString('route'),
      isRead: reader.boolOr('read', fallback: false),
    );
  }

  /// Document ID (the FCM message ID when the sender provides one).
  final String id;

  final String title;
  final String body;
  final DateTime receivedAt;

  /// In-app route to open when the student taps the notification.
  final String? route;
  final bool isRead;

  bool get isUnread => !isRead;

  AppNotification asRead() => AppNotification(
    id: id,
    title: title,
    body: body,
    receivedAt: receivedAt,
    route: route,
    isRead: true,
  );

  Map<String, Object?> toFirestore() => <String, Object?>{
    'title': title,
    'body': body,
    'route': route,
    'receivedAt': receivedAt,
    'read': isRead,
  };
}
