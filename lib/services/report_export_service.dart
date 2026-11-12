import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/errors/app_exception.dart';
import '../core/utils/application_report_pdf.dart';
import '../models/exported_report.dart';
import '../models/internship_application.dart';
import 'auth_service.dart';
import 'crashlytics_service.dart';
import 'file_storage_service.dart';

/// Exports the student's applications as a PDF report and keeps its metadata.
///
/// A report only exists after both steps succeed: the PDF is generated from
/// real application data, uploaded to `reports/{uid}/…` and only then written
/// to `users/{uid}/reports/{id}` with the URL Cloud Storage returned (G-05,
/// AGENTS.md rule 7: never store a placeholder URL).
abstract interface class ReportExportService {
  /// Reports of the current user, newest first; empty when signed out.
  Stream<List<ExportedReport>> watchReports();

  /// Generates and uploads the report for [applications].
  ///
  /// [onProgress] reports the upload from 0 to 1. Throws [AppException] when
  /// generation, upload or the metadata write fails.
  Future<ExportedReport> export({
    required List<InternshipApplication> applications,
    required String studentName,
    DateTime? generatedAt,
    void Function(double progress)? onProgress,
  });
}

final reportExportServiceProvider = Provider<ReportExportService>((ref) {
  // Watching the uid drops the previous student's listener on sign-out or an
  // account switch (AGENTS.md rule 11).
  final uid = ref.watch(currentUserIdProvider);

  return FirestoreReportExportService(
    FirebaseFirestore.instance,
    uid,
    storage: ref.watch(fileStorageServiceProvider),
    crashlytics: ref.watch(crashlyticsServiceProvider),
  );
});

class FirestoreReportExportService implements ReportExportService {
  FirestoreReportExportService(
    this._firestore,
    this._uid, {
    required this._storage,
    required this._crashlytics,
  });

  final FirebaseFirestore _firestore;
  final String? _uid;
  final FileStorageService _storage;
  final CrashlyticsService _crashlytics;

  @override
  Stream<List<ExportedReport>> watchReports() async* {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      yield const <ExportedReport>[];
      return;
    }

    final query = _firestore
        .collection('users')
        .doc(uid)
        .collection('reports')
        .orderBy('createdAt', descending: true);

    try {
      await for (final snapshot in query.snapshots()) {
        yield _parse(snapshot);
      }
    } on FirebaseException catch (error) {
      throw _toAppException(error);
    } on Exception catch (error) {
      throw AppException(
        AppErrorKind.unknown,
        'We could not load your reports. Try again in a moment.',
        cause: error,
      );
    }
  }

  @override
  Future<ExportedReport> export({
    required List<InternshipApplication> applications,
    required String studentName,
    DateTime? generatedAt,
    void Function(double progress)? onProgress,
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        'Sign in again and try once more.',
      );
    }
    if (applications.isEmpty) {
      throw const AppException(
        AppErrorKind.invalidInput,
        'There is nothing to export yet. Apply to an internship first.',
      );
    }

    final createdAt = generatedAt ?? DateTime.now();
    final fonts = await _loadFonts();
    final Uint8List bytes;
    try {
      bytes = await buildApplicationReportPdf(
        applications: applications,
        studentName: studentName,
        generatedAt: createdAt,
        baseFont: fonts?.base,
        boldFont: fonts?.bold,
      );
    } on Object catch (error, stack) {
      unawaited(
        _crashlytics.recordError(
          error,
          stack,
          reason: 'Could not build the application report PDF',
        ),
      );
      throw AppException(
        AppErrorKind.unknown,
        'We could not create your report. Try again in a moment.',
        cause: error,
      );
    }

    final fileName = reportFileName(createdAt);
    final uploaded = await _storage.uploadPdf(
      folder: StorageFolder.reports,
      fileName: fileName,
      bytes: bytes,
      onProgress: onProgress,
    );

    final report = ExportedReport(
      id: '',
      fileName: uploaded.fileName,
      url: uploaded.url,
      storagePath: uploaded.storagePath,
      sizeBytes: uploaded.sizeBytes,
      itemCount: applications.length,
      createdAt: createdAt,
    );

    // One document per day: exporting again the same day replaces that
    // report's metadata (new URL and size) instead of adding a duplicate row
    // to `Your reports`. The id is the file name without its extension.
    final reference = _firestore
        .collection('users')
        .doc(uid)
        .collection('reports')
        .doc(fileName.replaceFirst(RegExp(r'\.pdf$'), ''));

    try {
      await reference.set(<String, Object?>{
        'fileName': report.fileName,
        'url': report.url,
        'storagePath': report.storagePath,
        'sizeBytes': report.sizeBytes,
        'itemCount': report.itemCount,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ExportedReport(
        id: reference.id,
        fileName: report.fileName,
        url: report.url,
        storagePath: report.storagePath,
        sizeBytes: report.sizeBytes,
        itemCount: report.itemCount,
        createdAt: report.createdAt,
      );
    } on FirebaseException catch (error) {
      throw _toWriteException(error);
    }
  }

  /// The app's Inter faces, so Vietnamese names and company names render
  /// instead of the built-in Helvetica (which is ASCII only).
  ///
  /// `null` falls back to the default font instead of failing the export.
  Future<({pw.Font base, pw.Font bold})?> _loadFonts() async {
    try {
      final results = await Future.wait<ByteData>([
        rootBundle.load('assets/fonts/inter/Inter-Regular.ttf'),
        rootBundle.load('assets/fonts/inter/Inter-SemiBold.ttf'),
      ]);
      return (base: pw.Font.ttf(results[0]), bold: pw.Font.ttf(results[1]));
    } on Object catch (error) {
      debugPrint('Report font fallback: $error');
      return null;
    }
  }

  List<ExportedReport> _parse(QuerySnapshot<Map<String, Object?>> snapshot) {
    final reports = <ExportedReport>[];
    for (final doc in snapshot.docs) {
      try {
        reports.add(ExportedReport.fromFirestore(doc.id, doc.data()));
      } on FormatException catch (error, stack) {
        // One malformed document must not hide the others.
        unawaited(
          _crashlytics.recordError(
            error,
            stack,
            reason: 'Skipped a malformed report document',
          ),
        );
      }
    }
    return List<ExportedReport>.unmodifiable(reports);
  }

  static AppException _toAppException(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' || 'unauthenticated' => AppException(
        AppErrorKind.permissionDenied,
        'Your reports are not available for this account.',
        cause: error,
      ),
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => AppException(
        AppErrorKind.network,
        'We could not load your reports. Check your connection and try again.',
        cause: error,
      ),
      _ => AppException(
        AppErrorKind.unknown,
        'We could not load your reports. Try again in a moment.',
        cause: error,
      ),
    };
  }

  static AppException _toWriteException(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' || 'unauthenticated' => AppException(
        AppErrorKind.permissionDenied,
        'Sign in again and try once more.',
        cause: error,
      ),
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => AppException(
        AppErrorKind.network,
        'Your report was uploaded but could not be saved. Check your '
        'connection and try again.',
        cause: error,
      ),
      _ => AppException(
        AppErrorKind.unknown,
        'Your report was uploaded but could not be saved. Try again in a '
        'moment.',
        cause: error,
      ),
    };
  }
}
