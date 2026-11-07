import 'dart:async';

import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/models/app_notification.dart';
import 'package:internly/services/notification_service.dart';

/// In-memory [NotificationService] backed by broadcast streams. Tests emit
/// snapshots and assert the writes the app performed.
class FakeNotificationService implements NotificationService {
  List<AppNotification> results = const <AppNotification>[];

  /// Thrown by the next subscription; usually an [AppException].
  Object? watchError;
  Completer<void>? gate;
  int watchCalls = 0;

  /// Thrown by [save] / [markRead] / [markAllRead].
  AppException? writeError;

  final List<AppNotification> saved = <AppNotification>[];
  final List<String> readIds = <String>[];
  String? tokenValue = 'fcm-test-token';
  NotificationPermission permission = NotificationPermission.granted;
  int permissionCalls = 0;
  String? savedToken;
  String? savedTokenUid;
  AppNotification? initial;
  bool initialConsumed = false;

  final StreamController<List<AppNotification>> _updates =
      StreamController<List<AppNotification>>.broadcast();
  final StreamController<AppNotification> _foreground =
      StreamController<AppNotification>.broadcast();
  final StreamController<AppNotification> _opened =
      StreamController<AppNotification>.broadcast();
  final StreamController<String> _tokenRefreshes =
      StreamController<String>.broadcast();
  final StreamController<TestCrashRequest> _testCrashes =
      StreamController<TestCrashRequest>.broadcast();

  @override
  Future<NotificationPermission> requestPermission() async {
    permissionCalls++;
    return permission;
  }

  @override
  Future<String?> token() async => tokenValue;

  @override
  Future<void> saveToken(String uid, String? token) async {
    savedTokenUid = uid;
    savedToken = token;
  }

  @override
  Stream<String> tokenRefreshes() => _tokenRefreshes.stream;

  @override
  Stream<AppNotification> foregroundMessages() => _foreground.stream;

  @override
  Stream<AppNotification> openedMessages() => _opened.stream;

  @override
  Stream<TestCrashRequest> testCrashRequests() => _testCrashes.stream;

  @override
  Future<AppNotification?> initialMessage() async {
    if (initialConsumed) return null;
    initialConsumed = true;
    return initial;
  }

  @override
  Stream<List<AppNotification>> watchNotifications(String uid) async* {
    watchCalls++;
    await gate?.future;
    final failure = watchError;
    if (failure != null) throw failure;
    yield results;
    yield* _updates.stream;
  }

  @override
  Future<void> save(String uid, AppNotification notification) async {
    if (writeError case final failure?) throw failure;
    saved.add(notification);
  }

  @override
  Future<void> markRead(String uid, String id) async {
    if (writeError case final failure?) throw failure;
    readIds.add(id);
  }

  @override
  Future<void> markAllRead(String uid, Iterable<String> ids) async {
    if (writeError case final failure?) throw failure;
    readIds.addAll(ids);
  }

  /// Pushes a new snapshot, as Firestore would.
  void emit(List<AppNotification> next) {
    results = next;
    _updates.add(next);
  }

  /// Pushes a listener error, as a Firestore stream would.
  void fail(Object error) {
    watchError = error;
    _updates.addError(error);
  }

  /// A message received in the foreground.
  void receive(AppNotification notification) => _foreground.add(notification);

  /// A message the student tapped from the shade.
  void open(AppNotification notification) => _opened.add(notification);

  /// A rotated FCM registration token.
  void refreshToken(String token) => _tokenRefreshes.add(token);

  /// An admin-dashboard crash command.
  void requestTestCrash({String target = 'uid', String? requestedAt}) =>
      _testCrashes.add(
        TestCrashRequest(target: target, requestedAt: requestedAt),
      );

  Future<void> dispose() async {
    await _updates.close();
    await _foreground.close();
    await _opened.close();
    await _tokenRefreshes.close();
    await _testCrashes.close();
  }
}

/// A notification with stable fields for tests.
AppNotification testNotification(
  String id, {
  String? title,
  String? body,
  DateTime? receivedAt,
  String? route,
  bool isRead = false,
}) {
  return AppNotification(
    id: id,
    title: title ?? 'Notification $id',
    body: body ?? 'Body of notification $id',
    receivedAt: receivedAt ?? DateTime(2026, 11, 5, 9),
    route: route,
    isRead: isRead,
  );
}
