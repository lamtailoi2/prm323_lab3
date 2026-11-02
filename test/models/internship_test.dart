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

  test('salary falls back to the allowance stated in the description', () {
    final internship = Internship.fromSerpApi(
      job({
        'detected_extensions': {'posted_at': '2 days ago'},
        'description':
            'Quyền lợi: Internship allowance: 10,000,000 VND/month. Lương '
            'tháng 13.',
      }),
    );
    expect(internship.salary, '10,000,000 VND / mo');
  });

  test('Google salary wins over the description', () {
    final internship = Internship.fromSerpApi(
      job({'description': 'Mức lương: Thỏa thuận'}),
    );
    expect(internship.salary, '8M–12M VND a month');
  });

  test('a vague description leaves the salary unknown', () {
    final internship = Internship.fromSerpApi(
      job({
        'detected_extensions': {'posted_at': '2 days ago'},
        'description': 'Competitive salary and attractive allowance.',
      }),
    );
    expect(internship.salary, isNull);
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

  group('work mode stated only in the listing text (G-25 #9)', () {
    WorkMode? mode({
      String title = 'Backend Intern',
      String? location,
      String? description,
      List<String> extensions = const ['Full-time'],
    }) {
      return Internship.fromSerpApi(
        job({
          'title': title,
          'location': location,
          'description': description,
          'extensions': extensions,
          'detected_extensions': null,
        }),
      ).workMode;
    }

    test('title, chips and location are read first', () {
      expect(mode(title: 'Remote Flutter Intern'), WorkMode.remote);
      expect(mode(location: 'Remote, Vietnam'), WorkMode.remote);
      expect(
        mode(extensions: ['Làm việc tại nhà', 'Thực tập']),
        WorkMode.remote,
      );
      expect(mode(extensions: ['Từ xa', 'Thực tập']), WorkMode.remote);
    });

    test('explicit Vietnamese and English wording in the description', () {
      expect(
        mode(description: 'Hình thức làm việc: Remote (toàn thời gian).'),
        WorkMode.remote,
      );
      expect(
        mode(description: 'Bạn sẽ làm việc từ xa 3 ngày mỗi tuần.'),
        WorkMode.remote,
      );
      expect(
        mode(description: 'Mô hình làm việc hybrid, 2 ngày tại văn phòng.'),
        WorkMode.hybrid,
      );
      expect(
        mode(description: 'Địa điểm làm việc tại văn phòng Quận 1.'),
        WorkMode.onSite,
      );
    });

    test('office and home in the same listing mean hybrid', () {
      expect(
        mode(
          description:
              'You may work at the office or work from home, whichever fits.',
        ),
        WorkMode.hybrid,
      );
    });

    test('a bare "hybrid" in the description is not a work mode', () {
      expect(
        mode(description: 'We build hybrid mobile apps with Flutter.'),
        isNull,
      );
      expect(mode(description: 'Deploy the app to a remote server.'), isNull);
    });

    test('a description that never states the arrangement stays null', () {
      expect(mode(description: 'You will work with Firebase and Git.'), isNull);
    });
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

  test(
    'without detected_extensions (hl=vi) the chips give the type and age',
    () {
      final syncedAt = DateTime.utc(2026, 11, 2, 1);
      final internship = Internship.fromFirestore('abc123', {
        'raw': job({
          'extensions': ['3 ngày trước', 'Toàn thời gian và Thực tập'],
          'detected_extensions': null,
        }),
        'syncedAt': syncedAt,
      });

      expect(internship.scheduleType, 'Full-time and Internship');
      expect(internship.postedTextSource, '3 ngày trước');
      expect(internship.postedAt, syncedAt.subtract(const Duration(days: 3)));
    },
  );

  test('fromFirestore skips a document without raw job data', () {
    expect(
      () => Internship.fromFirestore('abc123', {'syncedAt': DateTime.now()}),
      throwsFormatException,
    );
  });

  test('parses the detail fields: description, highlights, type, via', () {
    final internship = Internship.fromSerpApi(
      job({
        'via': 'via LinkedIn',
        'job_highlights': [
          {
            'title': 'Qualifications',
            'items': ['Knowledge of Flutter', '  ', 'Git basics'],
          },
          {
            'title': 'Benefits',
            'items': ['Monthly allowance'],
          },
          {'title': 'Empty', 'items': <String>[]},
          {
            'items': ['No title'],
          },
          'not a map',
        ],
      }),
    );

    expect(internship.description, 'You will work with Firebase.');
    expect(internship.scheduleType, 'Full-time');
    expect(internship.via, 'LinkedIn');
    expect(internship.highlights.map((h) => h.title), [
      'Qualifications',
      'Benefits',
    ]);
    expect(internship.highlightItems('qualification'), [
      'Knowledge of Flutter',
      'Git basics',
    ]);
    expect(internship.highlightItems('BENEFIT'), ['Monthly allowance']);
    expect(internship.highlightItems('responsibilit'), isEmpty);
  });

  test('detail fields are optional', () {
    final internship = Internship.fromSerpApi({
      'job_id': 'id',
      'title': 'Backend Intern',
      'company_name': 'KMS Technology',
      'description': '   ',
      'via': 'TopCV',
    });
    expect(internship.description, isNull);
    expect(internship.highlights, isEmpty);
    expect(internship.scheduleType, isNull);
    expect(internship.via, 'TopCV');
  });

  test('fromFirestore keeps the detail fields of the raw job', () {
    final internship = Internship.fromFirestore('abc123', {
      'raw': job({'via': 'LinkedIn'}),
    });
    expect(internship.description, 'You will work with Firebase.');
    expect(internship.highlightItems('qualification'), hasLength(2));
    expect(internship.scheduleType, 'Full-time');
    expect(internship.via, 'LinkedIn');
  });

  test('detail text is shown without Markdown markers', () {
    final internship = Internship.fromSerpApi(
      job({
        'description': '## Job Purpose\n\n\n- Build **Flutter** apps',
        'job_highlights': [
          {
            'title': 'Qualifications',
            'items': ['- **Dart** basics', '  '],
          },
        ],
      }),
    );
    expect(internship.description, 'Job Purpose\n\n• Build Flutter apps');
    expect(internship.highlightItems('qualification'), ['Dart basics']);
    expect(internship.skills, containsAll(['Flutter', 'Dart']));
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
