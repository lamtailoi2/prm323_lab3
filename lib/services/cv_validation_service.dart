import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/cv_validation_result.dart';

/// CV quality gate for the Apply flow.
///
/// The app sends only the Storage path of the signed-in user's CV. The
/// callable Cloud Function reads the file with the Admin SDK and calls Gemini;
/// the model key never ships in the app (AGENTS.md rule 8).
abstract interface class CvValidationService {
  /// Validates the CV at [storagePath] (`cvs/{uid}/…`).
  Future<CvValidationResult> validate(String storagePath);
}

final cvValidationServiceProvider = Provider<CvValidationService>(
  (ref) => FirebaseCvValidationService(),
);

class FirebaseCvValidationService implements CvValidationService {
  FirebaseCvValidationService({FirebaseFunctions? functions})
    : _functionsOverride = functions;

  final FirebaseFunctions? _functionsOverride;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  @override
  Future<CvValidationResult> validate(String storagePath) async {
    try {
      final callable = _functions.httpsCallable('validateCv');
      final response = await callable.call<Object?>(<String, Object>{
        'storagePath': storagePath,
      });
      return parseValidationResult(response.data);
    } on FirebaseFunctionsException catch (error) {
      throw mapCvValidationError(error.code, cause: error);
    } on Exception catch (error) {
      throw AppException(
        AppErrorKind.unknown,
        'We could not check your CV. Please try again.',
        cause: error,
      );
    }
  }
}

/// Reads `{ isValid, reason? }` from the callable result without trusting its
/// shape. Malformed output is reported as a recoverable error, not a block.
@visibleForTesting
CvValidationResult parseValidationResult(Object? data) {
  if (data is! Map<Object?, Object?>) {
    throw const AppException(
      AppErrorKind.unknown,
      'We could not check your CV. Please try again.',
    );
  }

  final isValid = data['isValid'];
  if (isValid is! bool) {
    throw const AppException(
      AppErrorKind.unknown,
      'We could not check your CV. Please try again.',
    );
  }

  final reason = data['reason'];
  final trimmed = reason is String ? reason.trim() : '';
  return CvValidationResult(
    isValid: isValid,
    reason: trimmed.isEmpty ? null : trimmed,
  );
}

/// Translates Cloud Functions error codes into user-safe messages.
@visibleForTesting
AppException mapCvValidationError(String code, {Object? cause}) {
  return switch (code) {
    'unauthenticated' || 'permission-denied' => AppException(
      AppErrorKind.permissionDenied,
      'Sign in to check your CV.',
      cause: cause,
    ),
    'invalid-argument' => AppException(
      AppErrorKind.invalidInput,
      'This file could not be read as a CV. '
      'Upload a text-based PDF and try again.',
      cause: cause,
    ),
    'failed-precondition' => AppException(
      AppErrorKind.configuration,
      'CV checking is not available right now. Please try again later.',
      cause: cause,
    ),
    'not-found' => AppException(
      AppErrorKind.notFound,
      'We could not find your CV. Upload it again and retry.',
      cause: cause,
    ),
    'resource-exhausted' || 'too-many-requests' => AppException(
      AppErrorKind.rateLimited,
      'CV checks are busy right now. Please try again in a moment.',
      cause: cause,
    ),
    'cancelled' => AppException(
      AppErrorKind.cancelled,
      'The CV check was cancelled.',
      cause: cause,
    ),
    'unavailable' ||
    'deadline-exceeded' ||
    'internal' ||
    'network-request-failed' => AppException(
      AppErrorKind.network,
      'We could not check your CV. Check your connection and try again.',
      cause: cause,
    ),
    _ => AppException(
      AppErrorKind.unknown,
      'We could not check your CV. Please try again.',
      cause: cause,
    ),
  };
}
