import 'package:flutter/foundation.dart';

import '../core/utils/firestore_reader.dart';

/// Progress of a self-tracked application (design-system.md §2.12).
///
/// The five statuses the student sets, plus `Withdrawn` (Flow 3d); the
/// Application Detail frames supply its badge (G-18 is resolved).
enum ApplicationStatus {
  submitted('submitted', 'Submitted'),
  underReview('under_review', 'Under review'),
  interview('interview', 'Interview'),
  accepted('accepted', 'Accepted'),
  rejected('rejected', 'Rejected'),
  withdrawn('withdrawn', 'Withdrawn');

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
    this.withdrawnAt,
    this.previousStatus,
    this.cvFileName,
    this.cvUrl,
    this.cvStoragePath,
    this.applicant,
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
      // interview slot or the employer's reply deadline.
      nextStepAt: reader.optionalDateTime('nextStepAt'),
      withdrawnAt: reader.optionalDateTime('withdrawnAt'),
      previousStatus: reader.optionalEnum(
        'previousStatus',
        ApplicationStatus.fromStorage,
      ),
      cvFileName: reader.optionalString('cvFileName'),
      cvUrl: reader.optionalString('cvUrl'),
      cvStoragePath: reader.optionalString('cvStoragePath'),
      applicant: _optionalApplicant(reader),
    );
  }

  /// A malformed `applicant` map hides that section instead of failing the
  /// whole application; the service logs it.
  static ApplicationApplicant? _optionalApplicant(FirestoreReader reader) {
    final data = reader.optionalMap('applicant');
    if (data == null) return null;
    try {
      return ApplicationApplicant.fromFirestore(data);
    } on FormatException {
      return null;
    }
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

  /// When the student withdrew; `null` while the application is active.
  final DateTime? withdrawnAt;

  /// Status before the withdrawal, restored by `Undo`.
  final ApplicationStatus? previousStatus;

  /// The CV actually sent, snapshotted so the record survives a Profile
  /// change: name, download URL (for `Preview`) and Storage path.
  final String? cvFileName;
  final String? cvUrl;
  final String? cvStoragePath;

  /// Who applied, written by the Apply flow; `null` for documents saved
  /// before the snapshot existed.
  final ApplicationApplicant? applicant;
}

/// Who applied and with what, snapshotted with the application so the record
/// stays readable after the listing expires or the profile changes.
///
/// Written by the Apply flow; the list does not read it (Application Detail
/// will).
@immutable
class ApplicationApplicant {
  const ApplicationApplicant({
    required this.fullName,
    this.email,
    this.phone,
    this.university,
    this.yearOfStudy,
    this.skills = const <String>[],
    this.introduction,
  });

  factory ApplicationApplicant.fromFirestore(FirestoreReader reader) {
    return ApplicationApplicant(
      fullName: reader.requireString('fullName').trim(),
      email: reader.optionalString('email'),
      phone: reader.optionalString('phone'),
      university: reader.optionalString('university'),
      yearOfStudy: reader.optionalInt('yearOfStudy'),
      skills: reader.stringList('skills'),
      introduction: reader.optionalString('shortIntroduction'),
    );
  }

  final String fullName;
  final String? email;
  final String? phone;
  final String? university;

  /// 1 for first-year students; `null` when not given.
  final int? yearOfStudy;
  final List<String> skills;

  /// The form's `Short introduction`, written for this application only.
  final String? introduction;

  Map<String, Object?> toFirestore() => <String, Object?>{
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'university': university,
    'yearOfStudy': yearOfStudy,
    'skills': skills,
    'shortIntroduction': introduction,
  };
}
