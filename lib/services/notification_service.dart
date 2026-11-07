import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/app_notification.dart';
import 'crashlytics_service.dart';

/// Result of the Android 13+ / iOS notification permission prompt.
enum NotificationPermission { granted, denied }

/// A data-only command from the local admin dashboard that asks this device to
/// run the Crashlytics test crash. It never becomes a notification.
@immutable
class TestCrashRequest {
  const TestCrashRequest({required this.target, this.requestedAt});

  /// `all` for a broadcast, `uid` for one user.
  final String target;

  /// When the dashboard sent the command.
  final String? requestedAt;
}

/// Cloud Messaging and notification-history boundary.
///
/// Views and ViewModels never touch `firebase_messaging` or the
/// `users/{uid}/notifications` collection directly.
abstract interface class NotificationService {
  /// Shows the runtime permission prompt (Android 13+; a no-op below it) and
  /// returns what the student chose.
  Future<NotificationPermission> requestPermission();

  /// This device's FCM registration token, or `null` when it is unavailable
  /// (no Google Play services, missing APNs key, …).
  Future<String?> token();

  /// Stores the token on `users/{uid}` so a test message can target the
  /// device from the Firebase console.
  Future<void> saveToken(String uid, String? token);

  /// New tokens after the current one rotates, so the stored `fcmToken`
  /// keeps working for console test messages.
  Stream<String> tokenRefreshes();

  /// Messages received while the app is in the foreground.
  Stream<AppNotification> foregroundMessages();

  /// Messages the student tapped while the app was in the background.
  Stream<AppNotification> openedMessages();

  /// The message that launched the app while it was terminated.
  Future<AppNotification?> initialMessage();

  /// Explicit crash commands from the admin dashboard. Kept separate from
  /// [foregroundMessages] so a command never appears in the history or as a
  /// SnackBar.
  Stream<TestCrashRequest> testCrashRequests();

  /// `users/{uid}/notifications`, newest first.
  Stream<List<AppNotification>> watchNotifications(String uid);

  /// Writes one notification; the document ID is the FCM message ID, so the
  /// foreground, background and opened handlers cannot duplicate it.
  Future<void> save(String uid, AppNotification notification);

  /// Marks one notification as read.
  Future<void> markRead(String uid, String id);
}

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => FirebaseNotificationService(ref.watch(crashlyticsServiceProvider)),
);

