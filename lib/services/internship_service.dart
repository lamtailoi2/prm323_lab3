import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/internship.dart';
import 'crashlytics_service.dart';

/// Internship listings shared by every signed-in user.
///
/// Listings are written to Firestore by the scheduled `syncInternships` Cloud
/// Function (SerpAPI → Firestore) and are read-only in the app. The app never
/// calls SerpAPI directly, so the API key never ships in the APK.
abstract interface class InternshipService {
  /// Emits active listings whenever the shared collection changes. Documents
  /// with `expiresAt <= now` are excluded by the query.
  Stream<List<Internship>> watchActive();

  /// Emits the listing `/internships/{key}` whenever it changes, or `null`
  /// when the sync function has deleted it (expired listings, G-25 #5).
  Stream<Internship?> watchByKey(String key);
}

final internshipServiceProvider = Provider<InternshipService>(
  (ref) => FirestoreInternshipService(
    FirebaseFirestore.instance,
    crashlytics: ref.watch(crashlyticsServiceProvider),
  ),
);

class FirestoreInternshipService implements InternshipService {
  FirestoreInternshipService(this._firestore, {required this._crashlytics});

  final FirebaseFirestore _firestore;
  final CrashlyticsService _crashlytics;

  @override
  Stream<List<Internship>> watchActive() async* {
    final query = _firestore
        .collection('internships')
        .where('expiresAt', isGreaterThan: Timestamp.now());

    try {
      await for (final snapshot in query.snapshots()) {
        yield _parse(snapshot);
      }
    } on FirebaseException catch (error) {
      throw _toAppException(error);
    } on Exception catch (error) {
      throw AppException(
        AppErrorKind.unknown,
        'We could not load internships. Try again in a moment.',
        cause: error,
      );
    }
  }

  @override
  Stream<Internship?> watchByKey(String key) async* {
    final document = _firestore.collection('internships').doc(key);

    try {
      await for (final snapshot in document.snapshots()) {
        yield _parseOne(snapshot);
      }
    } on FirebaseException catch (error) {
      throw _toAppException(error);
    } on Exception catch (error) {
      throw AppException(
        AppErrorKind.unknown,
        'We could not load internships. Try again in a moment.',
        cause: error,
      );
    }
  }

  Internship? _parseOne(DocumentSnapshot<Map<String, Object?>> snapshot) {
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    try {
      return Internship.fromFirestore(snapshot.id, data);
    } on FormatException catch (error, stack) {
      // A malformed listing is shown as unavailable, like a deleted one.
      unawaited(
        _crashlytics.recordError(
          error,
          stack,
          reason: 'Malformed internship document on Internship Detail',
        ),
      );
      return null;
    }
  }

  List<Internship> _parse(QuerySnapshot<Map<String, Object?>> snapshot) {
    final results = <Internship>[];
    for (final doc in snapshot.docs) {
      try {
        results.add(Internship.fromFirestore(doc.id, doc.data()));
      } on FormatException catch (error, stack) {
        // One malformed document must not hide the others.
        unawaited(
          _crashlytics.recordError(
            error,
            stack,
            reason: 'Skipped a malformed internship document',
          ),
        );
      }
    }
    return List<Internship>.unmodifiable(results);
  }

  static AppException _toAppException(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' => AppException(
        AppErrorKind.permissionDenied,
        'Internships are not available for this account.',
        cause: error,
      ),
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => AppException(
        AppErrorKind.network,
        'We could not load internships. Check your connection and try again.',
        cause: error,
      ),
      _ => AppException(
        AppErrorKind.unknown,
        'We could not load internships. Try again in a moment.',
        cause: error,
      ),
    };
  }
}
