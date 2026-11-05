import { getStorage } from 'firebase-admin/storage';
import { HttpsError } from 'firebase-functions/v2/https';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { PDFParse } from 'pdf-parse';

/**
 * Gemini model for the blocking Validate CV callable (G-26, zero-cost
 * decision). The advisory CV Match commentary uses Groq (`groq.ts`).
 *
 * The `-latest` alias is deliberate: pinned versions are retired and then
 * answer `404 Not Found` (`gemini-2.5-flash-lite` did on 2026-11-03, while
 * `gemini-flash-lite-latest` kept working), which blocked every CV check.
 */
export const GEMINI_MODEL = 'gemini-flash-lite-latest';

/** Below this, a PDF is treated as unreadable without spending Gemini quota. */
export const MIN_CV_TEXT_LENGTH = 50;

/** Keeps prompts inside the free-tier request size and cost. */
export const MAX_CV_TEXT_LENGTH = 12_000;

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

export interface GeminiRequest {
  text: string;
  apiKey: string;
  rubric: string;
  /** Characters of [text] sent to the model; defaults to the CV prompt cap. */
  maxLength?: number;
}

/** Sends [text] to Gemini with [rubric] and returns the raw model output. */
export async function askGeminiWithRubric({
  text,
  apiKey,
  rubric,
  maxLength = MAX_CV_TEXT_LENGTH,
}: GeminiRequest): Promise<string> {
  const model = new GoogleGenerativeAI(apiKey).getGenerativeModel({
    model: GEMINI_MODEL,
    generationConfig: { temperature: 0, responseMimeType: 'application/json' },
  });
  const result = await model.generateContent([
    { text: rubric },
    { text: text.slice(0, maxLength) },
  ]);
  return result.response.text();
}

export function readStoragePath(data: unknown): unknown {
  if (typeof data !== 'object' || data === null) return undefined;
  return (data as Record<string, unknown>).storagePath;
}
