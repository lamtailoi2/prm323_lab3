// Local web harness for the Firebase rules tests: runs the same scenarios as
// the node:test files and streams each PASS/FAIL to the browser, so a screen
// recording can be used as evidence.
//
// Start together with the emulators:
//   firebase emulators:exec --only firestore,storage --project demo-internly \
//     "node firebase/tests/demo/server.mjs"
import { readFileSync } from 'node:fs';
import { createServer } from 'node:http';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';

const PORT = Number(process.env.DEMO_PORT ?? 5500);
const PROJECT_ID = 'demo-internly';
const firestoreRules = readFileSync(new URL('../../firestore.rules', import.meta.url), 'utf8');
const storageRules = readFileSync(new URL('../../storage.rules', import.meta.url), 'utf8');
const page = readFileSync(new URL('./index.html', import.meta.url), 'utf8');

const pdf = () => new Uint8Array([0x25, 0x50, 0x44, 0x46]); // "%PDF"
const tenMb = 10 * 1024 * 1024;

let testEnvPromise;
const testEnv = () => {
  testEnvPromise ??= initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: firestoreRules, host: '127.0.0.1', port: 8080 },
    storage: { rules: storageRules, host: '127.0.0.1', port: 9199 },
  });
  return testEnvPromise;
};

const scenarios = [
  {
    group: 'Firestore · users/{uid}',
    actor: 'signed out',
    expected: 'denied',
    action: 'Read users/alice',
    run: (env) => env.unauthenticatedContext().firestore().doc('users/alice').get(),
  },
  {
    group: 'Firestore · users/{uid}',
    actor: 'signed out',
    expected: 'denied',
    action: 'Create users/alice',
    run: (env) => env.unauthenticatedContext().firestore().doc('users/alice').set({ name: 'X' }),
  },
  {
    group: 'Firestore · users/{uid}',
    actor: 'alice',
    expected: 'allowed',
    action: 'Create, update, read and delete users/alice',
    run: async (env) => {
      const ref = env.authenticatedContext('alice').firestore().doc('users/alice');
      await assertSucceeds(ref.set({ name: 'Alice', skills: [] }));
      await assertSucceeds(ref.update({ name: 'Alice Nguyen' }));
      await assertSucceeds(ref.get());
      await assertSucceeds(ref.delete());
    },
  },
  {
    group: 'Firestore · users/{uid}',
    actor: 'bob',
    expected: 'denied',
    action: 'Read users/alice',
    run: async (env) => {
      await env.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc('users/alice').set({ name: 'Alice' });
      });
      return env.authenticatedContext('bob').firestore().doc('users/alice').get();
    },
  },
  {
    group: 'Firestore · users/{uid}',
    actor: 'bob',
    expected: 'denied',
    action: 'Overwrite users/alice',
    run: (env) => env.authenticatedContext('bob').firestore().doc('users/alice').set({ name: 'Bob' }),
  },
  {
    group: 'Firestore · users/{uid}',
    actor: 'alice',
    expected: 'allowed',
    action: 'Write own subcollection users/alice/applications/app1',
    run: (env) =>
      env
        .authenticatedContext('alice')
        .firestore()
        .doc('users/alice/applications/app1')
        .set({ status: 'applied' }),
  },
  {
    group: 'Firestore · users/{uid}',
    actor: 'bob',
    expected: 'denied',
    action: "Read alice's subcollection users/alice/applications/app1",
    run: async (env) => {
      await env.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc('users/alice/applications/app1').set({ status: 'applied' });
      });
      return env
        .authenticatedContext('bob')
        .firestore()
        .doc('users/alice/applications/app1')
        .get();
    },
  },
  {
    group: 'Firestore · users/{uid}',
    actor: 'alice',
    expected: 'allowed',
    action: 'Write exactly 50 fields',
    run: (env) => {
      const fields = Object.fromEntries(Array.from({ length: 50 }, (_, i) => [`f${i}`, i]));
      return env.authenticatedContext('alice').firestore().doc('users/alice').set(fields);
    },
  },
  {
    group: 'Firestore · users/{uid}',
    actor: 'alice',
    expected: 'denied',
    action: 'Write 51 fields (document size limit)',
    run: (env) => {
      const fields = Object.fromEntries(Array.from({ length: 51 }, (_, i) => [`f${i}`, i]));
      return env.authenticatedContext('alice').firestore().doc('users/alice/extra/size51').set(fields);
    },
  },
  {
    group: 'Firestore · internships/{key}',
    actor: 'signed out',
    expected: 'denied',
    action: 'Read the shared internship pool',
    run: async (env) => {
      await env.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc('internships/key1').set({ title: 'Flutter Intern' });
      });
      return env.unauthenticatedContext().firestore().doc('internships/key1').get();
    },
  },
  {
    group: 'Firestore · internships/{key}',
    actor: 'alice',
    expected: 'allowed',
    action: 'Read the shared internship pool',
    run: async (env) => {
      await env.withSecurityRulesDisabled(async (context) => {
        await context.firestore().doc('internships/key1').set({ title: 'Flutter Intern' });
      });
      return env.authenticatedContext('alice').firestore().doc('internships/key1').get();
    },
  },
  {
    group: 'Firestore · internships/{key}',
    actor: 'alice',
    expected: 'denied',
    action: 'Write a listing from the app',
    run: (env) =>
      env.authenticatedContext('alice').firestore().doc('internships/key2').set({ title: 'Fake' }),
  },
  {
    group: 'Firestore · sync/**',
    actor: 'alice',
    expected: 'denied',
    action: 'Read and write the sync bookkeeping document',
    run: async (env) => {
      const ref = env.authenticatedContext('alice').firestore().doc('sync/state');
      await assertFails(ref.get());
      return ref.set({ lastRun: 1 });
    },
  },
  {
    group: 'Storage · cvs/{uid}, reports/{uid}',
    actor: 'alice',
    expected: 'allowed',
    action: 'Upload a PDF CV to cvs/alice and read it back',
    run: async (env) => {
      const storage = env.authenticatedContext('alice').storage();
      await assertSucceeds(
        storage.ref('cvs/alice/cv.pdf').put(pdf(), { contentType: 'application/pdf' }),
      );
      return storage.ref('cvs/alice/cv.pdf').getMetadata();
    },
  },
  {
    group: 'Storage · cvs/{uid}, reports/{uid}',
    actor: 'bob',
    expected: 'denied',
    action: "Read alice's CV",
    run: async (env) => {
      await env.withSecurityRulesDisabled(async (context) => {
        await context
          .storage()
          .ref('cvs/alice/cv.pdf')
          .put(pdf(), { contentType: 'application/pdf' });
      });
      return env.authenticatedContext('bob').storage().ref('cvs/alice/cv.pdf').getMetadata();
    },
  },
  {
    group: 'Storage · cvs/{uid}, reports/{uid}',
    actor: 'signed out',
    expected: 'denied',
    action: 'Upload without signing in',
    run: (env) =>
      env
        .unauthenticatedContext()
        .storage()
        .ref('reports/alice/report.pdf')
        .put(pdf(), { contentType: 'application/pdf' }),
  },
  {
    group: 'Storage · cvs/{uid}, reports/{uid}',
    actor: 'alice',
    expected: 'denied',
    action: 'Upload a PNG instead of a PDF',
    run: (env) =>
      env
        .authenticatedContext('alice')
        .storage()
        .ref('cvs/alice/cv.png')
        .put(new Uint8Array([0x89, 0x50, 0x4e, 0x47]), { contentType: 'image/png' }),
  },
  {
    group: 'Storage · cvs/{uid}, reports/{uid}',
    actor: 'alice',
    expected: 'denied',
    action: 'Upload a PDF larger than 10 MB',
    run: (env) =>
      env
        .authenticatedContext('alice')
        .storage()
        .ref('cvs/alice/huge.pdf')
        .put(new Uint8Array(tenMb + 1), { contentType: 'application/pdf' }),
  },
  {
    group: 'Storage · cvs/{uid}, reports/{uid}',
    actor: 'alice',
    expected: 'denied',
    action: 'Upload outside reports/ and cvs/',
    run: (env) =>
      env
        .authenticatedContext('alice')
        .storage()
        .ref('public/announcement.pdf')
        .put(pdf(), { contentType: 'application/pdf' }),
  },
];

