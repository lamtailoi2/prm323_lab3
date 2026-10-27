import { Firestore, FieldValue, Timestamp } from 'firebase-admin/firestore';

import {
  EXPIRY_DAYS,
  KEYWORDS,
  LOCATION,
  PAGES_PER_KEYWORD,
} from './config';
import { jobKeyFor } from './job-key';
import { fetchJobs } from './serp';
import { selectKeywords, SyncConfig } from './selection';

const DAY_MS = 24 * 60 * 60 * 1000;
const FIRESTORE_BATCH_LIMIT = 450;

export interface SyncResult {
  keywords: string[];
  fetched: number;
  written: number;
  expiredDeleted: number;
  backfill: boolean;
}

/**
 * Pulls one page per due keyword and upserts `/internships/{jobKey}`.
 *
 * The raw SerpAPI job is stored unchanged so the Flutter parser stays the
 * single source of listing fields; sync metadata adds the keyword, rank and
 * expiry used by Home.
 */
export async function syncInternships(
  db: Firestore,
  apiKey: string,
  now: Date = new Date(),
): Promise<SyncResult> {
  const configRef = db.collection('sync').doc('config');
  const configSnapshot = await configRef.get();
  const config = (configSnapshot.data() ?? {}) as SyncConfig;
  const selection = selectKeywords(
    KEYWORDS,
    configSnapshot.exists ? config : undefined,
  );

  let fetched = 0;
  let written = 0;
  let expiredDeleted = 0;
  const expiresAt = Timestamp.fromDate(
    new Date(now.getTime() + EXPIRY_DAYS * DAY_MS),
  );

  for (const keyword of selection.keywords) {
    for (let page = 0; page < PAGES_PER_KEYWORD; page += 1) {
      const start = page * 20;
      const jobs = await fetchJobs({
        apiKey,
        keyword,
        location: LOCATION,
        start,
      });
      fetched += jobs.length;

      const batch = db.batch();
      for (const [index, job] of jobs.entries()) {
        const ref = db.collection('internships').doc(jobKeyFor(job.job_id));
        batch.set(
          ref,
          {
            raw: job,
            searchKeyword: keyword,
            searchLocation: LOCATION,
            searchRank: start + index,
            syncedAt: FieldValue.serverTimestamp(),
            expiresAt,
          },
          { merge: true },
        );
        written += 1;
      }
      if (jobs.length > 0) await batch.commit();
    }
  }

  const expired = await db
    .collection('internships')
    .where('expiresAt', '<=', Timestamp.fromDate(now))
    .limit(FIRESTORE_BATCH_LIMIT)
    .get();
  if (!expired.empty) {
    const batch = db.batch();
    for (const doc of expired.docs) batch.delete(doc.ref);
    await batch.commit();
    expiredDeleted = expired.size;
  }

  await configRef.set(
    {
      lastKeywordIndex: selection.nextIndex,
      ...(selection.backfill
        ? { lastBackfillAt: FieldValue.serverTimestamp() }
        : {}),
    },
    { merge: true },
  );

  await db
    .collection('sync')
    .doc('state')
    .set(
      {
        lastRunAt: FieldValue.serverTimestamp(),
        lastError: FieldValue.delete(),
        keywords: selection.keywords,
        fetched,
        written,
        expiredDeleted,
        backfill: selection.backfill,
      },
      { merge: true },
    );

  return {
    keywords: selection.keywords,
    fetched,
    written,
    expiredDeleted,
    backfill: selection.backfill,
  };
}
