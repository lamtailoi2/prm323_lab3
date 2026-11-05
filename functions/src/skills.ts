/**
 * IT skills recognised in listing and CV text.
 *
 * Keep in sync with `lib/core/utils/skill_matcher.dart`; the parity test in
 * `skills.test.ts` fails when the two lists differ.
 */
export const KNOWN_SKILLS: readonly string[] = [
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

const patterns = new Map<string, RegExp>();

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function isWordChar(char: string): boolean {
  return /[A-Za-z0-9]/.test(char);
}

function patternFor(skill: string): RegExp {
  const cached = patterns.get(skill);
  if (cached) return cached;
  // Word boundaries only on alphanumeric ends, so "C#" and "C++" still match,
  // while "Java" does not match inside "JavaScript" and "SQL" not inside
  // "MySQL" (same rule as the Dart matcher).
  const before = isWordChar(skill[0]) ? '(?<![A-Za-z0-9])' : '';
  const after = isWordChar(skill[skill.length - 1]) ? '(?![A-Za-z0-9])' : '';
  const pattern = new RegExp(
    `${before}${escapeRegExp(skill)}${after}`,
    'i',
  );
  patterns.set(skill, pattern);
  return pattern;
}

/**
 * The known skills [text] mentions, in order of first mention. A skill that is
 * part of a longer match is dropped (`React` when the text says
 * `React Native`).
 */
export function findKnownSkills(
  text: string,
  vocabulary: readonly string[] = KNOWN_SKILLS,
): string[] {
  if (typeof text !== 'string' || text.length === 0) return [];

  const found = new Map<string, number>();
  for (const skill of vocabulary) {
    const match = patternFor(skill).exec(text);
    if (match) found.set(skill, match.index);
  }

  for (const skill of [...found.keys()]) {
    const shadowed = [...found.keys()].some(
      (other) =>
        other !== skill &&
        other.length > skill.length &&
        patternFor(skill).test(other),
    );
    if (shadowed) found.delete(skill);
  }

  return [...found.entries()]
    .sort((a, b) => a[1] - b[1])
    .map(([skill]) => skill);
}
