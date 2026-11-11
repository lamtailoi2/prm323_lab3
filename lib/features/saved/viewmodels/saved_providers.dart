import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/distinct_listings.dart';
import '../../../models/internship.dart';
import '../../../services/saved_internship_service.dart';

/// Saved listings of the signed-in student.
///
/// The provider reads [savedInternshipServiceProvider], which watches
/// `currentUserIdProvider`, so the list is dropped on sign-out (AGENTS.md
/// rule 11).
final savedInternshipsProvider = StreamProvider<List<Internship>>((ref) {
  final service = ref.watch(savedInternshipServiceProvider);
  return service.watchSaved();
});

/// Jobs ([jobIdentity]) the signed-in student has saved, for the Save Toggle
/// on Home, Search Results and Internship Detail.
///
/// Identities, not keys: one job is synced under several keywords with a key
/// per copy, and lists keep only one copy (`distinctListings`). Matching the
/// key of the saved copy made the bookmark look empty once a re-sync kept
/// another copy, so the job could be saved twice (CR-07). Same rule as
/// `appliedJobsProvider`.
///
/// Derived from [savedInternshipsProvider] so Home, Search and Saved share one
/// Firestore listener per user instead of one per card.
final savedJobsProvider = Provider<Set<String>>((ref) {
  final saved = ref.watch(savedInternshipsProvider).asData?.value;

  return <String>{
    for (final internship in saved ?? const <Internship>[])
      jobIdentity(internship.title, internship.companyName),
  };
});
