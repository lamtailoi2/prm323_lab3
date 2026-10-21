import 'package:flutter/foundation.dart';

import '../core/utils/firestore_reader.dart';
import '../core/utils/job_key.dart';
import '../core/utils/posted_age.dart';
import '../core/utils/skill_matcher.dart';

/// Work arrangement, as far as a Google Jobs listing reveals it. Nothing in
/// the data says "on-site", so an unknown mode stays `null` and is hidden
/// instead of guessed (DC-10).
enum WorkMode {
  remote('Remote'),
  hybrid('Hybrid');

  const WorkMode(this.label);

  final String label;
}

/// An internship listing from SerpAPI Google Jobs (G-25).
///
/// Listings are fetched live and never stored in Firestore. Saved items and
/// applications keep a snapshot of the fields they display, because listings
/// expire.
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
    this.postedText,
    this.logoUrl,
    this.skills = const <String>[],
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
      postedText: detected?.optionalString('posted_at')?.trim(),
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
  /// (G-17).
  final String? salary;

  /// Relative date as Google shows it, e.g. "2 days ago".
  final String? postedText;

  /// Company logo (`thumbnail`), https only.
  final String? logoUrl;

  /// Known skills the listing mentions, title first ([findSkills]).
  final List<String> skills;

  /// Age parsed from [postedText]; `null` when unknown.
  Duration? get postedAge => parsePostedAge(postedText);

  static WorkMode? _workMode({
    required bool workFromHome,
    required List<String> texts,
  }) {
    if (workFromHome) return WorkMode.remote;
    final mentionsHybrid = texts.any(
      (text) => text.toLowerCase().contains('hybrid'),
    );
    return mentionsHybrid ? WorkMode.hybrid : null;
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
