import 'package:flutter/foundation.dart';

import '../core/utils/allowance.dart';
import '../core/utils/firestore_reader.dart';
import '../core/utils/job_key.dart';
import '../core/utils/job_role.dart';
import '../core/utils/listing_extensions.dart';
import '../core/utils/listing_text.dart';
import '../core/utils/posted_age.dart';
import '../core/utils/skill_matcher.dart';
import '../core/utils/text_fold.dart';

/// Work arrangement, as far as a Google Jobs listing reveals it. An unknown
/// mode stays `null` and is hidden instead of guessed (DC-10).
enum WorkMode {
  remote('Remote'),
  hybrid('Hybrid'),
  onSite('On-site');

  const WorkMode(this.label);

  final String label;
}

/// One `job_highlights` section of a Google Jobs listing, e.g.
/// "Qualifications" with its bullet items.
@immutable
class JobHighlight {
  const JobHighlight({required this.title, required this.items});

  final String title;
  final List<String> items;
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
    this.description,
    this.highlights = const <JobHighlight>[],
    this.scheduleType,
    this.via,
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
    final description = reader.optionalString('description') ?? '';
    final location = reader.optionalString('location')?.trim();
    final highlights = _highlightItems(json['job_highlights']);
    final via = reader.optionalString('via')?.trim();

    return Internship(
      jobId: jobId,
      key: jobKeyFor(jobId),
      title: title,
      companyName: reader.requireString('company_name').trim(),
      location: location,
      workMode: _workMode(
        workFromHome:
            detected?.boolOr('work_from_home', fallback: false) ?? false,
        title: title,
        extensions: extensions,
        location: location,
        description: description,
        highlights: highlights,
      ),
      // Google Jobs never fills `salary` for Vietnamese listings; the pay is
      // only stated in the description (G-17).
      salary:
          detected?.optionalString('salary')?.trim() ??
          allowanceFromText(description),
      // The `hl=vi` sync gets no `detected_extensions`; the posted age and
      // the schedule type are then only in the `extensions` chips.
      postedTextSource:
          detected?.optionalString('posted_at')?.trim() ??
          postedTextFromExtensions(extensions),
      logoUrl: _httpsUrl(reader.optionalString('thumbnail')),
      skills: findSkills(
        [
          title,
          ..._highlightItems(json['job_highlights']),
          description,
        ].join('\n'),
      ),
      // Skills and allowance above read the raw text; only the copy shown on
      // Internship Detail is cleaned of Markdown.
      description: _plainOrNull(description),
      highlights: _highlights(json['job_highlights']),
      scheduleType:
          detected?.optionalString('schedule_type')?.trim() ??
          scheduleTypeFromExtensions(extensions),
      // SerpAPI has sent both "LinkedIn" and "via LinkedIn" over time.
      via: via?.replaceFirst(RegExp('^via ', caseSensitive: false), ''),
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
      description: parsed.description,
      highlights: parsed.highlights,
      scheduleType: parsed.scheduleType,
      via: parsed.via,
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

  /// Salary text as Google shows it, or else the allowance stated in the
  /// description (`allowanceFromText`); `null` when the listing does not say
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

  /// Full listing text as Google shows it; `null` when the listing has none.
  final String? description;

  /// `job_highlights` sections ("Qualifications", "Responsibilities",
  /// "Benefits"…); empty for most Vietnamese listings, which put everything
  /// in [description].
  final List<JobHighlight> highlights;

  /// Google's job type, e.g. "Internship" or "Full-time".
  final String? scheduleType;

  /// The site Google Jobs found the listing on, e.g. "LinkedIn".
  final String? via;

  /// Items of the first highlight whose title contains [titleWord]
  /// (case-insensitive); empty when there is none.
  List<String> highlightItems(String titleWord) {
    final word = titleWord.toLowerCase();
    for (final highlight in highlights) {
      if (highlight.title.toLowerCase().contains(word)) return highlight.items;
    }
    return const <String>[];
  }

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

  /// Work-arrangement wording that is safe to read from the description,
  /// where a bare "hybrid" often means a hybrid mobile app (Flutter, React
  /// Native) rather than a hybrid workplace.
  static const List<String> _hybridPhrases = [
    'hybrid work',
    'hybrid working',
    'hybrid model',
    'hybrid mode',
    'hybrid arrangement',
    'work hybrid',
    'working hybrid',
    'lam viec hybrid',
    'mo hinh hybrid',
  ];

  static const List<String> _remotePhrases = [
    'fully remote',
    '100 remote',
    'remote work',
    'remote working',
    'remote job',
    'remote position',
    'remote role',
    'remote friendly',
    'work from home',
    'wfh',
    'lam viec remote',
    'lam viec tu xa',
    'lam viec tai nha',
  ];

  static const List<String> _onSitePhrases = [
    'on site',
    'at the office',
    'at office',
    'lam viec tai van phong',
    'lam viec truc tiep tai van phong',
  ];

  /// Vietnamese Google Jobs results carry no `detected_extensions` and their
  /// chips only hold the schedule and posted age, so most listings never
  /// state their work mode. The title, chips and location are checked first;
  /// the description and highlights are read only for explicit wording
  /// (G-25 #9), never for a bare "remote"/"hybrid".
  static WorkMode? _workMode({
    required bool workFromHome,
    required String title,
    required List<String> extensions,
    required String? location,
    required String description,
    required Iterable<String> highlights,
  }) {
    if (workFromHome) return WorkMode.remote;

    final structured = foldText([title, ...extensions, ?location].join('\n'));
    if (containsWords(structured, 'hybrid')) return WorkMode.hybrid;
    if (containsWords(structured, 'remote') ||
        containsWords(structured, 'tu xa') ||
        containsWords(structured, 'tai nha')) {
      return WorkMode.remote;
    }
    if (containsWords(structured, 'on site') ||
        containsWords(structured, 'onsite') ||
        containsWords(structured, 'at the office') ||
        containsWords(structured, 'tai van phong')) {
      return WorkMode.onSite;
    }

    final text = foldText([description, ...highlights].join('\n'));
    if (_containsAny(text, _hybridPhrases)) return WorkMode.hybrid;
    final remote = _containsAny(text, _remotePhrases);
    final onSite = _containsAny(text, _onSitePhrases);
    // A listing that offers both arrangements is a hybrid one.
    if (remote && onSite) return WorkMode.hybrid;
    if (remote) return WorkMode.remote;
    if (onSite) return WorkMode.onSite;
    return null;
  }

  static bool _containsAny(String text, List<String> phrases) =>
      phrases.any((phrase) => containsWords(text, phrase));

  static String? _httpsUrl(String? value) {
    final uri = value == null ? null : Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? value
        : null;
  }

  static String? _plainOrNull(String text) {
    final plain = plainListingText(text);
    return plain.isEmpty ? null : plain;
  }

  /// Sections of `job_highlights` with a title and at least one item;
  /// malformed sections are skipped instead of failing the listing.
  static List<JobHighlight> _highlights(Object? highlights) {
    if (highlights is! List) return const <JobHighlight>[];
    final results = <JobHighlight>[];
    for (final section in highlights) {
      if (section is! Map) continue;
      final title = section['title'];
      final items = section['items'];
      if (title is! String || title.trim().isEmpty || items is! List) continue;
      final texts = [
        for (final item in items.whereType<String>())
          if (plainListingItem(item) case final text when text.isNotEmpty) text,
      ];
      if (texts.isEmpty) continue;
      results.add(
        JobHighlight(
          title: title.trim(),
          items: List<String>.unmodifiable(texts),
        ),
      );
    }
    return List<JobHighlight>.unmodifiable(results);
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
