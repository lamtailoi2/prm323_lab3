import { findKnownSkills } from './skills';

export interface InternshipRequirements {
  required: string[];
  niceToHave: string[];
}

export interface MatchScore {
  matched: string[];
  missing: string[];
  matchedCount: number;
  missingCount: number;
  totalRequired: number;
  percent: number;
}

export interface MatchSuggestion {
  skill: string;
  text: string;
}

export interface MatchCommentary {
  summary: string;
  suggestions: MatchSuggestion[];
}

const NICE_TO_HAVE_TITLE = /nice to have|preferred|plus|bonus/i;

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

/** Trims to [max] characters at a word boundary, with a single ellipsis. */
function clip(value: string, max: number): string {
  const text = value.trim();
  if (text.length <= max) return text;
  const cut = text.slice(0, max - 1);
  const lastSpace = cut.lastIndexOf(' ');
  const base = (lastSpace > max * 0.6 ? cut.slice(0, lastSpace) : cut).replace(
    /[\s,;:.!?-]+$/,
    '',
  );
  return `${base}…`;
}

function stringList(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter(
    (entry): entry is string => typeof entry === 'string' && entry.trim() !== '',
  );
}

function uniqueSkills(skills: string[]): string[] {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const skill of skills) {
    const key = skill.trim().toLowerCase();
    if (!key || seen.has(key)) continue;
    seen.add(key);
    out.push(skill.trim());
  }
  return out;
}

/**
 * Splits a listing's known skills into required and nice-to-have.
 *
 * SerpAPI has no must-have/nice-to-have field, so a skill that appears only in
 * a `highlights` section whose title says "nice to have", "preferred", "plus"
 * or "bonus" is optional; everything else is required.
 */
export function requirementsFromInternship(
  data: unknown,
): InternshipRequirements {
  const record = asRecord(data) ?? {};
  const skills = uniqueSkills(stringList(record.skills));

  const niceText = stringList(
    Array.isArray(record.highlights)
      ? (record.highlights as unknown[]).flatMap((highlight) => {
          const section = asRecord(highlight);
          if (!section) return [];
          const title = typeof section.title === 'string' ? section.title : '';
          if (!NICE_TO_HAVE_TITLE.test(title)) return [];
          return stringList(section.items);
        })
      : [],
  ).join('\n');

  const niceSkills = new Set(
    findKnownSkills(niceText).map((skill) => skill.toLowerCase()),
  );

  const niceToHave: string[] = [];
  const required: string[] = [];
  for (const skill of skills) {
    (niceSkills.has(skill.toLowerCase()) ? niceToHave : required).push(skill);
  }
  return { required, niceToHave };
}

/** Rule-based score: Profile skills plus skills detected in the CV text. */
export function scoreMatch(options: {
  requiredSkills: string[];
  profileSkills: Iterable<string>;
  cvSkills: Iterable<string>;
}): MatchScore {
  const mine = new Set<string>();
  for (const skill of options.profileSkills) {
    mine.add(skill.trim().toLowerCase());
  }
  for (const skill of options.cvSkills) {
    mine.add(skill.trim().toLowerCase());
  }

  const matched: string[] = [];
  const missing: string[] = [];
  for (const skill of options.requiredSkills) {
    (mine.has(skill.toLowerCase()) ? matched : missing).push(skill);
  }

  const totalRequired = matched.length + missing.length;
  const percent =
    totalRequired === 0
      ? 0
      : Math.round((matched.length * 100) / totalRequired);

  return {
    matched,
    missing,
    matchedCount: matched.length,
    missingCount: missing.length,
    totalRequired,
    percent,
  };
}

/** One honest suggestion per gap; used when the model is unavailable. */
export function fallbackSuggestions(missing: string[]): MatchSuggestion[] {
  return missing.map((skill) => ({
    skill,
    text:
      `Add ${skill} to your skills if you have used it, or mention it in ` +
      'your CV.',
  }));
}

/**
 * Reads `{ "summary": string, "suggestions": [{ "skill", "text" }] }` from
 * model output. Suggestions for skills that are not actually missing are
 * dropped, so the model cannot invent a gap. Returns `null` when the output is
 * unusable (the caller then uses the deterministic fallback).
 */
export function parseMatchCommentary(
  raw: string,
  missingSkills: string[],
): MatchCommentary | null {
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
  const record = asRecord(parsed);
  if (!record) return null;

  const summary =
    typeof record.summary === 'string' ? clip(record.summary, 240) : '';

  const bySkill = new Map(
    missingSkills.map((skill) => [skill.toLowerCase(), skill]),
  );
  const suggestions: MatchSuggestion[] = [];
  const seen = new Set<string>();

  if (Array.isArray(record.suggestions)) {
    for (const entry of record.suggestions) {
      const item = asRecord(entry);
      if (!item) continue;
      const rawSkill = typeof item.skill === 'string' ? item.skill.trim() : '';
      const canonical = bySkill.get(rawSkill.toLowerCase());
      const text = typeof item.text === 'string' ? item.text.trim() : '';
      if (!canonical || !text || seen.has(canonical.toLowerCase())) continue;
      seen.add(canonical.toLowerCase());
      suggestions.push({ skill: canonical, text: clip(text, 160) });
    }
  }

  if (summary === '' && suggestions.length === 0) return null;
  return { summary, suggestions };
}

/** Fills suggestions the model did not return, keeping one per gap. */
export function mergeSuggestions(
  missing: string[],
  fromModel: MatchSuggestion[],
): MatchSuggestion[] {
  const found = new Map(
    fromModel.map((suggestion) => [
      suggestion.skill.toLowerCase(),
      suggestion,
    ]),
  );
  return missing.map(
    (skill) =>
      found.get(skill.toLowerCase()) ?? {
        skill,
        text:
          `Add ${skill} to your skills if you have used it, or mention it ` +
          'in your CV.',
      },
  );
}
