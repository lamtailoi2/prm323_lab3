import 'package:flutter/foundation.dart';

import '../../../core/utils/allowance.dart';
import '../../../core/utils/location_match.dart';
import '../../../core/utils/text_fold.dart';
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
    final q = removeDiacritics(query.trim());
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
    // Job type filter: Google's `schedule_type`, the "Job type" fact on
    // Internship Detail. The sync asks Google in Vietnamese (`hl=vi`), so
    // both spellings match; a listing that does not state its type is left
    // out rather than guessed from the title.
    if (jobType case final type? when type != 'Any job type') {
      if (!_matchesJobType(internship.scheduleType, type)) return false;
    }
    // Allowance range filter: every option the sheet offers filters, not
    // only `Paid only` (CR-12).
    switch (allowanceRange) {
      case 'Paid only':
        final salary = internship.salary?.toLowerCase();
        if (salary == null ||
            salary.isEmpty ||
            salary.contains('unpaid') ||
            salary.contains('không lương')) {
          return false;
        }
      case 'Above 5M VND/mo':
        if ((highestVndAmount(internship.salary) ?? 0) < 5000000) {
          return false;
        }
      case 'Negotiable':
        if (!isNegotiableAllowance(internship.salary)) return false;
    }
    // Query filter, without Vietnamese accents (the `hl=vi` sync stores
    // `Hà Nội`, `Thực tập sinh`) and also without spaces (`Hanoi`), but with
    // symbols kept so `C#` is not `C` (CR-09).
    if (q.isNotEmpty) {
      final compact = q.replaceAll(' ', '');
      bool has(String? text) {
        if (text == null) return false;
        final plain = removeDiacritics(text);
        return plain.contains(q) || plain.replaceAll(' ', '').contains(compact);
      }

      if (!has(internship.title) &&
          !has(internship.companyName) &&
          !internship.skills.any(has) &&
          !has(internship.searchKeyword) &&
          !has(internship.location)) {
        return false;
      }
    }
    return true;
  }

  /// Words of each Job type option, folded (`foldText`), in English and in
  /// Vietnamese.
  static const Map<String, List<String>> _jobTypeWords = {
    'Internship': ['internship', 'intern', 'thuc tap'],
    'Full-time': ['full time', 'toan thoi gian'],
    'Part-time': ['part time', 'ban thoi gian'],
  };

  static bool _matchesJobType(String? scheduleType, String jobType) {
    final words = _jobTypeWords[jobType];
    if (words == null) return true;
    if (scheduleType == null) return false;
    final folded = foldText(scheduleType);
    return words.any((word) => containsWords(folded, word));
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
