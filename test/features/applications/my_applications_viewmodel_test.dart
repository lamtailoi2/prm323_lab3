import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/features/applications/viewmodels/my_applications_viewmodel.dart';
import 'package:internly/models/internship_application.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeApplicationService applications;
  late ProviderContainer container;
  late String? signedInUid;

  setUp(() {
    applications = FakeApplicationService();
    signedInUid = testUser.uid;
    container = ProviderContainer.test(
      overrides: [
        applicationServiceProvider.overrideWithValue(applications),
        currentUserIdProvider.overrideWith((ref) => signedInUid),
      ],
    );
  });

  tearDown(() async {
    await applications.dispose();
  });

  MyApplicationsViewModel listen() {
    // Keep the auto-dispose provider alive, as the screen would.
    container.listen(myApplicationsViewModelProvider, (_, _) {});
    return container.read(myApplicationsViewModelProvider.notifier);
  }

  MyApplicationsState read() => container.read(myApplicationsViewModelProvider);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  MyApplicationsFeed feed() =>
      (read().applications as ViewData<MyApplicationsFeed>).data;

  final page = [
    testApplication(
      '1',
      title: 'Backend Engineer Intern',
      appliedAt: DateTime(2026, 9, 18),
      status: ApplicationStatus.rejected,
    ),
    testApplication(
      '2',
      title: 'Product Design Intern',
      appliedAt: DateTime(2026, 10, 1),
      status: ApplicationStatus.interview,
    ),
    testApplication(
      '3',
      title: 'Data Analyst Intern',
      appliedAt: DateTime(2026, 9, 24),
      status: ApplicationStatus.accepted,
    ),
    testApplication(
      '4',
      title: 'QA Engineer Intern',
      appliedAt: DateTime(2026, 10, 8),
      status: ApplicationStatus.underReview,
    ),
    testApplication(
      '5',
      title: 'Mobile Developer Intern',
      appliedAt: DateTime(2026, 10, 12),
    ),
  ];

  test('starts loading, then shows the applications newest first', () async {
    applications.results = page;
    listen();
    expect(read().applications, isA<ViewLoading<MyApplicationsFeed>>());

    await settle();

    expect(applications.watchCalls, 1);
    expect(read().applications, isA<ViewData<MyApplicationsFeed>>());
    expect(read().selectedStatus, isNull);
    expect(feed().total, 5);
    expect(feed().visible.map((application) => application.title), [
      'Mobile Developer Intern',
      'QA Engineer Intern',
      'Product Design Intern',
      'Data Analyst Intern',
      'Backend Engineer Intern',
    ]);
    expect(feed().counts, {
      ApplicationStatus.submitted: 1,
      ApplicationStatus.underReview: 1,
      ApplicationStatus.interview: 1,
      ApplicationStatus.accepted: 1,
      ApplicationStatus.rejected: 1,
    });
  });

  test('no applications becomes the empty state, never 0 cards', () async {
    listen();
    await settle();

    expect(read().applications, isA<ViewEmpty<MyApplicationsFeed>>());
  });

  test(
    'a listener error becomes the error state with a safe message',
    () async {
      applications.error = const AppException(
        AppErrorKind.network,
        'We could not load your applications. Check your connection and try '
        'again.',
      );
      listen();
      await settle();

      final state = read().applications;
      expect(state, isA<ViewError<MyApplicationsFeed>>());
      expect(
        (state as ViewError<MyApplicationsFeed>).error.message,
        'We could not load your applications. Check your connection and try '
        'again.',
      );
    },
  );

  test('an unknown listener error is wrapped in a generic message', () async {
    listen();
    await settle();

    applications.fail(StateError('boom'));
    await settle();

    final state = read().applications as ViewError<MyApplicationsFeed>;
    expect(state.error.message, isNot('boom'));
    expect(state.error.cause, isA<StateError>());
  });

  test('a status chip filters the list but not the counts', () async {
    applications.results = page;
    final viewModel = listen();
    await settle();

    viewModel.selectStatus(ApplicationStatus.interview);

    expect(read().selectedStatus, ApplicationStatus.interview);
    expect(feed().visible.single.title, 'Product Design Intern');
    expect(feed().total, 5);
    expect(feed().counts, hasLength(5));

    viewModel.selectStatus(null);

    expect(read().selectedStatus, isNull);
    expect(feed().visible, hasLength(5));
  });

  test('a new snapshot keeps the selected chip filtered', () async {
    applications.results = page;
    final viewModel = listen();
    await settle();
    viewModel.selectStatus(ApplicationStatus.accepted);

    applications.emit([
      ...page,
      testApplication(
        '6',
        title: 'Frontend Intern',
        appliedAt: DateTime(2026, 10, 20),
        status: ApplicationStatus.accepted,
      ),
    ]);
    await settle();

    expect(read().selectedStatus, ApplicationStatus.accepted);
    expect(feed().visible.map((application) => application.title), [
      'Frontend Intern',
      'Data Analyst Intern',
    ]);
    expect(feed().total, 6);
  });

  test('a filter whose status disappears falls back to All', () async {
    applications.results = page;
    final viewModel = listen();
    await settle();
    viewModel.selectStatus(ApplicationStatus.accepted);

    applications.emit([
      for (final application in page)
        if (application.status != ApplicationStatus.accepted) application,
    ]);
    await settle();

    expect(read().selectedStatus, isNull);
    expect(feed().visible, hasLength(4));
    expect(feed().counts.containsKey(ApplicationStatus.accepted), isFalse);
  });

  test('retry subscribes again and recovers from the error state', () async {
    applications.error = const AppException(
      AppErrorKind.network,
      'We could not load your applications. Check your connection and try '
      'again.',
    );
    final viewModel = listen();
    await settle();
    expect(read().applications, isA<ViewError<MyApplicationsFeed>>());

    applications.error = null;
    applications.results = page;
    await viewModel.retry();
    await settle();

    expect(applications.watchCalls, 2);
    expect(read().applications, isA<ViewData<MyApplicationsFeed>>());
    expect(feed().total, 5);
  });

  test('retry is ignored while the first snapshot is still loading', () async {
    applications.gate = Completer<void>();
    final viewModel = listen();

    expect(read().applications.isLoading, isTrue);
    await viewModel.retry();

    expect(applications.watchCalls, 1);
    applications.gate!.complete();
    applications.gate = null;
    await settle();
  });

  test('an account switch drops the previous list and resubscribes', () async {
    applications.results = page;
    listen();
    await settle();
    expect(read().applications, isA<ViewData<MyApplicationsFeed>>());

    applications.gate = Completer<void>();
    signedInUid = 'uid-456';
    container.invalidate(currentUserIdProvider);
    await settle();

    expect(applications.watchCalls, 2);
    // The old student's cards are gone while the new listener starts.
    expect(read().applications.isLoading, isTrue);

    applications.gate!.complete();
    applications.gate = null;
    await settle();

    expect(read().applications, isA<ViewData<MyApplicationsFeed>>());
  });
}
