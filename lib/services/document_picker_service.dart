import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';

/// A file chosen on the device, read into memory for upload.
@immutable
class PickedDocument {
  const PickedDocument({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  int get sizeBytes => bytes.length;
}

/// System file picker boundary (phone storage, Google Drive, iCloud…).
abstract interface class DocumentPickerService {
  /// Lets the student choose one PDF. Returns `null` when the picker is
  /// closed without a choice. Throws [AppException] when the file cannot be
  /// read.
  Future<PickedDocument?> pickPdf();
}

final documentPickerServiceProvider = Provider<DocumentPickerService>(
  (ref) => FileSelectorDocumentPicker(),
);

/// Uses the platform document picker (`file_selector`): no storage
/// permission is needed on Android or iOS.
class FileSelectorDocumentPicker implements DocumentPickerService {
  static const XTypeGroup _pdf = XTypeGroup(
    label: 'PDF',
    extensions: <String>['pdf'],
    mimeTypes: <String>['application/pdf'],
    uniformTypeIdentifiers: <String>['com.adobe.pdf'],
  );

  @override
  Future<PickedDocument?> pickPdf() async {
    try {
      final file = await openFile(acceptedTypeGroups: const [_pdf]);
      if (file == null) return null;
      return PickedDocument(name: file.name, bytes: await file.readAsBytes());
    } on PlatformException catch (error) {
      throw AppException(
        AppErrorKind.unknown,
        'We could not open this file. Choose it again or pick another PDF.',
        cause: error,
      );
    }
  }
}
