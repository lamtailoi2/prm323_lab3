import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/features/applications/widgets/cv_validation_step.dart';
import 'package:internly/models/cv_validation_result.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/cv_validation_service.dart';
import 'package:internly/theme/app_sizes.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

const _path = 'cvs/uid-123/cv.pdf';

Future<void> _pumpStep(
  WidgetTester tester, {
  required FakeAuthService auth,
  required FakeCvValidationService cv,
  VoidCallback? onValid,
  VoidCallback? onUpdateCv,
  double width = AppSizes.baseWidth,
}) async {
  setScreenSize(tester, width: width);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(auth),
        cvValidationServiceProvider.overrideWithValue(cv),
        analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: CvValidationStep(
            storagePath: _path,
            onValid: onValid,
            onUpdateCv: onUpdateCv,
          ),
        ),
      ),
    ),
  );
}

FakeAuthService _signedIn() {
  final auth = FakeAuthService(initialUser: testUser);
  addTearDown(auth.dispose);
  return auth;
}

void main() {
  testWidgets('shows the checking state until the callable resolves', (
    tester,
  ) async {
    final cv = FakeCvValidationService()..gate = Completer<void>();
    await _pumpStep(tester, auth: _signedIn(), cv: cv);

    await tester.pump();
    await tester.pump();

    expect(find.text('Checking your CV…'), findsOneWidget);
    expect(cv.calls, 1);
    expect(cv.paths, [_path]);

    cv.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Your CV looks good'), findsOneWidget);
  });

  testWidgets('a valid CV continues automatically', (tester) async {
    final cv = FakeCvValidationService();
    var valid = 0;
    await _pumpStep(tester, auth: _signedIn(), cv: cv, onValid: () => valid++);

    await tester.pumpAndSettle();

    expect(find.text('Your CV looks good'), findsOneWidget);
    expect(
      find.text('For this check, text from your CV is sent to our server.'),
      findsOneWidget,
    );
    expect(valid, 1);
  });

  testWidgets('a rejected CV blocks with Update CV and Retry', (tester) async {
    final cv = FakeCvValidationService()
      ..result = const CvValidationResult(
        isValid: false,
        reason: 'This file has no contact details.',
      );
    var updated = 0;
    await _pumpStep(
      tester,
      auth: _signedIn(),
      cv: cv,
      onUpdateCv: () => updated++,
    );

    await tester.pumpAndSettle();

    expect(find.text('We could not use this CV'), findsOneWidget);
    expect(find.text('This file has no contact details.'), findsOneWidget);
    expect(find.text('Update CV'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester, meetsGuideline(androidTapTargetGuideline));

    await tester.tap(find.text('Update CV'));
    await tester.pump();
    expect(updated, 1);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(cv.calls, 2);
    expect(find.text('We could not use this CV'), findsOneWidget);
  });

  testWidgets('a failed check shows its message and can be retried', (
    tester,
  ) async {
    final cv = FakeCvValidationService()
      ..error = const AppException(
        AppErrorKind.network,
        'We could not check your CV. Check your connection and try again.',
      );
    await _pumpStep(tester, auth: _signedIn(), cv: cv);

    await tester.pumpAndSettle();

    expect(find.text('We could not check your CV'), findsOneWidget);
    expect(
      find.text(
        'We could not check your CV. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Update CV'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('the step has no overflow at 360 and 412 dp', (tester) async {
    for (final width in checkWidths) {
      final cv = FakeCvValidationService()
        ..result = const CvValidationResult(
          isValid: false,
          reason: 'This file has no contact details.',
        );
      await _pumpStep(tester, auth: _signedIn(), cv: cv, width: width);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Update CV'), findsOneWidget);
      expect(tester, meetsGuideline(androidTapTargetGuideline));
    }
  });
}
