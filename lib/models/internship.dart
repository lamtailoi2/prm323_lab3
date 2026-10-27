import 'package:flutter/foundation.dart';

import '../core/utils/firestore_reader.dart';
import '../core/utils/job_key.dart';
import '../core/utils/job_role.dart';
import '../core/utils/posted_age.dart';
import '../core/utils/skill_matcher.dart';

/// Work arrangement, as far as a Google Jobs listing reveals it. An unknown
/// mode stays `null` and is hidden instead of guessed (DC-10).
enum WorkMode {
  remote('Remote'),
  hybrid('Hybrid'),
  onSite('On-site');

  const WorkMode(this.label);

  final String label;
}

/// An internship listing mirrored from SerpAPI Google Jobs into Firestore by
/// the sync function (G-25).
///
/// The Firestore document holds the raw SerpAPI object plus sync metadata;
/// this model reuses [Internship.fromSerpApi] for the listing fields so the
/// parser stays in one place.
@immutable
class Internship {
  const Internship({
    required this.jobId,
    required this.key,
    required this.title,
    required this.companyName,
    this.location,
    this.workMode,
    this.salary,
    this.postedTextSource,
    this.postedAt,
    this.logoUrl,
    this.skills = const <String>[],
    this.syncedAt,
    this.searchKeyword,
    this.searchRank,
  });

  /// Parses one entry of `jobs_results`. Throws [FormatException] when
  /// `job_id`, `title` or `company_name` is missing; the service skips and
  /// logs such entries.
  factory Internship.fromSerpApi(Map<String, Object?> json) {
    final reader = FirestoreReader('jobs_results', json);
    final jobId = reader.requireString('job_id');
    final title = reader.requireString('title').trim();
    final extensions = reader.stringList('extensions');
    final detected = reader.optionalMap('detected_extensions');

    return Internship(
      jobId: jobId,
      key: jobKeyFor(jobId),
      title: title,
      companyName: reader.requireString('company_name').trim(),
      location: reader.optionalString('location')?.trim(),
      workMode: _workMode(
        workFromHome:
            detected?.boolOr('work_from_home', fallback: false) ?? false,
        texts: [title, ...extensions],
      ),
      salary: detected?.optionalString('salary')?.trim(),
      postedTextSource: detected?.optionalString('posted_at')?.trim(),
      logoUrl: _httpsUrl(reader.optionalString('thumbnail')),
      skills: findSkills(
        [
          title,
          ..._highlightItems(json['job_highlights']),
          reader.optionalString('description') ?? '',
        ].join('\n'),
      ),
    );
  }

  /// Parses a `/internships/{key}` document written by the sync function.
  ///
  /// The document ID is authoritative for [key]; the listing fields come from
  /// the stored raw SerpAPI object. `postedAt` is anchored to `syncedAt`, so
  /// the relative age keeps increasing after the listing was cached.
  factory Internship.fromFirestore(String key, Map<String, Object?> data) {
    final reader = FirestoreReader('internships/$key', data);
    final raw = reader.requireMap('raw').toMap();
    final parsed = Internship.fromSerpApi(raw);
    final syncedAt = reader.optionalDateTime('syncedAt');
    final age = parsePostedAge(parsed.postedTextSource);
    final postedAt = syncedAt == null || age == null
        ? null
        : syncedAt.subtract(age);

    return Internship(
      jobId: parsed.jobId,
      key: key,
      title: parsed.title,
      companyName: parsed.companyName,
      location: parsed.location,
      workMode: parsed.workMode,
      salary: parsed.salary,
      postedTextSource: parsed.postedTextSource,
      postedAt: postedAt,
      logoUrl: parsed.logoUrl,
      skills: parsed.skills,
      syncedAt: syncedAt,
      searchKeyword: reader.optionalString('searchKeyword'),
      searchRank: reader.optionalInt('searchRank'),
    );
  }

  /// Raw SerpAPI `job_id`; needed to look the listing up again.
  final String jobId;

  /// Short URL-safe ID ([jobKeyFor]) for routes, Firestore IDs and analytics.
  final String key;
  final String title;
  final String companyName;

  /// As Google shows it, e.g. "Ho Chi Minh City, Vietnam".
  final String? location;
  final WorkMode? workMode;

  /// Salary text as Google shows it; `null` when the listing does not say
  /// (G-17). The Home feature formats it with `formatAllowance`.
  final String? salary;

  /// Google's original relative date, e.g. "2 days ago".
  final String? postedTextSource;

  /// Absolute posting time derived from [syncedAt] and [postedTextSource].
  final DateTime? postedAt;

  /// Relative date for display. Synced listings get a live compact form
  /// (`2d ago`); directly parsed listings keep Google's wording.
  String? get postedText =>
      postedAt == null ? postedTextSource : formatPostedAge(postedAt);

  /// Company logo (`thumbnail`), https only.
  final String? logoUrl;

  /// Known skills the listing mentions, title first ([findSkills]).
  final List<String> skills;

  /// IT job family inferred from the title/keyword ([jobRoleFor]); `null`
  /// for non-IT listings, which Home hides.
  JobRole? get role =>
      jobRoleFor(title: title, searchKeyword: searchKeyword, skills: skills);

  /// When the sync function last wrote this document.
  final DateTime? syncedAt;

  /// The keyword whose SerpAPI query found this listing.
  final String? searchKeyword;

  /// Position in that SerpAPI response (0 = most relevant).
  final int? searchRank;

  /// Age parsed from the listing; `null` when unknown.
  Duration? get postedAge {
    if (postedAt case final date?) return DateTime.now().difference(date);
    return parsePostedAge(postedTextSource);
  }

  static WorkMode? _workMode({
    required bool workFromHome,
    required List<String> texts,
  }) {
    if (workFromHome) return WorkMode.remote;
    final combined = texts.join('\n').toLowerCase();
    if (combined.contains('hybrid')) return WorkMode.hybrid;
    if (RegExp(
      r'on[-\s]?site|at (the )?office|tại văn phòng',
      caseSensitive: false,
    ).hasMatch(combined)) {
      return WorkMode.onSite;
    }
    return null;
  }

  static String? _httpsUrl(String? value) {
    final uri = value == null ? null : Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? value
        : null;
  }

  /// Items of `job_highlights` (e.g. "Qualifications"), which list the
  /// required skills more reliably than the description.
  static Iterable<String> _highlightItems(Object? highlights) sync* {
    if (highlights is! List) return;
    for (final section in highlights) {
      if (section is! Map) continue;
      final items = section['items'];
      if (items is List) yield* items.whereType<String>();
    }
  }
}
