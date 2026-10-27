import 'dart:async';
import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Keys of the Remote Config parameters. Every key must have an in-app
/// default in `firebase/remote-config-defaults.json` (the single source,
/// loaded as an asset) and a parameter of the same name and type in the
/// Firebase console. Proposed parameters: handoff-gaps G-11.
abstract final class RemoteConfigKeys {
  /// Number of cards in Home "Recommended for you".
  static const String homeRecommendedLimit = 'home_recommended_limit';

  /// Number of cards in Home "Recently Posted".
  static const String homeRecentLimit = 'home_recent_limit';

  /// Feature flag for the CV Match Check step in Apply (Flow 2d).
  static const String cvMatchEnabled = 'cv_match_enabled';
}

const String remoteConfigDefaultsAsset = 'firebase/remote-config-defaults.json';

/// Reads the in-app defaults from [remoteConfigDefaultsAsset].
Future<Map<String, Object>> loadRemoteConfigDefaults(AssetBundle bundle) async {
  final decoded = jsonDecode(
    await bundle.loadString(remoteConfigDefaultsAsset),
  );
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Remote Config defaults must be a JSON object');
  }
  return {
    for (final entry in decoded.entries)
      if (entry.value case final Object value) entry.key: value,
  };
}

/// Remote Config boundary.
abstract interface class RemoteConfigService {
  /// Applies the in-app defaults, starts a background fetch and listens for
  /// real-time updates. Never blocks startup on the network.
  Future<void> initialize();

  bool getBool(String key);
  int getInt(String key);
  String getString(String key);

  /// Current value and source (`default` / `remote` / `static`) of each
  /// parameter, for the Firebase demo area on Profile.
  Map<String, ({String value, String source})> snapshot();

  /// Emits after new values are activated (initial fetch or a real-time
  /// update from the console), so ViewModels can rebuild without a restart.
  Stream<void> get onUpdated;

  void dispose();
}

final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  final service = FirebaseRemoteConfigService();
  ref.onDispose(service.dispose);
  return service;
});

class FirebaseRemoteConfigService implements RemoteConfigService {
  FirebaseRemoteConfigService({
    FirebaseRemoteConfig? remoteConfig,
    AssetBundle? assets,
  }) : _config = remoteConfig ?? FirebaseRemoteConfig.instance,
       _assets = assets ?? rootBundle;

  final FirebaseRemoteConfig _config;
  final AssetBundle _assets;
  final StreamController<void> _updates = StreamController<void>.broadcast();
  StreamSubscription<RemoteConfigUpdate>? _realtime;

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
    await _config.setDefaults(await loadRemoteConfigDefaults(_assets));
    unawaited(_fetchAndActivate());
    _realtime = _config.onConfigUpdated.listen(
      (_) => unawaited(_activate()),
      onError: (Object error) => debugPrint('Remote Config stream: $error'),
    );
  }

  Future<void> _fetchAndActivate() async {
    try {
      if (await _config.fetchAndActivate()) _updates.add(null);
    } on Exception catch (error) {
      // Defaults stay active; the app keeps working offline.
      debugPrint('Remote Config fetch failed: $error');
    }
  }

  Future<void> _activate() async {
    try {
      await _config.activate();
      _updates.add(null);
    } on Exception catch (error) {
      debugPrint('Remote Config activate failed: $error');
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

  @override
  void dispose() {
    unawaited(_realtime?.cancel());
    unawaited(_updates.close());
  }
}
