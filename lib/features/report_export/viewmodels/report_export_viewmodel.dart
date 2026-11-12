import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/display_format.dart';
import '../../../models/exported_report.dart';
import '../../../models/internship_application.dart';
import '../../../services/analytics_service.dart';
import '../../../services/application_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/external_link_service.dart';
import '../../../services/report_export_service.dart';

/// What the export screen shows: how many applications the report would hold
/// and the reports already generated.
@immutable
class ReportExportState {
  const ReportExportState({
    this.applications = const ViewLoading(),
    this.reports = const ViewLoading(),
    this.progress,
    this.error,
    this.lastExported,
  });

  /// The student's applications; the report is built from these.
  final ViewState<List<InternshipApplication>> applications;

  /// Earlier reports, newest first (Firestore `users/{uid}/reports`).
  final ViewState<List<ExportedReport>> reports;

  /// Upload progress from 0 to 1; non-null only while an export runs.
  final double? progress;

  /// Why the last export failed; shown next to the action.
  final AppException? error;

  /// The report the last successful export produced.
  final ExportedReport? lastExported;

  bool get isExporting => progress != null;

  ReportExportState copyWith({
    ViewState<List<InternshipApplication>>? applications,
    ViewState<List<ExportedReport>>? reports,
    double? progress,
    AppException? error,
    ExportedReport? lastExported,
    bool clearProgress = false,
    bool clearError = false,
  }) {
    return ReportExportState(
      applications: applications ?? this.applications,
      reports: reports ?? this.reports,
      progress: clearProgress ? null : (progress ?? this.progress),
      error: clearError ? null : (error ?? this.error),
      lastExported: lastExported ?? this.lastExported,
    );
  }
}

final reportExportViewModelProvider =
    NotifierProvider.autoDispose<ReportExportViewModel, ReportExportState>(
      ReportExportViewModel.new,
    );

/// Report export (Lab 3 "export and upload", G-05): builds a PDF from the
/// student's real applications, uploads it to `reports/{uid}/…` and records
/// the metadata. The screen renders [ViewState] only (MVVM rule).
class ReportExportViewModel extends Notifier<ReportExportState> {
  StreamSubscription<List<InternshipApplication>>? _applications;
  StreamSubscription<List<ExportedReport>>? _reports;

  @override
  ReportExportState build() {
    // User-scoped (AGENTS.md rule 11): sign-out or an account switch rebuilds
    // this provider and cancels the previous listeners.
    ref.watch(currentUserIdProvider);
    final applicationService = ref.watch(applicationServiceProvider);
    final reportService = ref.watch(reportExportServiceProvider);

    ref.onDispose(() {
      unawaited(_applications?.cancel());
      unawaited(_reports?.cancel());
    });

    _subscribeApplications(applicationService);
    _subscribeReports(reportService);

    return const ReportExportState();
  }

  /// Retries both streams after an error.
  Future<void> retry() async {
    if (state.applications.isLoading || state.reports.isLoading) return;
    final applicationService = ref.read(applicationServiceProvider);
    final reportService = ref.read(reportExportServiceProvider);

    state = const ReportExportState();
    _subscribeApplications(applicationService);
    _subscribeReports(reportService);
  }

  /// Generates and uploads one report. Ignored while one is already running,
  /// so a repeated tap cannot upload twice.
  Future<void> export({required String studentName}) async {
    if (state.isExporting) return;
    final applications = switch (state.applications) {
      ViewData<List<InternshipApplication>>(:final data) => data,
      _ => const <InternshipApplication>[],
    };
    final service = ref.read(reportExportServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    if (applications.isEmpty) {
      state = state.copyWith(
        error: const AppException(
          AppErrorKind.invalidInput,
          'There is nothing to export yet. Apply to an internship first.',
        ),
      );
      return;
    }

    state = state.copyWith(progress: 0, clearError: true);
    try {
      final report = await service.export(
        applications: applications,
        studentName: studentName,
        onProgress: (progress) {
          if (!ref.mounted) return;
          state = state.copyWith(progress: progress);
        },
      );
      if (!ref.mounted) return;
      state = state.copyWith(clearProgress: true, lastExported: report);
      // Row 14 of docs/analytics-plan.md: a report counts once it exists.
      unawaited(
        analytics.logEvent('export_report', {
          'report_type': 'applications',
          'item_count': report.itemCount,
          'file_size_kb': (report.sizeBytes / 1024).ceil(),
        }),
      );
    } on AppException catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(clearProgress: true, error: error);
    }
  }

  /// Opens a generated report in the device's PDF viewer.
  Future<AppException?> open(ExportedReport report) async {
    try {
      await ref.read(externalLinkServiceProvider).open(Uri.parse(report.url));
      return null;
    } on AppException catch (error) {
      return error;
    }
  }

  void _subscribeApplications(ApplicationService service) {
    unawaited(_applications?.cancel());
    _applications = service.watchApplications().listen(
      (applications) {
        if (!ref.mounted) return;
        state = state.copyWith(
          applications: ViewState.fromData(
            applications,
            isEmpty: applications.isEmpty,
          ),
        );
      },
      onError: (Object error, StackTrace stack) {
        if (!ref.mounted) return;
        state = state.copyWith(applications: ViewError(_asAppException(error)));
      },
    );
  }

  void _subscribeReports(ReportExportService service) {
    unawaited(_reports?.cancel());
    _reports = service.watchReports().listen(
      (reports) {
        if (!ref.mounted) return;
        state = state.copyWith(
          reports: ViewState.fromData(reports, isEmpty: reports.isEmpty),
        );
      },
      onError: (Object error, StackTrace stack) {
        if (!ref.mounted) return;
        state = state.copyWith(reports: ViewError(_asAppException(error)));
      },
    );
  }

  static AppException _asAppException(Object error) {
    return error is AppException
        ? error
        : AppException(
            AppErrorKind.unknown,
            'We could not load your report data. Try again in a moment.',
            cause: error,
          );
  }

  /// `3 applications · 12 Nov` for the summary line, or `null` before the
  /// applications load.
  String? get summary {
    return switch (state.applications) {
      ViewData<List<InternshipApplication>>(:final data) when data.isNotEmpty =>
        '${data.length} ${data.length == 1 ? 'application' : 'applications'}'
            ' · ${formatShortDate(DateTime.now())}',
      _ => null,
    };
  }
}
