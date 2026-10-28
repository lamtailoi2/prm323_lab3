import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/app/app.dart';
import 'package:internly/app/app_shell.dart';
import 'package:internly/app/router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/models/app_user.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/crashlytics_service.dart';
import 'package:internly/services/internship_service.dart';
import 'package:internly/services/remote_config_service.dart';
import 'package:internly/services/search_history_service.dart';

import '../helpers/fakes.dart';
import '../helpers/pump.dart';

void main() {
  group('authRedirect', () {
    const loading = AsyncLoading<AppUser?>();
    const signedOut = AsyncData<AppUser?>(null);
    const signedIn = AsyncData<AppUser?>(testUser);

    test('waits on Splash until the first auth event', () {
      expect(
        authRedirect(auth: loading, location: AppRoutes.home),
        AppRoutes.splash,
      );
      expect(authRedirect(auth: loading, location: AppRoutes.splash), isNull);
    });

    test('signed-out users can only reach Login', () {
      for (final location in [
        AppRoutes.splash,
        AppRoutes.home,
        AppRoutes.search,
        AppRoutes.saved,
        AppRoutes.applications,
        AppRoutes.profile,
      ]) {
        expect(
          authRedirect(auth: signedOut, location: location),
          AppRoutes.login,
          reason: location,
        );
      }
      expect(authRedirect(auth: signedOut, location: AppRoutes.login), isNull);
    });

    test('auth errors are treated as signed out', () {
      final error = AsyncError<AppUser?>(
        Exception('stream failed'),
        StackTrace.empty,
      );
      expect(
        authRedirect(auth: error, location: AppRoutes.home),
        AppRoutes.login,
      );
    });

    test('signed-in users skip Login and Splash', () {
      expect(
        authRedirect(auth: signedIn, location: AppRoutes.login),
        AppRoutes.home,
      );
      expect(
        authRedirect(auth: signedIn, location: AppRoutes.splash),
        AppRoutes.home,
      );
      expect(authRedirect(auth: signedIn, location: AppRoutes.saved), isNull);
    });
  });

  group('InternlyApp', () {
    late FakeAnalyticsService analytics;
    late FakeCrashlyticsService crashlytics;

    Future<FakeAuthService> pumpApp(
      WidgetTester tester, {
      AppUser? user,
      double width = 360,
    }) async {
      setScreenSize(tester, width: width);
      final auth = FakeAuthService(initialUser: user);
      analytics = FakeAnalyticsService();
      crashlytics = FakeCrashlyticsService();
      final internships = FakeInternshipService();
      final remoteConfig = FakeRemoteConfigService();
      final searchHistory = FakeSearchHistoryService();
      addTearDown(auth.dispose);
      addTearDown(internships.dispose);
      addTearDown(remoteConfig.dispose);
      addTearDown(searchHistory.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            analyticsServiceProvider.overrideWithValue(analytics),
            crashlyticsServiceProvider.overrideWithValue(crashlytics),
            internshipServiceProvider.overrideWithValue(internships),
            remoteConfigServiceProvider.overrideWithValue(remoteConfig),
            searchHistoryServiceProvider.overrideWithValue(searchHistory),
          ],
          child: const InternlyApp(),
        ),
      );
      await tester.pumpAndSettle();
      return auth;
    }

    testWidgets('signed out: shows Login; Google sign-in opens Home', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.text('Find your next internship'), findsOneWidget);
      expect(analytics.events, contains('login:google'));
    });

    for (final width in checkWidths) {
      testWidgets('signed in: five tabs with icon + label at $width dp', (
        tester,
      ) async {
        await pumpApp(tester, user: testUser, width: width);
        expect(find.byType(NavigationBar), findsOneWidget);
        for (final destination in AppDestination.values) {
          expect(find.text(destination.label), findsWidgets);
          expect(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.byIcon(destination.icon),
            ),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('tab navigation switches screens and logs screen_view', (
      tester,
    ) async {
      await pumpApp(tester, user: testUser);
      expect(analytics.screens, ['home']);

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      expect(find.text('Work mode'), findsOneWidget);

      await tester.tap(find.text('Applications'));
      await tester.pumpAndSettle();
      expect(find.text('My Applications is not built yet'), findsOneWidget);
      expect(analytics.screens, ['home', 'search', 'my_applications']);
      // Crashlytics custom key follows the current screen.
      expect(crashlytics.customKeys['last_screen'], 'my_applications');
    });

    testWidgets('cancelled Google sign-in shows a message', (tester) async {
      final auth = await pumpApp(tester);
      auth.signInError = const AppException(
        AppErrorKind.cancelled,
        'Sign-in was cancelled. Tap Continue with Google to try again.',
      );
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Sign-in was cancelled'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('sign out from Profile returns to Login', (tester) async {
      await pumpApp(tester, user: testUser);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(analytics.events, contains('logout'));
    });
  });
}
