import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/display_format.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/app_top_bar.dart';
import '../../../core/widgets/cv_file_tile.dart';
import '../../../core/widgets/detail_section_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_view.dart';
import '../../../models/exported_report.dart';
import '../../../models/internship_application.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../viewmodels/report_export_viewmodel.dart';

/// Report export (Lab 3 "export and upload", G-05).
///
/// Builds a PDF from the student's own applications, uploads it to Cloud
/// Storage `reports/{uid}/…` and lists every report that exists with its real
/// download URL. The screen has an explicit [ViewState] for the applications
/// it exports and for the reports already generated.
class ReportExportScreen extends ConsumerWidget {
  const ReportExportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportExportViewModelProvider);
    final viewModel = ref.read(reportExportViewModelProvider.notifier);

    return Scaffold(
      appBar: const AppTopBar.back(title: 'Report export'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          AppSpacing.s16,
          AppSpacing.screenHorizontal,
          AppSpacing.s24,
        ),
        children: [
          switch (state.applications) {
            ViewLoading<List<InternshipApplication>>() =>
              const _ExportSkeleton(),
            ViewEmpty<List<InternshipApplication>>() => StateView.empty(
              icon: Symbols.description_rounded,
              title: 'Nothing to export yet',
              message:
                  'Your report is built from the internships you have applied '
                  'to. Apply to one first, then come back here.',
            ),
            ViewError<List<InternshipApplication>>(:final error) =>
              StateView.error(message: error.message, onRetry: viewModel.retry),
            ViewData<List<InternshipApplication>>(:final data) => _ExportCard(
              applicationCount: data.length,
              progress: state.progress,
              error: state.error,
              lastExported: state.lastExported,
              onExport: () => _export(ref, viewModel),
            ),
          },
          const SizedBox(height: AppSpacing.section),
          const _ReportsHeading(),
          const SizedBox(height: AppSpacing.s8),
          switch (state.reports) {
            ViewLoading<List<ExportedReport>>() => const _ReportsSkeleton(),
            ViewEmpty<List<ExportedReport>>() => StateView.empty(
              icon: Symbols.folder_open_rounded,
              title: 'No reports yet',
              message:
                  'Reports you export are saved here so you can open them '
                  'again.',
            ),
            ViewError<List<ExportedReport>>(:final error) => StateView.error(
              message: error.message,
              onRetry: viewModel.retry,
            ),
            ViewData<List<ExportedReport>>(:final data) => Column(
              children: [
                for (final (index, report) in data.indexed) ...[
                  if (index > 0) const SizedBox(height: AppSpacing.s12),
                  _ReportTile(
                    report: report,
                    onOpen: () => _open(context, viewModel, report),
                  ),
                ],
              ],
            ),
          },
        ],
      ),
    );
  }

  static Future<void> _export(
    WidgetRef ref,
    ReportExportViewModel viewModel,
  ) async {
    // Read before the await, and never after it (AGENTS.md async rule).
    final account = ref.read(authStateChangesProvider).value;
    final studentName = account?.displayName?.trim().isNotEmpty == true
        ? account!.displayName!.trim()
        : (account?.email ?? 'Internly student');
    await viewModel.export(studentName: studentName);
  }

  static Future<void> _open(
    BuildContext context,
    ReportExportViewModel viewModel,
    ExportedReport report,
  ) async {
    final error = await viewModel.open(report);
    if (error == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error.message)));
  }
}

class _ExportCard extends StatelessWidget {
  const _ExportCard({
    required this.applicationCount,
    required this.progress,
    required this.error,
    required this.lastExported,
    required this.onExport,
  });

  final int applicationCount;
  final double? progress;
  final AppException? error;
  final ExportedReport? lastExported;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isExporting = progress != null;
    final status = lastExported;

    return DetailSectionCard(
      icon: Symbols.description_rounded,
      title: 'Application report',
      children: [
        Text(
          applicationCount == 1
              ? '1 application'
              : '$applicationCount applications',
          style: textTheme.bodyMedium,
        ),
        Text(
          'A PDF with every application, its company, the date you applied '
          'and its status. Generated ${formatShortDate(DateTime.now())}.',
          style: textTheme.bodyMedium,
        ),
        if (status != null && !isExporting) ...[
          Text(
            'Last exported: ${status.fileName}',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (progress case final progress?) ...[
          Semantics(
            label: 'Uploading report',
            value: '${(progress * 100).round()}%',
            child: LinearProgressIndicator(value: progress),
          ),
          Text(
            'Uploading… ${(progress * 100).round()}%',
            style: textTheme.bodyMedium,
          ),
        ],
        if (error case final AppException failure)
          FormMessage(message: failure.message),
        AppButton(
          label: status == null ? 'Export report' : 'Export again',
          icon: Symbols.download_rounded,
          isLoading: isExporting,
          onPressed: onExport,
          expand: true,
        ),
      ],
    );
  }
}

class _ReportsHeading extends StatelessWidget {
  const _ReportsHeading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Symbols.folder_open_rounded,
          size: 20,
          color: AppColors.textPrimary,
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              'Your reports',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report, required this.onOpen});

  final ExportedReport report;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final details =
        '${formatShortDate(report.createdAt)} · '
        '${formatFileSize(report.sizeBytes)} · '
        '${report.itemCount == 1 ? '1 application' : '${report.itemCount} applications'}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s16),
        child: CvFileTile(
          fileName: report.fileName,
          details: details,
          trailing: AppButton(
            label: 'Open',
            variant: AppButtonVariant.text,
            onPressed: onOpen,
          ),
        ),
      ),
    );
  }
}

class _ExportSkeleton extends StatelessWidget {
  const _ExportSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 18),
            SizedBox(height: AppSpacing.s12),
            SkeletonBox(height: 14),
            SizedBox(height: AppSpacing.s8),
            FractionallySizedBox(
              widthFactor: 0.8,
              child: SkeletonBox(height: 14),
            ),
            SizedBox(height: AppSpacing.s16),
            SkeletonBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _ReportsSkeleton extends StatelessWidget {
  const _ReportsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            SkeletonBox(width: 40, height: 40),
            SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(height: 16),
                  SizedBox(height: AppSpacing.s8),
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: SkeletonBox(height: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
