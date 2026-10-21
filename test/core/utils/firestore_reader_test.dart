import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/firestore_reader.dart';

enum _Mode { remote, hybrid }

_Mode? _parseMode(String raw) =>
    _Mode.values.where((m) => m.name == raw).firstOrNull;

void main() {
  final date = DateTime.utc(2026, 10, 21, 8, 30);

  group('required fields', () {
    test('reads a non-empty string', () {
      final reader = FirestoreReader('c/1', {'title': 'Flutter Intern'});
      expect(reader.requireString('title'), 'Flutter Intern');
    });

    test('rejects missing, blank or wrongly typed strings with context', () {
      final reader = FirestoreReader('internships/abc', {
        'blank': '  ',
        'num': 3,
      });
      for (final key in ['missing', 'blank', 'num']) {
        expect(
          () => reader.requireString(key),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              allOf(contains('internships/abc'), contains('"$key"')),
            ),
          ),
        );
      }
    });

    test('treats null document data as empty', () {
      final reader = FirestoreReader('c/1', null);
      expect(reader.optionalString('x'), isNull);
      expect(() => reader.requireString('x'), throwsFormatException);
    });
  });

  group('timestamps', () {
    test('accepts Timestamp, DateTime, epoch millis and ISO strings', () {
      final reader = FirestoreReader('c/1', {
        'ts': Timestamp.fromDate(date),
        'dt': date,
        'ms': date.millisecondsSinceEpoch,
        'iso': date.toIso8601String(),
      });
      for (final key in ['ts', 'dt', 'ms', 'iso']) {
        expect(
          reader.requireDateTime(key).isAtSameMomentAs(date),
          isTrue,
          reason: key,
        );
      }
    });

    test('pending server timestamp (null) is missing, not "now"', () {
      final reader = FirestoreReader('c/1', {'createdAt': null});
      expect(reader.optionalDateTime('createdAt'), isNull);
      expect(() => reader.requireDateTime('createdAt'), throwsFormatException);
    });
  });

  group('optional and collection fields', () {
    test('optional values fall back safely on wrong types', () {
      final reader = FirestoreReader('c/1', {
        'count': '5',
        'ratio': 2.6,
        'flag': 'yes',
        'tags': 'not a list',
      });
      expect(reader.optionalInt('count'), isNull);
      expect(reader.optionalInt('ratio'), 3);
      expect(reader.boolOr('flag', fallback: true), isTrue);
      expect(reader.stringList('tags'), isEmpty);
    });

    test('stringList keeps only non-empty strings and is unmodifiable', () {
      final reader = FirestoreReader('c/1', {
        'skills': ['Flutter', '', 42, null, 'Dart'],
      });
      final skills = reader.stringList('skills');
      expect(skills, ['Flutter', 'Dart']);
      expect(() => skills.add('x'), throwsUnsupportedError);
    });

    test('enums: unknown values are rejected, not defaulted', () {
      final reader = FirestoreReader('c/1', {
        'mode': 'hybrid',
        'bad': 'onsite',
      });
      expect(reader.requireEnum('mode', _parseMode), _Mode.hybrid);
      expect(reader.optionalEnum('bad', _parseMode), isNull);
      expect(
        () => reader.requireEnum('bad', _parseMode),
        throwsFormatException,
      );
    });

    test('nested maps get a reader with a nested path', () {
      final reader = FirestoreReader('c/1', {
        'company': {'name': 'Acme'},
      });
      final company = reader.requireMap('company');
      expect(company.requireString('name'), 'Acme');
      expect(
        () => company.requireString('logo'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('c/1.company'),
          ),
        ),
      );
      expect(reader.optionalMap('missing'), isNull);
    });
  });
}
