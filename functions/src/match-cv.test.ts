import assert from 'node:assert/strict';
import test from 'node:test';

import { HttpsError } from 'firebase-functions/v2/https';

import { handleMatchCv, parseInternshipDocument, type MatchCvDeps } from './match-cv';

const uid = 'user-1';
const cvPath = `cvs/${uid}/cv-abc.pdf`;
const internshipKey = 'job-1';
const apiKey = 'test-key';

// Matches the real Firestore shape written by the sync function: the raw
// SerpAPI object under `raw`, with no parsed title/skills at the root.
const internship = {
  raw: {
    title: 'Flutter Intern',
    company_name: 'Northstar Labs',
    description: 'Work with Flutter and Dart. SQL is used for reporting.',
    job_highlights: [
      { title: 'Qualifications', items: ['Flutter and Dart experience'] },
      { title: 'Nice to have', items: ['Git'] },
    ],
  },
};

const cvText =
  'Minh Nguyen - CV. Experience: Flutter app for a campus club, ' +
  'education at VNU, coursework and personal projects. ' +
  'Email: minh@example.com';

interface Calls {
  download: number;
  extract: number;
  model: number;
  internship: number;
  profile: number;
}

function request(
  data: unknown,
  userId: string | null = uid,
): { auth?: { uid?: string } | null; data?: unknown } {
  return { auth: userId === null ? null : { uid: userId }, data };
}

function scriptedDeps(
  options: {
    cv?: string;
    profileSkills?: string[];
    internship?: Record<string, unknown> | null;
    internshipError?: Error;
    downloadError?: Error;
    extractError?: Error;
    modelResponse?: string;
    extractionResponse?: string;
    modelError?: Error;
    calls?: Calls;
    prompt?: { value: string };
    prompts?: string[];
  } = {},
): { deps: MatchCvDeps; calls: Calls } {
  const calls =
    options.calls ??
    { download: 0, extract: 0, model: 0, internship: 0, profile: 0 };
  return {
    calls,
    deps: {
      async downloadPdf() {
        calls.download += 1;
        if (options.downloadError) throw options.downloadError;
        return Buffer.from('%PDF-1.7');
      },
      async extractText() {
        calls.extract += 1;
        if (options.extractError) throw options.extractError;
        return options.cv ?? cvText;
      },
      async askExtraction(prompt: string) {
        calls.model += 1;
        options.prompts?.push(prompt);
        if (options.prompt && calls.model === 1) options.prompt.value = prompt;
        if (options.modelError) throw options.modelError;
        return (
          options.extractionResponse ??
          options.modelResponse ??
          '{"summary":"Good base.","suggestions":[{"skill":"Dart","text":"Mention your Dart project."}]}'
        );
      },
      async askModel(prompt: string) {
        calls.model += 1;
        options.prompts?.push(prompt);
        if (options.prompt && calls.model === 1) options.prompt.value = prompt;
        if (options.modelError) throw options.modelError;
        return (
          options.modelResponse ??
          '{"summary":"Good base.","suggestions":[{"skill":"Dart","text":"Mention your Dart project."}]}'
        );
      },
      async loadInternship() {
        calls.internship += 1;
        if (options.internshipError) throw options.internshipError;
        return options.internship === undefined
          ? internship
          : options.internship;
      },
      async loadProfileSkills() {
        calls.profile += 1;
        return options.profileSkills ?? ['SQL'];
      },
    },
  };
}

async function expectHttpsError(
  promise: Promise<unknown>,
  code: string,
): Promise<void> {
  await assert.rejects(promise, (error: unknown) => {
    assert.ok(error instanceof HttpsError, 'expected an HttpsError');
    assert.equal(error.code, code);
    return true;
  });
}

test('the real Firestore document shape is parsed like the app', () => {
  const parsed = parseInternshipDocument(internship);
  assert.ok(parsed);
  assert.equal(parsed.title, 'Flutter Intern');
  assert.equal(parsed.companyName, 'Northstar Labs');
  assert.deepEqual(parsed.skills, ['Flutter', 'Dart', 'Git', 'SQL']);
  assert.deepEqual(parsed.highlights[1], {
    title: 'Nice to have',
    items: ['Git'],
  });
  assert.equal(parseInternshipDocument({}), null);
});

test('the model extraction adds technologies outside the vocabulary', async () => {
  const prompts: string[] = [];
  const { deps } = scriptedDeps({
    extractionResponse:
      '{"cvSkills":["Go"],"jobSkills":["Go","Rust"],"jobNiceToHave":["Git"]}',
    prompts,
  });

  const result = await handleMatchCv(
    request({ storagePath: cvPath, internshipKey }),
    deps,
    apiKey,
  );

  assert.ok(
    result.matched.includes('Golang'),
    'Go from the model is canonicalised to Golang',
  );
  assert.ok(result.missing.includes('Rust'), 'Rust came from the model');
  assert.deepEqual(result.niceToHave, ['Git']);
  assert.ok(prompts[0].includes('JOB DESCRIPTION TEXT:'));
  assert.ok(prompts[0].includes('CV TEXT:'));
  assert.ok(prompts[0].includes('Flutter Intern'));
});

test('gaps are scored deterministically and described once by the model', async () => {
  const { deps, calls } = scriptedDeps();
  const result = await handleMatchCv(
    request({ storagePath: cvPath, internshipKey }),
    deps,
    apiKey,
  );

  assert.equal(result.internshipTitle, 'Flutter Intern');
  assert.equal(result.companyName, 'Northstar Labs');
  assert.deepEqual(result.matched, ['Flutter', 'SQL']);
  assert.deepEqual(result.missing, ['Dart']);
  assert.deepEqual(result.niceToHave, ['Git']);
  assert.equal(result.matchedCount, 2);
  assert.equal(result.totalRequired, 3);
  assert.equal(result.percent, 67);
  assert.equal(result.cvReadable, true);
  assert.equal(result.summary, 'Good base.');
  assert.deepEqual(result.suggestions, [
    { skill: 'Dart', text: 'Mention your Dart project.' },
  ]);
  assert.deepEqual(calls, {
    download: 1,
    extract: 1,
    model: 2,
    internship: 1,
    profile: 1,
  });
});

