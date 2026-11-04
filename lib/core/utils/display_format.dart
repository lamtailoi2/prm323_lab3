const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Date as shown on the CV file card in the Profile design: `Oct 14, 2024`.
String formatShortDate(DateTime date) {
  final local = date.toLocal();
  return '${_months[local.month - 1]} ${local.day}, ${local.year}';
}

/// Date and time as the Application submitted frame shows it:
/// `Oct 19, 2026, 22:20` (24-hour clock).
String formatShortDateTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${formatShortDate(local)}, $hour:$minute';
}

/// Day and month without a year, as the My Applications cards show it:
/// `1 Oct` (used as `Applied 1 Oct`).
String formatDayMonth(DateTime date) {
  final local = date.toLocal();
  return '${local.day} ${_months[local.month - 1]}';
}

/// Date and time for an interview slot: `Oct 24, 2:00 PM` (12-hour clock,
/// as in the My Applications frame).
String formatMonthDayTime(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '${_months[local.month - 1]} ${local.day}, $hour:$minute $period';
}

/// Reply deadline of an application: `Reply within 5 days` during the last
/// week, otherwise the date (`Reply by 1 Nov`).
///
/// [now] is injectable so the relative form is testable.
String formatReplyBy(DateTime deadline, {DateTime? now}) {
  final today = _dateOnly((now ?? DateTime.now()).toLocal());
  final due = _dateOnly(deadline.toLocal());
  final days = due.difference(today).inDays;

  if (days >= 1 && days <= 6) {
    return 'Reply within $days ${days == 1 ? 'day' : 'days'}';
  }
  return 'Reply by ${formatDayMonth(deadline)}';
}

/// Midnight UTC of [date]'s calendar day, so a day count never shifts by an
/// hour across a daylight-saving change.
DateTime _dateOnly(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day);

/// File size for file cards: `420 KB`, `1.2 MB`. Sizes under 1 KB round up
/// to `1 KB` so a real file never reads as empty.
String formatFileSize(int bytes) {
  const kb = 1024;
  const mb = kb * 1024;
  if (bytes >= mb) {
    final value = bytes / mb;
    final text = value >= 10
        ? value.round().toString()
        : value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
    return '$text MB';
  }
  final kilobytes = (bytes / kb).ceil();
  return '${kilobytes < 1 ? 1 : kilobytes} KB';
}
