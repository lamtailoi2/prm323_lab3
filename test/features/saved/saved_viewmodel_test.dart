import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/utils/distinct_listings.dart';
import 'package:internly/features/saved/viewmodels/saved_providers.dart';
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

  group('toggleAndReport (Internship Detail)', () {
    test('saves with the detail source and keeps state clean', () async {
      final viewModel = listen();

      final result = await viewModel.toggleAndReport(
        internship,
        source: 'detail',
      );

      expect(result.done, isTrue);
      expect(result.error, isNull);
      expect(saved.savedKeys, [internship.key]);
      expect(container.read(savedViewModelProvider), isA<AsyncData<void>>());
      expect(analytics.eventParameters.single, {
        'internship_id': internship.key,
        'source': 'detail',
      });
    });

    test('removes a saved listing without logging a save', () async {
      saved.seed([internship]);
      final viewModel = listen();
      await settle();

      final result = await viewModel.toggleAndReport(
        internship,
        source: 'detail',
      );

      expect(result.done, isTrue);
      expect(saved.savedKeys, isEmpty);
      expect(analytics.events, isEmpty);
    });

    test(
      'returns a failure instead of storing it, so Home stays quiet',
      () async {
        saved.error = const AppException(
          AppErrorKind.network,
          'We could not reach Internly. Check your connection and try again.',
        );
        final viewModel = listen();

        final result = await viewModel.toggleAndReport(
          internship,
          source: 'detail',
        );

        expect(result.done, isFalse);
        expect(result.error?.kind, AppErrorKind.network);
        expect(container.read(savedViewModelProvider), isA<AsyncData<void>>());
      },
    );

    test('ignores a tap while another write is running', () async {
      saved.gate = Completer<void>();
      final viewModel = listen();

      final first = viewModel.toggleAndReport(internship, source: 'detail');
      final second = await viewModel.toggleAndReport(
        internship,
        source: 'detail',
      );
      saved.gate!.complete();
      await first;

      expect(second.done, isFalse);
      expect(second.error, isNull);
      expect(saved.saveCalls, 1);
    });
  });

  test('removes a saved listing for the Saved screen', () async {
    saved.seed([internship]);
    final viewModel = listen();
    await settle();

    final result = await viewModel.remove(internship);

    expect(result.done, isTrue);
    expect(result.error, isNull);
    expect(saved.removeCalls, 1);
    expect(saved.savedKeys, isEmpty);
  });

  test('restore saves the listing again with the saved event', () async {
    saved.seed([internship]);
    final viewModel = listen();
    await settle();
    await viewModel.remove(internship);

    final result = await viewModel.restore(internship);

    expect(result.done, isTrue);
    expect(saved.saveCalls, 1);
    expect(saved.savedKeys, [internship.key]);
    expect(analytics.events, ['internship_save']);
    expect(analytics.eventParameters.single, {
      'internship_id': internship.key,
      'source': 'saved',
    });
  });

  test(
    'a failed unsave returns the message but is not an error state',
    () async {
      saved.seed([internship]);
      saved.error = const AppException(
        AppErrorKind.network,
        'We could not reach Internly. Check your connection and try again.',
      );
      final viewModel = listen();
      await settle();

      final result = await viewModel.remove(internship);

      expect(result.done, isFalse);
      expect(
        result.error!.message,
        'We could not reach Internly. Check your connection and try again.',
      );
      expect(saved.savedKeys, [internship.key]);
      // The Saved screen shows the failure itself; a second error state would
      // make HomeScreen's listener show the same SnackBar again.
      expect(container.read(savedViewModelProvider), isA<AsyncData<void>>());
    },
  );

  test('a failed undo returns the message', () async {
    saved.seed([internship]);
    final viewModel = listen();
    await settle();
    await viewModel.remove(internship);
    saved.error = const AppException(
      AppErrorKind.notFound,
      'This internship is no longer available.',
    );

    final result = await viewModel.restore(internship);

    expect(result.done, isFalse);
    expect(result.error!.message, 'This internship is no longer available.');
    expect(saved.savedKeys, isEmpty);
  });

  test('ignores a second unsave while the first write is running', () async {
    final other = testInternship('2');
    saved.seed([internship, other]);
    saved.gate = Completer<void>();
    final viewModel = listen();
    await settle();

    final first = viewModel.remove(internship);
    final second = await viewModel.remove(other);

    expect(second.done, isFalse);
    expect(second.error, isNull);

    saved.gate!.complete();
    expect((await first).done, isTrue);
    expect(saved.removeCalls, 1);
    expect(saved.savedKeys, [other.key]);
  });

  group('another synced copy of a saved job (CR-07)', () {
    // The same job synced under two keywords: same title and company, a key
    // per copy. Lists keep one copy, which may not be the saved one.
    final savedCopy = testInternship(
      '10',
      title: 'Flutter Developer Intern',
      companyName: 'FPT Software',
    );
    final cardCopy = testInternship(
      '11',
      title: 'Flutter Developer Intern',
      companyName: 'FPT Software',
    );

    test('savedJobsProvider holds the job, not the key of one copy', () async {
      saved.seed([savedCopy]);
      container.listen(savedJobsProvider, (_, _) {});
      await settle();
      await settle();

      final savedJobs = container.read(savedJobsProvider);
      expect(savedJobs, {
        jobIdentity('Flutter Developer Intern', 'FPT Software'),
      });
      expect(
        savedJobs.contains(jobIdentity(cardCopy.title, cardCopy.companyName)),
        isTrue,
      );
    });

    test('toggling the copy on the card unsaves the saved copy', () async {
      saved.seed([savedCopy]);
      final viewModel = listen();
      await settle();
      await settle();

      await viewModel.toggle(cardCopy, source: 'search');

      // No second save of the same job, and the saved copy is removed.
      expect(saved.saveCalls, 0);
      expect(saved.removeCalls, 1);
      expect(saved.savedKeys, isEmpty);
      expect(analytics.events, isEmpty);
    });

    test('two copies saved before the fix are both removed', () async {
      saved.seed([savedCopy, cardCopy]);
      final viewModel = listen();
      await settle();
      await settle();

      await viewModel.toggle(cardCopy, source: 'home');

      expect(saved.removeCalls, 2);
      expect(saved.savedKeys, isEmpty);
    });

    test('a job with the same title at another company is saved', () async {
      saved.seed([savedCopy]);
      final viewModel = listen();
      await settle();
      await settle();
      final otherCompany = testInternship(
        '12',
        title: 'Flutter Developer Intern',
        companyName: 'VNG Corporation',
      );

      await viewModel.toggle(otherCompany, source: 'search');

      expect(saved.saveCalls, 1);
      expect(saved.removeCalls, 0);
      expect(saved.savedKeys, [savedCopy.key, otherCompany.key]);
    });
  });
}
