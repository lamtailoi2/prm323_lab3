import 'package:flutter/foundation.dart';

import '../core/utils/firestore_reader.dart';

/// Progress of a self-tracked application (design-system.md §2.12).
///
/// Only the five statuses with a Figma specimen are accepted. "Withdrawn"
/// (Flow 3d) has no specimen yet (G-18), so a document that stores it is
/// treated as malformed instead of being shown with an invented badge.
enum ApplicationStatus {
  submitted('submitted', 'Submitted'),
  underReview('under_review', 'Under review'),
  interview('interview', 'Interview'),
  accepted('accepted', 'Accepted'),
  rejected('rejected', 'Rejected');

  const ApplicationStatus(this.storageValue, this.label);

  /// Value stored in Firestore (snake_case, AGENTS.md naming rule).
  final String storageValue;

  /// Visible label, from `screen-spec.md` › My Applications.
  final String label;

  /// Parses a stored value; `null` for an unknown one.
  static ApplicationStatus? fromStorage(String raw) {
    for (final status in values) {
      if (status.storageValue == raw) return status;
    }
    return null;
  }
}

/// One application the student tracks, stored at
/// `users/{uid}/applications/{jobKey}` (architecture.md §6).
///
/// The document keeps a snapshot of the fields the list shows (title,
/// company, applied date), because listings expire from the shared pool
/// (G-25). Required fields throw [FormatException]; services skip and log
/// malformed documents.
@immutable
class InternshipApplication {
  const InternshipApplication({
    required this.jobKey,
    required this.title,
    required this.companyName,
    required this.appliedAt,
    required this.status,
    this.nextStepAt,
  });

  factory InternshipApplication.fromFirestore(
    String jobKey,
    Map<String, Object?>? data,
  ) {
    final reader = FirestoreReader('applications/$jobKey', data);

    return InternshipApplication(
      jobKey: jobKey,
      title: reader.requireString('title').trim(),
      companyName: reader.requireString('companyName').trim(),
      appliedAt: reader.requireDateTime('appliedAt'),
      status: reader.requireEnum('status', ApplicationStatus.fromStorage),
      // Optional: the next date the student should act on, either an
      // interview slot or the employer's reply deadline. The Apply flow does
      // not write applications yet, so it is absent on every document today.
      nextStepAt: reader.optionalDateTime('nextStepAt'),
    );
  }

  /// Listing key; also the document ID.
  final String jobKey;
  final String title;
  final String companyName;
  final DateTime appliedAt;
  final ApplicationStatus status;

  /// Interview slot or reply deadline; `null` when the application has no
  /// next date to show.
  final DateTime? nextStepAt;
}
