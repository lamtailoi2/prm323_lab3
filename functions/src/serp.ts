const SERP_API_URL = 'https://serpapi.com/search.json';

/** A Google Jobs result with the three fields the app requires. */
export interface SerpJob extends Record<string, unknown> {
  job_id: string;
  title: string;
  company_name: string;
}

export interface FetchJobsOptions {
  apiKey: string;
  keyword: string;
  /** Google Jobs location filter; omitted for the nationwide sync pool. */
  location?: string;
  start?: number;
}

/**
 * Calls SerpAPI's `google_jobs` engine. Errors are thrown so the scheduled
 * function can record the failure in `sync/state` and alert.
 */
export async function fetchJobs(
  options: FetchJobsOptions,
): Promise<SerpJob[]> {
  const response = await fetch(buildSearchUrl(options), {
    signal: AbortSignal.timeout(20_000),
  });
  if (!response.ok) {
    const body = await response.text().catch(() => '');
    throw new Error(`SerpAPI returned ${response.status}: ${body.slice(0, 300)}`);
  }

  const payload = (await response.json()) as {
    error?: unknown;
    jobs_results?: unknown;
  };
  if (typeof payload.error === 'string') {
    if (hasNoResults(payload.error)) return [];
    throw new Error(`SerpAPI error: ${payload.error}`);
  }
  return parseJobs(payload.jobs_results);
}

/** Builds the Google Jobs request; location is optional. */
export function buildSearchUrl({
  apiKey,
  keyword,
  location,
  start = 0,
}: FetchJobsOptions): URL {
  const url = new URL(SERP_API_URL);
  url.searchParams.set('engine', 'google_jobs');
  url.searchParams.set('q', keyword);
  if (location?.trim()) url.searchParams.set('location', location.trim());
  url.searchParams.set('gl', 'vn');
  url.searchParams.set('hl', 'vi');
  url.searchParams.set('start', String(start));
  url.searchParams.set('api_key', apiKey);
  return url;
}

/** SerpAPI reports an empty page as an error string, not as `jobs_results`. */
export function hasNoResults(message: string): boolean {
  return /hasn't returned any results/i.test(message);
}

/** Keeps valid results only; one malformed job must not fail a whole page. */
export function parseJobs(value: unknown): SerpJob[] {
  if (!Array.isArray(value)) return [];
  return value.filter(isSerpJob).map((job) => ({ ...job }));
}

function isSerpJob(value: unknown): value is SerpJob {
  if (typeof value !== 'object' || value === null) return false;
  const job = value as Record<string, unknown>;
  return (
    typeof job.job_id === 'string' &&
    job.job_id.trim().length > 0 &&
    typeof job.title === 'string' &&
    job.title.trim().length > 0 &&
    typeof job.company_name === 'string' &&
    job.company_name.trim().length > 0
  );
}
