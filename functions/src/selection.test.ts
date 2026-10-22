import assert from 'node:assert/strict';
import test from 'node:test';

import { selectKeywords } from './selection';

const all = ['flutter', 'react', 'backend'];

test('the first run backfills every keyword', () => {
  assert.deepEqual(selectKeywords(all, undefined), {
    keywords: all,
    nextIndex: 0,
    backfill: true,
  });
});

test('later runs rotate through one keyword at a time', () => {
  assert.deepEqual(selectKeywords(all, { lastKeywordIndex: 2 }), {
    keywords: ['backend'],
    nextIndex: 0,
    backfill: false,
  });
  assert.deepEqual(selectKeywords(all, { lastKeywordIndex: 0 }), {
    keywords: ['flutter'],
    nextIndex: 1,
    backfill: false,
  });
});
