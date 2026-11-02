import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/internship_application.dart';
import 'auth_service.dart';
import 'crashlytics_service.dart';

/// Reads the signed-in student's tracked applications.
///
/// Documents live under `users/{uid}/applications/{jobKey}` (rule 9 in
/// AGENTS.md); the Apply flow owns the writes, this screen only reads them.
abstract interface class ApplicationService {
  /// Emits the applications of the current user, newest first; empty when
  /// signed out.
  Stream<List<InternshipApplication>> watchApplications();
}

final applicationServiceProvider = Provider<ApplicationService>((ref) {
  // Watching the uid rebuilds the service on sign-out or an account switch,
  // so the previous student's listener is dropped (AGENTS.md rule 11).
  final uid = ref.watch(currentUserIdProvider);

  return FirestoreApplicationService(
    FirebaseFirestore.instance,
    uid,
    crashlytics: ref.watch(crashlyticsServiceProvider),
  );
});

class FirestoreApplicationService implements ApplicationService {
  FirestoreApplicationService(
    this._firestore,
    this._uid, {
    required this._crashlytics,
  });

  final FirebaseFirestore _firestore;
  final String? _uid;
  final CrashlyticsService _crashlytics;

  @override
  Stream<List<InternshipApplication>> watchApplications() async* {
    final uid = _uid;

    // The router already sends signed-out users to Login; an empty list keeps
    // this service usable without a user document.
    if (uid == null || uid.isEmpty) {
      yield const <InternshipApplication>[];
      return;
    }

    final query = _firestore
        .collection('users')
        .doc(uid)
        .collection('applications')
        .orderBy('appliedAt', descending: true);

    try {
      await for (final snapshot in query.snapshots()) {
        yield _parse(snapshot);
      }
    } on FirebaseException catch (error) {
      throw _toAppException(error);
    } on Exception catch (error) {
      throw AppException(
        AppErrorKind.unknown,
        'We could not load your applications. Try again in a moment.',
        cause: error,
      );
    }
  }

  List<InternshipApplication> _parse(
    QuerySnapshot<Map<String, Object?>> snapshot,
  ) {
    final applications = <InternshipApplication>[];

    for (final doc in snapshot.docs) {
      try {
        applications.add(
          InternshipApplication.fromFirestore(doc.id, doc.data()),
        );
      } on FormatException catch (error, stack) {
        // One malformed document must not hide the others.
        unawaited(
          _crashlytics.recordError(
            error,
            stack,
            reason: 'Skipped a malformed application document',
          ),
        );
      }
    }

    return List<InternshipApplication>.unmodifiable(applications);
  }

  static AppException _toAppException(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' || 'unauthenticated' => AppException(
        AppErrorKind.permissionDenied,
        'Your applications are not available for this account.',
        cause: error,
      ),
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => AppException(
        AppErrorKind.network,
        'We could not load your applications. Check your connection and try '
        'again.',
        cause: error,
      ),
      _ => AppException(
        AppErrorKind.unknown,
        'We could not load your applications. Try again in a moment.',
        cause: error,
      ),
    };
  }
}
