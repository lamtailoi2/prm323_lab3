import 'package:flutter/foundation.dart';

import '../../../core/utils/firestore_reader.dart';

/// One past search term, stored at `users/{uid}/searchHistory/{id}` so it
/// follows the student across devices (AGENTS.md rule 9).
@immutable
class SearchHistoryEntry {
  const SearchHistoryEntry({
    required this.id,
    required this.term,
    required this.searchedAt,
  });

  factory SearchHistoryEntry.fromFirestore(
    String id,
    Map<String, Object?> data,
  ) {
    final reader = FirestoreReader('searchHistory/$id', data);
    return SearchHistoryEntry(
      id: id,
      term: reader.requireString('term'),
      searchedAt: reader.requireDateTime('searchedAt'),
    );
  }

  final String id;
  final String term;
  final DateTime searchedAt;

  @override
  bool operator ==(Object other) =>
      other is SearchHistoryEntry &&
      other.id == id &&
      other.term == term &&
      other.searchedAt == searchedAt;

  @override
  int get hashCode => Object.hash(id, term, searchedAt);
}
