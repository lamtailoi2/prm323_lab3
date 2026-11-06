import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError } from 'firebase-functions/v2/https';

import {
  assertOwnedCvPath,
  downloadPdfFromStorage,
  extractPdfText,
  MIN_CV_TEXT_LENGTH,
  readStoragePath,
} from './cv-shared';
import {
  fallbackSuggestions,
  mergeSuggestions,
  parseMatchCommentary,
  requirementsFromInternship,
  scoreMatch,
  type MatchSuggestion,
} from './match-cv-score';
import {
  buildSkillExtractionPrompt,
  parseSkillExtraction,
  unionSkills,
} from './skill-extraction';
import { findKnownSkills } from './skills';

const MAX_COMMENTARY_CV_LENGTH = 8_000;

export interface MatchCvRequest {
  auth?: { uid?: string } | null;
  data?: unknown;
}

export interface MatchCvDeps {
  downloadPdf: (storagePath: string) => Promise<Buffer>;
  extractText: (pdf: Buffer) => Promise<string>;
  askExtraction: (prompt: string, apiKey: string) => Promise<string>;
  askModel: (prompt: string, apiKey: string) => Promise<string>;
  loadInternship: (key: string) => Promise<Record<string, unknown> | null>;
  loadProfileSkills: (uid: string) => Promise<string[]>;
}

export interface CvMatchResponse {
  internshipTitle: string;
  companyName: string;
  percent: number;
  matchedCount: number;
  totalRequired: number;
  matched: string[];
  missing: string[];
  niceToHave: string[];
  suggestions: MatchSuggestion[];
  summary: string;
  cvReadable: boolean;
}

export const MATCH_RUBRIC = `You write short, honest feedback for a student comparing their CV
with one internship's required skills. You never invent skills, experience or
qualifications, and you never tell the student to claim something they do not
have.

Reply with strict JSON only, without markdown:
{"summary": "at most two sentences, 240 characters", "suggestions": [{"skill": "one of the listed gaps", "text": "one specific, supportive sentence, 160 characters"}]}

Rules:
- Use only the gap names given below; never add a skill that is not listed.
- Write exactly one suggestion per gap.
- Base suggestions on what the CV actually shows; if the CV shows nothing
  relevant, suggest adding the skill only if the student has used it, or
  mentioning relevant coursework/projects.
- Do not repeat the skill name as the whole suggestion.`;

function readInternshipKey(data: unknown): string {
  if (typeof data !== 'object' || data === null) {
    throw new HttpsError('invalid-argument', 'An internship is required.');
  }
  const raw = (data as Record<string, unknown>).internshipKey;
  if (typeof raw !== 'string' || raw.trim() === '') {
    throw new HttpsError('invalid-argument', 'An internship is required.');
  }
  const key = raw.trim();
  if (key.length > 200 || key.includes('/')) {
    throw new HttpsError('invalid-argument', 'An internship is required.');
  }
  return key;
}

function stringOr(value: unknown, fallback: string): string {
  return typeof value === 'string' && value.trim() !== ''
    ? value.trim().slice(0, 200)
    : fallback;
}

interface ParsedInternship {
  title: string;
  companyName: string;
  skills: string[];
  highlights: { title: string; items: string[] }[];
  jobText: string;
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}

function parseHighlights(
  value: unknown,
): { title: string; items: string[] }[] {
  if (!Array.isArray(value)) return [];
  const out: { title: string; items: string[] }[] = [];
  for (const entry of value) {
    const section = asRecord(entry);
    if (!section) continue;
    const title = typeof section.title === 'string' ? section.title : '';
    const items = Array.isArray(section.items)
      ? section.items.filter(
          (item): item is string => typeof item === 'string',
        )
      : [];
    out.push({ title, items });
  }
  return out;
}

/**
 * Parses a `/internships/{key}` document written by the sync function.
 *
 * The document stores the raw SerpAPI object under `raw` and has no parsed
 * `title` / `skills` fields, so this mirrors `Internship.fromFirestore` in the
 * app: skills are the known skills found in the title, the highlight items and
 * the description. Returns `null` for a document without that shape.
 */
