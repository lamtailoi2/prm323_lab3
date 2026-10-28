import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/features/saved/viewmodels/saved_viewmodel.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/saved_internship_service.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeSavedInternshipService saved;
  late FakeAnalyticsService analytics;
  late ProviderContainer container;

  setUp(() {
    saved = FakeSavedInternshipService();
    analytics = FakeAnalyticsService();
    container = ProviderContainer.test(
      overrides: [
        savedInternshipServiceProvider.overrideWithValue(saved),
        analyticsServiceProvider.overrideWithValue(analytics),
      ],
    );
  });

  tearDown(() async {
    await saved.dispose();
  });

  SavedViewModel listen() {
    // Keep the auto-dispose provider alive, as the screen would.
    container.listen(savedViewModelProvider, (_, _) {});
    return container.read(savedViewModelProvider.notifier);
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  final internship = testInternship('1');

  test('saves a listing, then reports success and logs the event', () async {
    final viewModel = listen();
    expect(container.read(savedViewModelProvider), isA<AsyncData<void>>());

    await viewModel.toggle(internship, source: 'home');

    expect(saved.saveCalls, 1);
    expect(saved.savedKeys, [internship.key]);
    expect(container.read(savedViewModelProvider), isA<AsyncData<void>>());
    expect(analytics.events, ['internship_save']);
    expect(analytics.eventParameters.single, {
      'internship_id': internship.key,
      'source': 'home',
    });
  });

  test('toggles a saved listing back off without logging a save', () async {
    saved.seed([internship]);
    final viewModel = listen();
    await settle();
    await settle();

    await viewModel.toggle(internship, source: 'home');

    expect(saved.removeCalls, 1);
    expect(saved.saveCalls, 0);
    expect(saved.savedKeys, isEmpty);
    expect(analytics.events, isEmpty);
  });

  test('a failure becomes an error state with a user message', () async {
    saved.error = const AppException(
      AppErrorKind.network,
      'We could not reach Internly. Check your connection and try again.',
    );
    final viewModel = listen();

    await viewModel.toggle(internship, source: 'home');

    final state = container.read(savedViewModelProvider);
    expect(state, isA<AsyncError<void>>());
    expect(
      (state.error! as AppException).message,
      'We could not reach Internly. Check your connection and try again.',
    );
    expect(saved.savedKeys, isEmpty);
    expect(analytics.events, isEmpty);
  });

  test('ignores repeated taps while a write is running', () async {
    saved.gate = Completer<void>();
    final viewModel = listen();

    final first = viewModel.toggle(internship, source: 'home');
    expect(container.read(savedViewModelProvider).isLoading, isTrue);
    await viewModel.toggle(internship, source: 'home');
    saved.gate!.complete();
    await first;

    expect(saved.saveCalls, 1);
    expect(analytics.events, ['internship_save']);
  });
}
