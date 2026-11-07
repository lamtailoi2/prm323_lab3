/// Builds a `mailto:` URI for the compose screen (RFC 6068).
///
/// Spaces and newlines become `%20` / `%0A` (not `+`), so every mail app
/// decodes the letter correctly. An empty [to] still opens the mail app with
/// the subject and body, so the student can pick a recipient there.
Uri buildMailtoUri({
  String? to,
  required String subject,
  required String body,
}) {
  final query = <String>[
    'subject=${Uri.encodeComponent(subject)}',
    'body=${Uri.encodeComponent(body)}',
  ].join('&');
  return Uri.parse('mailto:${(to ?? '').trim()}?$query');
}
