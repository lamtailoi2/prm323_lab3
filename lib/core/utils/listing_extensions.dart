/// Google Jobs in Vietnamese (`hl=vi`, as the sync asks) returns no
/// `detected_extensions`: the schedule type and the posted age are only in
/// the `extensions` chips, e.g. `["3 ngày trước", "Toàn thời gian và Thực
/// tập"]` (checked on 28 synced listings, 2026-11-02). These helpers read
/// them.
library;

import 'posted_age.dart';
import 'text_fold.dart';

/// Schedule words (folded with [foldText]) and the English label the app
/// shows, like the rest of the UI.
const Map<String, String> _scheduleLabels = {
  'toan thoi gian': 'Full-time',
  'ban thoi gian': 'Part-time',
  'thuc tap': 'Internship',
  'hop dong': 'Contractor',
  'nha thau': 'Contractor',
  'tam thoi': 'Temporary',
  'full time': 'Full-time',
  'part time': 'Part-time',
  'internship': 'Internship',
  'contractor': 'Contractor',
  'temporary': 'Temporary',
};

final RegExp _and = RegExp(r'\s+(?:va|and)\s+');

/// The schedule type named by a chip, in English: `Toàn thời gian và Thực
/// tập` → `Full-time and Internship`. `null` when no chip is a schedule.
String? scheduleTypeFromExtensions(List<String> extensions) {
  for (final chip in extensions) {
    final labels = [
      for (final part in foldText(chip).split(_and)) _scheduleLabels[part],
    ];
    if (labels.every((label) => label != null)) {
      return labels.toSet().join(' and ');
    }
  }
  return null;
}

/// The chip that states when the listing was posted (`3 ngày trước`,
/// `2 days ago`), or `null`.
String? postedTextFromExtensions(List<String> extensions) {
  for (final chip in extensions) {
    if (parsePostedAge(chip) != null) return chip.trim();
  }
  return null;
}
