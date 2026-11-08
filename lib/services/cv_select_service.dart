import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/cv_selection.dart';

/// Automatic CV selection for the Apply Form (G-33 item 8).
///
/// The app sends only its own CV Storage paths and the internship key. The
/// callable reads every CV server-side, scores them deterministically and
/// uses Groq only for the one-sentence reason; the model key never ships in
/// the app.
abstract interface class CvSelectService {
  Future<CvSelection> select({
    required String internshipKey,
    required List<String> storagePaths,
    String? defaultPath,
  });
}

final cvSelectServiceProvider = Provider<CvSelectService>(
  (ref) => FirebaseCvSelectService(),
);

class FirebaseCvSelectService implements CvSelectService {
  FirebaseCvSelectService({FirebaseFunctions? functions})
    : _functionsOverride = functions;

  final FirebaseFunctions? _functionsOverride;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  @override
  Future<CvSelection> select({
    required String internshipKey,
    required List<String> storagePaths,
    String? defaultPath,
  }) async {
    try {
      final callable = _functions.httpsCallable('selectCv');
      final response = await callable.call<Object?>(<String, Object?>{
        'internshipKey': internshipKey,
        'cvPaths': storagePaths,
        'defaultPath': ?defaultPath,
      });
      return parseSelectionResult(response.data);
    } on FirebaseFunctionsException catch (error) {
      throw mapCvSelectError(error.code, cause: error);
    } on AppException {
      rethrow;
    } on Exception catch (error) {
      throw AppException(
        AppErrorKind.unknown,
        'We could not compare your CVs. Please try again.',
        cause: error,
      );
    }
  }
}

const AppException _malformedResult = AppException(
  AppErrorKind.unknown,
  'We could not read the CV choice. Please try again.',
);

/// Maps a callable error code to a message safe to show (see
/// `functions/src/select-cv.ts`). Automatic selection never blocks applying,
/// so the form falls back to the default CV on any failure; this message is
/// only for the log.
@visibleForTesting
AppException mapCvSelectError(String code, {Object? cause}) {
  return switch (code) {
    'unauthenticated' || 'permission-denied' => AppException(
      AppErrorKind.permissionDenied,
      'Sign in to compare your CVs.',
      cause: cause,
    ),
    'invalid-argument' => AppException(
      AppErrorKind.invalidInput,
      'We could not compare these CVs. Try again from the Apply Form.',
      cause: cause,
    ),
    'not-found' => AppException(
      AppErrorKind.notFound,
      'This internship is no longer available.',
      cause: cause,
    ),
    'resource-exhausted' || 'too-many-requests' => AppException(
      AppErrorKind.rateLimited,
      'CV comparison is busy right now. Please try again in a moment.',
      cause: cause,
    ),
    'unavailable' ||
    'deadline-exceeded' ||
    'internal' ||
    'network-request-failed' => AppException(
      AppErrorKind.network,
      'We could not compare your CVs. Check your connection and try again.',
      cause: cause,
    ),
    _ => AppException(
      AppErrorKind.unknown,
      'We could not compare your CVs. Please try again.',
      cause: cause,
    ),
  };
}

/// Reads the callable payload without trusting its shape.
@visibleForTesting
CvSelection parseSelectionResult(Object? data) {
  if (data is! Map<Object?, Object?>) throw _malformedResult;

  final storagePath = data['storagePath'];
  final percent = data['percent'];
  final matchedCount = data['matchedCount'];
  final totalRequired = data['totalRequired'];
  final reason = data['reason'];
  final cvReadable = data['cvReadable'];

  if (storagePath is! String ||
      storagePath.trim() == '' ||
      percent is! num ||
      matchedCount is! num ||
      totalRequired is! num ||
      reason is! String ||
      cvReadable is! bool) {
    throw _malformedResult;
  }

  return CvSelection(
    storagePath: storagePath,
    percent: percent.toInt().clamp(0, 100).toInt(),
    matchedCount: matchedCount.toInt(),
    totalRequired: totalRequired.toInt(),
    reason: reason,
    cvReadable: cvReadable,
  );
}
