import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/crashlytics_service.dart';
import '../../../services/remote_config_service.dart';

/// What the Firebase demo area shows: the Remote Config parameters in use and
/// whether a non-fatal test is being recorded.
@immutable
class FirebaseDemoState {
  const FirebaseDemoState({
    required this.config,
    this.isSendingNonFatal = false,
  });

  /// Current value and source (`default` / `remote` / `static`) per key.
  final Map<String, ({String value, String source})> config;
  final bool isSendingNonFatal;

  FirebaseDemoState copyWith({
    Map<String, ({String value, String source})>? config,
    bool? isSendingNonFatal,
  }) {
    return FirebaseDemoState(
      config: config ?? this.config,
      isSendingNonFatal: isSendingNonFatal ?? this.isSendingNonFatal,
    );
  }
}

final firebaseDemoViewModelProvider =
    NotifierProvider.autoDispose<FirebaseDemoViewModel, FirebaseDemoState>(
      FirebaseDemoViewModel.new,
    );

/// Firebase demo area (G-06): displays the Remote Config values the app is
/// using and offers the explicit Crashlytics test actions. The parameter
/// list refreshes on every Remote Config update, so a console change appears
/// without rebuilding the app.
class FirebaseDemoViewModel extends Notifier<FirebaseDemoState> {
  StreamSubscription<void>? _updates;

  @override
  FirebaseDemoState build() {
    final remoteConfig = ref.watch(remoteConfigServiceProvider);
    _updates = remoteConfig.onUpdated.listen((_) => _refresh());
    ref.onDispose(() => unawaited(_updates?.cancel()));
    return FirebaseDemoState(config: remoteConfig.snapshot());
  }

  void _refresh() {
    if (!ref.mounted) return;
    state = state.copyWith(
      config: ref.read(remoteConfigServiceProvider).snapshot(),
    );
  }

  /// Records one handled error, the non-fatal half of the Crashlytics demo.
  /// Returns `false` when the write failed, so the screen never claims a
  /// report was sent that was not.
  Future<bool> recordNonFatal() async {
    if (state.isSendingNonFatal) return false;
    final crashlytics = ref.read(crashlyticsServiceProvider);
    state = state.copyWith(isSendingNonFatal: true);
    try {
      await crashlytics.recordError(
        Exception('Test non-fatal error from the Firebase demo area'),
        StackTrace.current,
        reason: 'Firebase demo',
      );
      await crashlytics.log('Non-fatal test from the Firebase demo area');
      return true;
    } on Exception catch (error) {
      debugPrint('Could not record the non-fatal test error: $error');
      return false;
    } finally {
      if (ref.mounted) state = state.copyWith(isSendingNonFatal: false);
    }
  }

  /// Forces a native crash. Only the demo screen calls this, always behind
  /// the confirmation dialog.
  void crashForTesting() =>
      ref.read(crashlyticsServiceProvider).crashForTesting();
}