class FirebaseNotificationService implements NotificationService {
  FirebaseNotificationService(
    this._crashlytics, {
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final CrashlyticsService _crashlytics;

  static const int _historyLimit = 50;

  @override
  Future<NotificationPermission> requestPermission() async {
    try {
      // iOS shows banners for foreground messages only after this call;
      // Android ignores it.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => NotificationPermission.granted,
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently ||
        AuthorizationStatus.notDetermined => NotificationPermission.denied,
      };
    } catch (error) {
      debugPrint('Notification permission request failed: $error');
      return NotificationPermission.denied;
    }
  }

  @override
  Future<String?> token() async {
    try {
      // The Firebase Console's "Send test message" field takes the FCM
      // registration token. FlutterFire 17 adds an FID API but keeps this
      // one for that workflow (firebase_messaging 17.0.0).
      // ignore: deprecated_member_use
      return await _messaging.getToken();
    } catch (error) {
      // No Google Play services, missing APNs configuration, or offline.
      debugPrint('Could not read the FCM token: $error');
      return null;
    }
  }

  @override
  Future<void> saveToken(String uid, String? token) async {
    final value = token?.trim();
    if (value == null || value.isEmpty) return;
    try {
      await _firestore.collection('users').doc(uid).set(<String, Object?>{
        'fcmToken': value,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      unawaited(
        _crashlytics.recordError(
          error,
          StackTrace.current,
          reason: 'Could not save the FCM token',
        ),
      );
    }
  }

  @override
  Stream<String> tokenRefreshes() {
    // Mirrors token(): the console test-message field takes the FCM
    // registration token, not the FID (firebase_messaging 17.0.0).
    // ignore: deprecated_member_use
    return _messaging.onTokenRefresh;
  }

  @override
  Stream<AppNotification> foregroundMessages() => FirebaseMessaging.onMessage
      .where((message) => !isTestCrashMessage(message))
      .map(notificationFromMessage);

  @override
  Stream<AppNotification> openedMessages() => FirebaseMessaging
      .onMessageOpenedApp
      .where((message) => !isTestCrashMessage(message))
      .map(notificationFromMessage);

  @override
  Future<AppNotification?> initialMessage() async {
    try {
      final message = await _messaging.getInitialMessage();
      if (message == null || isTestCrashMessage(message)) return null;
      return notificationFromMessage(message);
    } catch (error) {
      debugPrint('Could not read the initial FCM message: $error');
      return null;
    }
  }

  @override
  Stream<TestCrashRequest> testCrashRequests() => FirebaseMessaging.onMessage
      .where(isTestCrashMessage)
      .map(
        (message) => TestCrashRequest(
          target: _nonEmpty(message.data['target']) ?? 'uid',
          requestedAt: _nonEmpty(message.data['requestedAt']),
        ),
      );

  @override
  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('receivedAt', descending: true)
        .limit(_historyLimit)
        .snapshots()
        .map((snapshot) {
          final notifications = <AppNotification>[];
          for (final document in snapshot.docs) {
            try {
              notifications.add(
                AppNotification.fromFirestore(document.id, document.data()),
              );
            } on FormatException catch (error, stack) {
              // One malformed document must not hide the others.
              unawaited(
                _crashlytics.recordError(
                  error,
                  stack,
                  reason: 'Skipped a malformed notification document',
                ),
              );
            }
          }
          return List<AppNotification>.unmodifiable(notifications);
        });
  }

  @override
  Future<void> save(String uid, AppNotification notification) async {
    try {
      await _notifications(uid).doc(notification.id).set(<String, Object?>{
        ...notification.toFirestore(),
        // Stored as a Timestamp so the server-side order is exact.
        'receivedAt': Timestamp.fromDate(notification.receivedAt),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw _toAppException(error);
    }
  }

  @override
  Future<void> markRead(String uid, String id) async {
    try {
      await _notifications(uid).doc(id).update(<String, Object?>{'read': true});
    } on FirebaseException catch (error) {
      throw _toAppException(error);
    }
  }

  CollectionReference<Map<String, Object?>> _notifications(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  static AppException _toAppException(FirebaseException error) {
    return AppException(
      error.code == 'unavailable' || error.code == 'network-request-failed'
          ? AppErrorKind.network
          : AppErrorKind.unknown,
      'We could not update your notifications. Try again in a moment.',
      cause: error,
    );
  }
}

/// The admin dashboard sends a data-only message with `type=test_crash`.
/// Visible for tests.
const String _commandTypeKey = 'type';
const String _testCrashCommand = 'test_crash';

@visibleForTesting
bool isTestCrashMessage(RemoteMessage message) =>
    message.data[_commandTypeKey] == _testCrashCommand;

/// Maps an FCM message to the history document shape.
///
/// Title and body come from the notification payload; a data-only message
/// falls back to its `title` / `body` entries. `data.route` is the in-app
/// destination and stays unvalidated here (the UI validates it before
/// navigating). Visible for tests.
@visibleForTesting
AppNotification notificationFromMessage(RemoteMessage message) {
  final data = message.data;
  final receivedAt = message.sentTime ?? DateTime.now();
  return AppNotification(
    id: _documentId(message.messageId, receivedAt),
    title:
        _nonEmpty(message.notification?.title) ??
        _nonEmpty(data['title']) ??
        'Internly',
    body:
        _nonEmpty(message.notification?.body) ?? _nonEmpty(data['body']) ?? '',
    receivedAt: receivedAt,
    route: _nonEmpty(data['route']),
  );
}

/// Message ID as a Firestore document ID; Firebase message IDs are numeric,
/// but a custom sender may use characters a document ID cannot hold.
String _documentId(String? messageId, DateTime receivedAt) {
  final raw = messageId?.trim();
  if (raw == null || raw.isEmpty) {
    return 'notification-${receivedAt.millisecondsSinceEpoch}';
  }
  final safe = raw.replaceAll('/', '_');
  return safe.length <= 200 ? safe : safe.substring(0, 200);
}

String? _nonEmpty(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Runs when a message arrives while the app is in the background or
/// terminated. It cannot use Riverpod, so it writes straight to Firestore.
///
/// The sender includes the owner's `uid` in the data payload (the console
/// test message can add it under "Additional options"); without it the
/// handler falls back to the Firebase Auth session, which is also available
/// in this isolate on Android.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();

    // A crash command is not a notification: record why it happened, then
    // crash the process so Crashlytics uploads a fatal report on next launch.
    if (isTestCrashMessage(message)) {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCustomKey('crash_source', 'admin_dashboard');
      await crashlytics.setCustomKey(
        'crash_target',
        _nonEmpty(message.data['target']) ?? 'uid',
      );
      final requestedAt = _nonEmpty(message.data['requestedAt']);
      if (requestedAt != null) {
        await crashlytics.setCustomKey('crash_requested_at', requestedAt);
      }
      crashlytics.crash();
      return;
    }

    final uid =
        _nonEmpty(message.data['uid']) ??
        FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final notification = notificationFromMessage(message);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notification.id)
        .set(<String, Object?>{
          ...notification.toFirestore(),
          'receivedAt': Timestamp.fromDate(notification.receivedAt),
        }, SetOptions(merge: true));
  } catch (error) {
    // The background isolate must never throw: the message is already shown
    // by the system, and the opened handler writes the history on tap.
    debugPrint('Background FCM handler failed: $error');
  }
}
