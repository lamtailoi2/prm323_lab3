final RegExp _relativeAge = RegExp(
  r'^(\d+|an?)\+?\s+(minute|hour|day|week|month|year)s?\s+ago$',
);

/// Parses the relative "posted" text that Google Jobs returns (e.g.
/// `2 days ago`, `17 hours ago`, `30+ days ago`, `Just posted`) into an age,
/// so listings can be ordered newest first. Returns `null` when the text is
/// missing or not recognised; callers keep those listings last.
Duration? parsePostedAge(String? text) {
  if (text == null) return null;
  final normalized = text.trim().toLowerCase();
  if (const {'just posted', 'just now', 'today'}.contains(normalized)) {
    return Duration.zero;
  }
  final match = _relativeAge.firstMatch(normalized);
  if (match == null) return null;
  final count = int.tryParse(match[1]!) ?? 1; // "a day ago", "an hour ago"
  return switch (match[2]) {
    'minute' => Duration(minutes: count),
    'hour' => Duration(hours: count),
    'day' => Duration(days: count),
    'week' => Duration(days: count * 7),
    'month' => Duration(days: count * 30),
    _ => Duration(days: count * 365),
  };
}

/// Compact relative age for the Internship Card, matching the design samples
/// (`Just now`, `2d ago`) rather than Google's wording (`2 days ago`).
String formatPostedAge(DateTime? postedAt, {DateTime? now}) {
  if (postedAt == null) return '';
  final age = (now ?? DateTime.now()).difference(postedAt);
  if (age.isNegative || age.inMinutes < 1) return 'Just now';
  if (age.inHours < 1) return '${age.inMinutes}m ago';
  if (age.inDays < 1) return '${age.inHours}h ago';
  if (age.inDays < 7) return '${age.inDays}d ago';
  if (age.inDays < 30) return '${age.inDays ~/ 7}w ago';
  if (age.inDays < 365) return '${age.inDays ~/ 30}mo ago';
  return '${age.inDays ~/ 365}y ago';
}
