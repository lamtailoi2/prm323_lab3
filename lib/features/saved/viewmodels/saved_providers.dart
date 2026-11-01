import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Keys of the saved listings, for the Save Toggle on the cards.
///
/// Derived from [savedInternshipsProvider] so Home, Search and Saved share one
/// Firestore listener per user instead of one per card.
final savedInternshipIdsProvider = Provider<Set<String>>((ref) {
  final saved = ref.watch(savedInternshipsProvider).asData?.value;

  return <String>{
    for (final internship in saved ?? const <Internship>[]) internship.key,
  };
});
