import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/cv_match_result.dart';

/// Advisory, job-specific CV match for the Apply flow (G-24/DC-09).
///
/// The app sends only its own CV Storage path and the internship key. The
/// callable reads the internship, extracts the CV text server-side and calls
/// Gemini for the commentary; the model key never ships in the app.
abstract interface class CvMatchService {
  Future<CvMatchResult> match({
    required String storagePath,
    required String internshipKey,
  });
}

final cvMatchServiceProvider = Provider<CvMatchService>(
  (ref) => FirebaseCvMatchService(),
);

class FirebaseCvMatchService implements CvMatchService {
  FirebaseCvMatchService({FirebaseFunctions? functions})
    : _functionsOverride = functions;

  final FirebaseFunctions? _functionsOverride;

  FirebaseFunctions get _functions =>
      _functionsOverride ?? FirebaseFunctions.instance;

  @override
  Future<CvMatchResult> match({
    required String storagePath,
    required String internshipKey,
  }) async {
    try {
      final callable = _functions.httpsCallable('matchCv');
      final response = await callable.call<Object?>(<String, Object>{
        'storagePath': storagePath,
        'internshipKey': internshipKey,
      });
      return parseMatchResult(response.data);
    } on FirebaseFunctionsException catch (error) {
      throw mapCvMatchError(error.code, cause: error);
    } on AppException {
      rethrow;
    } on Exception catch (error) {
      throw AppException(
        AppErrorKind.unknown,
        'We could not check your CV. Please try again.',
        cause: error,
      );
    }
  }
}

const AppException _malformedResult = AppException(
  AppErrorKind.unknown,
  'We could not read the CV match result. Please try again.',
);

/// Reads the callable payload without trusting its shape.
@visibleForTesting
CvMatchResult parseMatchResult(Object? data) {
  if (data is! Map<Object?, Object?>) throw _malformedResult;

  final title = data['internshipTitle'];
  final company = data['companyName'] ?? '';
  final percent = data['percent'];
  final matchedCount = data['matchedCount'];
  final totalRequired = data['totalRequired'];
  final summary = data['summary'];
  final cvReadable = data['cvReadable'];

  if (title is! String ||
      company is! String ||
      summary is! String ||
      cvReadable is! bool ||
      percent is! num ||
      matchedCount is! num ||
      totalRequired is! num) {
    throw _malformedResult;
  }

  return CvMatchResult(
    internshipTitle: title,
    companyName: company,
    percent: percent.toInt().clamp(0, 100).toInt(),
    matchedCount: matchedCount.toInt(),
    totalRequired: totalRequired.toInt(),
    matched: _stringList(data['matched']),
    missing: _stringList(data['missing']),
    niceToHave: _stringList(data['niceToHave']),
    suggestions: _suggestions(data['suggestions']),
    summary: summary,
    cvReadable: cvReadable,
  );
}

List<String> _stringList(Object? value) {
  if (value is! List) throw _malformedResult;
  final out = <String>[];
  for (final entry in value) {
    if (entry is! String) throw _malformedResult;
    out.add(entry);
  }
  return List<String>.unmodifiable(out);
}

List<CvMatchSuggestion> _suggestions(Object? value) {
  if (value is! List) throw _malformedResult;
  final out = <CvMatchSuggestion>[];
  for (final entry in value) {
    if (entry is! Map<Object?, Object?>) throw _malformedResult;
    final skill = entry['skill'];
    final text = entry['text'];
    if (skill is! String || text is! String) throw _malformedResult;
    out.add(CvMatchSuggestion(skill: skill, text: text));
  }
  return List<CvMatchSuggestion>.unmodifiable(out);
}

/// Maps a callable error code to a message safe to show (see
/// `functions/src/match-cv.ts`).
@visibleForTesting
AppException mapCvMatchError(String code, {Object? cause}) {
  return switch (code) {
    'unauthenticated' || 'permission-denied' => AppException(
      AppErrorKind.permissionDenied,
      'Sign in to check your CV.',
      cause: cause,
    ),
    'invalid-argument' => AppException(
      AppErrorKind.invalidInput,
      'We could not read this CV or internship. Try again from the Apply Form.',
      cause: cause,
    ),
    'not-found' => AppException(
      AppErrorKind.notFound,
      'This internship is no longer available.',
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
