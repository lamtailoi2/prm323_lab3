import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/user_profile.dart';
import 'crashlytics_service.dart';

/// The signed-in student's profile document, `users/{uid}`.
///
/// Each update writes one section with a merge, so editing skills never
/// overwrites a CV that another device uploaded in the meantime.
abstract interface class UserProfileService {
  /// Emits the profile whenever it changes, or `null` while the document
  /// does not exist yet (nothing saved so far).
  Stream<UserProfile?> watchProfile(String uid);

  Future<void> updateDetails(String uid, ProfileDetails details);

  Future<void> updateSkills(String uid, List<String> skills);

  Future<void> updatePreferences(String uid, InternshipPreferences preferences);

  /// Sets the default CV. The previous file stays in Cloud Storage because
  /// submitted applications may still link to it.
  Future<void> updateCv(String uid, CvFile cv);
}

final userProfileServiceProvider = Provider<UserProfileService>(
  (ref) => FirestoreUserProfileService(
    FirebaseFirestore.instance,
    crashlytics: ref.watch(crashlyticsServiceProvider),
  ),
);

class FirestoreUserProfileService implements UserProfileService {
  FirestoreUserProfileService(this._firestore, {required this._crashlytics});

  final FirebaseFirestore _firestore;
  final CrashlyticsService _crashlytics;

  DocumentReference<Map<String, Object?>> _document(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    try {
      await for (final snapshot in _document(uid).snapshots()) {
        final data = snapshot.data();
        if (data == null) {
          yield null;
          continue;
        }
        final profile = UserProfile.fromFirestore(uid, data);
        if (data['cv'] != null && profile.cv == null) {
          unawaited(
            _crashlytics.recordError(
              const FormatException('users/{uid}.cv is malformed'),
              StackTrace.current,
              reason: 'Ignored a malformed CV entry in a profile',
            ),
          );
        }
        yield profile;
      }
    } on FirebaseException catch (error) {
      throw _toAppException(error, saving: false);
    }
  }

  @override
  Future<void> updateDetails(String uid, ProfileDetails details) =>
      _merge(uid, 'details', details.toFirestore());

  @override
  Future<void> updateSkills(String uid, List<String> skills) =>
      _merge(uid, 'skills', {'skills': skills});

  @override
  Future<void> updatePreferences(
    String uid,
    InternshipPreferences preferences,
  ) => _merge(uid, 'preferences', {'preferences': preferences.toFirestore()});

  @override
  Future<void> updateCv(String uid, CvFile cv) =>
      _merge(uid, 'cv', {'cv': cv.toFirestore()});

  /// The returned future completes when the server acknowledges the write,
  /// so its duration is logged: a slow acknowledgement looks like a hang in
  /// the form that waits for it.
  Future<void> _merge(
    String uid,
    String section,
    Map<String, Object?> fields,
  ) async {
    final watch = Stopwatch()..start();
    _trace('saving $section');
    try {
      await _document(uid).set({
        ...fields,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _trace('saved $section in ${watch.elapsedMilliseconds} ms');
    } on FirebaseException catch (error) {
      _trace(
        'save $section failed (${error.code}) '
        'after ${watch.elapsedMilliseconds} ms',
      );
      throw _toAppException(error, saving: true);
    }
  }

  /// Crashlytics breadcrumb. Section names and timings only, never profile
  /// values (personal data).
  void _trace(String message) =>
      unawaited(_crashlytics.log('profile: $message'));

  static AppException _toAppException(
    FirebaseException error, {
    required bool saving,
  }) {
    final action = saving
        ? 'We could not save your changes.'
        : 'We could not load your profile.';
    return switch (error.code) {
      'permission-denied' || 'unauthenticated' => AppException(
        AppErrorKind.permissionDenied,
        '$action Sign in again and try once more.',
        cause: error,
      ),
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => AppException(
        AppErrorKind.network,
        '$action Check your connection and try again.',
        cause: error,
      ),
      _ => AppException(
        AppErrorKind.unknown,
        '$action Try again in a moment.',
        cause: error,
      ),
    };
  }
}
