import assert from 'node:assert/strict';
import test from 'node:test';

import {
  chunk,
  normaliseMessageId,
  requireText,
  summariseSend,
  toIso,
  validateRoute,
} from '../lib/admin.js';

test('validateRoute accepts paths under a known tab', () => {
  assert.deepEqual(validateRoute('/saved'), { value: '/saved' });
  assert.deepEqual(validateRoute('/home/internships/abc123'), {
    value: '/home/internships/abc123',
  });
  assert.deepEqual(validateRoute(' /applications?tab=all '), {
    value: '/applications?tab=all',
  });
  assert.deepEqual(validateRoute(''), { value: null });
  assert.deepEqual(validateRoute(undefined), { value: null });
});

test('validateRoute rejects URLs, unknown tabs and relative paths', () => {
  assert.match(validateRoute('https://example.com').error, /absolute in-app/);
  assert.match(validateRoute('//evil.example').error, /absolute in-app/);
  assert.match(validateRoute('saved').error, /start with/);
  assert.match(validateRoute('/settings').error, /must start with one of/);
  assert.match(validateRoute(42).error, /string/);
});

test('chunk splits into capped groups', () => {
  assert.deepEqual(chunk([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
  assert.deepEqual(chunk([], 500), []);
  assert.throws(() => chunk([1], 0), /positive integer/);
});

test('requireText trims, rejects blank and caps the length', () => {
  assert.deepEqual(requireText('  hello  ', 10), { value: 'hello' });
  assert.match(requireText('   ', 10).error, /required/);
  assert.match(requireText(null, 10).error, /required/);
  assert.match(requireText('toolong', 3).error, /under 3/);
});

test('toIso renders Dates, ISO strings and nulls', () => {
  const date = new Date('2026-11-06T10:00:00.000Z');
  assert.equal(toIso(date), '2026-11-06T10:00:00.000Z');
  assert.equal(toIso('2026-11-06T10:00:00.000Z'), '2026-11-06T10:00:00.000Z');
  assert.equal(toIso('not a date'), null);
  assert.equal(toIso(null), null);
});

test('summariseSend keeps successes and failure codes', () => {
  assert.deepEqual(
    summariseSend([
      { success: true, messageId: 'm1' },
      { success: false, error: { code: 'messaging/registration-token-not-registered' } },
    ]),
    [
      { ok: true, messageId: 'm1' },
      { ok: false, error: 'messaging/registration-token-not-registered' },
    ],
  );
});

test('normaliseMessageId keeps the trailing ID the app stores', () => {
  assert.equal(
    normaliseMessageId(
      'projects/prm-lab3/messages/0:1793903803901195%e4b5a4cce4b5a4cc',
    ),
    '0:1793903803901195%e4b5a4cce4b5a4cc',
  );
  assert.equal(normaliseMessageId('plain-id'), 'plain-id');
  assert.equal(normaliseMessageId('  '), null);
  assert.equal(normaliseMessageId(null), null);
  assert.equal(normaliseMessageId(42), null);
});
