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
      // "Withdrawn" now has its Application Detail specimen (G-18), so it is
      // a known value; anything else stays unknown.
      expect(
        ApplicationStatus.fromStorage('withdrawn'),
        ApplicationStatus.withdrawn,
      );
      expect(ApplicationStatus.fromStorage('ACCEPTED'), isNull);
      expect(ApplicationStatus.fromStorage('ghosted'), isNull);
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
      expect(application.applicant, isNull);
      expect(application.withdrawnAt, isNull);
      expect(application.cvFileName, isNull);
    });

    test('reads the withdrawal, the CV snapshot and the applicant', () {
      final withdrawnAt = DateTime(2026, 10, 12, 9);
      final application = InternshipApplication.fromFirestore('job-7', {
        'title': 'Flutter Developer Intern',
        'companyName': 'FPT Software',
        'appliedAt': DateTime(2026, 10, 11),
        'status': 'withdrawn',
        'withdrawnAt': Timestamp.fromDate(withdrawnAt),
        'previousStatus': 'under_review',
        'cvFileName': 'Profile_CV.pdf',
        'cvUrl': 'https://storage.example/cvs/profile.pdf',
        'cvStoragePath': 'cvs/uid-123/profile.pdf',
        'applicant': {
          'fullName': ' Minh Nguyen ',
          'email': 'minh@example.com',
          'phone': '0908 123 456',
          'university': 'HCMUT',
          'yearOfStudy': 3,
          'skills': ['Flutter', 'Dart'],
          'shortIntroduction': 'Hello',
        },
      });

      expect(application.status, ApplicationStatus.withdrawn);
      expect(application.withdrawnAt, isNotNull);
      expect(application.previousStatus, ApplicationStatus.underReview);
      expect(application.cvFileName, 'Profile_CV.pdf');
      expect(application.cvUrl, 'https://storage.example/cvs/profile.pdf');
      final applicant = application.applicant!;
      expect(applicant.fullName, 'Minh Nguyen');
      expect(applicant.email, 'minh@example.com');
      expect(applicant.yearOfStudy, 3);
      expect(applicant.skills, ['Flutter', 'Dart']);
      expect(applicant.introduction, 'Hello');
    });

    test('a malformed applicant map hides the snapshot, not the document', () {
      final application = InternshipApplication.fromFirestore('job-8', {
        'title': 'Flutter Developer Intern',
        'companyName': 'FPT Software',
        'appliedAt': DateTime(2026, 10, 11),
        'status': 'submitted',
        'applicant': {'fullName': 42},
      });

      expect(application.applicant, isNull);
      expect(application.title, 'Flutter Developer Intern');
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
          'status': 'ghosted',
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
