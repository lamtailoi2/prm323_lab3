/**
 * Search configuration for the scheduled SerpAPI sync.
 *
 * These five queries gave 40 distinct jobs for `location=Vietnam` in testing
 * (10 + 10 + 7 + 9 + 4), while `thực tập mobile` / `thực tập devops` returned
 * nothing. Keep the list at 3–5 searches: the first backfill is one search
 * per keyword, then one keyword per 6-hour run (~120/month), inside the
 * SerpAPI free plan (250/month).
 */
export const KEYWORDS: readonly string[] = [
  'IT internship Vietnam',
  'thực tập IT',
  'thực tập backend',
  'thực tập frontend',
  'thực tập data',
  'thực tập tester',
] as const;

/**
 * Fetch a nationwide pool; the app filters by the listing's stored location
 * (Ho Chi Minh City, Hanoi, …). Google Jobs needs a location to return jobs.
 */
export const LOCATION: string | undefined = 'Vietnam';

export const PAGES_PER_KEYWORD = 1;

export const EXPIRY_DAYS = 7;
