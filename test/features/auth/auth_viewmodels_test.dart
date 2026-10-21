import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/features/auth/viewmodels/login_viewmodel.dart';
import 'package:internly/features/auth/viewmodels/sign_out_viewmodel.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeAuthService auth;
  late FakeAnalyticsService analytics;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthService();
    analytics = FakeAnalyticsService();
    container = ProviderContainer.test(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        analyticsServiceProvider.overrideWithValue(analytics),
      ],
    );
  });

  tearDown(() => auth.dispose());

  group('LoginViewModel', () {
    LoginViewModel listen() {
      // Keep the auto-dispose provider alive, as the screen would.
      container.listen(loginViewModelProvider, (_, _) {});
      return container.read(loginViewModelProvider.notifier);
    }

    test('starts idle', () {
      listen();
      expect(
        container.read(loginViewModelProvider),
        const AsyncData<void>(null),
      );
    });

    test(
      'success: loading, then idle, and logs login with method google',
      () async {
        final vm = listen();
        auth.signInGate = Completer<void>();

        final future = vm.signInWithGoogle();
        expect(container.read(loginViewModelProvider).isLoading, isTrue);

        auth.signInGate!.complete();
        await future;
        expect(container.read(loginViewModelProvider).hasError, isFalse);
        expect(container.read(loginViewModelProvider).isLoading, isFalse);
        expect(analytics.events, ['login:google']);
      },
    );

    test('ignores taps while a sign-in is in progress', () async {
      final vm = listen();
      auth.signInGate = Completer<void>();
      final first = vm.signInWithGoogle();
      await vm.signInWithGoogle();
      auth.signInGate!.complete();
      await first;
      expect(auth.signInCalls, 1);
    });

    test('cancelled picker returns to idle without an error', () async {
      final vm = listen();
      auth.signInError = const AppException(
        AppErrorKind.cancelled,
        'Sign-in was cancelled.',
      );
      await vm.signInWithGoogle();
      expect(
        container.read(loginViewModelProvider),
        const AsyncData<void>(null),
      );
      expect(analytics.events, isEmpty);
    });

    test('network failure exposes a plain-language error', () async {
      final vm = listen();
      auth.signInError = const AppException(
        AppErrorKind.network,
        'We could not sign you in. Check your connection and try again.',
      );
      await vm.signInWithGoogle();
      final state = container.read(loginViewModelProvider);
      expect(state.error, isA<AppException>());
      expect((state.error! as AppException).kind, AppErrorKind.network);
      expect(analytics.events, isEmpty);
    });
  });

  group('SignOutViewModel', () {
    SignOutViewModel listen() {
      container.listen(signOutViewModelProvider, (_, _) {});
      return container.read(signOutViewModelProvider.notifier);
    }

    test('logs logout and signs out', () async {
      await listen().signOut();
      expect(auth.signOutCalls, 1);
      expect(analytics.events, ['logout']);
      expect(container.read(signOutViewModelProvider).hasError, isFalse);
    });

    test('exposes a sign-out failure', () async {
      auth.signOutError = const AppException(AppErrorKind.network, 'Offline');
      await listen().signOut();
      expect(
        container.read(signOutViewModelProvider).error,
        isA<AppException>(),
      );
    });
  });
}
