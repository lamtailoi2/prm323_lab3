/**
 * The first run backfills every keyword. Later runs fetch one keyword, moving
 * through the list, so a single bad keyword cannot starve the others.
 */
export interface KeywordSelection {
  keywords: string[];
  nextIndex: number;
  backfill: boolean;
}

export interface SyncConfig {
  lastKeywordIndex?: unknown;
}

export function selectKeywords(
  all: readonly string[],
  config: SyncConfig | undefined,
): KeywordSelection {
  if (all.length === 0) return { keywords: [], nextIndex: 0, backfill: false };

  const stored = config?.lastKeywordIndex;
  if (typeof stored !== 'number' || !Number.isInteger(stored)) {
    return { keywords: [...all], nextIndex: 0, backfill: true };
  }

  const index = ((stored % all.length) + all.length) % all.length;
  return {
    keywords: [all[index]],
    nextIndex: (index + 1) % all.length,
    backfill: false,
  };
}
