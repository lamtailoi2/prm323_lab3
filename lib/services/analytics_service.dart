import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Analytics boundary. Event names and parameters are defined in
/// docs/analytics-plan.md. Never log passwords, tokens, emails, names,
/// phone numbers, CV file names or free-text input.
abstract interface class AnalyticsService {
  Future<void> logLogin({required String method});
  Future<void> logLogout();
  Future<void> logScreenView({required String screenName});

  /// Custom event. [name] must pass [AnalyticsNames.isValidEventName].
  Future<void> logEvent(String name, [Map<String, Object>? parameters]);

  /// Pseudonymous Firebase UID only (or `null` on sign-out).
  Future<void> setUserId(String? uid);
}

final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => FirebaseAnalyticsService(),
);

/// Naming rules for Google Analytics for Firebase events.
abstract final class AnalyticsNames {
  static final RegExp _name = RegExp(r'^[A-Za-z][A-Za-z0-9_]{0,39}$');
  static const List<String> _reservedPrefixes = <String>[
    'firebase_',
    'google_',
    'ga_',
  ];

  /// 1–40 chars, letters/digits/underscores, starts with a letter, no
  /// reserved prefix.
  static bool isValidEventName(String name) {
    if (!_name.hasMatch(name)) return false;
    final lower = name.toLowerCase();
    return !_reservedPrefixes.any(lower.startsWith);
  }
}

/// Analytics must never break a user flow, so failures are swallowed (and
/// printed in debug builds).
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logLogin({required String method}) =>
      _guard(() => _analytics.logLogin(loginMethod: method));

  @override
  Future<void> logLogout() => logEvent('logout');

  @override
  Future<void> logScreenView({required String screenName}) => _guard(
    () => _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
    ),
  );

  @override
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) {
    assert(
      AnalyticsNames.isValidEventName(name),
      'Invalid analytics event name: $name',
    );
    return _guard(
      () => _analytics.logEvent(name: name, parameters: parameters),
    );
  }

  @override
  Future<void> setUserId(String? uid) =>
      _guard(() => _analytics.setUserId(id: uid));

  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } on Exception catch (error) {
      debugPrint('Analytics call failed: $error');
    }
  }
}
