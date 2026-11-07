import 'package:flutter/foundation.dart';

import '../core/utils/firestore_reader.dart';
import '../core/utils/job_role.dart';
import 'internship.dart' show WorkMode;

/// The student's own profile, stored in Firestore at `users/{uid}`.
///
/// Every field is optional: the document does not exist until the student
/// first saves something, and Apply reuses whatever is filled in (prefill,
/// CV from Profile, skills for CV Match Check). Email and photo are not
/// stored; they come from the Google account (`AppUser`).
@immutable
class UserProfile {
  const UserProfile({
    this.details = const ProfileDetails(),
    this.skills = const <String>[],
    this.preferences = const InternshipPreferences(),
    this.cv,
    this.defaultCvId,
  });

  factory UserProfile.fromFirestore(String id, Map<String, Object?>? data) {
    final reader = FirestoreReader('users/$id', data);
    return UserProfile(
      details: ProfileDetails.fromReader(reader),
      skills: reader.stringList('skills'),
      preferences: InternshipPreferences.fromReader(
        reader.optionalMap('preferences'),
      ),
      cv: _optionalCv(reader),
      defaultCvId: reader.optionalString('defaultCvId'),
    );
  }

  final ProfileDetails details;
  final List<String> skills;
  final InternshipPreferences preferences;

  /// The default CV for applications; `null` until one is uploaded.
  ///
  /// Also a mirror of the default document under `users/{uid}/cvs` for
  /// backwards compatibility with builds that only knew this field.
  final CvFile? cv;

  /// The `users/{uid}/cvs/{cvId}` document marked as default; `null` when
  /// the library is empty or the profile has not been migrated yet. A legacy
  /// [cv] without this id counts as the default.
  final String? defaultCvId;

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.details == details &&
      listEquals(other.skills, skills) &&
      other.preferences == preferences &&
      other.cv == cv &&
      other.defaultCvId == defaultCvId;

  @override
  int get hashCode => Object.hash(
    details,
    Object.hashAll(skills),
    preferences,
    cv,
    defaultCvId,
  );

  /// A malformed `cv` map is treated as "no CV" instead of hiding the whole
  /// profile: the student can still upload a new one, which overwrites it.
  /// The service logs the malformed value.
  static CvFile? _optionalCv(FirestoreReader reader) {
    final cv = reader.optionalMap('cv');
    if (cv == null) return null;
    try {
      return CvFile.fromReader(cv);
    } on FormatException {
      return null;
    }
  }
}

/// Personal, academic and contact information edited in Edit profile.
@immutable
class ProfileDetails {
  const ProfileDetails({
    this.fullName,
    this.headline,
    this.university,
    this.major,
    this.yearOfStudy,
    this.graduationYear,
    this.phone,
    this.city,
    this.bio,
  });

  factory ProfileDetails.fromReader(FirestoreReader reader) {
    return ProfileDetails(
      fullName: reader.optionalString('fullName'),
      headline: reader.optionalString('headline'),
      university: reader.optionalString('university'),
      major: reader.optionalString('major'),
      yearOfStudy: reader.optionalInt('yearOfStudy'),
      graduationYear: reader.optionalInt('graduationYear'),
      phone: reader.optionalString('phone'),
      city: reader.optionalString('city'),
      bio: reader.optionalString('bio'),
    );
  }

  final String? fullName;

  /// Short line under the name on Profile, e.g. "Software Engineering
  /// Student". Target roles live in [InternshipPreferences].
  final String? headline;
  final String? university;
  final String? major;

  /// 1 for first-year students; `null` when not given.
  final int? yearOfStudy;

  /// Expected graduation year, e.g. 2026.
  final int? graduationYear;
  final String? phone;

  /// Where the student lives now; internship location wishes are in
  /// [InternshipPreferences.location].
  final String? city;

  /// Short introduction, at most 300 characters (Apply can reuse it).
  final String? bio;

  /// Writes every field, so a cleared field is stored as `null`.
  Map<String, Object?> toFirestore() => <String, Object?>{
    'fullName': fullName,
    'headline': headline,
    'university': university,
    'major': major,
    'yearOfStudy': yearOfStudy,
    'graduationYear': graduationYear,
    'phone': phone,
    'city': city,
    'bio': bio,
  };

  @override
  bool operator ==(Object other) =>
      other is ProfileDetails &&
      other.fullName == fullName &&
      other.headline == headline &&
      other.university == university &&
      other.major == major &&
      other.yearOfStudy == yearOfStudy &&
      other.graduationYear == graduationYear &&
      other.phone == phone &&
      other.city == city &&
      other.bio == bio;

  @override
  int get hashCode => Object.hash(
    fullName,
    headline,
    university,
    major,
    yearOfStudy,
    graduationYear,
    phone,
    city,
    bio,
  );
}

/// Target roles offered by the Update Preferences frame, in its order.
enum TargetRole {
  softwareEngineer('Software Engineer Intern', {
    JobRole.backend,
    JobRole.fullStack,
    JobRole.otherIt,
  }),
  mobile('Mobile Intern', {JobRole.mobile}),
  frontend('Frontend Intern', {JobRole.frontend}),
  backend('Backend Intern', {JobRole.backend}),
  qaTester('QA / Tester Intern', {JobRole.tester});

