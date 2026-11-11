// Emulator tests for firebase/storage.rules.
// Run through `firebase emulators:exec --only firestore,storage --project demo-internly ...`
// (see firebase/tests/README.md).
import { readFileSync } from 'node:fs';
import { after, afterEach, before, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const PROJECT_ID = 'demo-internly';
const rules = readFileSync(new URL('../storage.rules', import.meta.url), 'utf8');

const pdf = () => new Uint8Array([0x25, 0x50, 0x44, 0x46]); // "%PDF"
const tenMb = 10 * 1024 * 1024;

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    storage: { rules, host: '127.0.0.1', port: 9199 },
  });
});

after(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearStorage();
});

describe('reports/{uid} and cvs/{uid}', () => {
  it('lets the owner upload and read a PDF in both folders', async () => {
    const storage = testEnv.authenticatedContext('alice').storage();

    await assertSucceeds(
      storage.ref('reports/alice/report.pdf').put(pdf(), { contentType: 'application/pdf' }),
    );
    await assertSucceeds(
      storage.ref('cvs/alice/cv.pdf').put(pdf(), { contentType: 'application/pdf' }),
    );
    await assertSucceeds(storage.ref('reports/alice/report.pdf').getMetadata());
  });

  it('denies another signed-in user', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context
        .storage()
        .ref('reports/alice/report.pdf')
        .put(pdf(), { contentType: 'application/pdf' });
    });

    const bob = testEnv.authenticatedContext('bob').storage();
    await assertFails(bob.ref('reports/alice/report.pdf').getMetadata());
    await assertFails(
      bob.ref('reports/alice/other.pdf').put(pdf(), { contentType: 'application/pdf' }),
    );
  });

  it('denies an unauthenticated client', async () => {
    const storage = testEnv.unauthenticatedContext().storage();
    await assertFails(
      storage.ref('reports/alice/report.pdf').put(pdf(), { contentType: 'application/pdf' }),
    );
  });

  it('accepts only PDF content', async () => {
    const storage = testEnv.authenticatedContext('alice').storage();
    await assertFails(
      storage
        .ref('cvs/alice/cv.png')
        .put(new Uint8Array([0x89, 0x50, 0x4e, 0x47]), { contentType: 'image/png' }),
    );
    await assertFails(
      storage.ref('cvs/alice/cv.pdf').put(pdf(), { contentType: 'text/plain' }),
    );
  });

  it('rejects a PDF larger than 10 MB', async () => {
    const storage = testEnv.authenticatedContext('alice').storage();
    await assertFails(
      storage
        .ref('cvs/alice/huge.pdf')
        .put(new Uint8Array(tenMb + 1), { contentType: 'application/pdf' }),
    );
  });

  it('denies every other path', async () => {
    const storage = testEnv.authenticatedContext('alice').storage();
    await assertFails(
      storage.ref('public/announcement.pdf').put(pdf(), { contentType: 'application/pdf' }),
    );
    await assertFails(
      storage
        .ref('reports/alice/nested/deeper/report.pdf')
        .put(pdf(), { contentType: 'application/pdf' }),
    );
  });
});
