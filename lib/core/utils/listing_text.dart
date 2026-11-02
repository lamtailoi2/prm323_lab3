/// Google Jobs copies the employer's text, which often still contains
/// Markdown (`## Job Purpose`, `**Requirements**`, `- item`). Internship
/// Detail shows it as plain text, so these helpers drop the markers instead
/// of rendering them literally.
library;

// The text after the hashes is optional, so an empty `##` line is dropped;
// `#hashtag` (no space) is not a heading.
final RegExp _heading = RegExp(r'^\s{0,3}#{1,6}(?:\s+(.*?))?\s*#*\s*$');
final RegExp _bullet = RegExp(r'^\s*[-*+•]\s+(.*)$');
final RegExp _rule = RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$');
final RegExp _emphasis = RegExp(r'\*\*|__');
final RegExp _blankRun = RegExp(r'\n{3,}');

/// Description text for display: headings lose their `#`, list markers
/// become `• `, bold markers and horizontal rules are removed, and runs of
/// blank lines collapse to one.
String plainListingText(String text) {
  final lines = <String>[];
  for (final raw in text.replaceAll('\r\n', '\n').split('\n')) {
    if (_rule.hasMatch(raw)) continue;
    var line = raw.replaceAll(_emphasis, '').trimRight();
    if (_heading.firstMatch(line) case final match?) {
      line = match.group(1) ?? '';
    } else if (_bullet.firstMatch(line) case final match?) {
      line = '• ${match.group(1)!.trim()}';
    }
    lines.add(line);
  }
  return lines.join('\n').replaceAll(_blankRun, '\n\n').trim();
}

/// One `job_highlights` item: the list already provides the bullet, so a
/// leading marker and bold markers are removed.
String plainListingItem(String item) {
  var text = item.replaceAll(_emphasis, '').trim();
  if (_heading.firstMatch(text) case final match?) text = match.group(1) ?? '';
  if (_bullet.firstMatch(text) case final match?) text = match.group(1)!;
  return text.trim();
}
