import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../core/errors/app_exception.dart';
import 'auth_service.dart';
import 'serp_api_client.dart' show httpClientProvider;

/// Cloudinary settings, injected at build time from `.env`
/// (`--dart-define-from-file=.env`). Neither value is a secret; the API
/// secret is never used by the app (handoff-gaps G-12).
const String cloudinaryCloudName = String.fromEnvironment(
  'CLOUDINARY_CLOUD_NAME',
);
const String cloudinaryUploadPreset = String.fromEnvironment(
  'CLOUDINARY_UPLOAD_PRESET',
);

/// Per-user folders; the same layout as `firebase/storage.rules`.
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

  final String url;

  /// Provider path (`internly/<folder>/<uid>/<id>`), for the metadata record.
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
  (ref) => CloudinaryStorageService(
    ref.watch(httpClientProvider),
    auth: ref.watch(authServiceProvider),
    cloudName: cloudinaryCloudName,
    uploadPreset: cloudinaryUploadPreset,
  ),
);

/// Cloudinary (free plan, unsigned upload preset) with access control in the
/// service layer, because Cloudinary has no per-user security rules:
///
/// 1. The folder is always `internly/<folder>/<current uid>`; callers cannot
///    choose a UID, so a user can only upload into their own folder.
/// 2. Signed-out users are rejected before any request.
/// 3. Only real PDFs (`%PDF-` signature) up to [maxBytes] are sent.
/// 4. Each file gets a 128-bit random id, so URLs cannot be guessed or
///    enumerated.
/// 5. Files are only listed through Firestore metadata under `users/{uid}`,
///    which the Firestore rules restrict to the owner.
///
/// Known limit: a delivery URL is public, so anyone who already has the link
/// can open the file; and the unsigned preset name ships in the app. Both
/// are documented trade-offs of the zero-cost setup (G-12).
class CloudinaryStorageService implements FileStorageService {
  CloudinaryStorageService(
    this._http, {
    required this._auth,
    required this._cloudName,
    required this._uploadPreset,
    Random? random,
    this._timeout = const Duration(seconds: 60),
  }) : _random = random ?? Random.secure();

  final http.Client _http;
  final AuthService _auth;
  final String _cloudName;
  final String _uploadPreset;
  final Random _random;
  final Duration _timeout;

  static const int maxBytes = 10 * 1024 * 1024;
  static const String rootFolder = 'internly';

  @override
  Future<UploadedFile> uploadPdf({
    required StorageFolder folder,
    required String fileName,
    required Uint8List bytes,
    void Function(double progress)? onProgress,
  }) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw const AppException(
        AppErrorKind.configuration,
        'File upload is not set up for this build (missing Cloudinary '
        'settings).',
      );
    }
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        'Sign in to upload files.',
      );
    }
    if (bytes.isEmpty || bytes.length > maxBytes) {
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

    final folderPath = '$rootFolder/${folder.path}/$uid';
    final publicId = '${_slug(fileName)}-${_randomHex(16)}';
    final uri = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$_cloudName/auto/upload',
    );
    final multipart = http.MultipartRequest('POST', uri)
      ..fields.addAll({
        'upload_preset': _uploadPreset,
        'folder': folderPath,
        'public_id': publicId,
      })
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: '$publicId.pdf'),
      );

    final http.StreamedResponse streamed;
    try {
      streamed = await _http
          .send(_withProgress(multipart, onProgress))
          .timeout(_timeout);
    } on TimeoutException {
      throw const AppException(
        AppErrorKind.network,
        'The upload is taking too long. Check your connection and try again.',
      );
    } on http.ClientException {
      throw const AppException(
        AppErrorKind.network,
        'We could not upload the file. Check your connection and try again.',
      );
    }

    final body = await streamed.stream.bytesToString();
    final json = _decode(body);
    if (streamed.statusCode != 200) throw _error(streamed.statusCode, json);

    final url = json['secure_url'];
    if (url is! String || url.isEmpty) {
      throw const AppException(
        AppErrorKind.unknown,
        'The upload did not return a file link. Please try again.',
      );
    }
    onProgress?.call(1);
    final returnedId = json['public_id'];
    final size = json['bytes'];
    final created = json['created_at'];
    return UploadedFile(
      url: url,
      storagePath: returnedId is String ? returnedId : '$folderPath/$publicId',
      fileName: fileName,
      sizeBytes: size is int ? size : bytes.length,
      uploadedAt:
          (created is String ? DateTime.tryParse(created) : null) ??
          DateTime.now(),
    );
  }

  /// Re-streams the multipart body so the caller sees upload progress.
  static http.BaseRequest _withProgress(
    http.MultipartRequest multipart,
    void Function(double progress)? onProgress,
  ) {
    final total = multipart.contentLength;
    final request = http.StreamedRequest(multipart.method, multipart.url)
      ..headers.addAll(multipart.headers)
      ..contentLength = total;
    var sent = 0;
    multipart.finalize().listen(
      (chunk) {
        sent += chunk.length;
        if (total > 0) onProgress?.call((sent / total).clamp(0, 0.99));
        request.sink.add(chunk);
      },
      onError: request.sink.addError,
      onDone: request.sink.close,
      cancelOnError: true,
    );
    return request;
  }

  static AppException _error(int status, Map<String, Object?> json) {
    final error = json['error'];
    final message = error is Map ? '${error['message']}' : 'HTTP $status';
    if (message.toLowerCase().contains('file size too large')) {
      return const AppException(
        AppErrorKind.invalidInput,
        'The file is too large to upload.',
      );
    }
    return switch (status) {
      420 || 429 => const AppException(
        AppErrorKind.rateLimited,
        'The upload limit has been reached. Please try again later.',
      ),
      >= 500 => AppException(
        AppErrorKind.unknown,
        'The upload service is unavailable. Try again in a moment.',
        cause: message,
      ),
      _ => AppException(
        AppErrorKind.configuration,
        'File upload is not set up correctly. Please contact the app team.',
        cause: message,
      ),
    };
  }

  static bool _isPdf(Uint8List bytes) =>
      bytes.length >= 5 &&
      bytes[0] == 0x25 && // %
      bytes[1] == 0x50 && // P
      bytes[2] == 0x44 && // D
      bytes[3] == 0x46 && // F
      bytes[4] == 0x2D; // -

  static String _slug(String fileName) {
    final base = fileName.replaceAll(
      RegExp(r'\.pdf$', caseSensitive: false),
      '',
    );
    final slug = base
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (slug.isEmpty) return 'file';
    return slug.length > 40 ? slug.substring(0, 40) : slug;
  }

  String _randomHex(int byteCount) => [
    for (var i = 0; i < byteCount; i++)
      _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();

  static Map<String, Object?> _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) return decoded;
    } on FormatException {
      // Fall through.
    }
    return const <String, Object?>{};
  }
}
