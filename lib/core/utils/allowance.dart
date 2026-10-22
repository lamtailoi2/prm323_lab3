/// Formats the allowance text Google Jobs returns for the internship cards.
///
/// SerpAPI copies Google's wording, so the same period appears as
/// `a month`, `per month`, `/month` or `monthly`. The Lab 2 card uses the
/// compact `VND / mo` form (G-17). Nothing is invented: text that is already
/// meaningful (hourly pay, "Negotiable", a range) is kept, only the period
/// word is normalised.
String formatAllowance(String? raw, {String undisclosed = 'Not disclosed'}) {
  final text = raw?.trim();
  if (text == null || text.isEmpty) return undisclosed;

  var normalized = text.replaceAll(RegExp(r'\s+'), ' ');
  normalized = normalized.replaceAll(
    RegExp(r'\s*(?:/|per\s+|a\s+|an\s+)?month(?:ly)?\b', caseSensitive: false),
    ' / mo',
  );
  normalized = normalized.replaceAll(
    RegExp(r'\s*/\s*mo\b', caseSensitive: false),
    ' / mo',
  );
  return normalized.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}