const plan = scenarios.map(({ group, actor, expected, action }) => ({
  group,
  actor,
  expected,
  action,
}));

let running = false;

function send(res, message) {
  res.write(`${JSON.stringify(message)}\n`);
}

async function runAll(send) {
  const env = await testEnv();
  const total = scenarios.length;
  let passed = 0;
  let failed = 0;
  const started = performance.now();

  send({ type: 'plan', total, scenarios: plan });

  for (const [index, scenario] of scenarios.entries()) {
    send({ type: 'start', index });
    const at = performance.now();
    try {
      await env.clearFirestore();
      await env.clearStorage();
      const assertDecision = scenario.expected === 'allowed' ? assertSucceeds : assertFails;
      await assertDecision(scenario.run(env));
      passed += 1;
      send({ type: 'result', index, ok: true, ms: Math.round(performance.now() - at) });
      console.log(`PASS  ${scenario.group} · ${scenario.action} (${scenario.actor})`);
    } catch (error) {
      failed += 1;
      const message = String(error?.message ?? error).split('\n')[0].slice(0, 300);
      send({ type: 'result', index, ok: false, ms: Math.round(performance.now() - at), error: message });
      console.log(`FAIL  ${scenario.group} · ${scenario.action} (${scenario.actor}): ${message}`);
    }
  }

  await env.clearFirestore();
  await env.clearStorage();
  send({
    type: 'done',
    passed,
    failed,
    total,
    ms: Math.round(performance.now() - started),
  });
  console.log(`\n${passed}/${total} passed, ${failed} failed in ${Math.round(performance.now() - started)} ms`);
  return { passed, failed, total };
}

const server = createServer(async (req, res) => {
  if (req.url === '/' || req.url === '/index.html') {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(page);
    return;
  }

  if (req.url === '/run') {
    if (running) {
      res.writeHead(409, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'A run is already in progress.' }));
      return;
    }
    running = true;
    res.writeHead(200, {
      'Content-Type': 'application/x-ndjson; charset=utf-8',
      'Cache-Control': 'no-store',
    });
    try {
      await runAll((message) => send(res, message));
    } catch (error) {
      send(res, { type: 'fatal', error: String(error?.message ?? error) });
    } finally {
      running = false;
      res.end();
    }
    return;
  }

  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('Not found');
});

if (process.argv.includes('--self-test')) {
  runAll(() => {})
    .then(async ({ failed }) => {
      await (await testEnv()).cleanup();
      process.exit(failed === 0 ? 0 : 1);
    })
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
} else {
  server.listen(PORT, '127.0.0.1', () => {
    console.log(`Rules demo on http://localhost:${PORT}`);
    console.log('Emulator UI on http://localhost:4000 (Firestore data, Storage files)');
  });
}
