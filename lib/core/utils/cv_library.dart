import '../../models/user_profile.dart';

/// Helpers for the CV library, which is stored as `users/{uid}/cvs/{cvId}`
/// with a legacy `users/{uid}.cv` mirror (G-33).
///
/// The library may still contain the legacy mirror until the first write
/// migrates it, so every reader merges both views. Entries are compared by
/// [CvFile.storagePath], which is unique per upload; file names can repeat.

/// Pseudo-id for the legacy `users/{uid}.cv` entry, which has no library
/// document yet. It cannot be a storage path: Firestore ids cannot contain
/// `/`. The first write migrates the entry to a real document.
const String legacyCvId = 'legacy';

/// The real library plus the legacy mirror, deduplicated by storage path.
///
/// The library keeps its order (newest first from Firestore); the legacy
/// entry is appended only when it is not already there, so a student never
/// sees the same file twice.
List<CvFile> mergeLegacyCv(List<CvFile> library, CvFile? legacy) {
  final merged = <CvFile>[...library];
  if (legacy == null) return List<CvFile>.unmodifiable(merged);

  final known = merged.map((cv) => cv.storagePath).toSet();
  if (!known.contains(legacy.storagePath)) {
    merged.add(legacy.copyWith(id: legacy.id ?? legacyCvId));
  }
  return List<CvFile>.unmodifiable(merged);
}

/// The default CV, or `null` when the library is empty.
///
/// Resolution order: [defaultCvId], the legacy mirror, then the newest CV.
/// A `defaultCvId` that no longer exists is ignored instead of hiding the
/// library.
CvFile? defaultCv(List<CvFile> library, String? defaultCvId, CvFile? legacy) {
  final merged = mergeLegacyCv(library, legacy);
  if (merged.isEmpty) return null;

  if (defaultCvId != null) {
    for (final cv in merged) {
      if (cv.id == defaultCvId) return cv;
    }
  }
  if (legacy != null) {
    for (final cv in merged) {
      if (cv.storagePath == legacy.storagePath) return cv;
    }
  }
  return merged.reduce(
    (newest, cv) => cv.uploadedAt.isAfter(newest.uploadedAt) ? cv : newest,
  );
}

/// Whether two entries point at the same uploaded file.
bool isSameCv(CvFile a, CvFile b) => a.storagePath == b.storagePath;
