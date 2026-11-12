// Emulator tests for firebase/firestore.rules.
// Run through `firebase emulators:exec --only firestore,storage --project demo-internly ...`
// (see firebase/tests/README.md).
import { readFileSync } from 'node:fs';
import { after, afterEach, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const PROJECT_ID = 'demo-internly';
const rules = readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8');

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules, host: '127.0.0.1', port: 8080 },
  });
});

after(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

describe('users/{uid}', () => {
  it('denies an unauthenticated client', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(db.doc('users/alice').get());
    await assertFails(db.doc('users/alice').set({ name: 'Alice' }));
  });

  it('lets the owner create, read, update and delete their document', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    const ref = db.doc('users/alice');

    await assertSucceeds(ref.set({ name: 'Alice', skills: [] }));
    await assertSucceeds(ref.update({ name: 'Alice Nguyen' }));
    await assertSucceeds(ref.get());
    await assertSucceeds(ref.delete());
  });

  it('denies another signed-in user', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('users/alice').set({ name: 'Alice' });
    });

    const bob = testEnv.authenticatedContext('bob').firestore();
    await assertFails(bob.doc('users/alice').get());
    await assertFails(bob.doc('users/alice').set({ name: 'Bob' }));
  });

  it('applies the same ownership to subcollections', async () => {
    const alice = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(alice.doc('users/alice/applications/app1').set({ status: 'applied' }));
    await assertSucceeds(alice.doc('users/alice/saved/int1').set({ savedAt: 1 }));

    const bob = testEnv.authenticatedContext('bob').firestore();
    await assertFails(bob.doc('users/alice/applications/app1').get());
    await assertFails(bob.doc('users/alice/applications/app2').set({ status: 'applied' }));
  });

  it('rejects a write with more than 50 fields', async () => {
    const alice = testEnv.authenticatedContext('alice').firestore();

    const fields = (count) =>
      Object.fromEntries(Array.from({ length: count }, (_, i) => [`f${i}`, i]));

    await assertSucceeds(alice.doc('users/alice').set(fields(50)));
    await assertFails(alice.doc('users/alice/extra/size51').set(fields(51)));
  });
});

describe('internships/{key}', () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().doc('internships/key1').set({ title: 'Flutter Intern' });
    });
  });

  it('lets a signed-in user read the shared pool', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertSucceeds(db.doc('internships/key1').get());
  });

  it('denies an unauthenticated read', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(db.doc('internships/key1').get());
  });

  it('denies every client write, even from a signed-in user', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertFails(db.doc('internships/key2').set({ title: 'Fake' }));
    await assertFails(db.doc('internships/key1').update({ title: 'Changed' }));
    await assertFails(db.doc('internships/key1').delete());
  });
});

describe('sync/{doc}', () => {
  it('is closed to clients', async () => {
    const db = testEnv.authenticatedContext('alice').firestore();
    await assertFails(db.doc('sync/state').get());
    await assertFails(db.doc('sync/state').set({ lastRun: 1 }));
  });
});
