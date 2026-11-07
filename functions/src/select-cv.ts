import { logger } from 'firebase-functions';
import { HttpsError } from 'firebase-functions/v2/https';

import {
  assertOwnedCvPath,
  MIN_CV_TEXT_LENGTH,
} from './cv-shared';
import { parseInternshipDocument } from './match-cv';
import { requirementsFromInternship, scoreMatch } from './match-cv-score';
import { findKnownSkills } from './skills';

/** The library cap from G-33: the app never sends more than this. */
export const MAX_CVS = 10;

/** One CV as the model sees it: its score, not the file itself. */
export interface SelectCandidate {
  storagePath: string;
  percent: number;
  matchedCount: number;
  totalRequired: number;
  matched: string[];
  missing: string[];
  cvReadable: boolean;
}

export interface SelectCvRequest {
  auth?: { uid?: string } | null;
  data?: unknown;
}

export interface SelectCvDeps {
  downloadPdf: (storagePath: string) => Promise<Buffer>;
  extractText: (pdf: Buffer) => Promise<string>;
  askModel: (prompt: string, apiKey: string) => Promise<string>;
  loadInternship: (key: string) => Promise<Record<string, unknown> | null>;
  loadProfileSkills: (uid: string) => Promise<string[]>;
}

export interface SelectCvResponse {
  storagePath: string;
  percent: number;
  matchedCount: number;
  totalRequired: number;
  reason: string;
  cvReadable: boolean;
}

export const SELECT_RUBRIC = `You explain to a student why one of their CVs is the best
fit for one internship. You never invent skills or experience.

Reply with strict JSON only, without markdown:
{"reason": "one short, honest sentence, at most 160 characters"}

Rules:
- Mention the CV that was chosen, not the others.
- Use only the skills listed below; never add a skill that is not listed.
- If the chosen CV covers every requirement, say so plainly.
- Be encouraging but factual. Do not claim the student has experience they
  have not shown.`;

function readInternshipKey(data: unknown): string {
  if (typeof data !== 'object' || data === null) {
    throw new HttpsError('invalid-argument', 'An internship is required.');
  }
  const raw = (data as Record<string, unknown>).internshipKey;
  if (typeof raw !== 'string' || raw.trim() === '') {
    throw new HttpsError('invalid-argument', 'An internship is required.');
  }
  return raw.trim();
}

/** Every path must belong to the caller; no path is ever taken from a payload. */
function readCvPaths(uid: string | undefined, data: unknown): string[] {
  if (typeof data !== 'object' || data === null) {
    throw new HttpsError('invalid-argument', 'Your CV library is required.');
  }
  const raw = (data as Record<string, unknown>).cvPaths;
  if (!Array.isArray(raw) || raw.length === 0) {
    throw new HttpsError('invalid-argument', 'Your CV library is required.');
  }
  if (raw.length > MAX_CVS) {
    throw new HttpsError('invalid-argument', 'You can compare up to 10 CVs.');
  }
  return raw.map((entry) => assertOwnedCvPath(uid, entry));
}

function readDefaultPath(
  uid: string | undefined,
  data: unknown,
  cvPaths: string[],
): string | null {
  const raw = (data as Record<string, unknown>).defaultPath;
  if (raw === undefined || raw === null) return null;
  const path = assertOwnedCvPath(uid, raw);
  return cvPaths.includes(path) ? path : null;
}

function buildReasonPrompt(options: {
  title: string;
  companyName: string;
  best: SelectCandidate;
  candidates: SelectCandidate[];
}): string {
  const others = options.candidates
    .filter((cv) => cv.storagePath !== options.best.storagePath)
    .map(
      (cv) =>
        `${cv.matchedCount}/${cv.totalRequired} (${cv.percent}%)`,
    )
    .join(', ');
  return [
    `Internship: ${options.title}${
      options.companyName ? ` at ${options.companyName}` : ''
    }`,
    `Chosen CV matched: ${options.best.matched.join(', ') || 'none'}`,
    `Chosen CV gaps: ${options.best.missing.join(', ') || 'none'}`,
    `Other CVs scored: ${others || 'none'}`,
    'Write one sentence explaining why the chosen CV fits best.',
  ].join('\n');
}

