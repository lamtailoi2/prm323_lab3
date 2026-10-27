import assert from 'node:assert/strict';
import test from 'node:test';

import { jobKeyFor } from './job-key';

test('jobKeyFor is a stable 16-character hex key', () => {
  const first = jobKeyFor('eyJqb2IiOiIxIn0=');
  assert.match(first, /^[0-9a-f]{16}$/);
  assert.equal(first, jobKeyFor('eyJqb2IiOiIxIn0='));
  assert.notEqual(first, jobKeyFor('another-id'));
});
