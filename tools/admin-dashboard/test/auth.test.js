import assert from 'node:assert/strict';
import test from 'node:test';

import { isAllowedAdmin, parseAdminEmails } from '../lib/auth.js';

test('parseAdminEmails trims, lowercases and drops empty entries', () => {
  assert.deepEqual(
    [...parseAdminEmails(' Admin@Example.com , ops@example.com, ,')],
    ['admin@example.com', 'ops@example.com'],
  );
  assert.equal(parseAdminEmails('').size, 0);
  assert.equal(parseAdminEmails(undefined).size, 0);
});

test('isAllowedAdmin requires a verified allowlisted email', () => {
  const allowlist = parseAdminEmails('admin@example.com');

  assert.equal(
    isAllowedAdmin(
      { email: 'Admin@Example.com', email_verified: true },
      allowlist,
    ),
    true,
  );
  assert.equal(
    isAllowedAdmin(
      { email: 'admin@example.com', email_verified: false },
      allowlist,
    ),
    false,
  );
  assert.equal(
    isAllowedAdmin({ email: 'other@example.com', email_verified: true }, allowlist),
    false,
  );
  assert.equal(isAllowedAdmin({ email_verified: true }, allowlist), false);
  assert.equal(isAllowedAdmin(null, allowlist), false);
});
