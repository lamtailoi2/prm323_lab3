import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';

/// Service for managing saved internships under `users/{uid}/savedInternships`
/// (AGENTS.md rule 9: all user data stays in `users/{uid}/**`).
abstract interface class SavedService {
  /// Emits the list of saved internship keys/IDs for [uid].
  Stream<List<String>> watchSavedIds(String uid);

  /// Saves an internship for [uid].
  Future<void> save(String uid, String internshipId);

  /// Unsaves an internship for [uid].
  Future<void> unsave(String uid, String internshipId);
}

final savedServiceProvider = Provider<SavedService>(
  (ref) => FirestoreSavedService(FirebaseFirestore.instance),
);

class FirestoreSavedService implements SavedService {
  FirestoreSavedService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, Object?>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('savedInternships');

  @override
  Stream<List<String>> watchSavedIds(String uid) {
    return _collection(uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.id).toList(growable: false);
        })
        .handleError((Object error) {
          if (error is FirebaseException) throw _toAppException(error);
          throw AppException(
            AppErrorKind.unknown,
            'We could not load saved internships. Try again in a moment.',
            cause: error,
          );
        });
  }

  @override
  Future<void> save(String uid, String internshipId) async {
    try {
      await _collection(uid)
          .doc(internshipId)
          .set(<String, Object?>{'savedAt': FieldValue.serverTimestamp()});
    } on FirebaseException catch (error) {
      throw _toAppException(error);
    }
  }

  @override
  Future<void> unsave(String uid, String internshipId) async {
    try {
      await _collection(uid).doc(internshipId).delete();
    } on FirebaseException catch (error) {
      throw _toAppException(error);
    }
  }

  static AppException _toAppException(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' => AppException(
        AppErrorKind.permissionDenied,
        'You do not have permission to modify saved internships.',
        cause: error,
      ),
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => AppException(
        AppErrorKind.network,
        'Network error. Please check your connection and try again.',
        cause: error,
      ),
      _ => AppException(
        AppErrorKind.unknown,
        'We could not update saved internships. Try again in a moment.',
        cause: error,
      ),
    };
  }
}
