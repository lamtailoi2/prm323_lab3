import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-app defaults for every Remote Config parameter.
///
/// Every parameter read by the app must have a default here, so the app
/// behaves correctly offline and before the first fetch. Parameter choices
/// belong to the feature that uses them; see docs/handoff-gaps.md (G-11)
/// for the open proposal.
abstract final class RemoteConfigDefaults {
  static const Map<String, Object> values = <String, Object>{};
}

/// Remote Config boundary.
abstract interface class RemoteConfigService {
  /// Applies [RemoteConfigDefaults] and starts a background fetch. Never
  /// blocks startup on the network.
  Future<void> initialize();

  bool getBool(String key);
  int getInt(String key);
  String getString(String key);

  /// Current value and source (`default` / `remote` / `static`) of each
  /// parameter, for the demonstration screen.
  Map<String, ({String value, String source})> snapshot();

  /// Emits after new values are activated.
  Stream<void> get onUpdated;
}

final remoteConfigServiceProvider = Provider<RemoteConfigService>(
  (ref) => FirebaseRemoteConfigService(),
);

class FirebaseRemoteConfigService implements RemoteConfigService {
  FirebaseRemoteConfigService({FirebaseRemoteConfig? remoteConfig})
    : _config = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _config;
  final StreamController<void> _updates = StreamController<void>.broadcast();

  @override
  Future<void> initialize() async {
    await _config.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 1)
            : const Duration(hours: 1),
      ),
    );
    await _config.setDefaults(RemoteConfigDefaults.values);
    unawaited(_fetchAndActivate());
  }

  Future<void> _fetchAndActivate() async {
    try {
      if (await _config.fetchAndActivate()) _updates.add(null);
    } on Exception catch (error) {
      // Defaults stay active; the app keeps working offline.
      debugPrint('Remote Config fetch failed: $error');
    }
  }

  @override
  bool getBool(String key) => _config.getBool(key);

  @override
  int getInt(String key) => _config.getInt(key);

  @override
  String getString(String key) => _config.getString(key);

  @override
  Map<String, ({String value, String source})> snapshot() {
    return _config.getAll().map(
      (key, value) =>
          MapEntry(key, (value: value.asString(), source: value.source.name)),
    );
  }

  @override
  Stream<void> get onUpdated => _updates.stream;
}
