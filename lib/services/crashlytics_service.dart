import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Crash and error reporting boundary.
abstract interface class CrashlyticsService {
  /// Routes uncaught Flutter and platform errors to Crashlytics. Called once
  /// from bootstrap.
  void registerGlobalErrorHandlers();

  /// Records a handled (non-fatal) error.
  Future<void> recordError(Object error, StackTrace? stack, {String? reason});

  /// Breadcrumb attached to the next report. No personal data.
  Future<void> log(String message);

  /// Pseudonymous Firebase UID only (or `null` on sign-out).
  Future<void> setUserId(String? uid);

  /// Forces a native crash. Only for an explicit, user-triggered test
  /// control; never call it during startup or from automated flows.
  void crashForTesting();
}

final crashlyticsServiceProvider = Provider<CrashlyticsService>(
  (ref) => FirebaseCrashlyticsService(),
);

class FirebaseCrashlyticsService implements CrashlyticsService {
  FirebaseCrashlyticsService({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  void registerGlobalErrorHandlers() {
    FlutterError.onError = _crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  @override
  Future<void> recordError(Object error, StackTrace? stack, {String? reason}) {
    return _crashlytics.recordError(error, stack, reason: reason);
  }

  @override
  Future<void> log(String message) => _crashlytics.log(message);

  @override
  Future<void> setUserId(String? uid) =>
      _crashlytics.setUserIdentifier(uid ?? '');

  @override
  void crashForTesting() => _crashlytics.crash();
}
