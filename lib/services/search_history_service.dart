import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../features/internships/models/search_history_entry.dart';

/// Per-student search history, under `users/{uid}/searchHistory` (AGENTS.md
/// rule 9: user data stays under `users/{uid}/**`, no rules change needed).
abstract interface class SearchHistoryService {
  /// Emits the most recent entries, newest first, whenever they change.
  Stream<List<SearchHistoryEntry>> watchRecent(String uid, {int limit});

  /// Records [term] as searched now. A previous entry for the same term
  /// (case-insensitive) is replaced so it moves to the top instead of
  /// duplicating.
  Future<void> record(String uid, String term);

  /// Deletes every entry for [uid].
  Future<void> clear(String uid);
}

final searchHistoryServiceProvider = Provider<SearchHistoryService>(
  (ref) => FirestoreSearchHistoryService(FirebaseFirestore.instance),
);

class FirestoreSearchHistoryService implements SearchHistoryService {
  FirestoreSearchHistoryService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, Object?>> _collection(String uid) =>
      _firestore.collection('users').doc(uid).collection('searchHistory');

  @override
  Stream<List<SearchHistoryEntry>> watchRecent(String uid, {int limit = 10}) {
    final query = _collection(uid)
        .orderBy('searchedAt', descending: true)
        .limit(limit);

    return query.snapshots().map(_parse).handleError((Object error) {
      if (error is FirebaseException) throw _toAppException(error);
      throw AppException(
        AppErrorKind.unknown,
        'We could not load recent searches. Try again in a moment.',
        cause: error,
      );
    });
  }

  @override
  Future<void> record(String uid, String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    try {
      final collection = _collection(uid);
      final existing = await collection.where('term', isEqualTo: trimmed).get();
      final batch = _firestore.batch();
      for (final doc in existing.docs) {
        batch.delete(doc.reference);
      }
      batch.set(collection.doc(), <String, Object?>{
        'term': trimmed,
        'searchedAt': Timestamp.now(),
      });
      await batch.commit();
    } on FirebaseException catch (error) {
      throw _toAppException(error);
    }
  }

  @override
  Future<void> clear(String uid) async {
    try {
      final docs = await _collection(uid).get();
      final batch = _firestore.batch();
      for (final doc in docs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (error) {
      throw _toAppException(error);
    }
  }

  List<SearchHistoryEntry> _parse(
    QuerySnapshot<Map<String, Object?>> snapshot,
  ) {
    final results = <SearchHistoryEntry>[];
    for (final doc in snapshot.docs) {
      try {
        results.add(SearchHistoryEntry.fromFirestore(doc.id, doc.data()));
      } on FormatException {
        // Skip a malformed entry; it is not worth crashing the list over.
      }
    }
    return List<SearchHistoryEntry>.unmodifiable(results);
  }

  static AppException _toAppException(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' => AppException(
        AppErrorKind.permissionDenied,
        'Search history is not available for this account.',
        cause: error,
      ),
      'unavailable' ||
      'deadline-exceeded' ||
      'network-request-failed' => AppException(
        AppErrorKind.network,
        'We could not load recent searches. Check your connection and try again.',
        cause: error,
      ),
      _ => AppException(
        AppErrorKind.unknown,
        'We could not load recent searches. Try again in a moment.',
        cause: error,
      ),
    };
  }
}
