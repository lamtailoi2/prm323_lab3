import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';

String describe(ViewState<List<String>> state) => switch (state) {
  ViewLoading() => 'loading',
  ViewEmpty() => 'empty',
  ViewError(:final error) => 'error: ${error.message}',
  ViewData(:final data) => 'data: ${data.length}',
};

void main() {
  test('fromData picks Empty or Data', () {
    expect(
      ViewState<List<String>>.fromData(const [], isEmpty: true),
      isA<ViewEmpty<List<String>>>(),
    );
    final state = ViewState<List<String>>.fromData(const ['a'], isEmpty: false);
    expect(state, isA<ViewData<List<String>>>());
    expect(describe(state), 'data: 1');
  });

  test('switch is exhaustive over the four states', () {
    expect(describe(const ViewLoading()), 'loading');
    expect(describe(const ViewEmpty()), 'empty');
    expect(
      describe(const ViewError(AppException(AppErrorKind.network, 'Offline'))),
      'error: Offline',
    );
  });

  test('equality lets Riverpod skip identical states', () {
    expect(const ViewLoading<int>(), const ViewLoading<int>());
    expect(const ViewEmpty<int>(), const ViewEmpty<int>());
    const data = ['x'];
    expect(const ViewData(data), const ViewData(data));
    expect(const ViewLoading<int>().isLoading, isTrue);
    expect(const ViewEmpty<int>().isLoading, isFalse);
  });
}
