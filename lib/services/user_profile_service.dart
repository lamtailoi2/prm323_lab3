import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/cv_library.dart';
import '../core/utils/firestore_reader.dart';
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

  /// Emits the student's CV library (`users/{uid}/cvs`), newest first. The
  /// legacy `users/{uid}.cv` mirror is not part of this stream; callers
  /// merge it with [mergeLegacyCv] (G-33).
  Stream<List<CvFile>> watchCvs(String uid);

  /// Adds [cv] to the library and returns it with the generated document id.
  /// The first CV becomes the default.
  Future<CvFile> addCv(String uid, CvFile cv);

  /// Marks [cvId] as the default and mirrors it into `users/{uid}.cv`.
  Future<void> setDefaultCv(String uid, String cvId);

  /// Removes [cvId] from the library. The Storage file is deleted by the
  /// caller only when no submitted application still references it.
  Future<void> removeCv(String uid, String cvId);

  Future<void> updateDetails(String uid, ProfileDetails details);

  /// Merge write of the fields the Apply Form collects (`fullName`, `phone`,
  /// `university`, `yearOfStudy`). Null fields are skipped, so saving an
  /// application never clears the headline, major, city, bio or graduation
  /// year that Edit profile owns.
  Future<void> updateApplyDetails(String uid, ProfileDetails details);

  Future<void> updateSkills(String uid, List<String> skills);

  Future<void> updatePreferences(String uid, InternshipPreferences preferences);

  /// Adds [cv] to the library and makes it the default. Kept for call sites
  /// written before the library existed; new code uses [addCv] /
  /// [setDefaultCv]. The previous file stays in the library (and in Cloud
  /// Storage) because submitted applications may still link to it.
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

  CollectionReference<Map<String, Object?>> _cvs(String uid) =>
      _document(uid).collection('cvs');

  @override
  Stream<List<CvFile>> watchCvs(String uid) async* {
    final query = _cvs(uid).orderBy('uploadedAt', descending: true);
    try {
      await for (final snapshot in query.snapshots()) {
        yield _parseCvs(snapshot);
      }
    } on FirebaseException catch (error) {
      throw _cvFailure('load your CVs', error);
    }
  }

  List<CvFile> _parseCvs(QuerySnapshot<Map<String, Object?>> snapshot) {
    final cvs = <CvFile>[];
    for (final doc in snapshot.docs) {
      try {
        cvs.add(CvFile.fromFirestore(doc.id, doc.data()));
      } on FormatException catch (error, stack) {
        // One malformed document must not hide the rest of the library.
        unawaited(
          _crashlytics.recordError(
            error,
            stack,
            reason: 'Skipped a malformed CV document',
          ),
        );
      }
    }
    return List<CvFile>.unmodifiable(cvs);
  }

  @override
  Future<CvFile> addCv(String uid, CvFile cv) async {
    final cvs = _cvs(uid);
    final document = cvs.doc();
    final added = cv.copyWith(id: document.id);

    try {
      final existing = await cvs.limit(1).get();
      final profile = await _document(uid).get();
      final firstWrite = existing.docs.isEmpty;

      // The first write migrates the legacy `users/{uid}.cv` into the
      // library, so the student keeps the CV they already had.
      final migratedId = firstWrite
          ? await _migrateLegacy(cvs, uid, profile.data())
          : null;

      await document.set(added.toFirestore());

      if (firstWrite && migratedId == null) {
        // The first CV is the default, so Apply never shows an empty
        // picker next to a non-empty library.
        await _document(uid).set({
          'defaultCvId': document.id,
          'cv': added.toFirestore(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else if (migratedId != null && profile.data()?['defaultCvId'] == null) {
        // The migrated legacy CV stays the default it already was.
        await _document(uid).set({
          'defaultCvId': migratedId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      return added;
    } on FirebaseException catch (error) {
      throw _cvFailure('add your CV', error);
    }
  }

  /// Creates a real document for `users/{uid}.cv` and returns its id.
  Future<String?> _migrateLegacy(
    CollectionReference<Map<String, Object?>> cvs,
    String uid,
    Map<String, Object?>? profile,
  ) async {
    final raw = profile?['cv'];
    if (raw is! Map) return null;
    try {
      final legacy = CvFile.fromReader(
        FirestoreReader('users/$uid.cv', Map<String, Object?>.from(raw)),
      );
      final document = cvs.doc();
      await document.set(legacy.toFirestore());
      return document.id;
    } on FormatException {
      // A malformed mirror cannot be migrated; adding still works.
      return null;
    }
  }

  @override
  Future<void> setDefaultCv(String uid, String cvId) async {
    try {
      if (cvId == legacyCvId) {
        // The legacy mirror is the default whenever `defaultCvId` is null.
        final profile = await _document(uid).get();
        if (profile.data()?['cv'] is! Map) {
          throw const AppException(
            AppErrorKind.notFound,
            'That CV is no longer in your library.',
          );
        }
        await _document(uid).set({
          'defaultCvId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }

      final snapshot = await _cvs(uid).doc(cvId).get();
      final data = snapshot.data();
      if (data == null) {
        throw const AppException(
          AppErrorKind.notFound,
          'That CV is no longer in your library.',
        );
      }
      final cv = CvFile.fromFirestore(cvId, data);
      await _document(uid).set({
        'defaultCvId': cvId,
        'cv': cv.toFirestore(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FormatException catch (error) {
      throw AppException(
        AppErrorKind.unknown,
        'We could not change the default CV. Try again in a moment.',
        cause: error,
      );
    } on FirebaseException catch (error) {
      throw _cvFailure('change the default CV', error);
    }
  }

  /// The newest parseable CV in the library, or `null` when there is none.
  Future<CvFile?> _newestCv(String uid) async {
    final snapshot = await _cvs(uid).get();
    final cvs = <CvFile>[];
    for (final doc in snapshot.docs) {
      try {
        cvs.add(CvFile.fromFirestore(doc.id, doc.data()));
      } on FormatException {
        // A malformed entry cannot become the default; skip it.
      }
    }
    if (cvs.isEmpty) return null;
    return cvs.reduce(
      (newest, cv) => cv.uploadedAt.isAfter(newest.uploadedAt) ? cv : newest,
    );
  }

  @override
  Future<void> removeCv(String uid, String cvId) async {
    try {
      if (cvId == legacyCvId) {
        // The mirror is what the Apply Form prefills, so a library entry
        // becomes the new default instead of leaving it null. The caller
        // deletes the Storage file after its reference check.
        final next = await _newestCv(uid);
        await _document(uid).set({
          'cv': next?.toFirestore(),
          'defaultCvId': next?.id,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }

      final library = await _cvs(uid).get();
      final profile = await _document(uid).get();
      final removed = library.docs.where((doc) => doc.id == cvId).firstOrNull;

      await _cvs(uid).doc(cvId).delete();

      final remaining = <CvFile>[];
      for (final doc in library.docs) {
        if (doc.id == cvId) continue;
        try {
          remaining.add(CvFile.fromFirestore(doc.id, doc.data()));
        } on FormatException {
          // A malformed entry cannot become the default; skip it.
        }
      }
      remaining.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

      final data = profile.data();
      final currentDefault = data?['defaultCvId'];
      final removedPath = removed?.data()['storagePath'];
      final mirrorPath = switch (data?['cv']) {
        final Map<Object?, Object?> cv => cv['storagePath'],
        _ => null,
      };
      final removingDefault =
          currentDefault == cvId ||
          (removedPath != null && removedPath == mirrorPath);

      // A surviving legacy mirror is the default when `defaultCvId` is
      // null, so promoting a library file would silently change the
      // student's default.
      if (!removingDefault && (currentDefault != null || mirrorPath != null)) {
        return;
      }

      final next = remaining.firstOrNull;
      if (next != null) {
        await _document(uid).set({
          'defaultCvId': next.id,
          'cv': next.toFirestore(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else if (mirrorPath != null && removedPath != mirrorPath) {
        // A legacy mirror that is not the removed file survives.
        await _document(uid).set({
          'defaultCvId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await _document(uid).set({
          'defaultCvId': null,
          'cv': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } on FirebaseException catch (error) {
      throw _cvFailure('remove this CV', error);
    }
  }

  @override
  Future<void> updateCv(String uid, CvFile cv) async {
    final added = await addCv(uid, cv);
    await setDefaultCv(uid, added.id!);
  }

  static AppException _cvFailure(String action, FirebaseException error) {
    return switch (error.code) {
      'permission-denied' || 'unauthenticated' => AppException(
        AppErrorKind.permissionDenied,
        'We could not $action. Sign in again and try once more.',
        cause: error,
      ),
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => AppException(
        AppErrorKind.network,
        'We could not $action. Check your connection and try again.',
        cause: error,
      ),
      _ => AppException(
        AppErrorKind.unknown,
        'We could not $action. Try again in a moment.',
        cause: error,
      ),
    };
  }

  @override
  Future<void> updateDetails(String uid, ProfileDetails details) =>
      _merge(uid, 'details', details.toFirestore());

  @override
  Future<void> updateApplyDetails(String uid, ProfileDetails details) {
    final fields = <String, Object?>{
      for (final entry in details.toFirestore().entries)
        if (entry.value != null) entry.key: entry.value,
    };
    return _merge(uid, 'apply details', fields);
  }

  @override
  Future<void> updateSkills(String uid, List<String> skills) =>
      _merge(uid, 'skills', {'skills': skills});

  @override
  Future<void> updatePreferences(
    String uid,
    InternshipPreferences preferences,
  ) => _merge(uid, 'preferences', {'preferences': preferences.toFirestore()});

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
