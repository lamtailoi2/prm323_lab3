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
