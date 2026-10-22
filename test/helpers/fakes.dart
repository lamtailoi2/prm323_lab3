import 'dart:async';

import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/utils/job_key.dart';
import 'package:internly/models/app_user.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/crashlytics_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/remote_config_service.dart';

const testUser = AppUser(
  uid: 'uid-123',
  email: 'student@example.com',
  displayName: 'Test Student',
);

/// A listing with stable IDs for tests: `job-<id>` and its short key.
Internship testInternship(
  String id, {
  String? title,
  String? companyName,
  String? location,
  WorkMode? workMode,
  String? salary,
  String? postedText,
  DateTime? postedAt,
  String? logoUrl,
  int? searchRank,
  String? searchKeyword,
  List<String> skills = const <String>[],
}) {
  final jobId = 'job-$id';
  return Internship(
    jobId: jobId,
    key: jobKeyFor(jobId),
    title: title ?? 'Internship $id',
    companyName: companyName ?? 'Company $id',
    location: location ?? 'Ho Chi Minh City, Vietnam',
    workMode: workMode,
    salary: salary,
    postedTextSource: postedText,
    postedAt: postedAt,
    logoUrl: logoUrl,
    searchRank: searchRank,
    searchKeyword: searchKeyword,
    skills: skills,
  );
}

/// In-memory [InternshipService] backed by a broadcast stream. Tests set
/// [results] before listening, or call [emit] to model a Firestore update.
class FakeInternshipService implements InternshipService {
  List<Internship> results = const <Internship>[];
  AppException? error;
  Completer<void>? gate;
  int watchCalls = 0;

  final StreamController<List<Internship>> _updates =
      StreamController<List<Internship>>.broadcast();

  @override
  Stream<List<Internship>> watchActive() async* {
    watchCalls++;
    await gate?.future;
    final failure = error;
    if (failure != null) throw failure;
    yield results;
    yield* _updates.stream;
  }

  /// Pushes a new snapshot, as Firestore would.
  void emit(List<Internship> next) {
    results = next;
    _updates.add(next);
  }

  /// Pushes a listener error.
  void fail(AppException failure) {
    error = failure;
    _updates.addError(failure);
  }

  Future<void> dispose() => _updates.close();
}

/// In-memory [RemoteConfigService] seeded with the in-app defaults.
class FakeRemoteConfigService implements RemoteConfigService {
  final Map<String, Object> values = <String, Object>{
    RemoteConfigKeys.homeRecommendedLimit: 5,
    RemoteConfigKeys.homeRecentLimit: 10,
    RemoteConfigKeys.cvMatchEnabled: true,
  };

  final StreamController<void> _updates = StreamController<void>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  bool getBool(String key) => values[key] as bool? ?? false;

  @override
  int getInt(String key) => values[key] as int? ?? 0;

  @override
  String getString(String key) => values[key] as String? ?? '';

  @override
  Map<String, ({String value, String source})> snapshot() => {
    for (final entry in values.entries)
      entry.key: (value: '${entry.value}', source: 'default'),
  };

  /// Changes [key] and notifies listeners like a console update would.
  void publish(String key, Object value) {
    values[key] = value;
    _updates.add(null);
  }

  @override
  Stream<void> get onUpdated => _updates.stream;

  @override
  void dispose() => _updates.close();
}

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
