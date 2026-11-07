import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/features/applications/viewmodels/cv_match_viewmodel.dart';
import 'package:internly/models/cv_match_result.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/cv_match_service.dart';

import '../../helpers/fakes.dart';

const _path = 'cvs/uid-123/cv-abc.pdf';
const _job = 'job-1';

CvMatchResult _result({
  List<String> missing = const <String>['Dart'],
  int totalRequired = 2,
  int matchedCount = 1,
  int percent = 50,
}) {
  return CvMatchResult(
    internshipTitle: 'Flutter Intern',
    companyName: 'Northstar Labs',
    percent: percent,
    matchedCount: matchedCount,
    totalRequired: totalRequired,
    matched: const <String>['Flutter'],
    missing: missing,
    niceToHave: const <String>[],
    suggestions: const <CvMatchSuggestion>[],
    summary: 'A solid start.',
    cvReadable: true,
  );
}

void main() {
  late FakeAuthService auth;
  late FakeCvMatchService match;
  late FakeAnalyticsService analytics;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthService(initialUser: testUser);
    match = FakeCvMatchService();
    analytics = FakeAnalyticsService();
    container = ProviderContainer.test(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        cvMatchServiceProvider.overrideWithValue(match),
        analyticsServiceProvider.overrideWithValue(analytics),
      ],
    );
  });

  tearDown(() async {
    await auth.dispose();
  });

  Future<void> signedIn() async {
    container.listen(authStateChangesProvider, (_, _) {});
    await container.read(authStateChangesProvider.future);
    container.listen(cvMatchViewModelProvider, (_, _) {});
  }

  ViewState<CvMatchResult> state() => container.read(cvMatchViewModelProvider);

  CvMatchViewModel viewModel() =>
      container.read(cvMatchViewModelProvider.notifier);

  test('gaps reach ViewData and log both counts', () async {
    match.result = _result();
    await signedIn();

    final result = await viewModel().run(
      storagePath: _path,
      internshipKey: _job,
    );

    expect(result, _result());
    expect(state(), isA<ViewData<CvMatchResult>>());
    expect(match.paths, [_path]);
    expect(match.internshipKeys, [_job]);
    expect(analytics.events, contains('cv_match_check'));
    expect(
      analytics.parameters['cv_match_check'],
      equals(<String, Object>{
        'internship_id': _job,
        'result': 'gaps',
        'matched_count': 1,
        'missing_count': 1,
      }),
    );
  });

  test('all matched logs all_matched', () async {
    match.result = _result(
      missing: const <String>[],
      totalRequired: 2,
      matchedCount: 2,
      percent: 100,
    );
    await signedIn();

    await viewModel().run(storagePath: _path, internshipKey: _job);

    expect(
      analytics.parameters['cv_match_check'],
      equals(<String, Object>{
        'internship_id': _job,
        'result': 'all_matched',
        'matched_count': 2,
        'missing_count': 0,
      }),
    );
  });

  test('a listing without requirements is data but logs nothing', () async {
    match.result = _result(
      missing: const <String>[],
      totalRequired: 0,
      matchedCount: 0,
      percent: 0,
    );
    await signedIn();

    await viewModel().run(storagePath: _path, internshipKey: _job);

    expect(state(), isA<ViewData<CvMatchResult>>());
    expect(analytics.events, isNot(contains('cv_match_check')));
  });

  test('a failed check is ViewError and logs failed', () async {
    match.error = const AppException(AppErrorKind.network, 'Offline.');
    await signedIn();

    final result = await viewModel().run(
      storagePath: _path,
      internshipKey: _job,
    );

    expect(result, isNull);
    final error = (state() as ViewError<CvMatchResult>).error;
    expect(error.kind, AppErrorKind.network);
    expect(
      analytics.parameters['cv_match_check'],
      equals(<String, Object>{
        'internship_id': _job,
        'result': 'failed',
        'matched_count': 0,
        'missing_count': 0,
      }),
    );
  });

  test('a repeated tap while the check runs starts one call', () async {
    match.gate = Completer<void>();
    await signedIn();

    final first = viewModel().run(storagePath: _path, internshipKey: _job);
    final second = await viewModel().run(
      storagePath: _path,
      internshipKey: _job,
    );

    expect(second, isNull);
    expect(match.calls, 1);
    match.gate!.complete();
    await first;
    expect(state(), isA<ViewData<CvMatchResult>>());
  });

  test('a signed-out student gets a permission error and no call', () async {
    final signedOut = ProviderContainer.test(
      overrides: [
        currentUserIdProvider.overrideWithValue(null),
        cvMatchServiceProvider.overrideWithValue(match),
        analyticsServiceProvider.overrideWithValue(analytics),
      ],
    );
    signedOut.listen(cvMatchViewModelProvider, (_, _) {});

    final result = await signedOut
        .read(cvMatchViewModelProvider.notifier)
        .run(storagePath: _path, internshipKey: _job);

    expect(result, isNull);
    expect(match.calls, 0);
    expect(analytics.events, isEmpty);
    expect(
      (signedOut.read(
        cvMatchViewModelProvider,
      ) as ViewError<CvMatchResult>).error.kind,
      AppErrorKind.permissionDenied,
    );
  });
}
