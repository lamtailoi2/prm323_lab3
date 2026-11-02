import 'package:flutter_test/flutter_test.dart';
import 'package:internly/core/utils/skill_matcher.dart';
import 'package:internly/core/utils/skill_suggestions.dart';

import '../../helpers/fakes.dart';

void main() {
  test('offers only skills the pool mentions, most common first', () {
    final listings = [
      testInternship('1', skills: const ['Flutter', 'Dart']),
      testInternship('2', skills: const ['Flutter', 'Git']),
      testInternship('3', skills: const ['Flutter']),
    ];

    expect(suggestedFilterSkills(listings), ['Flutter', 'Dart', 'Git']);
  });

  test('ties follow the app vocabulary', () {
    final listings = [
      testInternship('1', skills: const ['Git', 'React', 'Flutter']),
    ];

    expect(suggestedFilterSkills(listings), ['Flutter', 'React', 'Git']);
  });

  test('unknown skills tie-break alphabetically', () {
    final listings = [
      testInternship('1', skills: const ['Zeta', 'Alpha']),
    ];

    expect(suggestedFilterSkills(listings), ['Alpha', 'Zeta']);
  });

  test('an empty or skill-less pool offers no chips', () {
    expect(suggestedFilterSkills(const []), isEmpty);
    expect(suggestedFilterSkills([testInternship('1')]), isEmpty);
  });

  test('caps the list at the sheet row size', () {
    final listings = [
      testInternship('1', skills: knownSkills.take(10).toList()),
    ];

    final skills = suggestedFilterSkills(listings);
    expect(skills, hasLength(filterSkillLimit));
    expect(skills, knownSkills.take(filterSkillLimit));
  });
}
