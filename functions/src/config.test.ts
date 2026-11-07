import assert from 'node:assert/strict';
import test from 'node:test';

import { EXPIRY_DAYS, KEYWORDS, PAGES_PER_KEYWORD } from './config';

test('keywords cover intern, fresher and junior listings', () => {
  assert.ok(KEYWORDS.length > 0);
  assert.ok(KEYWORDS.every((keyword) => keyword.trim().length > 0));
  assert.ok(KEYWORDS.some((keyword) => /intern/i.test(keyword)));
  assert.ok(KEYWORDS.some((keyword) => /fresher/i.test(keyword)));
  assert.ok(KEYWORDS.some((keyword) => /junior/i.test(keyword)));
});

test('the rotation fits the SerpAPI free plan and the expiry window', () => {
  const runsPerDay = 24 / 6;
  const searchesPerMonth = runsPerDay * 31 + KEYWORDS.length;
  assert.ok(
    searchesPerMonth <= 250,
    `${searchesPerMonth} searches/month exceed the free plan`,
  );
  assert.equal(PAGES_PER_KEYWORD, 1);
  assert.ok(KEYWORDS.length / runsPerDay <= EXPIRY_DAYS);
});
