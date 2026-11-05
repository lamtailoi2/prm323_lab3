import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/widgets/app_button.dart';
import 'package:internly/features/applications/widgets/cv_match_step.dart';
import 'package:internly/models/cv_match_result.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/cv_match_service.dart';
import 'package:internly/theme/app_sizes.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

const _path = 'cvs/uid-123/cv.pdf';
const _job = 'job-1';

CvMatchResult _result({
  List<String> matched = const <String>['Flutter'],
  List<String> missing = const <String>['Dart'],
  List<String> niceToHave = const <String>['Docker'],
  List<CvMatchSuggestion> suggestions = const <CvMatchSuggestion>[
    CvMatchSuggestion(skill: 'Dart', text: 'Mention your Dart project.'),
  ],
  int matchedCount = 1,
  int totalRequired = 2,
  int percent = 50,
  String summary = 'A solid start.',
  bool cvReadable = true,
}) {
  return CvMatchResult(
    internshipTitle: 'Flutter Intern',
    companyName: 'Northstar Labs',
    percent: percent,
    matchedCount: matchedCount,
    totalRequired: totalRequired,
    matched: matched,
    missing: missing,
    niceToHave: niceToHave,
    suggestions: suggestions,
    summary: summary,
    cvReadable: cvReadable,
  );
}

Future<void> _pumpStep(
  WidgetTester tester, {
  required FakeCvMatchService match,
  VoidCallback? onContinue,
  VoidCallback? onEdit,
  double width = AppSizes.baseWidth,
}) async {
  setScreenSize(tester, width: width);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // The Apply flow reaches this step with the auth state resolved.
        currentUserIdProvider.overrideWithValue(testUser.uid),
        cvMatchServiceProvider.overrideWithValue(match),
        analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: CvMatchStep(
              storagePath: _path,
              internshipKey: _job,
              onContinue: onContinue ?? () {},
              onEdit: onEdit,
            ),
          ),
        ),
      ),
    ),
  );
}

AppButton _button(WidgetTester tester, String label) =>
    tester.widget<AppButton>(find.widgetWithText(AppButton, label));

void main() {
  testWidgets('gaps show the score, matched skills and one suggestion each', (
    tester,
  ) async {
    final match = FakeCvMatchService()..result = _result();
    var continued = 0;
    var edited = 0;
    await _pumpStep(
      tester,
      match: match,
      onContinue: () => continued++,
      onEdit: () => edited++,
    );
    await tester.pumpAndSettle();

    expect(match.calls, 1);
    expect(match.paths, [_path]);
    expect(match.internshipKeys, [_job]);
    expect(find.text('50% match'), findsOneWidget);
    expect(find.text('1 of 2 requirements matched'), findsOneWidget);
    expect(find.text('Medium match'), findsOneWidget);
    expect(find.text('A solid start.'), findsOneWidget);
    expect(find.text('Matched'), findsOneWidget);
    expect(find.text('Gaps to review'), findsOneWidget);
    expect(find.text('Dart'), findsOneWidget);
    expect(find.text('Mention your Dart project.'), findsOneWidget);
    expect(find.text('Nice to have'), findsOneWidget);
    expect(find.text('Docker'), findsOneWidget);
    expect(
      find.text(
        'This check is a guide. You can continue even if something is missing.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('For this check, text from your CV is sent to our server.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(AppButton, 'Continue'));
    await tester.tap(find.widgetWithText(AppButton, 'Edit skills'));
    expect(continued, 1);
    expect(edited, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Continue stays available while the check runs', (tester) async {
    final match = FakeCvMatchService()..gate = Completer<void>();
    await _pumpStep(tester, match: match);

    await tester.pump();
    await tester.pump();

    expect(
      find.text('Checking your CV against this internship…'),
      findsOneWidget,
    );
    expect(_button(tester, 'Continue').onPressed, isNotNull);

    match.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Gaps to review'), findsOneWidget);
  });

  testWidgets('all matched continues without an Edit skills action', (
    tester,
  ) async {
    var continued = 0;
    final match = FakeCvMatchService()
      ..result = _result(
        missing: const <String>[],
        suggestions: const <CvMatchSuggestion>[],
        matchedCount: 2,
        percent: 100,
        summary: 'Your CV covers every skill this internship lists.',
      );
    await _pumpStep(
      tester,
      match: match,
      onContinue: () => continued++,
      onEdit: () {},
    );
    await tester.pumpAndSettle();

    expect(find.text('Your CV covers every requirement'), findsOneWidget);
    expect(find.text('Gaps to review'), findsNothing);
    await tester.tap(find.widgetWithText(AppButton, 'Continue'));
    expect(continued, 1);
  });

  testWidgets('a listing without requirements explains why', (tester) async {
    final match = FakeCvMatchService()
      ..result = _result(
        matched: const <String>[],
        missing: const <String>[],
        niceToHave: const <String>[],
        suggestions: const <CvMatchSuggestion>[],
        matchedCount: 0,
        totalRequired: 0,
        percent: 0,
        summary: 'This internship does not list specific skills to compare.',
      );
    await _pumpStep(tester, match: match);
    await tester.pumpAndSettle();

    expect(find.text('Nothing to compare yet'), findsOneWidget);
    expect(
      find.text('This internship does not list specific skills to compare.'),
      findsOneWidget,
    );
    expect(find.text('Gaps to review'), findsNothing);
  });

  testWidgets('an unreadable CV is explained instead of failing', (
    tester,
  ) async {
    final match = FakeCvMatchService()
      ..result = _result(cvReadable: false, niceToHave: const <String>[]);
    await _pumpStep(tester, match: match);
    await tester.pumpAndSettle();

    expect(find.text('We could not read your CV'), findsOneWidget);
    expect(find.text('Gaps to review'), findsOneWidget);
  });

  testWidgets('a failed check offers Retry and Continue', (tester) async {
    final match = FakeCvMatchService()
      ..error = const AppException(AppErrorKind.network, 'Offline.');
    await _pumpStep(tester, match: match);
    await tester.pumpAndSettle();

    expect(find.text('We could not check your CV'), findsOneWidget);
    expect(find.text('Offline.'), findsOneWidget);
    expect(_button(tester, 'Continue').onPressed, isNotNull);

    match.error = null;
    match.result = _result();
    await tester.tap(find.widgetWithText(AppButton, 'Retry'));
    await tester.pumpAndSettle();

    expect(match.calls, 2);
    expect(find.text('Gaps to review'), findsOneWidget);
  });

  for (final width in checkWidths) {
    testWidgets('gaps fit and keep 48 dp targets at $width dp', (tester) async {
      final match = FakeCvMatchService()
        ..result = _result(
          matched: const <String>['Flutter', 'SQL', 'Git', 'REST API'],
          missing: const <String>['Dart', 'Kubernetes'],
          niceToHave: const <String>['Docker', 'GraphQL'],
          suggestions: const <CvMatchSuggestion>[
            CvMatchSuggestion(
              skill: 'Dart',
              text: 'Add your Dart coursework or a small Dart project.',
            ),
            CvMatchSuggestion(
              skill: 'Kubernetes',
              text: 'Mention any container deployment you have tried.',
            ),
          ],
          matchedCount: 4,
          totalRequired: 6,
          percent: 67,
        );
      await _pumpStep(tester, match: match, width: width, onEdit: () {});
      await tester.pumpAndSettle();

      expect(find.text('67% match'), findsOneWidget);
      expect(find.text('4 of 6 requirements matched'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('Kubernetes'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  }
}
