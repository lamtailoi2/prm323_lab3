import 'dart:async';

/// Maps a Firestore listener's snapshots with [convert], but reports an empty
/// snapshot that only came from the local cache as [offlineError].
///
/// Offline, Firestore answers a listener with whatever its cache holds. With an
/// empty cache that is an empty result marked `isFromCache`, which a screen
/// cannot tell apart from "nothing here", so Saved showed `No saved internships
/// yet` and Search `No internships found` instead of the error state with
/// `Retry` (UAT-R1B-01, BR-D6).
///
/// The error waits [grace] first: online, Firestore may answer with an empty
/// cached result and then with the server's, and the student should not see an
/// error flash in between. Any later snapshot cancels a waiting error and
/// replaces one already shown, so the screen recovers by itself when the
/// connection returns. Errors from [source] are passed on unchanged.
Stream<R> emptyCacheAsError<S, R>(
  Stream<S> source, {
  required bool Function(S snapshot) isEmptyFromCache,
  required R Function(S snapshot) convert,
  required Object Function() offlineError,
  Duration grace = const Duration(seconds: 3),
}) {
  late final StreamController<R> controller;
  StreamSubscription<S>? subscription;
  Timer? pendingError;

  void cancelPendingError() {
    pendingError?.cancel();
    pendingError = null;
  }

  void onData(S snapshot) {
    cancelPendingError();
    if (isEmptyFromCache(snapshot)) {
      pendingError = Timer(grace, () => controller.addError(offlineError()));
      return;
    }
    final R value;
    try {
      value = convert(snapshot);
    } on Object catch (error, stack) {
      controller.addError(error, stack);
      return;
    }
    controller.add(value);
  }

  controller = StreamController<R>(
    onListen: () {
      subscription = source.listen(
        onData,
        onError: (Object error, StackTrace stack) {
          cancelPendingError();
          controller.addError(error, stack);
        },
        onDone: () {
          // No newer snapshot can replace a waiting error any more.
          if (pendingError != null) {
            cancelPendingError();
            controller.addError(offlineError());
          }
          unawaited(controller.close());
        },
      );
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () {
      cancelPendingError();
      return subscription?.cancel();
    },
  );

  return controller.stream;
}
