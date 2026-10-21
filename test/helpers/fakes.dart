import 'dart:async';

import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/models/app_user.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/crashlytics_service.dart';

const testUser = AppUser(
  uid: 'uid-123',
  email: 'student@example.com',
  displayName: 'Test Student',
);

/// In-memory [AuthService]. Sign-in succeeds with [testUser] unless
/// [signInError] is set.
class FakeAuthService implements AuthService {
  FakeAuthService({AppUser? initialUser}) : _user = initialUser;

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();
  AppUser? _user;

  AppException? signInError;
  AppException? signOutError;
  int signInCalls = 0;
  int signOutCalls = 0;

  /// Completes the next sign-in only when the test calls `complete()`.
  Completer<void>? signInGate;

  /// Emits the current user first, then every change. Subscribes to the
  /// change stream synchronously on listen, so no event can be lost.
  @override
  Stream<AppUser?> authStateChanges() {
    StreamSubscription<AppUser?>? changes;
    late final StreamController<AppUser?> controller;
    controller = StreamController<AppUser?>(
      onListen: () {
        controller.add(_user);
        changes = _controller.stream.listen(controller.add);
      },
      onCancel: () async {
        await changes?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> signInWithGoogle() async {
    signInCalls++;
    await signInGate?.future;
    final error = signInError;
    if (error != null) throw error;
    _emit(testUser);
    return testUser;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    final error = signOutError;
    if (error != null) throw error;
    _emit(null);
  }

  void _emit(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  Future<void> dispose() => _controller.close();
}

/// Records Crashlytics calls instead of sending them.
class FakeCrashlyticsService implements CrashlyticsService {
  final Map<String, Object> customKeys = <String, Object>{};
  final List<Object> recordedErrors = <Object>[];
  String? userId;

  @override
  void registerGlobalErrorHandlers() {}

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) async => recordedErrors.add(error);

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> setUserId(String? uid) async => userId = uid;

  @override
  Future<void> setCustomKey(String key, Object value) async =>
      customKeys[key] = value;

  @override
  void crashForTesting() {}
}

/// Records analytics calls instead of sending them.
class FakeAnalyticsService implements AnalyticsService {
  final List<String> events = <String>[];
  final List<String> screens = <String>[];
  final List<String?> userIds = <String?>[];

  @override
  Future<void> logLogin({required String method}) async =>
      events.add('login:$method');

  @override
  Future<void> logLogout() async => events.add('logout');

  @override
  Future<void> logScreenView({required String screenName}) async =>
      screens.add(screenName);

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async =>
      events.add(name);

  @override
  Future<void> setUserId(String? uid) async => userIds.add(uid);
}