export function parseInternshipDocument(
  data: Record<string, unknown>,
): ParsedInternship | null {
  const raw = asRecord(data.raw);
  if (!raw) return null;

  const title = stringOr(raw.title, 'This internship');
  const companyName = stringOr(raw.company_name, '');
  const description =
    typeof raw.description === 'string' ? raw.description : '';
  const highlights = parseHighlights(raw.job_highlights);
  const jobText = [
    title,
    ...highlights.flatMap((section) => section.items),
    description,
  ].join('\n');
  const skills = findKnownSkills(jobText);

  return { title, companyName, skills, highlights, jobText };
}

function buildPrompt(options: {
  title: string;
  companyName: string;
  required: string[];
  matched: string[];
  missing: string[];
  niceToHave: string[];
  cvText: string;
}): string {
  const cv = options.cvText
    ? options.cvText.slice(0, MAX_COMMENTARY_CV_LENGTH)
    : '(the CV text could not be read)';
  return [
    `Internship: ${options.title}${
      options.companyName ? ` at ${options.companyName}` : ''
    }`,
    `Required skills: ${options.required.join(', ') || 'none listed'}`,
    `Already matched: ${options.matched.join(', ') || 'none'}`,
    `Gaps: ${options.missing.join(', ') || 'none'}`,
    `Nice to have: ${options.niceToHave.join(', ') || 'none'}`,
    'CV text follows:',
    cv,
  ].join('\n');
}

/**
 * Advisory, job-specific CV match (CV Match Check, G-24/DC-09).
 *
 * The score is deterministic: requirements come from the internship document,
 * and a skill counts as matched when it is in the Profile or detected in the
 * CV text. The model (Groq) only writes the summary and one suggestion per
 * gap; any model failure falls back to deterministic suggestions, and an
 * unreadable CV falls back to Profile skills instead of failing the step.
 */
