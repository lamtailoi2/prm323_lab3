import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/internship_application.dart';
import 'auth_service.dart';
import 'crashlytics_service.dart';

/// Reads and records the signed-in student's tracked applications.
///
/// Documents live under `users/{uid}/applications/{jobKey}` (rule 9 in
/// AGENTS.md).
abstract interface class ApplicationService {
  /// Emits the applications of the current user, newest first; empty when
  /// signed out.
  Stream<List<InternshipApplication>> watchApplications();

  /// Records a submitted application (Flow 2 end). Writing the same listing
  /// again overwrites its document instead of creating a duplicate.
  Future<void> createApplication({
    required String internshipKey,
    required String title,
    required String companyName,
    required String cvStoragePath,
    required String cvFileName,
    required String cvUrl,
    required ApplicationApplicant applicant,
  });

  /// Withdraws an application (Flow 3d): keeps the status it had so
  /// `undoWithdrawal` can restore it, and stamps when it happened.
  Future<void> withdraw(
    String internshipKey, {
    required ApplicationStatus previous,
  });

  /// Restores the status the application had before it was withdrawn.
  Future<void> undoWithdrawal(String internshipKey);
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

  @override
  Future<void> createApplication({
    required String internshipKey,
    required String title,
    required String companyName,
    required String cvStoragePath,
    required String cvFileName,
    required String cvUrl,
    required ApplicationApplicant applicant,
  }) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        'Sign in again and try once more.',
      );
    }

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('applications')
          .doc(internshipKey)
          .set(<String, Object?>{
            // Snapshot of what the list shows: listings expire from the
            // shared pool (G-25 #5).
            'title': title,
            'companyName': companyName,
            'appliedAt': FieldValue.serverTimestamp(),
            'status': ApplicationStatus.submitted.storageValue,
            'cvStoragePath': cvStoragePath,
            // The CV can no longer be replaced, so it is stored here too.
            'cvFileName': cvFileName,
            'cvUrl': cvUrl,
            // What the student sent: the profile can change later.
            'applicant': applicant.toFirestore(),
          });
    } on FirebaseException catch (error) {
      throw _toWriteAppException(error);
    } on Exception catch (error) {
      throw AppException(
        AppErrorKind.unknown,
        'We could not submit your application. Try again in a moment.',
        cause: error,
      );
    }
  }

  @override
  Future<void> withdraw(
    String internshipKey, {
    required ApplicationStatus previous,
  }) => _updateApplication(internshipKey, <String, Object?>{
    'status': ApplicationStatus.withdrawn.storageValue,
    'withdrawnAt': FieldValue.serverTimestamp(),
    'previousStatus': previous.storageValue,
  });

  @override
  Future<void> undoWithdrawal(String internshipKey) async {
    final status = await _previousStatus(internshipKey);
    await _updateApplication(internshipKey, <String, Object?>{
      'status': status.storageValue,
      'withdrawnAt': FieldValue.delete(),
      'previousStatus': FieldValue.delete(),
    });
  }

  /// Reads the stored status a withdrawal replaced; `submitted` when the
  /// document does not have one.
  Future<ApplicationStatus> _previousStatus(String internshipKey) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        'Sign in again and try once more.',
      );
    }
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('applications')
          .doc(internshipKey)
          .get();
      final data = snapshot.data();
      final raw = data?['previousStatus'];
      return raw is String
          ? ApplicationStatus.fromStorage(raw) ?? ApplicationStatus.submitted
          : ApplicationStatus.submitted;
    } on FirebaseException catch (error) {
      throw _toWriteAppException(error);
    }
  }

  /// Merge write of the fields an update changes; the rest of the document,
  /// including the applicant snapshot, is kept.
  Future<void> _updateApplication(
    String internshipKey,
    Map<String, Object?> fields,
  ) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw const AppException(
        AppErrorKind.permissionDenied,
        'Sign in again and try once more.',
      );
    }
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('applications')
          .doc(internshipKey)
          .set(fields, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw _toWriteAppException(error);
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

  /// The write fails for the same reasons a read does, but the message names
  /// the action the student just took.
  static AppException _toWriteAppException(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' || 'unauthenticated' => AppException(
        AppErrorKind.permissionDenied,
        'Sign in again and try once more.',
        cause: error,
      ),
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => AppException(
        AppErrorKind.network,
        'We could not submit your application. Check your connection and try '
        'again.',
        cause: error,
      ),
      _ => AppException(
        AppErrorKind.unknown,
        'We could not submit your application. Try again in a moment.',
        cause: error,
      ),
    };
  }
}
