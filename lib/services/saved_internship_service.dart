
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/internship.dart';
import 'auth_service.dart';

/// Stores each user's saved internships separately from the shared listings.
final savedInternshipServiceProvider =
    Provider<SavedInternshipService>((ref) {
  final uid = ref.watch(currentUserIdProvider);

  return SavedInternshipService(
    firestore: FirebaseFirestore.instance,
    uid: uid,
  );
});

class SavedInternshipService {
  SavedInternshipService({
    required FirebaseFirestore firestore,
    required String? uid,
  })  : _firestore = firestore,
        _uid = uid;

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

  /// Watches the current user's saved internship snapshots.
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

          final internshipData = Map<String, Object?>.from(raw);
          internships.add(
            Internship.fromFirestore(
              doc.id,
              internshipData,
            ),
          );
        } on Exception {
          // Skip invalid saved documents rather than breaking the whole list.
          continue;
        }
      }

      return internships;
    });
  }

  /// Saves a copy of the shared listing under the user's own UID.
  Future<void> save(Internship internship) async {
    final collection = _savedCollection;
    if (collection == null) {
      throw StateError('Please sign in to save internships.');
    }

    final listing = await _firestore
        .collection('internships')
        .doc(internship.key)
        .get();

    if (!listing.exists || listing.data() == null) {
      throw StateError('This internship is no longer available.');
    }

    await collection.doc(internship.key).set({
      'internship': listing.data(),
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes a saved internship for the current user.
  Future<void> remove(String internshipKey) async {
    final collection = _savedCollection;
    if (collection == null) {
      throw StateError('Please sign in to manage saved internships.');
    }

    await collection.doc(internshipKey).delete();
  }
}
