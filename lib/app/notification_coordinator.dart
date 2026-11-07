import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/notification_target.dart';
import '../models/app_notification.dart';
import '../services/auth_service.dart';
import '../services/crashlytics_service.dart';
import '../services/notification_service.dart';
import 'app.dart';
import 'router.dart';

/// Wires Cloud Messaging into the app for the signed-in student:
/// permission prompt, token upload, and the three delivery states.
///
/// - foreground: saved to the history and announced with a SnackBar;
/// - background: opened from the shade → saved, marked read and opened;
/// - terminated: `getInitialMessage()` does the same on the next launch.
///
/// The background isolate writes on its own (see
/// `firebaseMessagingBackgroundHandler`).
class NotificationCoordinator {
  NotificationCoordinator(this._container);

  final ProviderContainer _container;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  String? _startedFor;
  bool _initialHandled = false;

  void start() {
    final service = _container.read(notificationServiceProvider);
    _subscriptions
      ..add(service.foregroundMessages().listen(_receiveInForeground))
      ..add(service.openedMessages().listen(_open))
      ..add(service.testCrashRequests().listen(_testCrash))
      ..add(service.tokenRefreshes().listen(_storeToken));
  }

  /// Keeps `users/{uid}.fcmToken` current when the registration token rotates.
  Future<void> _storeToken(String token) async {
    final uid = _container.read(currentUserIdProvider);
    if (uid == null) return;
    await _container.read(notificationServiceProvider).saveToken(uid, token);
  }

  /// Runs once per signed-in account: asks for permission, uploads this
  /// device's token and handles a message that launched the app.
  Future<void> signedIn(String uid) async {
    if (_startedFor == uid) return;
    _startedFor = uid;
    final service = _container.read(notificationServiceProvider);
    await service.requestPermission();
    await service.saveToken(uid, await service.token());

    if (_initialHandled) return;
    _initialHandled = true;
    final initial = await service.initialMessage();
    if (initial != null) await _open(initial);
  }

  /// Admin-triggered Crashlytics test. The command is a control message, so
  /// it is never stored or shown; the app closes immediately.
  Future<void> _testCrash(TestCrashRequest request) async {
    final crashlytics = _container.read(crashlyticsServiceProvider);
    await crashlytics.setCustomKey('crash_source', 'admin_dashboard');
    await crashlytics.setCustomKey('crash_target', request.target);
    if (request.requestedAt case final requestedAt?) {
      await crashlytics.setCustomKey('crash_requested_at', requestedAt);
    }
    crashlytics.crashForTesting();
  }

  Future<void> _receiveInForeground(AppNotification notification) async {
    await _store(notification);
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(notification.title),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => _go(notification),
          ),
        ),
      );
  }

  Future<void> _open(AppNotification notification) async {
    await _store(notification);
    final uid = _container.read(currentUserIdProvider);
    if (uid != null) {
      try {
        await _container
            .read(notificationServiceProvider)
            .markRead(uid, notification.id);
      } on AppException catch (error) {
        debugPrint('Could not mark the notification read: ${error.message}');
      }
    }
    _go(notification);
  }

  Future<void> _store(AppNotification notification) async {
    final uid = _container.read(currentUserIdProvider);
    if (uid == null) return;
    try {
      await _container
          .read(notificationServiceProvider)
          .save(uid, notification);
    } on AppException catch (error) {
      debugPrint('Could not store the notification: ${error.message}');
    }
  }

  void _go(AppNotification notification) {
    final target =
        notificationTarget(notification.route) ?? notificationCenterPath;
    _container.read(routerProvider).go(target);
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
  }
}
