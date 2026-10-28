import 'job_role.dart';

/// Points for a listing whose role is one the student targets.
const int exactRoleScore = 3;

/// Points for a Full-stack listing when the student targets frontend or
/// backend work: it covers part of that role.
const int partialRoleScore = 2;

/// Each skill the listing and the profile share adds one point, up to this
/// many, so a long skill list cannot outweigh the role.
const int maxSkillScore = 3;

/// How well a listing fits the profile, for ordering "Recommended for you"
/// (G-23): the role first, then the shared skills. `0` when nothing in the
/// profile matches; listings with equal scores keep their sync order.
///
/// Work mode is not scored: Google Jobs almost never states it for the
/// Vietnamese pool (288 of 289 IT listings on 2026-10-28).
int recommendationScore({
  required JobRole? role,
  required Iterable<String> listingSkills,
  required Set<JobRole> wantedRoles,
  required Set<String> profileSkills,
}) {
  return _roleScore(role, wantedRoles) +
      _skillScore(listingSkills, profileSkills);
}

int _roleScore(JobRole? role, Set<JobRole> wanted) {
  if (role == null || wanted.isEmpty) return 0;
  if (wanted.contains(role)) return exactRoleScore;
  final wantsFrontOrBack =
      wanted.contains(JobRole.frontend) || wanted.contains(JobRole.backend);
  return role == JobRole.fullStack && wantsFrontOrBack ? partialRoleScore : 0;
}

int _skillScore(Iterable<String> listingSkills, Set<String> profileSkills) {
  if (profileSkills.isEmpty) return 0;
  final mine = {for (final skill in profileSkills) skill.toLowerCase()};
  final shared = listingSkills
      .where((skill) => mine.contains(skill.toLowerCase()))
      .toSet()
      .length;
  return shared > maxSkillScore ? maxSkillScore : shared;
}
