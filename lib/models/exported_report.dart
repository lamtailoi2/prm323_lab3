import 'package:flutter/foundation.dart';

import '../core/utils/firestore_reader.dart';

/// One generated PDF report, stored at `users/{uid}/reports/{fileName}` with
/// the file itself in Cloud Storage `reports/{uid}/…` (G-05).
///
/// The document id is the file name without `.pdf`, so there is one report per
/// day: exporting again the same day replaces that document instead of adding
/// a duplicate row to `Your reports`. The metadata keeps the real download URL
/// and the size; nothing here is written unless the upload succeeded.
/// Required fields throw [FormatException]; services skip and log malformed
/// documents.
@immutable
class ExportedReport {
  const ExportedReport({
    required this.id,
    required this.fileName,
    required this.url,
    required this.storagePath,
    required this.sizeBytes,
    required this.createdAt,
    this.itemCount = 0,
  });

  factory ExportedReport.fromFirestore(String id, Map<String, Object?>? data) {
    final reader = FirestoreReader('reports/$id', data);
    return ExportedReport(
      id: id,
      fileName: reader.requireString('fileName').trim(),
      url: reader.requireString('url').trim(),
      storagePath: reader.requireString('storagePath').trim(),
      sizeBytes: reader.optionalInt('sizeBytes') ?? 0,
      // Absent on a document written before the field existed.
      itemCount: reader.optionalInt('itemCount') ?? 0,
      createdAt: reader.requireDateTime('createdAt'),
    );
  }

  final String id;
  final String fileName;

  /// Download URL returned by Cloud Storage; never a placeholder.
  final String url;
  final String storagePath;
  final int sizeBytes;

  /// Applications the report holds, for the "N applications" line.
  final int itemCount;
  final DateTime createdAt;
}
