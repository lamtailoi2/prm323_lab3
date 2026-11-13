import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/offline_snapshots.dart';

/// A stand-in for a Firestore `QuerySnapshot`: its items and whether it came
/// only from the local cache.
typedef _Snapshot = ({List<String> items, bool fromCache});

const _grace = Duration(milliseconds: 20);

Stream<List<String>> _offlineAware(Stream<_Snapshot> source) {
  return emptyCacheAsError(
    source,
    isEmptyFromCache: (snapshot) =>
        snapshot.items.isEmpty && snapshot.fromCache,
    convert: (snapshot) => snapshot.items,
    offlineError: () => StateError('offline'),
    grace: _grace,
  );
}

Future<void> _waitPastGrace() => Future<void>.delayed(_grace * 3);

void main() {
  late StreamController<_Snapshot> source;
  late List<Object> events;
  late StreamSubscription<List<String>> subscription;

  setUp(() {
    source = StreamController<_Snapshot>();
    events = <Object>[];
    subscription = _offlineAware(source.stream)
        .listen(events.add, onError: events.add);
  });

  tearDown(() async {
    await subscription.cancel();
    await source.close();
  });

  test('passes non-empty snapshots through, from cache or server', () async {
    source
      ..add((items: ['a'], fromCache: true))
      ..add((items: ['a', 'b'], fromCache: false));
    await _waitPastGrace();

    expect(events, [
      ['a'],
      ['a', 'b'],
    ]);
  });

  test('an empty server snapshot is data, not an error', () async {
    source.add((items: <String>[], fromCache: false));
    await _waitPastGrace();

    expect(events, [<String>[]]);
  });

  test('an empty cached snapshot becomes the offline error after the grace '
      'period', () async {
    source.add((items: <String>[], fromCache: true));
    await Future<void>.delayed(Duration.zero);
    expect(events, isEmpty, reason: 'waits before showing an error');

    await _waitPastGrace();
    expect(events, hasLength(1));
    expect(events.single, isA<StateError>());
  });

  test('a server answer inside the grace period cancels the error', () async {
    source.add((items: <String>[], fromCache: true));
    await Future<void>.delayed(Duration.zero);
    source.add((items: <String>[], fromCache: false));
    await _waitPastGrace();

    expect(events, [<String>[]]);
  });

  test('data after the offline error replaces it (back online)', () async {
    source.add((items: <String>[], fromCache: true));
    await _waitPastGrace();
    source.add((items: ['a'], fromCache: false));
    await _waitPastGrace();

    expect(events, hasLength(2));
    expect(events.first, isA<StateError>());
    expect(events.last, ['a']);
  });

  test('source errors pass through unchanged', () async {
    final error = Exception('permission-denied');
    source.addError(error);
    await _waitPastGrace();

    expect(events, [error]);
  });

  test('an empty cached snapshot right before the source ends still reports '
      'the error', () async {
    final done = Completer<void>();
    final ended = <Object>[];
    final short = _offlineAware(
      Stream.value((items: <String>[], fromCache: true)),
    );
    short.listen(ended.add, onError: ended.add, onDone: done.complete);

    await done.future;
    expect(ended, hasLength(1));
    expect(ended.single, isA<StateError>());
  });

  test('cancelling stops the pending error', () async {
    source.add((items: <String>[], fromCache: true));
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();
    await _waitPastGrace();

    expect(events, isEmpty);
  });
}
