import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { defineSecret } from 'firebase-functions/params';
import { onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { syncInternships } from './sync';
import { askGroq } from './groq';
import {
  handleMatchCv,
  loadInternshipFromFirestore,
  loadProfileSkillsFromFirestore,
  MATCH_RUBRIC,
} from './match-cv';
import { SKILL_EXTRACTION_RUBRIC } from './skill-extraction';
import {
  askGemini,
  downloadPdfFromStorage,
  extractPdfText,
  handleValidateCv,
} from './validate-cv';

initializeApp();

const serpApiKey = defineSecret('SERPAPI_KEY');

// Separate secret binding scoped only to `validateCv` (least privilege); the
// value comes from the same free-tier Gemini key as ARTEMIS (G-26).
const geminiApiKey = defineSecret('GEMINI_API_KEY');

// Groq serves only the advisory CV Match commentary. The blocking Validate CV
// gate stays on Gemini, so a Groq outage can never stop a submission.
const groqApiKey = defineSecret('GROQ_API_KEY');

/**
 * Fills the shared Firestore listing pool from SerpAPI every six hours.
 *
 * The key lives in Secret Manager (`firebase functions:secrets:set
 * SERPAPI_KEY`), never in the app or the repository.
 */
export const syncInternshipsJob = onSchedule(
  {
    schedule: 'every 6 hours',
    timeZone: 'Asia/Ho_Chi_Minh',
    secrets: [serpApiKey],
    retryCount: 0,
    timeoutSeconds: 540,
    memory: '256MiB',
  },
  async () => {
    const db = getFirestore();
    try {
      const result = await syncInternships(db, serpApiKey.value());
      logger.info('internship sync complete', result);
    } catch (error) {
      await db
        .collection('sync')
        .doc('state')
        .set(
          {
            lastRunAt: FieldValue.serverTimestamp(),
            lastError: error instanceof Error ? error.message : String(error),
          },
          { merge: true },
        );
      logger.error('internship sync failed', error);
      throw error;
    }
  },
);

/**
 * Generic CV quality gate for the Apply flow.
 *
 * The client sends only the Storage path of its own CV. The function reads it
 * with the Admin SDK, extracts text and asks Gemini whether the file looks
 * like a usable CV. The key never reaches the app.
 */
export const validateCv = onCall(
  {
    secrets: [geminiApiKey],
    timeoutSeconds: 60,
    memory: '256MiB',
  },
  (request) =>
    handleValidateCv(
      request,
      {
        downloadPdf: downloadPdfFromStorage,
        extractText: extractPdfText,
        askGemini,
      },
      geminiApiKey.value(),
    ),
);

const matchGroq = (prompt: string, apiKey: string) =>
  askGroq({ prompt, apiKey, system: MATCH_RUBRIC });

const extractGroq = (prompt: string, apiKey: string) =>
  askGroq({ prompt, apiKey, system: SKILL_EXTRACTION_RUBRIC });

/**
 * Advisory CV Match Check (G-24/DC-09).
 *
 * The score is computed from the internship document, the Profile skills and
 * the known skills found in the CV text; Groq only writes the summary and the
 * per-gap suggestions. It never blocks applying.
 */
export const matchCv = onCall(
  {
    secrets: [groqApiKey],
    timeoutSeconds: 60,
    memory: '256MiB',
  },
  (request) =>
    handleMatchCv(
      request,
      {
        downloadPdf: downloadPdfFromStorage,
        extractText: extractPdfText,
        askExtraction: extractGroq,
        askModel: matchGroq,
        loadInternship: loadInternshipFromFirestore,
        loadProfileSkills: loadProfileSkillsFromFirestore,
      },
      groqApiKey.value(),
    ),
);
