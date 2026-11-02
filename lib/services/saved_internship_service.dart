import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/internship.dart';
import 'auth_service.dart';

/// Reads and writes the signed-in student's saved internships.
///
/// Every saved item is a copy of the shared listing stored under
/// `users/{uid}/savedInternships/{key}` (rule 9 in AGENTS.md). Copying the
/// fields the Saved screen shows means the item still renders after the
/// listing expires from the shared pool (G-25).
abstract interface class SavedInternshipService {
  /// Emits the saved listings of the current user; empty when signed out.
  Stream<List<Internship>> watchSaved();

  /// Saves a copy of [internship] for the current user.
  ///
  /// Throws [AppException] when the listing disappeared from the shared pool
  /// or the write failed.
  Future<void> save(Internship internship);

  /// Removes the saved item with [internshipKey].
  Future<void> remove(String internshipKey);
}

final savedInternshipServiceProvider = Provider<SavedInternshipService>((ref) {
  final uid = ref.watch(currentUserIdProvider);

  return FirestoreSavedInternshipService(FirebaseFirestore.instance, uid);
});

class FirestoreSavedInternshipService implements SavedInternshipService {
  FirestoreSavedInternshipService(this._firestore, this._uid);

  final FirebaseFirestore _firestore;
  final String? _uid;

  CollectionReference<Map<String, dynamic>>? get _savedCollection {
    final uid = _uid;

    if (uid == null || uid.isEmpty) return null;

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('savedInternships');
  }

  @override
  Stream<List<Internship>> watchSaved() {
    final collection = _savedCollection;

    if (collection == null) {
      return Stream.value(const <Internship>[]);
    }

    return collection.snapshots().map((snapshot) {
      final internships = <Internship>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final raw = data['internship'];

          if (raw is! Map) continue;

          internships.add(
            Internship.fromFirestore(doc.id, Map<String, Object?>.from(raw)),
          );
        } on FormatException {
          // Skip malformed saved documents instead of breaking the list.
          continue;
        }
      }

      return internships;
    });
  }

  @override
  Future<void> save(Internship internship) async {
    final collection = _savedCollection;

    if (collection == null) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        'Sign in to save internships.',
      );
    }

    try {
      final listing = await _firestore
          .collection('internships')
          .doc(internship.key)
          .get();

      final data = listing.data();
      if (!listing.exists || data == null) {
        throw const AppException(
          AppErrorKind.notFound,
          'This internship is no longer available.',
        );
      }

      await collection.doc(internship.key).set({
        'internship': data,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } on AppException {
      rethrow;
    } on Exception catch (error) {
      throw _failure(
        error,
        'We could not save this internship. Check your connection and try '
        'again.',
      );
    }
  }

  @override
  Future<void> remove(String internshipKey) async {
    final collection = _savedCollection;

    if (collection == null) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        'Sign in to manage saved internships.',
      );
    }

    try {
      await collection.doc(internshipKey).delete();
    } on Exception catch (error) {
      throw _failure(
        error,
        'We could not remove this internship. Check your connection and try '
        'again.',
      );
    }
  }

  static AppException _failure(Object error, String fallback) {
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' || 'unauthenticated' => AppException(
          AppErrorKind.permissionDenied,
          "You don't have permission to change your saved internships.",
          cause: error,
        ),
        'unavailable' ||
        'deadline-exceeded' ||
        'network-request-failed' => AppException(
          AppErrorKind.network,
          'We could not reach Internly. Check your connection and try '
          'again.',
          cause: error,
        ),
        _ => AppException(AppErrorKind.unknown, fallback, cause: error),
      };
    }

    return AppException(AppErrorKind.unknown, fallback, cause: error);
  }
}
