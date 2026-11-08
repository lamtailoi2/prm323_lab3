import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/features/auth/screens/login_screen.dart';
import 'package:internly/features/auth/widgets/google_sign_in_button.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/user_profile_service.dart';
import 'package:internly/theme/app_sizes.dart';
import 'package:internly/theme/app_theme.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeAuthService auth;
  late FakeAnalyticsService analytics;

  setUp(() {
    auth = FakeAuthService();
    analytics = FakeAnalyticsService();
  });

  tearDown(() => auth.dispose());

  Future<void> pumpLogin(
    WidgetTester tester, {
    double width = AppSizes.baseWidth,
    double height = 800,
    double textScale = 1,
  }) async {
    setScreenSize(tester, width: width, height: height);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          analyticsServiceProvider.overrideWithValue(analytics),
          userProfileServiceProvider.overrideWithValue(
            FakeUserProfileService(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const LoginScreen(),
        ),
      ),
    );
  }

  Finder googleLogo() =>
      find.image(const AssetImage(GoogleSignInButton.logoAsset));

  for (final width in checkWidths) {
    testWidgets('shows the Login frame content at $width dp', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpLogin(tester, width: width);

      expect(find.bySemanticsLabel('Internly'), findsOneWidget);
      expect(find.text('Start your IT career'), findsOneWidget);
      expect(
        find.text('Connecting tech students with hundreds of top internships.'),
        findsOneWidget,
      );
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(googleLogo(), findsOneWidget);
      expect(
        find.image(const AssetImage(LoginScreen.backgroundAsset)),
        findsOneWidget,
      );
      expect(find.text('By continuing, you agree to our'), findsOneWidget);
      expect(find.bySemanticsLabel('Terms'), findsOneWidget);
      expect(find.bySemanticsLabel('Privacy'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The legal line fits on one line, as in the frame.
      final sentence = tester.getCenter(
        find.text('By continuing, you agree to our'),
      );
      final privacy = tester.getCenter(find.bySemanticsLabel('Privacy'));
      expect(privacy.dy, moreOrLessEquals(sentence.dy, epsilon: 1));

      final button = tester.getSize(find.byType(FilledButton));
      expect(button.height, greaterThanOrEqualTo(AppSizes.buttonHeight));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });
  }

  testWidgets('Continue with Google signs in and logs the login event', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(auth.signInCalls, 1);
    expect(analytics.events, contains('login:google'));
  });

  testWidgets('loading: a spinner replaces the G and taps are ignored', (
    tester,
  ) async {
    final gate = Completer<void>();
    auth.signInGate = gate;
    await pumpLogin(tester);

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(googleLogo(), findsNothing);
    expect(
      find.bySemanticsLabel('Continue with Google, loading'),
      findsOneWidget,
    );

    await tester.tap(find.text('Continue with Google'), warnIfMissed: false);
    await tester.pump();
    expect(auth.signInCalls, 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('error: the message appears above the button', (tester) async {
    auth.signInError = const AppException(
      AppErrorKind.network,
      'Check your internet connection and try again.',
    );
    await pumpLogin(tester);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    final message = find.text('Check your internet connection and try again.');
    expect(message, findsOneWidget);
    expect(find.byIcon(Symbols.error_rounded), findsOneWidget);
    expect(
      tester.getBottomLeft(message).dy,
      lessThan(tester.getTopLeft(find.byType(FilledButton)).dy),
    );
    // The button is usable again for a retry.
    expect(googleLogo(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelled picker: shown as information, not as an error', (
    tester,
  ) async {
    auth.signInError = const AppException(
      AppErrorKind.cancelled,
      'Sign-in was cancelled.',
    );
    await pumpLogin(tester);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Sign-in was cancelled.'), findsOneWidget);
    expect(find.byIcon(Symbols.info_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.error_rounded), findsNothing);
  });

  testWidgets('Terms and Privacy say they are coming soon (G-31)', (
    tester,
  ) async {
    await pumpLogin(tester);

    await tester.tap(find.bySemanticsLabel('Terms'));
    await tester.pump();
    expect(find.text('The terms of use are coming soon.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Privacy'));
    await tester.pumpAndSettle();
    expect(find.text('The privacy policy is coming soon.'), findsOneWidget);
    expect(find.text('The terms of use are coming soon.'), findsNothing);
    expect(auth.signInCalls, 0);
  });

  testWidgets('large text on a short screen scrolls instead of overflowing', (
    tester,
  ) async {
    await pumpLogin(tester, height: 640, textScale: 2);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.bySemanticsLabel('Privacy'),
      100,
      scrollable: find.byType(Scrollable),
    );
    expect(find.bySemanticsLabel('Privacy').hitTestable(), findsOneWidget);
  });
}
