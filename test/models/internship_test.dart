import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/job_key.dart';
import 'package:internly/models/internship.dart';

void main() {
  Map<String, Object?> job([Map<String, Object?> overrides = const {}]) => {
    'job_id': 'eyJqb2IiOiIxIn0=',
    'title': 'Mobile Developer Intern (Hybrid)',
    'company_name': 'MoMo Financial Tech',
    'location': 'District 3, Ho Chi Minh City',
    'thumbnail': 'https://example.com/logo.png',
    'extensions': ['2 days ago', 'Full-time'],
    'detected_extensions': {
      'posted_at': '2 days ago',
      'schedule_type': 'Full-time',
      'salary': '8M–12M VND a month',
    },
    'job_highlights': [
      {
        'title': 'Qualifications',
        'items': ['Knowledge of Flutter and Dart', 'REST API basics'],
      },
    ],
    'description': 'You will work with Firebase.',
    ...overrides,
  };

  test('parses a complete Google Jobs result', () {
    final internship = Internship.fromSerpApi(job());

    expect(internship.jobId, 'eyJqb2IiOiIxIn0=');
    expect(internship.key, jobKeyFor('eyJqb2IiOiIxIn0='));
    expect(internship.title, 'Mobile Developer Intern (Hybrid)');
    expect(internship.companyName, 'MoMo Financial Tech');
    expect(internship.location, 'District 3, Ho Chi Minh City');
    expect(internship.workMode, WorkMode.hybrid);
    expect(internship.salary, '8M–12M VND a month');
    expect(internship.postedText, '2 days ago');
    expect(internship.postedAge, const Duration(days: 2));
    expect(internship.logoUrl, 'https://example.com/logo.png');
    expect(internship.skills, ['Flutter', 'Dart', 'REST API', 'Firebase']);
  });

  test('work_from_home means remote', () {
    final internship = Internship.fromSerpApi(
      job({
        'title': 'Backend Intern',
        'detected_extensions': {'work_from_home': true},
      }),
    );
    expect(internship.workMode, WorkMode.remote);
  });

  test('missing optional fields stay null instead of being guessed', () {
    final internship = Internship.fromSerpApi({
      'job_id': 'id',
      'title': 'Backend Intern',
      'company_name': 'KMS Technology',
    });
    expect(internship.location, isNull);
    expect(internship.workMode, isNull);
    expect(internship.salary, isNull);
    expect(internship.postedText, isNull);
    expect(internship.postedAge, isNull);
    expect(internship.logoUrl, isNull);
    expect(internship.skills, isEmpty);
  });

  test('on-site wording is detected', () {
    final internship = Internship.fromSerpApi(
      job({
        'title': 'Backend Intern',
        'extensions': ['On-site', 'Full-time'],
      }),
    );
    expect(internship.workMode, WorkMode.onSite);
  });

  test('fromFirestore reads the raw job and anchors postedAt to syncedAt', () {
    final syncedAt = DateTime.utc(2026, 10, 20, 12);
    final internship = Internship.fromFirestore('abc123', {
      'raw': job(),
      'syncedAt': syncedAt,
      'searchKeyword': 'flutter internship',
      'searchRank': 3,
    });

    expect(internship.key, 'abc123');
    expect(internship.jobId, 'eyJqb2IiOiIxIn0=');
    expect(internship.title, 'Mobile Developer Intern (Hybrid)');
    expect(internship.syncedAt, syncedAt);
    expect(internship.postedAt, syncedAt.subtract(const Duration(days: 2)));
    expect(internship.searchKeyword, 'flutter internship');
    expect(internship.searchRank, 3);
  });

  test('fromFirestore skips a document without raw job data', () {
    expect(
      () => Internship.fromFirestore('abc123', {'syncedAt': DateTime.now()}),
      throwsFormatException,
    );
  });

  test('ignores a non-https logo', () {
    final internship = Internship.fromSerpApi(
      job({'thumbnail': 'http://example.com/logo.png'}),
    );
    expect(internship.logoUrl, isNull);
  });

  test('missing or invalid required fields throw FormatException', () {
    for (final field in ['job_id', 'title', 'company_name']) {
      expect(
        () => Internship.fromSerpApi(job({field: null})),
        throwsFormatException,
        reason: field,
      );
      expect(
        () => Internship.fromSerpApi(job({field: 42})),
        throwsFormatException,
        reason: field,
      );
    }
  });
}