/** Reads `{"reason": "..."}` without trusting the model output. */
export function parseSelectionReason(value: string): string | null {
  try {
    const parsed: unknown = JSON.parse(value);
    if (typeof parsed !== 'object' || parsed === null) return null;
    const reason = (parsed as Record<string, unknown>).reason;
    if (typeof reason !== 'string') return null;
    const text = reason.trim();
    if (text === '') return null;
    return text.length > 200 ? `${text.slice(0, 197)}...` : text;
  } catch {
    return null;
  }
}

/** The reason used when the model is unavailable or returns nothing useful. */
export function fallbackReason(best: SelectCandidate): string {
  if (best.totalRequired === 0) {
    return 'This internship does not list specific skills to compare.';
  }
  if (best.missing.length === 0) {
    return 'This CV covers every skill the internship lists.';
  }
  return `This CV matches ${best.matchedCount} of ${best.totalRequired} required skills, more than your other CVs.`;
}

/**
 * Automatic CV selection for the Apply Form (G-33 item 8).
 *
 * Scoring is deterministic: each CV's text is read server-side, its known
 * skills are scored against the internship requirements together with the
 * Profile skills, and the highest score wins. A tie prefers the student's
 * default CV. Groq only writes the one-sentence reason; any model failure
 * falls back to a deterministic sentence, so the call never blocks applying.
 */
export async function handleSelectCv(
  request: SelectCvRequest,
  deps: SelectCvDeps,
  apiKey: string,
): Promise<SelectCvResponse> {
  const uid = request.auth?.uid;
  const internshipKey = readInternshipKey(request.data);
  const cvPaths = readCvPaths(uid, request.data);
  const defaultPath = readDefaultPath(uid, request.data, cvPaths);

  let internship: Record<string, unknown> | null;
  try {
    internship = await deps.loadInternship(internshipKey);
  } catch (error) {
    logger.error('selectCv: could not read the internship', {
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

  const requirements = requirementsFromInternship(parsed);
  const profileSkills = await deps.loadProfileSkills(uid as string);

  const candidates: SelectCandidate[] = [];
  for (const storagePath of cvPaths) {
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
      // One unreadable file must not fail the whole comparison: it is
      // scored on the Profile skills alone and marked unreadable.
      cvReadable = false;
      logger.warn('selectCv: CV text unavailable', {
        internshipKey,
        error: error instanceof Error ? error.message : String(error),
      });
    }
    const score = scoreMatch({
      requiredSkills: requirements.required,
      profileSkills,
      cvSkills: cvReadable ? findKnownSkills(cvText) : [],
    });
    candidates.push({
      storagePath,
      percent: score.percent,
      matchedCount: score.matchedCount,
      totalRequired: score.totalRequired,
      matched: score.matched,
      missing: score.missing,
      cvReadable,
    });
  }

  let best = candidates[0];
  for (const candidate of candidates) {
    if (candidate.percent > best.percent) {
      best = candidate;
    } else if (candidate.percent === best.percent && candidate.storagePath === defaultPath) {
      best = candidate;
    }
  }
  if (requirements.required.length === 0 && defaultPath) {
    best = candidates.find((cv) => cv.storagePath === defaultPath) ?? best;
  }

  let reason = fallbackReason(best);
  if (apiKey.trim() !== '' && candidates.length > 1) {
    try {
      const raw = await deps.askModel(
        buildReasonPrompt({
          title: parsed.title,
          companyName: parsed.companyName,
          best,
          candidates,
        }),
        apiKey,
      );
      const parsedReason = parseSelectionReason(raw);
      if (parsedReason) {
        reason = parsedReason;
      } else {
        logger.warn('selectCv: unparseable reason, using fallback');
      }
    } catch (error) {
      logger.warn('selectCv: model request failed, using fallback reason', {
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  logger.info('selectCv: result', {
    internshipKey,
    cvCount: candidates.length,
    bestPercent: best.percent,
    usedDefault: defaultPath !== null && best.storagePath === defaultPath,
  });

  return {
    storagePath: best.storagePath,
    percent: best.percent,
    matchedCount: best.matchedCount,
    totalRequired: best.totalRequired,
    reason,
    cvReadable: best.cvReadable,
  };
}