export async function handleMatchCv(
  request: MatchCvRequest,
  deps: MatchCvDeps,
  apiKey: string,
): Promise<CvMatchResponse> {
  const uid = request.auth?.uid;
  const storagePath = assertOwnedCvPath(uid, readStoragePath(request.data));
  const internshipKey = readInternshipKey(request.data);

  let internship: Record<string, unknown> | null;
  try {
    internship = await deps.loadInternship(internshipKey);
  } catch (error) {
    logger.error('matchCv: could not read the internship', {
      internshipKey,
      error: error instanceof Error ? error.message : String(error),
    });
    throw new HttpsError(
      'unavailable',
      'We could not load this internship. Please try again.',
    );
  }
  if (!internship) {
    throw new HttpsError(
      'not-found',
      'This internship is no longer available.',
    );
  }

  const parsed = parseInternshipDocument(internship);
  if (!parsed) {
    throw new HttpsError(
      'not-found',
      'This internship is no longer available.',
    );
  }

  const internshipTitle = parsed.title;
  const companyName = parsed.companyName;
  const vocabularyRequirements = requirementsFromInternship(parsed);

  let cvText = '';
  let cvReadable = true;
  try {
    const pdf = await deps.downloadPdf(storagePath);
    cvText = (await deps.extractText(pdf)).trim();
    if (cvText.length < MIN_CV_TEXT_LENGTH) {
      cvReadable = false;
      cvText = '';
    }
  } catch (error) {
    // The step is advisory: a broken PDF must not dead-end the application.
    cvReadable = false;
    logger.warn('matchCv: CV text unavailable, using Profile skills only', {
      internshipKey,
      error: error instanceof Error ? error.message : String(error),
    });
  }

  let jobSkills = vocabularyRequirements.required;
  let niceToHave = vocabularyRequirements.niceToHave;
  let cvSkills = cvReadable ? findKnownSkills(cvText) : [];
  let extractedByModel = false;

  // The model reads both texts to catch technologies outside the local
  // vocabulary; the local vocabulary is unioned in so a model omission cannot
  // remove a skill the listing plainly names.
  if (apiKey.trim() !== '' && cvReadable) {
    try {
      const raw = await deps.askExtraction(
        buildSkillExtractionPrompt({ jobText: parsed.jobText, cvText }),
        apiKey,
      );
      const extraction = parseSkillExtraction(raw);
      if (extraction) {
        extractedByModel = true;
        jobSkills = unionSkills(extraction.jobSkills, jobSkills);
        niceToHave = unionSkills(extraction.jobNiceToHave, niceToHave);
        cvSkills = unionSkills(extraction.cvSkills, cvSkills);
      } else {
        logger.warn('matchCv: unparseable skill extraction, using vocabulary', {
          sample: raw.slice(0, 300),
        });
      }
    } catch (error) {
      logger.warn('matchCv: skill extraction failed, using vocabulary', {
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  // A skill named as optional in the job must not stay a hard requirement.
  const niceKeys = new Set(niceToHave.map((skill) => skill.toLowerCase()));
  const required = jobSkills.filter(
    (skill) => !niceKeys.has(skill.toLowerCase()),
  );
  const requiredKeys = new Set(required.map((skill) => skill.toLowerCase()));
  niceToHave = niceToHave.filter(
    (skill) => !requiredKeys.has(skill.toLowerCase()),
  );

  if (required.length === 0) {
    return {
      internshipTitle,
      companyName,
      percent: 0,
      matchedCount: 0,
      totalRequired: 0,
      matched: [],
      missing: [],
      niceToHave,
      suggestions: [],
      summary: 'This internship does not list specific skills to compare.',
      cvReadable,
    };
  }

  const profileSkills = await deps.loadProfileSkills(uid as string);
  const score = scoreMatch({
    requiredSkills: required,
    profileSkills,
    cvSkills,
  });

  let summary: string;
  let suggestions: MatchSuggestion[];

  if (score.missing.length === 0) {
    summary = 'Your CV covers every skill this internship lists.';
    suggestions = [];
  } else {
    const fallback = fallbackSuggestions(score.missing);
    summary = `You match ${score.matchedCount} of ${score.totalRequired} required skills. Review the gaps below.`;
    suggestions = fallback;

    if (apiKey.trim() !== '') {
      try {
        const raw = await deps.askModel(
          buildPrompt({
            title: internshipTitle,
            companyName,
            required,
            matched: score.matched,
            missing: score.missing,
            niceToHave,
            cvText,
          }),
          apiKey,
        );
        const commentary = parseMatchCommentary(raw, score.missing);
        if (commentary) {
          if (commentary.summary) summary = commentary.summary;
          suggestions = mergeSuggestions(
            score.missing,
            commentary.suggestions,
          );
        } else {
          logger.warn('matchCv: unparseable commentary, using fallback');
        }
      } catch (error) {
        logger.warn('matchCv: model request failed, using fallback suggestions', {
          error: error instanceof Error ? error.message : String(error),
        });
      }
    } else {
      logger.warn('matchCv: model key is not configured, using fallback');
    }
  }

  logger.info('matchCv: result', {
    internshipKey,
    matched: score.matchedCount,
    missing: score.missingCount,
    cvReadable,
    extractedByModel,
  });

  return {
    internshipTitle,
    companyName,
    percent: score.percent,
    matchedCount: score.matchedCount,
    totalRequired: score.totalRequired,
    matched: score.matched,
    missing: score.missing,
    niceToHave,
    suggestions,
    summary,
    cvReadable,
  };
}

/** Default dependency: the internship document written by the sync function. */
export async function loadInternshipFromFirestore(
  key: string,
): Promise<Record<string, unknown> | null> {
  const snapshot = await getFirestore().collection('internships').doc(key).get();
  if (!snapshot.exists) return null;
  return (snapshot.data() as Record<string, unknown> | undefined) ?? null;
}

/** Default dependency: the skills the student declared in Profile. */
export async function loadProfileSkillsFromFirestore(
  uid: string,
): Promise<string[]> {
  const snapshot = await getFirestore().collection('users').doc(uid).get();
  const skills = snapshot.get('skills');
  if (!Array.isArray(skills)) return [];
  return skills.filter(
    (entry): entry is string => typeof entry === 'string' && entry.trim() !== '',
  );
}

/** Default dependency: exports kept next to the other effects for clarity. */
export { downloadPdfFromStorage, extractPdfText };
