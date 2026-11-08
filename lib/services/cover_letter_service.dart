import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../features/internships/models/cover_letter_draft.dart';

/// Drafts the application email (subject + cover letter) for one internship.
///
/// The app sends only the internship key, its own CV Storage path and the
/// student's name. The callable reads the listing and the profile, calls Groq
/// and falls back to a deterministic template; the model key never ships in
/// the app (AGENTS.md rule 8).
abstract interface class CoverLetterService {
  Future<CoverLetterDraft> compose({
    required String internshipKey,
    String? storagePath,
    String? studentName,
  });
}

final coverLetterServiceProvider = Provider<CoverLetterService>(
  (ref) => FirebaseCoverLetterService(),
);

class FirebaseCoverLetterService implements CoverLetterService {
  FirebaseCoverLetterService({FirebaseFunctions? functions})
    : _functionsOverride = functions;

  final FirebaseFunctions? _functionsOverride;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  @override
  Future<CoverLetterDraft> compose({
    required String internshipKey,
    String? storagePath,
    String? studentName,
  }) async {
    try {
      final callable = _functions.httpsCallable('composeCoverLetter');
      final response = await callable.call<Object?>(<String, Object>{
        'internshipKey': internshipKey,
        'storagePath': ?storagePath,
        if (studentName != null && studentName.trim().isNotEmpty)
          'studentName': studentName.trim(),
      });
      return parseCoverLetterDraft(response.data);
    } on FirebaseFunctionsException catch (error) {
      throw mapCoverLetterError(error.code, cause: error);
    } on AppException {
      rethrow;
    } on Exception catch (error) {
      throw AppException(
        AppErrorKind.unknown,
        'We could not draft your cover letter. Please try again.',
        cause: error,
      );
    }
  }
}

const AppException _malformedResult = AppException(
  AppErrorKind.unknown,
  'We could not read the drafted cover letter. Please try again.',
);

/// Reads the callable payload without trusting its shape.
@visibleForTesting
CoverLetterDraft parseCoverLetterDraft(Object? data) {
  if (data is! Map<Object?, Object?>) throw _malformedResult;

  final subject = data['subject'];
  final body = data['body'];
  final source = data['source'];
  if (subject is! String ||
      body is! String ||
      subject.trim().isEmpty ||
      body.trim().isEmpty) {
    throw _malformedResult;
  }

  return CoverLetterDraft(
    subject: subject.trim(),
    body: body.trim(),
    usedAi: source != 'template',
  );
}

/// Maps a callable error code to a message safe to show (see
/// `functions/src/compose-cover-letter.ts`).
@visibleForTesting
AppException mapCoverLetterError(String code, {Object? cause}) {
  return switch (code) {
    'unauthenticated' || 'permission-denied' => AppException(
      AppErrorKind.permissionDenied,
      'Sign in to draft your cover letter.',
      cause: cause,
    ),
    'invalid-argument' => AppException(
      AppErrorKind.invalidInput,
      'We could not read this job or CV. Try again.',
      cause: cause,
    ),
    'not-found' => AppException(
      AppErrorKind.notFound,
      'This internship is no longer available.',
      cause: cause,
    ),
    'failed-precondition' => AppException(
      AppErrorKind.configuration,
      'Drafting is not available right now. Please try again later.',
      cause: cause,
    ),
    'resource-exhausted' || 'too-many-requests' => AppException(
      AppErrorKind.rateLimited,
      'Drafting is busy right now. Please try again in a moment.',
      cause: cause,
    ),
    'cancelled' => AppException(
      AppErrorKind.cancelled,
      'Drafting was cancelled.',
      cause: cause,
    ),
    'unavailable' ||
    'deadline-exceeded' ||
    'internal' ||
    'network-request-failed' => AppException(
      AppErrorKind.network,
      'We could not draft your letter. Check your connection and try again.',
      cause: cause,
    ),
    _ => AppException(
      AppErrorKind.unknown,
      'We could not draft your cover letter. Please try again.',
      cause: cause,
    ),
  };
}
