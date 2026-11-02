import 'package:flutter/foundation.dart';

/// Coarse match level shown as the badge of the Skill match card.
enum MatchLevel {
  high('High match'),
  medium('Medium match'),
  low('Low match');

  const MatchLevel(this.label);

  final String label;
}

/// How the student's Profile skills cover the known skills a listing
/// mentions (Internship Detail "Skill match" card, G-24 rule 1).
///
/// Only declared skills are compared: the CV file is never read for this
/// card, so it works with any CV the student later sends (DC-24).
@immutable
class SkillMatch {
  const SkillMatch({
    required this.matched,
    required this.missing,
    this.profileHasSkills = true,
  });

  /// `false` when the student has not added any skill yet: the card then
  /// invites them to add skills instead of showing a discouraging "0 %".
  final bool profileHasSkills;

  /// Listing skills the profile has, in listing order.
  final List<String> matched;

  /// Listing skills the profile does not have yet, in listing order.
  final List<String> missing;

  int get total => matched.length + missing.length;

  /// Share of the listing skills the profile covers, 0–100.
  int get percent => total == 0 ? 0 : (matched.length * 100 / total).round();

  MatchLevel get level {
    if (percent >= highMatchPercent) return MatchLevel.high;
    if (percent >= mediumMatchPercent) return MatchLevel.medium;
    return MatchLevel.low;
  }

  /// Three of four skills (the Figma example) is a high match.
  static const int highMatchPercent = 75;
  static const int mediumMatchPercent = 40;
}

/// Compares [listingSkills] with [profileSkills], ignoring case.
///
/// Returns `null` when the listing mentions no known skill: there is nothing
/// to match, so the card is hidden instead of showing "0 of 0".
SkillMatch? skillMatchFor({
  required List<String> listingSkills,
  required Iterable<String> profileSkills,
}) {
  if (listingSkills.isEmpty) return null;
  final mine = {for (final skill in profileSkills) skill.toLowerCase()};
  final matched = <String>[];
  final missing = <String>[];
  final seen = <String>{};
  for (final skill in listingSkills) {
    if (!seen.add(skill.toLowerCase())) continue;
    (mine.contains(skill.toLowerCase()) ? matched : missing).add(skill);
  }
  return SkillMatch(
    matched: List<String>.unmodifiable(matched),
    missing: List<String>.unmodifiable(missing),
    profileHasSkills: mine.isNotEmpty,
  );
}
