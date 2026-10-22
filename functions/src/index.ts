import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { defineSecret } from 'firebase-functions/params';
import { onSchedule } from 'firebase-functions/v2/scheduler';

import { syncInternships } from './sync';

initializeApp();

const serpApiKey = defineSecret('SERPAPI_KEY');

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
