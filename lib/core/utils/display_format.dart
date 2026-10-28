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
