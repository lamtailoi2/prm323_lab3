import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/features/applications/viewmodels/cv_validation_viewmodel.dart';
import 'package:internly/models/cv_validation_result.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/cv_validation_service.dart';

import '../../helpers/fakes.dart';

const _path = 'cvs/uid-123/cv-abc.pdf';

void main() {
  late FakeAuthService auth;
  late FakeCvValidationService cv;
  late FakeAnalyticsService analytics;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthService(initialUser: testUser);
    cv = FakeCvValidationService();
    analytics = FakeAnalyticsService();
    container = ProviderContainer.test(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        cvValidationServiceProvider.overrideWithValue(cv),
        analyticsServiceProvider.overrideWithValue(analytics),
      ],
    );
  });

  tearDown(() async {
    await auth.dispose();
  });

  /// Keeps the auto-dispose ViewModel alive, as the step widget does, and
  /// waits for the first auth event.
  Future<void> signedIn() async {
    container.listen(authStateChangesProvider, (_, _) {});
    await container.read(authStateChangesProvider.future);
    container.listen(cvValidationViewModelProvider, (_, _) {});
  }

  ViewState<CvValidationResult> state() =>
      container.read(cvValidationViewModelProvider);

  CvValidationViewModel viewModel() =>
      container.read(cvValidationViewModelProvider.notifier);

  test('a valid CV reaches ViewData and logs the result', () async {
    await signedIn();

    final result = await viewModel().validate(_path);

    expect(result, const CvValidationResult(isValid: true));
    expect(state(), isA<ViewData<CvValidationResult>>());
    expect(cv.paths, [_path]);
    expect(analytics.events, contains('cv_validation_result'));
    expect(
      analytics.parameters['cv_validation_result'],
      equals(<String, Object>{'is_valid': true}),
    );
  });

  test('a rejected CV is data with a user-safe reason', () async {
    await signedIn();
    const rejected = CvValidationResult(
      isValid: false,
      reason: 'This file has no contact details.',
    );
    cv.result = rejected;

    final result = await viewModel().validate(_path);

    expect(result, rejected);
    expect(state(), isA<ViewData<CvValidationResult>>());
    expect(
      (state() as ViewData<CvValidationResult>).data.reason,
      'This file has no contact details.',
    );
    expect(
      analytics.parameters['cv_validation_result'],
      equals(<String, Object>{'is_valid': false}),
    );
  });

  test('loading is visible until the callable resolves', () async {
    await signedIn();
    cv.gate = Completer<void>();

    final pending = viewModel().validate(_path);
    await pumpEventQueue();
    expect(state(), isA<ViewLoading<CvValidationResult>>());

    cv.gate!.complete();
    await pending;
    expect(state(), isA<ViewData<CvValidationResult>>());
  });

  test('repeated taps while loading start only one call', () async {
    await signedIn();
    cv.gate = Completer<void>();

    final first = viewModel().validate(_path);
    await pumpEventQueue();
    final second = await viewModel().validate(_path);

    expect(second, isNull);
    expect(cv.calls, 1);

    cv.gate!.complete();
    await first;
  });

  test('a failed check becomes ViewError and logs no result', () async {
    await signedIn();
    cv.error = const AppException(
      AppErrorKind.network,
      'We could not check your CV. Check your connection and try again.',
    );

    final result = await viewModel().validate(_path);

    expect(result, isNull);
    expect(state(), isA<ViewError<CvValidationResult>>());
    expect(
      (state() as ViewError<CvValidationResult>).error.kind,
      AppErrorKind.network,
    );
    expect(analytics.events, isEmpty);
  });

  test('a signed-out student cannot start a check', () async {
    final signedOutAuth = FakeAuthService();
    addTearDown(signedOutAuth.dispose);
    final signedOutContainer = ProviderContainer.test(
      overrides: [
        authServiceProvider.overrideWithValue(signedOutAuth),
        cvValidationServiceProvider.overrideWithValue(cv),
        analyticsServiceProvider.overrideWithValue(analytics),
      ],
    );
    signedOutContainer.listen(authStateChangesProvider, (_, _) {});
    await signedOutContainer.read(authStateChangesProvider.future);
    signedOutContainer.listen(cvValidationViewModelProvider, (_, _) {});

    final result = await signedOutContainer
        .read(cvValidationViewModelProvider.notifier)
        .validate(_path);

    expect(result, isNull);
    expect(cv.calls, 0);
    expect(
      signedOutContainer.read(cvValidationViewModelProvider),
      isA<ViewError<CvValidationResult>>(),
    );
    expect(
      (signedOutContainer.read(
        cvValidationViewModelProvider,
      ) as ViewError<CvValidationResult>).error.kind,
      AppErrorKind.permissionDenied,
    );
  });
}
