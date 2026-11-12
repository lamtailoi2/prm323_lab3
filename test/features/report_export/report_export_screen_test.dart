import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/features/report_export/screens/report_export_screen.dart';
import 'package:internly/models/exported_report.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/external_link_service.dart';
import 'package:internly/services/report_export_service.dart';
import 'package:internly/theme/app_theme.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump.dart';

void main() {
  late FakeApplicationService applications;
  late FakeReportExportService reports;
  late FakeExternalLinkService links;

  setUp(() {
    applications = FakeApplicationService();
    reports = FakeReportExportService();
    links = FakeExternalLinkService();
  });

  tearDown(() async {
    await applications.dispose();
    await reports.dispose();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    double width = 360,
    double height = 900,
  }) async {
    setScreenSize(tester, width: width, height: height);
    final router = GoRouter(
      initialLocation: '/profile/export',
      routes: [
        GoRoute(
          path: '/profile/export',
          builder: (context, state) => const ReportExportScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          applicationServiceProvider.overrideWithValue(applications),
          reportExportServiceProvider.overrideWithValue(reports),
          analyticsServiceProvider.overrideWithValue(FakeAnalyticsService()),
          externalLinkServiceProvider.overrideWithValue(links),
          currentUserIdProvider.overrideWithValue(testUser.uid),
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(testUser),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in checkWidths) {
    testWidgets('shows the export action and the report list at $width dp', (
      tester,
    ) async {
      applications.results = [
        testApplication('1', appliedAt: DateTime(2026, 9, 18)),
        testApplication('2', appliedAt: DateTime(2026, 10, 1)),
      ];
      await pumpScreen(tester, width: width);

      expect(find.text('Report export'), findsOneWidget);
      expect(find.text('Application report'), findsOneWidget);
      expect(find.text('2 applications'), findsOneWidget);
      expect(find.text('Export report'), findsOneWidget);
      expect(find.text('No reports yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('exporting uploads and then lists the new report', (
    tester,
  ) async {
    applications.results = [testApplication('1')];
    await pumpScreen(tester);

    await tester.tap(find.text('Export report'));
    await tester.pumpAndSettle();

    expect(reports.exported, hasLength(1));
    expect(
      find.text('Last exported: application-report-2026-11-12.pdf'),
      findsOneWidget,
    );
    expect(find.text('Export again'), findsOneWidget);
  });

  testWidgets('no applications explains what to do instead of exporting', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Nothing to export yet'), findsOneWidget);
    expect(find.text('Export report'), findsNothing);
  });

  testWidgets('a load error shows the message and Retry', (tester) async {
    applications.error = const AppException(
      AppErrorKind.network,
      'We could not load your applications. Check your connection and try '
      'again.',
    );
    await pumpScreen(tester);

    expect(
      find.text(
        'We could not load your applications. Check your connection and try '
        'again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsWidgets);
  });

  testWidgets('an existing report opens from the list', (tester) async {
    applications.results = [testApplication('1')];
    reports.reports = [
      ExportedReport(
        id: 'r1',
        fileName: 'application-report-2026-11-12.pdf',
        url: 'https://storage.example/reports/uid-123/a.pdf',
        storagePath: 'reports/uid-123/a.pdf',
        sizeBytes: 2048,
        itemCount: 1,
        createdAt: DateTime(2026, 11, 12),
      ),
    ];
    await pumpScreen(tester);

    expect(find.text('application-report-2026-11-12.pdf'), findsOneWidget);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(
      links.opened.single.toString(),
      'https://storage.example/reports/uid-123/a.pdf',
    );
  });

  testWidgets('every tap target is at least 48 dp', (tester) async {
    applications.results = [testApplication('1')];
    reports.reports = [
      ExportedReport(
        id: 'r1',
        fileName: 'application-report-2026-11-12.pdf',
        url: 'https://storage.example/reports/uid-123/a.pdf',
        storagePath: 'reports/uid-123/a.pdf',
        sizeBytes: 2048,
        itemCount: 1,
        createdAt: DateTime(2026, 11, 12),
      ),
    ];
    await pumpScreen(tester);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });
}
