import 'package:flutter/foundation.dart';

import '../core/utils/skill_match.dart';

/// One honest suggestion for a missing requirement of the internship.
@immutable
class CvMatchSuggestion {
  const CvMatchSuggestion({required this.skill, required this.text});

  final String skill;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is CvMatchSuggestion && other.skill == skill && other.text == text;

  @override
  int get hashCode => Object.hash(skill, text);

  @override
  String toString() => 'CvMatchSuggestion($skill, $text)';
}

/// Result of the advisory CV Match Check (G-24/DC-09).
///
/// The percentage and the matched/missing lists are computed server-side from
/// the internship requirements, the Profile skills and the skills found in the
/// CV text; [summary] and [suggestions] may come from Gemini, with a
/// deterministic fallback. Parsing lives in `CvMatchService`.
@immutable
class CvMatchResult {
  const CvMatchResult({
    required this.internshipTitle,
    required this.companyName,
    required this.percent,
    required this.matchedCount,
    required this.totalRequired,
    required this.matched,
    required this.missing,
    required this.niceToHave,
    required this.suggestions,
    required this.summary,
    required this.cvReadable,
  });

  final String internshipTitle;

  /// Empty when the listing names no company.
  final String companyName;

  /// 0–100; 0 when the listing lists no known skill.
  final int percent;
  final int matchedCount;
  final int totalRequired;

  /// Required skills found in the Profile or in the CV text.
  final List<String> matched;

  /// Required skills found in neither.
  final List<String> missing;

  /// Optional skills: shown for information, never as gaps.
  final List<String> niceToHave;

  /// One entry per missing skill when the check found gaps.
  final List<CvMatchSuggestion> suggestions;

  final String summary;

  /// `false` when the PDF text could not be read; the score then compares
  /// Profile skills only.
  final bool cvReadable;

  bool get hasRequirements => totalRequired > 0;

  bool get allMatched => hasRequirements && missing.isEmpty;

  MatchLevel get level {
    if (percent >= SkillMatch.highMatchPercent) return MatchLevel.high;
    if (percent >= SkillMatch.mediumMatchPercent) return MatchLevel.medium;
    return MatchLevel.low;
  }

  @override
  bool operator ==(Object other) =>
      other is CvMatchResult &&
      other.internshipTitle == internshipTitle &&
      other.companyName == companyName &&
      other.percent == percent &&
      other.matchedCount == matchedCount &&
      other.totalRequired == totalRequired &&
      listEquals(other.matched, matched) &&
      listEquals(other.missing, missing) &&
      listEquals(other.niceToHave, niceToHave) &&
      listEquals(other.suggestions, suggestions) &&
      other.summary == summary &&
      other.cvReadable == cvReadable;

  @override
  int get hashCode => Object.hash(
    internshipTitle,
    companyName,
    percent,
    matchedCount,
    totalRequired,
    Object.hashAll(matched),
    Object.hashAll(missing),
    Object.hashAll(niceToHave),
    Object.hashAll(suggestions),
    summary,
    cvReadable,
  );

  @override
  String toString() =>
      'CvMatchResult($percent%, $matchedCount/$totalRequired, '
      'missing: ${missing.join(', ')})';
}
