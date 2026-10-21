import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart' show math;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../services/file_storage_service.dart' show UploadedFile;
import '../services/auth_service.dart';
import '../services/local_auth_service.dart';

/// Local [FileStorageService] implementation that stores PDFs in the
/// application's documents directory under per-user folders.
///
/// Path format: `docs/<folder>/<uid>/<slug>-<random>.pdf`
/// Matches the same folder enum values as `FirebaseStorageService`
/// (`reports`, `cvs`) so the generated paths are compatible with the
/// existing rules/structure.
class LocalFileStorageService implements FileStorageService {
  LocalFileStorageService({AuthService? auth}) : _auth = auth ?? LocalAuthService();

  final AuthService _auth;

  static const _maxBytes = 10 * 1024 * 1024;

  @override
  Future<UploadedFile> uploadPdf({
    required StorageFolder folder,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    if (bytes.isEmpty) {
      throw const AppException(
        AppErrorKind.invalidInput,
        'The file must be a PDF of at most 10 MB.',
      );
    }
    if (bytes.length > _maxBytes) {
      throw const AppException(
        AppErrorKind.invalidInput,
        'The file must be a PDF of at most 10 MB.',
      );
    }
    if (bytes.length < 5 ||
        bytes[0] != 0x25 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x44 ||
        bytes[3] != 0x46 ||
        bytes[4] != 0x2D) {
      throw const AppException(
        AppErrorKind.invalidInput,
        'Only PDF files can be uploaded.',
      );
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        'Sign in to upload files.',
      );
    }

    final randomId = _randomHex(16);
    final slug = _slug(fileName);
    final path = '${folder.path}/$uid/$slug-$randomId.pdf';
    final file = File(path);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);

    final downloadUrl = Uri.file(file.path).toString();
    return UploadedFile(
      url: downloadUrl,
      storagePath: path,
      fileName: fileName,
      sizeBytes: bytes.length,
      uploadedAt: DateTime.now(),
    );
  }

  String _randomHex(int byteCount) =>
      List.generate(byteCount, (_) => (math.Random().nextInt(256)).toRadixString(16).padLeft(2, '0')).join();

  String _slug(String fileName) {
    final base = fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
    final slug = base
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) return 'file';
    return slug.length > 40 ? slug.substring(0, 40) : slug;
  }
}

/// Provides a [LocalFileStorageService] instance.
final localFileStorageServiceProvider = Provider<FileStorageService>(
  (ref) => LocalFileStorageService(),
);