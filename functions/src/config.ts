/**
 * Search configuration for the scheduled SerpAPI sync.
 *
 * Eight queries cover interns, freshers and juniors for `location=Vietnam`:
 * the six intern queries plus one query per early-career level. The
 * first backfill is one search per keyword (8); after that one keyword per
 * 6-hour run (~120/month) refreshes each keyword every ~2 days, inside the
 * SerpAPI free plan (250/month) and the 7-day listing expiry.
 */
export const KEYWORDS: readonly string[] = [
  'IT internship Vietnam',
  'thực tập IT',
  'thực tập backend',
  'thực tập frontend',
  'thực tập data',
  'thực tập tester',
  'IT fresher Vietnam',
  'IT junior Vietnam',
] as const;

/**
 * Fetch a nationwide pool; the app filters by the listing's stored location
 * (Ho Chi Minh City, Hanoi, …). Google Jobs needs a location to return jobs.
 */
export const LOCATION: string | undefined = 'Vietnam';

export const PAGES_PER_KEYWORD = 1;

export const EXPIRY_DAYS = 7;
