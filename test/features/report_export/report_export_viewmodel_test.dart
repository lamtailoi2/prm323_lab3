import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/errors/app_exception.dart';
import 'package:internly/core/state/view_state.dart';
import 'package:internly/features/report_export/viewmodels/report_export_viewmodel.dart';
import 'package:internly/models/exported_report.dart';
import 'package:internly/models/internship_application.dart';
import 'package:internly/services/analytics_service.dart';
import 'package:internly/services/application_service.dart';
import 'package:internly/services/auth_service.dart';
import 'package:internly/services/external_link_service.dart';
import 'package:internly/services/report_export_service.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeApplicationService applications;
  late FakeReportExportService reports;
  late FakeAnalyticsService analytics;
  late FakeExternalLinkService links;
  late ProviderContainer container;

  setUp(() {
    applications = FakeApplicationService();
    reports = FakeReportExportService();
    analytics = FakeAnalyticsService();
    links = FakeExternalLinkService();
    container = ProviderContainer.test(
      overrides: [
        applicationServiceProvider.overrideWithValue(applications),
        reportExportServiceProvider.overrideWithValue(reports),
        analyticsServiceProvider.overrideWithValue(analytics),
        externalLinkServiceProvider.overrideWithValue(links),
        currentUserIdProvider.overrideWith((ref) => testUser.uid),
      ],
    );
  });

  tearDown(() async {
    await applications.dispose();
    await reports.dispose();
  });

  ReportExportViewModel listen() {
    // Keep the auto-dispose provider alive, as the screen would.
    container.listen(reportExportViewModelProvider, (_, _) {});
    return container.read(reportExportViewModelProvider.notifier);
  }

  ReportExportState read() => container.read(reportExportViewModelProvider);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  final page = [
    testApplication('1', appliedAt: DateTime(2026, 9, 18)),
    testApplication(
      '2',
      appliedAt: DateTime(2026, 10, 1),
      status: ApplicationStatus.interview,
    ),
  ];

  test('starts loading, then shows the applications to export', () async {
    applications.results = page;
    final viewModel = listen();

    expect(
      read().applications,
      isA<ViewLoading<List<InternshipApplication>>>(),
    );
    expect(read().reports, isA<ViewLoading<List<ExportedReport>>>());

    await settle();

    final loaded =
        (read().applications as ViewData<List<InternshipApplication>>).data;
    expect(loaded, hasLength(2));
    expect(read().reports, isA<ViewEmpty<List<ExportedReport>>>());
    expect(viewModel.summary, contains('2 applications'));
  });

  test('no applications shows the empty state, not an error', () async {
    final viewModel = listen();
    await settle();

    expect(read().applications, isA<ViewEmpty<List<InternshipApplication>>>());
    expect(viewModel.summary, isNull);
  });

  test(
    'export reports the upload progress, the report and the event',
    () async {
      applications.results = page;
      final viewModel = listen();
      await settle();

      reports.exportGate = Completer<void>();
      final future = viewModel.export(studentName: 'Test Student');

      expect(read().isExporting, isTrue);
      expect(read().progress, 0.5);

      reports.exportGate!.complete();
      await future;

      expect(read().isExporting, isFalse);
      expect(read().error, isNull);
      expect(read().lastExported?.fileName, endsWith('.pdf'));
      expect(reports.studentNames, ['Test Student']);
      expect(reports.exported.single, hasLength(2));
      expect(analytics.events, contains('export_report'));
      expect(analytics.parameters['export_report'], {
        'report_type': 'applications',
        'item_count': 2,
        'file_size_kb': 20,
      });
    },
  );

  test('a repeated tap while exporting does not upload twice', () async {
    applications.results = page;
    final viewModel = listen();
    await settle();

    reports.exportGate = Completer<void>();
    final first = viewModel.export(studentName: 'Test Student');
    await viewModel.export(studentName: 'Test Student');

    reports.exportGate!.complete();
    await first;

    expect(reports.exported, hasLength(1));
  });

  test('export failure keeps a plain-language error and no report', () async {
    applications.results = page;
    final viewModel = listen();
    await settle();

    reports.exportError = const AppException(
      AppErrorKind.network,
      'We could not upload the file. Check your connection and try again.',
    );
    await viewModel.export(studentName: 'Test Student');

    expect(read().isExporting, isFalse);
    expect(read().lastExported, isNull);
    expect(
      read().error?.message,
      'We could not upload the file. Check your connection and try again.',
    );
    expect(analytics.events, isNot(contains('export_report')));
  });

  test('export with no applications reports what to do first', () async {
    final viewModel = listen();
    await settle();

    await viewModel.export(studentName: 'Test Student');

    expect(reports.exported, isEmpty);
    expect(read().error?.kind, AppErrorKind.invalidInput);
  });

  test(
    'a report stream error becomes a ViewError and retry recovers',
    () async {
      applications.results = page;
      reports.error = const AppException(AppErrorKind.network, 'Offline.');
      final viewModel = listen();
      await settle();

      expect(read().reports, isA<ViewError<List<ExportedReport>>>());

      reports.error = null;
      reports.reports = [
        ExportedReport(
          id: 'r1',
          fileName: 'application-report-2026-11-12.pdf',
          url: 'https://storage.example/reports/uid-123/a.pdf',
          storagePath: 'reports/uid-123/a.pdf',
          sizeBytes: 2048,
          itemCount: 2,
          createdAt: DateTime(2026, 11, 12),
        ),
      ];
      await viewModel.retry();
      await settle();

      // The error state clears and the new subscription delivers the report.
      expect(read().reports, isA<ViewData<List<ExportedReport>>>());
      final loaded = (read().reports as ViewData<List<ExportedReport>>).data;
      expect(loaded.single.fileName, 'application-report-2026-11-12.pdf');
    },
  );

  test('opening a report hands its URL to the device viewer', () async {
    final viewModel = listen();
    await settle();

    final report = ExportedReport(
      id: 'r1',
      fileName: 'application-report-2026-11-12.pdf',
      url: 'https://storage.example/reports/uid-123/a.pdf',
      storagePath: 'reports/uid-123/a.pdf',
      sizeBytes: 2048,
      itemCount: 2,
      createdAt: DateTime(2026, 11, 12),
    );

    expect(await viewModel.open(report), isNull);
    expect(links.opened.single.toString(), report.url);
  });

  test(
    'an app with no viewer returns the failure instead of throwing',
    () async {
      final viewModel = listen();
      await settle();

      links.error = const AppException(
        AppErrorKind.unknown,
        'No app on this device can open this file.',
      );

      final error = await viewModel.open(
        ExportedReport(
          id: 'r1',
          fileName: 'a.pdf',
          url: 'https://storage.example/reports/uid-123/a.pdf',
          storagePath: 'reports/uid-123/a.pdf',
          sizeBytes: 2048,
          itemCount: 1,
          createdAt: DateTime(2026, 11, 12),
        ),
      );

      expect(error?.message, 'No app on this device can open this file.');
    },
  );
}
