import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/features/applications/viewmodels/application_detail_viewmodel.dart';
import 'package:internly/models/internship_application.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/internship_service.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeApplicationService applications;
  late FakeInternshipService internships;
  late FakeAnalyticsService analytics;

  final appliedAt = DateTime(2026, 10, 11, 9);
  final withdrawnAt = DateTime(2026, 10, 12, 9);
  final application = testApplication(
    '1',
    title: 'Flutter Developer Intern',
    companyName: 'FPT Software',
    appliedAt: appliedAt,
    status: ApplicationStatus.underReview,
  );
  final key = application.jobKey;
  final withdrawn = InternshipApplication(
    jobKey: key,
    title: application.title,
    companyName: application.companyName,
    appliedAt: appliedAt,
    status: ApplicationStatus.withdrawn,
    withdrawnAt: withdrawnAt,
    previousStatus: ApplicationStatus.underReview,
  );

  setUp(() {
    applications = FakeApplicationService()..results = [application];
    internships = FakeInternshipService();
    analytics = FakeAnalyticsService();
  });

  tearDown(() async {
    await applications.dispose();
    await internships.dispose();
  });

  ProviderContainer build({DateTime? now}) {
    final container = ProviderContainer.test(
      overrides: [
        applicationServiceProvider.overrideWithValue(applications),
        internshipServiceProvider.overrideWithValue(internships),
        analyticsServiceProvider.overrideWithValue(analytics),
        currentUserIdProvider.overrideWithValue(testUser.uid),
        nowProvider.overrideWithValue(() => now ?? DateTime(2026, 10, 12, 10)),
      ],
    );
    container.listen(applicationDetailViewModelProvider(key), (_, _) {});
    return container;
  }

  ApplicationDetailState read(ProviderContainer container) =>
      container.read(applicationDetailViewModelProvider(key));

  ApplicationDetailViewModel viewModel(ProviderContainer container) =>
      container.read(applicationDetailViewModelProvider(key).notifier);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('loads the application and logs view_application once', () async {
    final container = build();
    expect(read(container).detail, isA<ViewLoading<ApplicationDetail>>());

    await settle();
    await settle();

    final detail = read(container).detail as ViewData<ApplicationDetail>;
    expect(detail.data.application.jobKey, key);
    expect(detail.data.application.status, ApplicationStatus.underReview);
    expect(analytics.parameters['view_application'], {
      'internship_id': key,
      'status': 'under_review',
    });
    expect(
      analytics.events.where((event) => event == 'view_application'),
      hasLength(1),
    );
  });

  test('an application that is gone is the empty state', () async {
    applications.results = const <InternshipApplication>[];
    final container = build();
    await settle();
    await settle();

    expect(read(container).detail, isA<ViewEmpty<ApplicationDetail>>());
  });

  test('a load error shows the error state; Retry listens again', () async {
    applications.error = const AppException(
      AppErrorKind.network,
      'We could not reach Internly.',
    );
    final container = build();
    await settle();
    expect(read(container).detail, isA<ViewError<ApplicationDetail>>());

    applications.error = null;
    viewModel(container).retry();
    await settle();
    await settle();
    expect(read(container).detail, isA<ViewData<ApplicationDetail>>());
    expect(applications.watchCalls, 2);
  });

  test('withdraw keeps the previous status for Undo', () async {
    final container = build();
    await settle();

    expect(await viewModel(container).withdraw(), isTrue);
    expect(applications.withdrawn, [
      (internshipKey: key, previous: ApplicationStatus.underReview),
    ]);

    // The screen follows the live document.
    applications.emit([withdrawn]);
    await settle();
    expect(
      (read(container).detail as ViewData<ApplicationDetail>)
          .data
          .application
          .status,
      ApplicationStatus.withdrawn,
    );
  });

  test('Undo is offered for 24 hours only', () async {
    applications.results = [withdrawn];

    final inside = build(now: withdrawnAt.add(const Duration(hours: 23)));
    await settle();
    await settle();
    expect(read(inside).canUndoWithdrawal, isTrue);
    expect(
      read(inside).undoDeadline,
      withdrawnAt.add(ApplicationDetailViewModel.undoWindow),
    );
    expect(await viewModel(inside).undoWithdrawal(), isTrue);
    expect(applications.undone, [key]);

    applications.undone.clear();
    final after = build(now: withdrawnAt.add(const Duration(hours: 25)));
    await settle();
    await settle();
    expect(read(after).canUndoWithdrawal, isFalse);
    expect(await viewModel(after).undoWithdrawal(), isFalse);
    expect(applications.undone, isEmpty);
  });

  test('a failed withdraw keeps the screen and reports the message', () async {
    applications.updateError = const AppException(
      AppErrorKind.network,
      'We could not submit your application. Check your connection and try '
      'again.',
    );
    final container = build();
    await settle();

    expect(await viewModel(container).withdraw(), isFalse);
    final action = read(container).action;
    expect(action, isA<AsyncError<void>>());
    expect((action as AsyncError<void>).error, isA<AppException>());
  });

  test('a second tap while the write runs is ignored', () async {
    applications.updateGate = Completer<void>();
    final container = build();
    await settle();

    final first = viewModel(container).withdraw();
    await settle();
    expect(read(container).action.isLoading, isTrue);
    expect(await viewModel(container).withdraw(), isFalse);

    applications.updateGate!.complete();
    expect(await first, isTrue);
    expect(applications.withdrawn, hasLength(1));
  });
}
