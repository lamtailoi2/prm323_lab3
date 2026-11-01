import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions';
import { HttpsError } from 'firebase-functions/v2/https';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { PDFParse } from 'pdf-parse';

/**
 * Free-tier Gemini model chosen under G-26 (zero-cost decision). Reuse the
 * same provider as ARTEMIS rather than introducing a second one.
 */
export const GEMINI_MODEL = 'gemini-2.5-flash-lite';

/** Below this, a PDF is treated as unreadable without spending Gemini quota. */
export const MIN_CV_TEXT_LENGTH = 50;

/** Keeps prompts inside the free-tier request size and cost. */
const MAX_CV_TEXT_LENGTH = 12_000;

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
 * Checks that the caller owns the CV path. The UID always comes from the
 * callable's auth context, never from the client payload.
 */
export function assertOwnedCvPath(
  uid: string | undefined,
  storagePath: unknown,
): string {
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Sign in to validate a CV.');
  }
  if (typeof storagePath !== 'string' || storagePath.trim() === '') {
    throw new HttpsError('invalid-argument', 'A CV file path is required.');
  }

  const path = storagePath.trim();
  const prefix = `cvs/${uid}/`;
  const fileName = path.slice(prefix.length);

  if (
    !path.startsWith(prefix) ||
    fileName.length === 0 ||
    path.includes('..') ||
    path.includes('//')
  ) {
    throw new HttpsError(
      'permission-denied',
      'You can only validate your own CV.',
    );
  }
  return path;
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
    throw new HttpsError(
      'unavailable',
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

/** Downloads an object from the default Storage bucket (Admin SDK). */
export async function downloadPdfFromStorage(
  storagePath: string,
): Promise<Buffer> {
  const [contents] = await getStorage().bucket().file(storagePath).download();
  return contents;
}

/** Extracts plain text from a PDF buffer. */
export async function extractPdfText(pdfBytes: Buffer): Promise<string> {
  const parser = new PDFParse({ data: pdfBytes });
  try {
    const result = await parser.getText();
    return result.text;
  } finally {
    await parser.destroy();
  }
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
  const model = new GoogleGenerativeAI(apiKey).getGenerativeModel({
    model: GEMINI_MODEL,
    generationConfig: { temperature: 0, responseMimeType: 'application/json' },
  });
  const result = await model.generateContent([
    { text: RUBRIC },
    { text: `CV text follows:\n\n${cvText}` },
  ]);
  return result.response.text();
}

function readStoragePath(data: unknown): unknown {
  if (typeof data !== 'object' || data === null) return undefined;
  return (data as Record<string, unknown>).storagePath;
}
