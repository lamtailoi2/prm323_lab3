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
