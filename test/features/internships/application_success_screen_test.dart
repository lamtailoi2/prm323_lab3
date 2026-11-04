import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/features/internships/screens/application_success_screen.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/pump.dart';

void main() {
  Future<void> pumpSuccess(
    WidgetTester tester, {
    double width = 360,
    String? title = 'Flutter Developer Intern',
    String? company = 'FPT Software',
    WorkMode? workMode = WorkMode.remote,
    DateTime? submittedAt,
  }) async {
    setScreenSize(tester, width: width, height: 900);
    final router = GoRouter(
      initialLocation: '/success',
      routes: [
        GoRoute(
          path: '/success',
          builder: (context, state) => ApplicationSuccessScreen(
            internshipTitle: title,
            companyName: company,
            workMode: workMode,
            submittedAt: submittedAt,
          ),
        ),
        GoRoute(
          path: '/applications',
          builder: (context, state) => const Text('Applications tab'),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Text('Home tab'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
    );
    await tester.pumpAndSettle();
  }

  for (final width in checkWidths) {
    testWidgets('confirms the application with the recap at $width dp', (
      tester,
    ) async {
      await pumpSuccess(
        tester,
        width: width,
        submittedAt: DateTime(2026, 10, 19, 22, 20),
      );

      expect(find.text('Application submitted!'), findsOneWidget);
      expect(
        find.text(
          'Your application for Flutter Developer Intern at FPT Software is '
          'saved in My Applications.',
        ),
        findsOneWidget,
      );
      expect(find.text('Flutter Developer Intern'), findsOneWidget);
      expect(find.text('FPT Software · Remote'), findsOneWidget);
      expect(find.text('Submitted Oct 19, 2026, 22:20'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);

      expect(find.text('What happens next?'), findsOneWidget);
      expect(
        find.text('We saved your details and CV with this application.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Update the status in My Applications when the company replies.',
        ),
        findsOneWidget,
      );

      expect(find.text('View my applications'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  }

  testWidgets('without a recap it still confirms and offers both steps', (
    tester,
  ) async {
    await pumpSuccess(tester, title: null, company: null);

    expect(find.text('Application submitted!'), findsOneWidget);
    expect(
      find.text('Your application is saved in My Applications.'),
      findsOneWidget,
    );
    expect(find.text('View my applications'), findsOneWidget);
  });

  testWidgets('View my applications opens the Applications tab', (
    tester,
  ) async {
    await pumpSuccess(tester);

    await tester.tap(find.text('View my applications'));
    await tester.pumpAndSettle();
    expect(find.text('Applications tab'), findsOneWidget);
  });

  testWidgets('Back to Home opens Home', (tester) async {
    await pumpSuccess(tester);

    await tester.tap(find.text('Back to Home'));
    await tester.pumpAndSettle();
    expect(find.text('Home tab'), findsOneWidget);
  });
}
