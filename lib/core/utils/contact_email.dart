/// Finds the most likely application address in a job description.
///
/// Google Jobs does not provide a recruiter email, so the only source is the
/// listing text itself ("Send your CV to hr@company.vn"). When the text lists
/// several addresses, a recruiting mailbox wins. Returns `null` when there is
/// no usable address, so the student can type one themselves.
String? findApplicationEmail(String? text) {
  if (text == null || text.trim().isEmpty) return null;

  final candidates = <String>[];
  final seen = <String>{};
  for (final match in _emailPattern.allMatches(text)) {
    final email = _clean(match.group(0)!);
    if (email == null) continue;
    if (seen.add(email.toLowerCase())) candidates.add(email);
  }
  if (candidates.isEmpty) return null;

  for (final email in candidates) {
    if (_recruitingHint.hasMatch(email)) return email;
  }
  return candidates.first;
}

final RegExp _emailPattern = RegExp(
  r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}',
);

/// `hr@`, `recruitment@`, `tuyendung@`, `careers@`, `jobs@`, …
final RegExp _recruitingHint = RegExp(
  r'(hr|recruit|tuyen.?dung|career|job|apply|contact)',
  caseSensitive: false,
);

/// Addresses nobody should apply to.
final RegExp _machineMailbox = RegExp(
  r'^(noreply|no-reply|donotreply|do-not-reply)@',
  caseSensitive: false,
);

String? _clean(String raw) {
  var value = raw;
  while (value.isNotEmpty && '.,;:)]}\'"'.contains(value[value.length - 1])) {
    value = value.substring(0, value.length - 1);
  }
  if (value.isEmpty || _machineMailbox.hasMatch(value)) return null;
  return value;
}
