import { logger } from 'firebase-functions';
import { HttpsError } from 'firebase-functions/v2/https';

import {
  askGeminiWithRubric,
  assertOwnedCvPath,
  MAX_CV_TEXT_LENGTH,
  MIN_CV_TEXT_LENGTH,
  readStoragePath,
} from './cv-shared';

// Kept exported here because the function tests and index.ts import them from
// this module; the implementations live in cv-shared.ts so the CV Match
// callable can reuse them.
export {
  assertOwnedCvPath,
  downloadPdfFromStorage,
  extractPdfText,
  GEMINI_MODEL,
  MIN_CV_TEXT_LENGTH,
} from './cv-shared';

const DEFAULT_INVALID_REASON =
  'This file does not look like a usable CV. Update your CV and try again.';

export interface ValidateCvResult {
  isValid: boolean;
  reason?: string;
}

/** The parts of a callable request this handler needs (keeps tests light). */
export interface ValidateCvRequest {
  auth?: { uid?: string } | null;
  data?: unknown;
}

/**
 * Every external effect is injected so tests can run without Storage, Gemini
 * or a Firebase project.
 */
export interface ValidateCvDeps {
  downloadPdf: (storagePath: string) => Promise<Buffer>;
  extractText: (pdf: Buffer) => Promise<string>;
  askGemini: (cvText: string, apiKey: string) => Promise<string>;
}

/**
 * Reads `{ "isValid": boolean, "reason"?: string }` from model output.
 * Returns `null` when the output is not usable JSON, so the caller can fail
 * open instead of blocking a real application on a formatting glitch.
 */
export function parseValidationResponse(raw: string): ValidateCvResult | null {
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
  const isValid = record.isValid;
  if (typeof isValid !== 'boolean') return null;

  if (isValid) return { isValid: true };

  const rawReason = record.reason;
  const reason =
    typeof rawReason === 'string' ? rawReason.trim().slice(0, 240) : '';
  return { isValid: false, reason: reason || DEFAULT_INVALID_REASON };
}

/**
 * Generic CV quality gate that can block submission (unlike the advisory CV
 * Match Check): is this PDF readable and does it look like a CV?
 */
export async function handleValidateCv(
  request: ValidateCvRequest,
  deps: ValidateCvDeps,
  apiKey: string,
): Promise<ValidateCvResult> {
  const storagePath = assertOwnedCvPath(
    request.auth?.uid,
    readStoragePath(request.data),
  );

  if (apiKey.trim() === '') {
    logger.error('validateCv: GEMINI_API_KEY is not configured');
    throw new HttpsError(
      'failed-precondition',
      'CV validation is not configured.',
    );
  }

  let pdf: Buffer;
  try {
    pdf = await deps.downloadPdf(storagePath);
  } catch (error) {
    logger.error('validateCv: download failed', { storagePath, error });
    throw new HttpsError(
      'not-found',
      'We could not read your CV. Upload it again and retry.',
    );
  }

  let text: string;
  try {
    text = await deps.extractText(pdf);
  } catch (error) {
    logger.error('validateCv: PDF text extraction failed', { error });
    throw new HttpsError(
      'invalid-argument',
      'This file could not be read as a PDF. Upload a text-based PDF and try again.',
    );
  }

  const cvText = text.trim();
  if (cvText.length < MIN_CV_TEXT_LENGTH) {
    return {
      isValid: false,
      reason: 'CV appears to be empty or unreadable.',
    };
  }

  let raw: string;
  try {
    raw = await deps.askGemini(
      cvText.slice(0, MAX_CV_TEXT_LENGTH),
      apiKey,
    );
  } catch (error) {
    logger.error('validateCv: Gemini request failed', { error });
    // `failed-precondition`: the model provider is not working, not the
    // student's connection, so the app must not tell them to check it.
    throw new HttpsError(
      'failed-precondition',
      'CV validation is unavailable right now. Please try again.',
    );
  }

  const result = parseValidationResponse(raw);
  if (result === null) {
    // Fail open: the model's formatting must not block a real application.
    logger.warn('validateCv: unparseable Gemini response, failing open', {
      sample: raw.slice(0, 200),
    });
    return { isValid: true };
  }
  return result;
}

const RUBRIC = `You are a strict CV screening assistant for a student internship app.
Decide whether the supplied document is a usable CV/resume.

Treat it as a valid CV only when the text clearly comes from a CV/resume and
shows some identifiable structure: contact details plus at least one of work
experience, education, projects or skills. A cover letter, an unrelated
document, random text, or unreadable text is not a valid CV.

Reply with strict JSON only, without markdown:
{"isValid": true or false, "reason": "one short sentence"}
When isValid is true, reason may be an empty string. When false, explain in
plain English what is missing, at most 160 characters.`;

/** Sends the CV text to Gemini with a fixed, non-job-specific rubric. */
export async function askGemini(
  cvText: string,
  apiKey: string,
): Promise<string> {
  return askGeminiWithRubric({ text: cvText, apiKey, rubric: RUBRIC });
}
