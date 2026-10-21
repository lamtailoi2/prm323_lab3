/// IT skills recognised in listing text. Google Jobs has no skills field, so
/// the skill tags on Internship Cards are the known skills that a listing
/// mentions. Ambiguous words are left out on purpose: `Go` (use `Golang`),
/// `AI` (a common Vietnamese word), `Spring`, `Express`, `REST` alone, and
/// `.NET` alone (it matches `.net` domains in contact details).
///
/// Shared with recommendation and CV matching (G-23, G-24).
const List<String> knownSkills = <String>[
  'Flutter',
  'Dart',
  'React Native',
  'React',
  'Angular',
  'Vue',
  'Next.js',
  'Node.js',
  'NestJS',
  'JavaScript',
  'TypeScript',
  'HTML',
  'CSS',
  'Java',
  'Spring Boot',
  'Kotlin',
  'Swift',
  'Python',
  'Django',
  'FastAPI',
  'Golang',
  'PHP',
  'Laravel',
  'C#',
  'ASP.NET',
  'C++',
  'SQL',
  'MySQL',
  'PostgreSQL',
  'MongoDB',
  'Redis',
  'Firebase',
  'Docker',
  'Kubernetes',
  'AWS',
  'Azure',
  'Git',
  'Linux',
  'REST API',
  'GraphQL',
  'Figma',
  'Machine Learning',
];

final Map<String, RegExp> _patterns = <String, RegExp>{};

RegExp _patternFor(String skill) {
  return _patterns.putIfAbsent(skill, () {
    // Word boundaries only on alphanumeric ends, so "C#" and "C++" still
    // match, while "Java" does not match inside "JavaScript" and "SQL" not
    // inside "MySQL".
    final before = _isWordChar(skill[0]) ? r'(?<![A-Za-z0-9])' : '';
    final after = _isWordChar(skill[skill.length - 1])
        ? r'(?![A-Za-z0-9])'
        : '';
    return RegExp('$before${RegExp.escape(skill)}$after', caseSensitive: false);
  });
}

bool _isWordChar(String char) => RegExp('[A-Za-z0-9]').hasMatch(char);

/// The skills from [vocabulary] that [text] mentions, in order of first
/// mention. A skill that is part of a longer match is dropped (`React` when
/// the text says `React Native`).
List<String> findSkills(String text, {List<String> vocabulary = knownSkills}) {
  final found = <String, int>{};
  for (final skill in vocabulary) {
    final match = _patternFor(skill).firstMatch(text);
    if (match != null) found[skill] = match.start;
  }
  found.removeWhere(
    (skill, _) => found.keys.any(
      (other) =>
          other != skill &&
          other.length > skill.length &&
          _patternFor(skill).hasMatch(other),
    ),
  );
  return (found.entries.toList()..sort((a, b) => a.value.compareTo(b.value)))
      .map((entry) => entry.key)
      .toList(growable: false);
}
