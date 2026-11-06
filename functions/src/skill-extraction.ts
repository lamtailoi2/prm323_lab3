import { findKnownSkills } from './skills';

/** Technology lists extracted from one CV and one job description. */
export interface SkillExtraction {
  cvSkills: string[];
  jobSkills: string[];
  jobNiceToHave: string[];
}

const MAX_PER_LIST = 40;
const MAX_JOB_TEXT = 6_000;
const MAX_CV_TEXT = 8_000;

export const SKILL_EXTRACTION_RUBRIC = `You extract technology skills from a job description and a CV
for a student internship app.

Reply with strict JSON only, without markdown:
{"cvSkills": [], "jobSkills": [], "jobNiceToHave": []}

Rules:
- Include only concrete technologies: programming languages, frameworks, libraries,
  databases, cloud platforms, developer tools and technical platforms.
- Exclude soft skills ("communication", "teamwork"), degrees, years of study,
  natural languages ("English") and benefits.
- Use canonical names: "JavaScript" (not JS), "TypeScript" (not TS),
  "PostgreSQL" (not Postgres), "Node.js" (not Node), "React" (not ReactJS),
  "REST API" (not REST), "Kubernetes" (not K8s), "Google Cloud" (not GCP).
- Remove duplicates; keep the order of first mention; at most 40 per list.
- cvSkills: technologies the CV text shows evidence for. Do not infer a skill
  that the CV does not mention.
- jobSkills: technologies the internship requires or expects.
- jobNiceToHave: technologies the job text marks as optional, preferred,
  "nice to have", "plus" or "bonus". When unclear, put it in jobSkills.`;

/** Maps common variants to one canonical spelling; keys are normalized. */
const ALIASES: Record<string, string> = {
  js: 'JavaScript',
  javascript: 'JavaScript',
  ecmascript: 'JavaScript',
  ts: 'TypeScript',
  typescript: 'TypeScript',
  node: 'Node.js',
  nodejs: 'Node.js',
  react: 'React',
  reactjs: 'React',
  reactnative: 'React Native',
  nextjs: 'Next.js',
  vue: 'Vue',
  vuejs: 'Vue',
  angular: 'Angular',
  postgres: 'PostgreSQL',
  postgresql: 'PostgreSQL',
  psql: 'PostgreSQL',
  mysql: 'MySQL',
  mongo: 'MongoDB',
  mongodb: 'MongoDB',
  k8s: 'Kubernetes',
  kubernetes: 'Kubernetes',
  aws: 'AWS',
  amazonwebservices: 'AWS',
  azure: 'Azure',
  gcp: 'Google Cloud',
  googlecloud: 'Google Cloud',
  rest: 'REST API',
  restapi: 'REST API',
  golang: 'Golang',
  go: 'Golang',
  csharp: 'C#',
  cplusplus: 'C++',
  cpp: 'C++',
  dotnet: '.NET',
  net: '.NET',
  aspnet: 'ASP.NET',
  sql: 'SQL',
  machinelearning: 'Machine Learning',
  ml: 'Machine Learning',
  html: 'HTML',
  css: 'CSS',
  flutter: 'Flutter',
  dart: 'Dart',
  java: 'Java',
  kotlin: 'Kotlin',
  swift: 'Swift',
  python: 'Python',
  django: 'Django',
  fastapi: 'FastAPI',
  php: 'PHP',
  laravel: 'Laravel',
  springboot: 'Spring Boot',
  redis: 'Redis',
  firebase: 'Firebase',
  docker: 'Docker',
  git: 'Git',
  linux: 'Linux',
  graphql: 'GraphQL',
  figma: 'Figma',
};

function normalizeKey(value: string): string {
  return value.toLowerCase().replace(/[\s._-]+/g, '');
}

/** Canonical spelling for a technology name, or `null` when it is empty. */
export function canonicalSkill(value: string): string | null {
  const text = value.trim().replace(/\s+/g, ' ');
  if (!text) return null;
  const canonical = ALIASES[normalizeKey(text)] ?? text;
  return canonical.length > 60 ? canonical.slice(0, 60) : canonical;
}

function cleanList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  const seen = new Set<string>();
  const out: string[] = [];
  for (const entry of value) {
    if (typeof entry !== 'string') continue;
    const canonical = canonicalSkill(entry);
    if (!canonical) continue;
    const key = canonical.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(canonical);
    if (out.length >= MAX_PER_LIST) break;
  }
  return out;
}

/**
 * Reads `{ cvSkills, jobSkills, jobNiceToHave }` from model output. Returns
 * `null` when the output is unusable, so the caller falls back to the local
 * vocabulary instead of failing the advisory step.
 */
export function parseSkillExtraction(raw: string): SkillExtraction | null {
  if (typeof raw !== 'string' || raw.trim() === '') return null;
  const start = raw.indexOf('{');
  const end = raw.lastIndexOf('}');
  if (start === -1 || end <= start) return null;

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw.slice(start, end + 1));
  } catch {
    return null;
  }
  if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
    return null;
  }
  const record = parsed as Record<string, unknown>;
  const result: SkillExtraction = {
    cvSkills: cleanList(record.cvSkills),
    jobSkills: cleanList(record.jobSkills),
    jobNiceToHave: cleanList(record.jobNiceToHave),
  };
  if (
    result.cvSkills.length === 0 &&
    result.jobSkills.length === 0 &&
    result.jobNiceToHave.length === 0
  ) {
    return null;
  }
  return result;
}

/** Local fallback when the extraction call is unavailable or unusable. */
export function vocabularyExtraction(
  jobText: string,
  cvText: string,
): SkillExtraction {
  return {
    cvSkills: findKnownSkills(cvText),
    jobSkills: findKnownSkills(jobText),
    jobNiceToHave: [],
  };
}

export function buildSkillExtractionPrompt(options: {
  jobText: string;
  cvText: string;
}): string {
  const job = options.jobText.slice(0, MAX_JOB_TEXT);
  const cv = options.cvText
    ? options.cvText.slice(0, MAX_CV_TEXT)
    : '(the CV text could not be read)';
  return [
    'JOB DESCRIPTION TEXT:',
    job,
    '',
    'CV TEXT:',
    cv,
  ].join('\n');
}

/** Case-insensitive union that keeps the first spelling. */
export function unionSkills(
  ...lists: (readonly string[])[]
): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const list of lists) {
    for (const skill of list) {
      const key = skill.toLowerCase();
      if (seen.has(key)) continue;
      seen.add(key);
      out.push(skill);
    }
  }
  return out;
}
