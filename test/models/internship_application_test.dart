import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/models/internship_application.dart';

void main() {
  group('ApplicationStatus', () {
    test('parses the stored snake_case values', () {
      expect(
        ApplicationStatus.fromStorage('under_review'),
        ApplicationStatus.underReview,
      );
      expect(
        ApplicationStatus.fromStorage('accepted'),
        ApplicationStatus.accepted,
      );
    });

    test('rejects an unknown value instead of guessing a status', () {
      // "Withdrawn" has no Figma specimen yet (G-18), so it is not mapped.
      expect(ApplicationStatus.fromStorage('withdrawn'), isNull);
      expect(ApplicationStatus.fromStorage('ACCEPTED'), isNull);
    });
  });

  group('InternshipApplication.fromFirestore', () {
    test('reads a complete document', () {
      final appliedAt = DateTime(2026, 10, 1);
      final nextStepAt = DateTime(2026, 10, 24, 14);

      final application = InternshipApplication.fromFirestore('job-1', {
        'title': ' Product Design Intern ',
        'companyName': 'Orbit Labs',
        'appliedAt': Timestamp.fromDate(appliedAt),
        'status': 'interview',
        'nextStepAt': Timestamp.fromDate(nextStepAt),
      });

      expect(application.jobKey, 'job-1');
      expect(application.title, 'Product Design Intern');
      expect(application.companyName, 'Orbit Labs');
      expect(application.appliedAt.isAtSameMomentAs(appliedAt), isTrue);
      expect(application.status, ApplicationStatus.interview);
      expect(application.nextStepAt, isNotNull);
      expect(application.nextStepAt!.isAtSameMomentAs(nextStepAt), isTrue);
    });

    test('the next step is optional', () {
      final application = InternshipApplication.fromFirestore('job-2', {
        'title': 'QA Engineer Intern',
        'companyName': 'Brightpath',
        'appliedAt': DateTime(2026, 10, 8),
        'status': 'under_review',
      });

      expect(application.nextStepAt, isNull);
    });

    test('a missing or empty required field is malformed', () {
      expect(
        () => InternshipApplication.fromFirestore('job-3', {
          'companyName': 'No Title Ltd',
          'appliedAt': DateTime(2026, 10, 1),
          'status': 'submitted',
        }),
        throwsFormatException,
      );
      expect(
        () => InternshipApplication.fromFirestore('job-4', {
          'title': 'Backend Engineer Intern',
          'companyName': '   ',
          'appliedAt': DateTime(2026, 10, 1),
          'status': 'submitted',
        }),
        throwsFormatException,
      );
    });

    test('an unknown status is malformed, not shown as Submitted', () {
      expect(
        () => InternshipApplication.fromFirestore('job-5', {
          'title': 'Backend Engineer Intern',
          'companyName': 'Harbor Tech',
          'appliedAt': DateTime(2026, 10, 1),
          'status': 'withdrawn',
        }),
        throwsFormatException,
      );
    });

    test('a missing applied date is malformed', () {
      expect(
        () => InternshipApplication.fromFirestore('job-6', {
          'title': 'Data Analyst Intern',
          'companyName': 'Kite Analytics',
          'status': 'accepted',
        }),
        throwsFormatException,
      );
    });
  });
}