test('all matched: no model call and a canned summary', async () => {
  const { deps, calls } = scriptedDeps({
    cv: `${cvText} Skills: Flutter, Dart, SQL`,
    profileSkills: [],
  });
  const result = await handleMatchCv(
    request({ storagePath: cvPath, internshipKey }),
    deps,
    apiKey,
  );

  assert.deepEqual(result.missing, []);
  assert.equal(result.percent, 100);
  assert.match(result.summary, /covers every skill/);
  assert.equal(calls.model, 1);
});

test('a listing without known skills returns a neutral result and no work', async () => {
  const { deps, calls } = scriptedDeps({
    internship: {
      raw: {
        title: 'Intern',
        company_name: 'X',
        description: 'Administrative support only.',
        job_highlights: [],
      },
    },
  });
  const result = await handleMatchCv(
    request({ storagePath: cvPath, internshipKey }),
    deps,
    apiKey,
  );

  assert.equal(result.totalRequired, 0);
  assert.equal(result.percent, 0);
  assert.deepEqual(result.missing, []);
  assert.match(result.summary, /does not list specific skills/);
  assert.equal(calls.download, 1);
  assert.equal(calls.extract, 1);
  assert.equal(calls.model, 1);
  assert.equal(calls.profile, 0);
});

test('an unreadable CV falls back to Profile skills instead of failing', async () => {
  const { deps } = scriptedDeps({ cv: 'short', modelResponse: 'not json' });
  const result = await handleMatchCv(
    request({ storagePath: cvPath, internshipKey }),
    deps,
    '',
  );

  assert.equal(result.cvReadable, false);
  assert.deepEqual(result.matched, ['SQL']);
  assert.deepEqual(result.missing, ['Flutter', 'Dart']);
  assert.match(result.summary, /1 of 3/);
  assert.equal(result.suggestions.length, 2);
});

test('a download failure still returns the Profile-only result', async () => {
  const { deps } = scriptedDeps({ downloadError: new Error('gone') });
  const result = await handleMatchCv(
    request({ storagePath: cvPath, internshipKey }),
    deps,
    '',
  );

  assert.equal(result.cvReadable, false);
  assert.deepEqual(result.matched, ['SQL']);
});

test('model failures and blank keys fall back to deterministic suggestions', async () => {
  for (const options of [
    { modelError: new Error('quota') },
    { modelResponse: 'not json' },
  ]) {
    const { deps } = scriptedDeps({
      cv: 'Flutter only, plus coursework and personal projects listed.',
      ...options,
    });
    const result = await handleMatchCv(
      request({ storagePath: cvPath, internshipKey }),
      deps,
      apiKey,
    );
    assert.match(result.summary, /2 of 3/);
    assert.deepEqual(
      result.suggestions.map((entry) => entry.skill),
      ['Dart'],
    );
  }

  const { deps } = scriptedDeps({
    cv: 'Flutter only, plus coursework and personal projects listed.',
  });
  const result = await handleMatchCv(
    request({ storagePath: cvPath, internshipKey }),
    deps,
    '   ',
  );
  assert.deepEqual(
    result.suggestions.map((entry) => entry.skill),
    ['Dart'],
  );
});

test('the prompt carries at most 8000 characters of CV text', async () => {
  const prompt = { value: '' };
  const { deps } = scriptedDeps({
    cv: `${cvText}${'x'.repeat(20_000)}`,
    prompt,
  });
  await handleMatchCv(
    request({ storagePath: cvPath, internshipKey }),
    deps,
    apiKey,
  );
  const cvPart = prompt.value.split('CV TEXT:\n')[1] ?? '';
  assert.ok(cvPart.length <= 8_000, `prompt CV part is ${cvPart.length}`);
});

test('a missing internship is not-found', async () => {
  const { deps } = scriptedDeps({ internship: null });
  await expectHttpsError(
    handleMatchCv(
      request({ storagePath: cvPath, internshipKey }),
      deps,
      apiKey,
    ),
    'not-found',
  );
});

test('an invalid internship key is invalid-argument', async () => {
  const { deps } = scriptedDeps();
  await expectHttpsError(
    handleMatchCv(
      request({ storagePath: cvPath, internshipKey: 'a/b' }),
      deps,
      apiKey,
    ),
    'invalid-argument',
  );
  await expectHttpsError(
    handleMatchCv(request({ storagePath: cvPath }), deps, apiKey),
    'invalid-argument',
  );
});

test('only the caller\'s own CV path is accepted', async () => {
  const { deps } = scriptedDeps();
  await expectHttpsError(
    handleMatchCv(request({ storagePath: cvPath, internshipKey }, null), deps, apiKey),
    'unauthenticated',
  );
  await expectHttpsError(
    handleMatchCv(
      request({ storagePath: `cvs/another/${uid}.pdf`, internshipKey }),
      deps,
      apiKey,
    ),
    'permission-denied',
  );
});

test('an internship read failure is unavailable', async () => {
  const { deps } = scriptedDeps({ internshipError: new Error('offline') });
  await expectHttpsError(
    handleMatchCv(
      request({ storagePath: cvPath, internshipKey }),
      deps,
      apiKey,
    ),
    'unavailable',
  );
});
