import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/skill_match.dart';

void main() {
  test('returns null when the listing mentions no known skill', () {
    expect(
      skillMatchFor(listingSkills: const [], profileSkills: const ['Dart']),
      isNull,
    );
  });

  test('matches case-insensitively and keeps the listing order', () {
    final match = skillMatchFor(
      listingSkills: const ['Flutter', 'Dart', 'Git', 'REST API'],
      profileSkills: const ['git', 'flutter', 'DART', 'Python'],
    )!;

    expect(match.matched, ['Flutter', 'Dart', 'Git']);
    expect(match.missing, ['REST API']);
    expect(match.total, 4);
    expect(match.percent, 75);
    expect(match.level, MatchLevel.high);
  });

  test('counts a skill the listing repeats only once', () {
    final match = skillMatchFor(
      listingSkills: const ['Flutter', 'flutter', 'Dart'],
      profileSkills: const ['Flutter'],
    )!;

    expect(match.matched, ['Flutter']);
    expect(match.missing, ['Dart']);
    expect(match.percent, 50);
  });

  test('levels follow the 75 % and 40 % thresholds', () {
    SkillMatch of(int matched, int total) => skillMatchFor(
      listingSkills: [for (var i = 0; i < total; i++) 'S$i'],
      profileSkills: [for (var i = 0; i < matched; i++) 'S$i'],
    )!;

    expect(of(3, 4).level, MatchLevel.high);
    expect(of(2, 4).level, MatchLevel.medium);
    expect(of(2, 5).level, MatchLevel.medium);
    expect(of(1, 4).level, MatchLevel.low);
    expect(of(0, 3).percent, 0);
    expect(of(0, 3).level.label, 'Low match');
  });

  test('records whether the profile has any skill', () {
    final empty = skillMatchFor(
      listingSkills: const ['Flutter'],
      profileSkills: const [],
    )!;
    final some = skillMatchFor(
      listingSkills: const ['Flutter'],
      profileSkills: const ['Java'],
    )!;

    expect(empty.profileHasSkills, isFalse);
    expect(some.profileHasSkills, isTrue);
    expect(some.percent, 0);
  });
}
