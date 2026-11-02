import 'text_fold.dart';

final RegExp _relativeAge = RegExp(
  r'^(\d+|an?)\+?\s+(minute|hour|day|week|month|year)s?\s+ago$',
);

/// The same in Vietnamese after [foldText] (`3 ngày trước` → `3 ngay
/// truoc`), which Google Jobs returns for the `hl=vi` sync.
final RegExp _relativeAgeVi = RegExp(
  r'^(\d+)\s+(phut|gio|ngay|tuan|thang|nam)\s+truoc$',
);

/// Parses the relative "posted" text that Google Jobs returns (e.g.
/// `2 days ago`, `17 hours ago`, `30+ days ago`, `Just posted`, or in
/// Vietnamese `3 ngày trước`, `30+ ngày trước`) into an age,
/// so listings can be ordered newest first. Returns `null` when the text is
/// missing or not recognised; callers keep those listings last.
Duration? parsePostedAge(String? text) {
  if (text == null) return null;
  final normalized = text.trim().toLowerCase();
  if (const {'just posted', 'just now', 'today'}.contains(normalized)) {
    return Duration.zero;
  }
  final match = _relativeAge.firstMatch(normalized);
  if (match == null) return _vietnameseAge(text);
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

Duration? _vietnameseAge(String text) {
  final match = _relativeAgeVi.firstMatch(foldText(text));
  if (match == null) return null;
  final count = int.parse(match[1]!);
  return switch (match[2]) {
    'phut' => Duration(minutes: count),
    'gio' => Duration(hours: count),
    'ngay' => Duration(days: count),
    'tuan' => Duration(days: count * 7),
    'thang' => Duration(days: count * 30),
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

/// Full relative age for the Internship Detail meta row, as in the Figma
/// frame (`Posted 2 days ago`); cards keep the compact [formatPostedAge].
String formatPostedAgeLong(DateTime postedAt, {DateTime? now}) {
  final age = (now ?? DateTime.now()).difference(postedAt);
  String ago(int count, String unit) =>
      '$count $unit${count == 1 ? '' : 's'} ago';
  if (age.isNegative || age.inMinutes < 1) return 'just now';
  if (age.inHours < 1) return ago(age.inMinutes, 'minute');
  if (age.inDays < 1) return ago(age.inHours, 'hour');
  if (age.inDays < 7) return ago(age.inDays, 'day');
  if (age.inDays < 30) return ago(age.inDays ~/ 7, 'week');
  if (age.inDays < 365) return ago(age.inDays ~/ 30, 'month');
  return ago(age.inDays ~/ 365, 'year');
}