  const TargetRole(this.label, this.jobRoles);

  final String label;

  /// Home's listing roles (DC-13) that this target covers, for
  /// "Recommended for you". "Software Engineer Intern" is the general
  /// software role: backend, full-stack and generic IT titles.
  final Set<JobRole> jobRoles;
}

/// What the student is looking for: target roles, work modes and a location.
@immutable
class InternshipPreferences {
  const InternshipPreferences({
    this.targetRoles = const <TargetRole>[],
    this.workModes = const <WorkMode>[],
    this.location,
  });

  /// Unknown stored values are dropped, so renaming an enum value never
  /// breaks the profile.
  factory InternshipPreferences.fromReader(FirestoreReader? reader) {
    if (reader == null) return const InternshipPreferences();
    return InternshipPreferences(
      targetRoles: List.unmodifiable(
        reader.stringList('targetRoles').map(_roleFor).nonNulls,
      ),
      workModes: List.unmodifiable(
        reader.stringList('workModes').map(_workModeFor).nonNulls,
      ),
      location: reader.optionalString('location'),
    );
  }

  /// Roles in [TargetRole] order.
  final List<TargetRole> targetRoles;

  /// Work modes in the order the sheet shows them.
  final List<WorkMode> workModes;
  final String? location;

  Map<String, Object?> toFirestore() => <String, Object?>{
    'targetRoles': [for (final role in targetRoles) storageValue(role)],
    'workModes': [for (final mode in workModes) storageValue(mode)],
    'location': location,
  };

  @override
  bool operator ==(Object other) =>
      other is InternshipPreferences &&
      listEquals(other.targetRoles, targetRoles) &&
      listEquals(other.workModes, workModes) &&
      other.location == location;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(targetRoles),
    Object.hashAll(workModes),
    location,
  );

  /// `snake_case` storage value of an enum (`onSite` → `on_site`).
  static String storageValue(Enum value) => value.name.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '_${match[0]!.toLowerCase()}',
  );

  static TargetRole? _roleFor(String raw) =>
      TargetRole.values.where((role) => storageValue(role) == raw).firstOrNull;

  static WorkMode? _workModeFor(String raw) =>
      WorkMode.values.where((mode) => storageValue(mode) == raw).firstOrNull;
}

/// One CV in the library, uploaded to Cloud Storage `cvs/{uid}/…`.
///
/// Only built from an `UploadedFile` returned by `FileStorageService`, so the
/// URL is always a real download URL (AGENTS.md rule 7). [id] is the
/// `users/{uid}/cvs/{cvId}` document id, and `null` for the legacy
/// `users/{uid}.cv` entry.
@immutable
class CvFile {
  const CvFile({
    this.id,
    required this.fileName,
    required this.url,
    required this.storagePath,
    required this.sizeBytes,
    required this.uploadedAt,
    this.label,
  });

  factory CvFile.fromReader(FirestoreReader reader) {
    return CvFile(
      fileName: reader.requireString('fileName'),
      url: reader.requireString('url'),
      storagePath: reader.requireString('storagePath'),
      sizeBytes: reader.optionalInt('sizeBytes') ?? 0,
      uploadedAt: reader.requireDateTime('uploadedAt'),
      label: reader.optionalString('label'),
    );
  }

  /// Library document, `users/{uid}/cvs/{id}`; malformed data throws a
  /// [FormatException] so the service can skip and log it.
  factory CvFile.fromFirestore(String id, Map<String, Object?>? data) {
    final reader = FirestoreReader('users/cvs/$id', data);
    return CvFile(
      id: id,
      fileName: reader.requireString('fileName'),
      url: reader.requireString('url'),
      storagePath: reader.requireString('storagePath'),
      sizeBytes: reader.optionalInt('sizeBytes') ?? 0,
      uploadedAt: reader.requireDateTime('uploadedAt'),
      label: reader.optionalString('label'),
    );
  }

  final String? id;
  final String fileName;
  final String url;
  final String storagePath;
  final int sizeBytes;
  final DateTime uploadedAt;

  /// Optional short name shown instead of the file name, e.g. "Backend CV".
  final String? label;

  /// What the student sees in the library and in the Apply picker.
  String get displayName => label ?? fileName;

  CvFile copyWith({String? id, String? label}) => CvFile(
    id: id ?? this.id,
    fileName: fileName,
    url: url,
    storagePath: storagePath,
    sizeBytes: sizeBytes,
    uploadedAt: uploadedAt,
    label: label ?? this.label,
  );

  Map<String, Object?> toFirestore() => <String, Object?>{
    'fileName': fileName,
    'url': url,
    'storagePath': storagePath,
    'sizeBytes': sizeBytes,
    'uploadedAt': uploadedAt,
    'label': label,
  };

  @override
  bool operator ==(Object other) =>
      other is CvFile &&
      other.id == id &&
      other.fileName == fileName &&
      other.url == url &&
      other.storagePath == storagePath &&
      other.sizeBytes == sizeBytes &&
      other.uploadedAt == uploadedAt &&
      other.label == label;

  @override
  int get hashCode =>
      Object.hash(id, fileName, url, storagePath, sizeBytes, uploadedAt, label);
}
