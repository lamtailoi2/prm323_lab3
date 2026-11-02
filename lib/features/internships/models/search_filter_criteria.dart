import 'package:flutter/foundation.dart';

import '../../../core/utils/location_match.dart';
import '../../../models/internship.dart';

/// Filter criteria for internships search.
@immutable
class SearchFilterCriteria {
  const SearchFilterCriteria({
    this.workModes = const <WorkMode>{},
    this.skills = const <String>{},
    this.location,
    this.jobType,
    this.allowanceRange,
  });

  /// Work arrangements selected (e.g. Remote, On-site, Hybrid).
  final Set<WorkMode> workModes;

  /// Skills selected (e.g. Flutter, React, NestJS).
  final Set<String> skills;

  /// Location constraint (e.g. "Ho Chi Minh City", "Ha Noi", or null for Any).
  final String? location;

  /// Job type (e.g. "Internship", "Full-time", or null for Any).
  final String? jobType;

  /// Allowance range (e.g. "Paid only", or null for Any).
  final String? allowanceRange;

  int get criteriaCount {
    var count = 0;
    count += workModes.length;
    count += skills.length;
    if (location != null && location != 'Any location') count++;
    if (jobType != null && jobType != 'Any job type') count++;
    if (allowanceRange != null && allowanceRange != 'Any allowance') count++;
    return count;
  }

  bool get isEmpty => criteriaCount == 0;

  /// Whether [internship] passes these filters and the free-text [query]
  /// (title, company, skills, sync keyword or location). Shared by Search,
  /// which previews the match count, and Search Results.
  bool matches(Internship internship, {String query = ''}) {
    final q = query.trim().toLowerCase();
    // Work mode filter (multi-select)
    if (workModes.isNotEmpty) {
      if (internship.workMode == null ||
          !workModes.contains(internship.workMode)) {
        return false;
      }
    }
    // Skills filter (multi-select)
    if (skills.isNotEmpty) {
      final matchesSkill = skills.any(
        (filterSkill) => internship.skills.any(
          (s) => s.toLowerCase() == filterSkill.toLowerCase(),
        ),
      );
      if (!matchesSkill) return false;
    }
    // Location filter. The sheet offers English city names while Google Jobs
    // writes Vietnamese ones ("Thành phố Hồ Chí Minh", "Hà Nội"), so the
    // accent-folding matcher Home uses replaces a plain `contains`.
    if (location != 'Any location' &&
        !matchesPreferredLocation(internship.location, location)) {
      return false;
    }
    // Allowance range filter
    if (allowanceRange != null && allowanceRange != 'Any allowance') {
      if (allowanceRange == 'Paid only') {
        final salary = internship.salary?.toLowerCase();
        if (salary == null ||
            salary.isEmpty ||
            salary.contains('unpaid') ||
            salary.contains('không lương')) {
          return false;
        }
      }
    }
    // Query filter
    if (q.isNotEmpty) {
      final inTitle = internship.title.toLowerCase().contains(q);
      final inCompany = internship.companyName.toLowerCase().contains(q);
      final inSkills = internship.skills.any(
        (s) => s.toLowerCase().contains(q),
      );
      final inKeyword =
          internship.searchKeyword?.toLowerCase().contains(q) ?? false;
      final inLocation =
          internship.location?.toLowerCase().contains(q) ?? false;
      if (!inTitle && !inCompany && !inSkills && !inKeyword && !inLocation) {
        return false;
      }
    }
    return true;
  }

  SearchFilterCriteria copyWith({
    Set<WorkMode>? workModes,
    Set<String>? skills,
    String? location,
    bool clearLocation = false,
    String? jobType,
    bool clearJobType = false,
    String? allowanceRange,
    bool clearAllowanceRange = false,
  }) {
    return SearchFilterCriteria(
      workModes: workModes ?? this.workModes,
      skills: skills ?? this.skills,
      location: clearLocation ? null : (location ?? this.location),
      jobType: clearJobType ? null : (jobType ?? this.jobType),
      allowanceRange: clearAllowanceRange
          ? null
          : (allowanceRange ?? this.allowanceRange),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchFilterCriteria &&
          setEquals(other.workModes, workModes) &&
          setEquals(other.skills, skills) &&
          other.location == location &&
          other.jobType == jobType &&
          other.allowanceRange == allowanceRange;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(workModes),
    Object.hashAll(skills),
    location,
    jobType,
    allowanceRange,
  );
}
