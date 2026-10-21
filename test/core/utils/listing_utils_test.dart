import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/job_key.dart';
import 'package:internly/core/utils/posted_age.dart';
import 'package:internly/core/utils/skill_matcher.dart';

void main() {
  group('jobKeyFor', () {
    test('is short, URL-safe and stable', () {
      const jobId =
          'eyJqb2JfdGl0bGUiOiJGbHV0dGVyIEludGVybiIsImh0aWRvY2lkIjoiYS9i'
          'K2MvZD0ifQ==';
      final key = jobKeyFor(jobId);
      expect(key, matches(RegExp(r'^[0-9a-f]{16}$')));
      expect(jobKeyFor(jobId), key);
    });

    test('differs for different IDs', () {
      expect(jobKeyFor('job-1'), isNot(jobKeyFor('job-2')));
    });

    test('matches the FNV-1a 64 reference values', () {
      expect(jobKeyFor(''), 'cbf29ce484222325');
      expect(jobKeyFor('a'), 'af63dc4c8601ec8c');
    });
  });

  group('parsePostedAge', () {
    test('parses Google Jobs relative dates', () {
      expect(parsePostedAge('17 hours ago'), const Duration(hours: 17));
      expect(parsePostedAge('2 days ago'), const Duration(days: 2));
      expect(parsePostedAge('1 day ago'), const Duration(days: 1));
      expect(parsePostedAge('30+ days ago'), const Duration(days: 30));
      expect(parsePostedAge('a week ago'), const Duration(days: 7));
      expect(parsePostedAge('an hour ago'), const Duration(hours: 1));
      expect(parsePostedAge('Just posted'), Duration.zero);
    });

    test('returns null for missing or unknown text', () {
      expect(parsePostedAge(null), isNull);
      expect(parsePostedAge('Full-time'), isNull);
      expect(parsePostedAge(''), isNull);
    });
  });

  group('findSkills', () {
    test('finds known skills in order of first mention', () {
      expect(
        findSkills('Flutter Intern. Requirements: Dart, Firebase and Git.'),
        ['Flutter', 'Dart', 'Firebase', 'Git'],
      );
    });

    test('is case-insensitive and respects word boundaries', () {
      expect(findSkills('We use javascript and MySQL'), [
        'JavaScript',
        'MySQL',
      ]);
      expect(findSkills('GitHub, Golang'), ['Golang']);
    });

    test('matches skills with symbols', () {
      expect(findSkills('C#, ASP.NET Core and C++'), ['C#', 'ASP.NET', 'C++']);
    });

    test('drops a skill that is part of a longer match', () {
      expect(findSkills('React Native developer'), ['React Native']);
      expect(findSkills('React and React Native'), ['React Native']);
    });

    test('ignores ambiguous words and domains', () {
      expect(
        findSkills('Ai cũng có thể apply, contact hr@company.net'),
        isEmpty,
      );
    });
  });
}
