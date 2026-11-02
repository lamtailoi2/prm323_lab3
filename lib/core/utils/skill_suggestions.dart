import '../../models/internship.dart';
import 'skill_matcher.dart';

/// How many skills the Search Filter sheet offers, matching its Figma row.
const int filterSkillLimit = 6;

/// Skills offered by the Search Filter sheet, most common first.
///
/// Only skills that the current pool actually mentions are returned, so a
/// chip always has at least one matching listing instead of the fixed
/// Flutter / React / NestJS list. Ties follow [knownSkills], the vocabulary
/// the app tags listings with, and then the alphabet.
List<String> suggestedFilterSkills(
  Iterable<Internship> listings, {
  int limit = filterSkillLimit,
}) {
  final counts = <String, int>{};
  for (final internship in listings) {
    for (final skill in internship.skills) {
      counts[skill] = (counts[skill] ?? 0) + 1;
    }
  }

  final ranked = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      if (byCount != 0) return byCount;
      final byVocabulary = _vocabularyIndex(a).compareTo(_vocabularyIndex(b));
      if (byVocabulary != 0) return byVocabulary;
      return a.compareTo(b);
    });
  return List.unmodifiable(ranked.take(limit));
}

int _vocabularyIndex(String skill) {
  final index = knownSkills.indexOf(skill);
  return index == -1 ? knownSkills.length : index;
}
