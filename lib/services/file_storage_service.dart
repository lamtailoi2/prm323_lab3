import 'dart:async';
import 'dart:math';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import 'auth_service.dart';

/// Per-user folders; must match `firebase/storage.rules`.
enum StorageFolder {
  /// Generated PDF reports (export and upload).
  reports('reports'),

  /// CVs uploaded in the Apply flow (Flow 2a) or Profile.
  cvs('cvs');

  const StorageFolder(this.path);
  final String path;
}

/// Result of a completed upload. Store it in Firestore under
/// `users/{uid}/…`; never store a URL that did not come from here.
@immutable
class UploadedFile {
  const UploadedFile({
    required this.url,
    required this.storagePath,
    required this.fileName,
    required this.sizeBytes,
    required this.uploadedAt,
  });

  /// Download URL returned by Cloud Storage.
  final String url;

  /// Full object path, e.g. `reports/<uid>/<name>-<id>.pdf`.
  final String storagePath;
  final String fileName;
  final int sizeBytes;
  final DateTime uploadedAt;
}

/// File storage boundary (CV upload, report export).
abstract interface class FileStorageService {
  /// Uploads [bytes] (a PDF) into the **signed-in user's own** [folder].
  /// [onProgress] receives values from 0 to 1.
  Future<UploadedFile> uploadPdf({
    required StorageFolder folder,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  });
}

final fileStorageServiceProvider = Provider<FileStorageService>(
  (ref) => FirebaseStorageService(auth: ref.watch(authServiceProvider)),
);

/// Maximum upload size; `firebase/storage.rules` enforces the same limit.
const int maxUploadBytes = 10 * 1024 * 1024;

/// Cloud Storage for Firebase (Blaze plan, no-cost quota; handoff-gaps G-12).
///
/// Access is enforced twice: `firebase/storage.rules` on the server (owner
/// only, PDF, ≤ 10 MB) and the same checks here, so users get a clear
/// message before any upload starts:
///
/// 1. Signed-in users only.
/// 2. The path is always `<folder>/<current uid>/…`; callers cannot choose
///    the UID.
/// 3. Only real PDFs (`%PDF-` signature) up to [maxUploadBytes].
/// 4. A 128-bit random id per file avoids collisions and guessable names.
class FirebaseStorageService implements FileStorageService {
  FirebaseStorageService({
    required this._auth,
    FirebaseStorage? storage,
    Random? random,
  }) : _storageOverride = storage,
       _random = random ?? Random.secure();

  final AuthService _auth;
  final FirebaseStorage? _storageOverride;
  final Random _random;

  // Resolved lazily so validation works (and is testable) without Firebase.
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  @override
  Future<UploadedFile> uploadPdf({
    required StorageFolder folder,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    final path = prepareUploadPath(
      uid: _auth.currentUser?.uid,
      folder: folder,
      fileName: fileName,
      bytes: bytes,
      randomId: _randomHex(16),
    );

    final reference = _storage.ref(path);
    final task = reference.putData(
      bytes,
      SettableMetadata(contentType: 'application/pdf'),
    );
    final progress = task.snapshotEvents.listen(
      (snapshot) {
        if (snapshot.totalBytes > 0) {
          onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
        }
      },
      // Errors are handled when awaiting the task below.
      onError: (Object _) {},
    );

    try {
      final snapshot = await task;
      final url = await reference.getDownloadURL();
      onProgress?.call(1);
      return UploadedFile(
        url: url,
        storagePath: reference.fullPath,
        fileName: fileName,
        sizeBytes: snapshot.totalBytes > 0 ? snapshot.totalBytes : bytes.length,
        uploadedAt: DateTime.now(),
      );
    } on FirebaseException catch (error) {
      throw mapStorageError(error.code, cause: error);
    } finally {
      await progress.cancel();
    }
  }

  String _randomHex(int byteCount) => [
    for (var i = 0; i < byteCount; i++)
      _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}

/// Validates an upload and returns its object path. Throws [AppException]
/// before anything is sent.
@visibleForTesting
String prepareUploadPath({
  required String? uid,
  required StorageFolder folder,
  required String fileName,
  required Uint8List bytes,
  required String randomId,
}) {
  if (uid == null) {
    throw const AppException(
      AppErrorKind.permissionDenied,
      'Sign in to upload files.',
    );
  }
  if (bytes.isEmpty || bytes.length > maxUploadBytes) {
    throw const AppException(
      AppErrorKind.invalidInput,
      'The file must be a PDF of at most 10 MB.',
    );
  }
  if (!_isPdf(bytes)) {
    throw const AppException(
      AppErrorKind.invalidInput,
      'Only PDF files can be uploaded.',
    );
  }
  return '${folder.path}/$uid/${_slug(fileName)}-$randomId.pdf';
}

/// Translates Cloud Storage error codes into user-safe messages.
@visibleForTesting
AppException mapStorageError(String code, {Object? cause}) {
  return switch (code.replaceFirst('storage/', '')) {
    'unauthorized' || 'unauthenticated' => AppException(
      AppErrorKind.permissionDenied,
      'You do not have permission to upload this file.',
      cause: cause,
    ),
    'canceled' => AppException(
      AppErrorKind.cancelled,
      'The upload was cancelled.',
      cause: cause,
    ),
    'retry-limit-exceeded' => AppException(
      AppErrorKind.network,
      'We could not upload the file. Check your connection and try again.',
      cause: cause,
    ),
    'quota-exceeded' => AppException(
      AppErrorKind.rateLimited,
      'The storage limit has been reached. Please try again later.',
      cause: cause,
    ),
    _ => AppException(
      AppErrorKind.unknown,
      'The upload failed. Please try again.',
      cause: cause,
    ),
  };
}

bool _isPdf(Uint8List bytes) =>
    bytes.length >= 5 &&
    bytes[0] == 0x25 && // %
    bytes[1] == 0x50 && // P
    bytes[2] == 0x44 && // D
    bytes[3] == 0x46 && // F
    bytes[4] == 0x2D; // -

String _slug(String fileName) {
  final base = fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
  final slug = base
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.isEmpty) return 'file';
  return slug.length > 40 ? slug.substring(0, 40) : slug;
}
