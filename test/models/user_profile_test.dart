import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/firestore_reader.dart';
import 'package:internly/core/utils/job_level.dart';
import 'package:internly/core/utils/job_role.dart';
import 'package:internly/models/internship.dart';
import 'package:internly/models/user_profile.dart';

void main() {
  final uploadedAt = DateTime.utc(2026, 10, 14, 9);

  group('UserProfile.fromFirestore', () {
    test('valid document: every section is parsed', () {
      final profile = UserProfile.fromFirestore('uid-1', {
        'fullName': 'Minh Nguyen',
        'phone': '+84 908 123 456',
        'university': 'University of Science, HCMC',
        'major': 'Software Engineering',
        'yearOfStudy': 3,
        'skills': ['Flutter', 'React', 'NestJS', 'MongoDB'],
        'preferences': {
          'targetRoles': ['mobile', 'software_engineer'],
          'experience': 'one_to_two',
          'workModes': ['hybrid', 'on_site'],
          'location': 'Ho Chi Minh City',
        },
        'cv': {
          'fileName': 'Minh_Nguyen_CV_SE.pdf',
          'url': 'https://storage.example/cv.pdf',
          'storagePath': 'cvs/uid-1/minh-nguyen-cv-se-abc.pdf',
          'sizeBytes': 430080,
          'uploadedAt': Timestamp.fromDate(uploadedAt),
        },
      });

      expect(profile.details.fullName, 'Minh Nguyen');
      expect(profile.details.phone, '+84 908 123 456');
      expect(profile.details.university, 'University of Science, HCMC');
      expect(profile.details.major, 'Software Engineering');
      expect(profile.details.yearOfStudy, 3);
      expect(profile.skills, ['Flutter', 'React', 'NestJS', 'MongoDB']);
      expect(profile.preferences.targetRoles, [
        TargetRole.mobile,
        TargetRole.softwareEngineer,
      ]);
      expect(profile.preferences.experience, ExperienceRange.oneToTwo);
      expect(profile.preferences.workModes, [WorkMode.hybrid, WorkMode.onSite]);
      expect(profile.preferences.location, 'Ho Chi Minh City');
      expect(profile.cv?.fileName, 'Minh_Nguyen_CV_SE.pdf');
      expect(profile.cv?.sizeBytes, 430080);
      expect(profile.cv!.uploadedAt.isAtSameMomentAs(uploadedAt), isTrue);
    });

    test('missing document or optional fields: an empty profile', () {
      for (final data in [null, <String, Object?>{}]) {
        final profile = UserProfile.fromFirestore('uid-1', data);
        expect(profile, const UserProfile());
        expect(profile.details.fullName, isNull);
        expect(profile.skills, isEmpty);
        expect(profile.preferences, const InternshipPreferences());
        expect(profile.cv, isNull);
      }
    });

    test('wrong types and unknown enum values are dropped', () {
      final profile = UserProfile.fromFirestore('uid-1', {
        'fullName': '   ',
        'yearOfStudy': 'three',
        'skills': ['Flutter', 42, ''],
        'preferences': {
          'targetRoles': ['mobile', 'astronaut'],
          'experience': 'expert',
          'workModes': 'remote',
        },
      });

      expect(profile.details.fullName, isNull);
      expect(profile.details.yearOfStudy, isNull);
      expect(profile.skills, ['Flutter']);
      expect(profile.preferences.targetRoles, [TargetRole.mobile]);
      expect(profile.preferences.experience, isNull);
      expect(profile.preferences.workModes, isEmpty);
    });

    test('a legacy profile without an experience field reads as not set', () {
      final profile = UserProfile.fromFirestore('uid-1', {
        'preferences': {
          'targetRoles': ['mobile'],
          'workModes': ['remote'],
        },
      });

      expect(profile.preferences.targetRoles, [TargetRole.mobile]);
      expect(profile.preferences.experience, isNull);
      expect(profile.preferences.toFirestore()['experience'], isNull);
    });

    test('a CV without its required fields is treated as no CV', () {
      final profile = UserProfile.fromFirestore('uid-1', {
        'fullName': 'Minh Nguyen',
        'cv': {'fileName': 'cv.pdf'},
      });

      expect(profile.details.fullName, 'Minh Nguyen');
      expect(profile.cv, isNull);
    });

    test('CvFile.fromReader names the missing required field', () {
      expect(
        () => CvFile.fromReader(
          FirestoreReader('users/uid-1.cv', {
            'fileName': 'cv.pdf',
            'url': 'https://storage.example/cv.pdf',
            'storagePath': 'cvs/uid-1/cv.pdf',
          }),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('uploadedAt'),
          ),
        ),
      );
    });
  });

  group('toFirestore', () {
    test('round-trips through fromFirestore', () {
      final cv = CvFile(
        fileName: 'cv.pdf',
        url: 'https://storage.example/cv.pdf',
        storagePath: 'cvs/uid-1/cv-abc.pdf',
        sizeBytes: 2048,
        uploadedAt: uploadedAt,
      );
      const details = ProfileDetails(
        fullName: 'Minh Nguyen',
        headline: 'Software Engineering Student',
        yearOfStudy: 2,
        graduationYear: 2028,
        phone: '0908123456',
        city: 'Ho Chi Minh City',
        bio: 'Looking for a mobile internship.',
      );
      const preferences = InternshipPreferences(
        targetRoles: [TargetRole.frontend, TargetRole.qaTester],
        experience: ExperienceRange.underOne,
        workModes: [WorkMode.remote],
        location: 'Hanoi',
      );

      final restored = UserProfile.fromFirestore('uid-1', {
        ...details.toFirestore(),
        'skills': ['Dart'],
        'preferences': preferences.toFirestore(),
        'cv': cv.toFirestore(),
      });

      expect(
        restored,
        UserProfile(
          details: details,
          skills: const ['Dart'],
          preferences: preferences,
          cv: cv,
        ),
      );
    });

    test('enums are stored as snake_case strings', () {
      const preferences = InternshipPreferences(
        targetRoles: [TargetRole.softwareEngineer, TargetRole.qaTester],
        workModes: [WorkMode.onSite],
      );
      expect(preferences.toFirestore(), {
        'targetRoles': ['software_engineer', 'qa_tester'],
        'experience': null,
        'workModes': ['on_site'],
        'location': null,
      });
    });

    test('details write cleared fields as null', () {
      expect(const ProfileDetails(fullName: 'Lan').toFirestore(), {
        'fullName': 'Lan',
        'headline': null,
        'university': null,
        'major': null,
        'yearOfStudy': null,
        'graduationYear': null,
        'phone': null,
        'city': null,
        'bio': null,
      });
    });
  });

  test('target roles map to the Home listing roles', () {
    expect(TargetRole.frontend.jobRoles, {JobRole.frontend});
    expect(TargetRole.backend.jobRoles, {JobRole.backend});
    expect(TargetRole.mobile.jobRoles, {JobRole.mobile});
    expect(TargetRole.qaTester.jobRoles, {JobRole.tester});
    expect(TargetRole.dataAi.jobRoles, {JobRole.dataAi});
    expect(TargetRole.devOps.jobRoles, {JobRole.devOps});
    expect(TargetRole.softwareEngineer.jobRoles, {
      JobRole.backend,
      JobRole.fullStack,
      JobRole.otherIt,
    });
  });

  test('every Home listing role is covered by a target role', () {
    final covered = {
      for (final target in TargetRole.values) ...target.jobRoles,
    };
    expect(covered, JobRole.values.toSet());
  });

  test('experience bands store snake_case and map to levels', () {
    expect(
      const InternshipPreferences(experience: ExperienceRange.twoPlus)
          .toFirestore()['experience'],
      'two_plus',
    );
    expect(ExperienceRange.none.levels, {JobLevel.intern});
    expect(ExperienceRange.underOne.levels, {
      JobLevel.intern,
      JobLevel.fresher,
    });
    expect(ExperienceRange.oneToTwo.levels, {
      JobLevel.fresher,
      JobLevel.junior,
    });
    expect(ExperienceRange.twoPlus.levels, {JobLevel.junior});
  });

  test('profiles that differ only by experience are not equal', () {
    const without = InternshipPreferences();
    const withNone = InternshipPreferences(experience: ExperienceRange.none);
    expect(without, isNot(withNone));
    expect(without.hashCode, isNot(withNone.hashCode));
  });
}
