import '../../models/internship.dart';
import 'text_fold.dart';

/// One listing per job. The same job appears under several sync keywords
/// with a different Google `job_id` each time (171 of 322 listings on
/// 2026-10-28), so the copy with the best sync rank is kept. Home, Search
/// and Search Results all use it, so a job is counted and shown once.
List<Internship> distinctListings(Iterable<Internship> listings) {
  final best = <String, Internship>{};
  for (final internship in [...listings]..sort(compareBySyncRank)) {
    best.putIfAbsent(
      '${foldText(internship.title)}|${foldText(internship.companyName)}',
      () => internship,
    );
  }
  return List.unmodifiable(best.values);
}

/// Best sync rank first (the order Google Jobs returned for the keyword),
/// then newest; listings without a rank go last.
int compareBySyncRank(Internship a, Internship b) {
  const unknownRank = 1 << 30;
  final rank = (a.searchRank ?? unknownRank).compareTo(
    b.searchRank ?? unknownRank,
  );
  return rank != 0 ? rank : compareByNewest(a, b);
}

/// Newest first; listings without a posting date go last.
int compareByNewest(Internship a, Internship b) {
  final first = a.postedAt;
  final second = b.postedAt;
  if (first == null && second == null) return 0;
  if (first == null) return 1;
  if (second == null) return -1;
  return second.compareTo(first);
}
