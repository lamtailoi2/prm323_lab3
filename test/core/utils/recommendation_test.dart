import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/job_level.dart';
import 'package:internly/core/utils/job_role.dart';
import 'package:internly/core/utils/recommendation.dart';
import 'package:internly/models/user_profile.dart' show ExperienceRange;

void main() {
  int score(
    JobRole? role, {
    List<String> listingSkills = const [],
    Set<JobRole> wanted = const {},
    Set<String> mine = const {},
  }) => recommendationScore(
    role: role,
    listingSkills: listingSkills,
    wantedRoles: wanted,
    profileSkills: mine,
  );

  test('a targeted role scores 3; Full-stack covers frontend or backend', () {
    expect(score(JobRole.frontend, wanted: {JobRole.frontend}), 3);
    expect(score(JobRole.fullStack, wanted: {JobRole.frontend}), 2);
    expect(score(JobRole.fullStack, wanted: {JobRole.backend}), 2);
    expect(score(JobRole.fullStack, wanted: {JobRole.mobile}), 0);
    expect(score(JobRole.tester, wanted: {JobRole.frontend}), 0);
    expect(score(null, wanted: {JobRole.frontend}), 0);
  });

  test('each shared skill adds one point, case-insensitively, up to 3', () {
    expect(
      score(null, listingSkills: ['React', 'Vue'], mine: {'react', 'Vue'}),
      2,
    );
    expect(
      score(
        null,
        listingSkills: ['React', 'Vue', 'Dart', 'Flutter', 'Git'],
        mine: {'React', 'Vue', 'Dart', 'Flutter', 'Git'},
      ),
      maxSkillScore,
    );
    expect(score(null, listingSkills: ['Java'], mine: {'React'}), 0);
  });

  test('role and skills add up; an empty profile scores everything 0', () {
    expect(
      score(
        JobRole.frontend,
        listingSkills: ['React'],
        wanted: {JobRole.frontend},
        mine: {'React'},
      ),
      4,
    );
    expect(score(JobRole.frontend, listingSkills: ['React']), 0);
  });

  test('a level matches only the bands the experience covers', () {
    expect(
      matchesWantedLevel(JobLevel.intern, ExperienceRange.none.levels),
      isTrue,
    );
    expect(
      matchesWantedLevel(JobLevel.intern, ExperienceRange.underOne.levels),
      isTrue,
    );
    expect(
      matchesWantedLevel(JobLevel.fresher, ExperienceRange.underOne.levels),
      isTrue,
    );
    expect(
      matchesWantedLevel(JobLevel.junior, ExperienceRange.oneToTwo.levels),
      isTrue,
    );
    expect(
      matchesWantedLevel(JobLevel.junior, ExperienceRange.twoPlus.levels),
      isTrue,
    );
    expect(
      matchesWantedLevel(JobLevel.intern, ExperienceRange.oneToTwo.levels),
      isFalse,
    );
    expect(
      matchesWantedLevel(JobLevel.junior, ExperienceRange.underOne.levels),
      isFalse,
    );
    expect(matchesWantedLevel(null, ExperienceRange.none.levels), isFalse);
  });

  test('experience never changes the role + skill score', () {
    expect(
      score(
        JobRole.frontend,
        listingSkills: ['React'],
        wanted: {JobRole.frontend},
        mine: {'React'},
      ),
      exactRoleScore + 1,
    );
  });
}
