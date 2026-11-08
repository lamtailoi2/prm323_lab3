import assert from 'node:assert/strict';
import test from 'node:test';

import { HttpsError } from 'firebase-functions/v2/https';

import {
  fallbackReason,
  handleSelectCv,
  parseSelectionReason,
  type SelectCvDeps,
} from './select-cv';

const uid = 'user-1';
const pathA = `cvs/${uid}/a.pdf`;
const pathB = `cvs/${uid}/b.pdf`;
const internshipKey = 'job-1';

const internship = {
  raw: {
    title: 'Flutter Intern',
    company_name: 'Northstar Labs',
    description: 'Work with Flutter and Dart.',
    job_highlights: [
      { title: 'Qualifications', items: ['Flutter and Dart experience'] },
    ],
  },
};

interface Calls {
  download: number;
  extract: number;
  model: number;
  internship: number;
  profile: number;
}

function request(data: unknown, userId: string | null = uid) {
  return { auth: userId === null ? null : { uid: userId }, data };
}

function scriptedDeps(options: {
  texts?: Record<string, string>;
  profileSkills?: string[];
  internship?: Record<string, unknown> | null;
  downloadError?: Error;
  modelResponse?: string;
  modelError?: Error;
} = {}): { deps: SelectCvDeps; calls: Calls } {
  const calls: Calls = { download: 0, extract: 0, model: 0, internship: 0, profile: 0 };
  const texts = options.texts ?? {};
  return {
    calls,
    deps: {
      async downloadPdf(storagePath: string) {
        calls.download += 1;
        if (options.downloadError) throw options.downloadError;
        return Buffer.from(storagePath);
      },
      async extractText(pdf: Buffer) {
        calls.extract += 1;
        return texts[pdf.toString()] ?? '';
      },
      async askModel() {
        calls.model += 1;
        if (options.modelError) throw options.modelError;
        return options.modelResponse ?? '{"reason": "A good fit."}';
      },
      async loadInternship() {
        calls.internship += 1;
        return options.internship === undefined ? internship : options.internship;
      },
      async loadProfileSkills() {
        calls.profile += 1;
        return options.profileSkills ?? [];
      },
    },
  };
}

const flutterCv =
  'Minh Nguyen CV. Flutter app for a campus club with Dart and SQL. ' +
  'Email: minh@example.com';
const plainCv =
  'Minh Nguyen CV. Coursework in databases and team projects. ' +
  'Email: minh@example.com';

test('the highest scoring CV wins and the model writes the reason', async () => {
  const { deps, calls } = scriptedDeps({
    texts: { [pathA]: plainCv, [pathB]: flutterCv },
  });

  const result = await handleSelectCv(
    request({ internshipKey, cvPaths: [pathA, pathB] }),
    deps,
    'key',
  );

  assert.equal(result.storagePath, pathB);
  assert.equal(result.percent, 100);
  assert.equal(result.reason, 'A good fit.');
  assert.equal(calls.model, 1);
});

test('a tie prefers the default CV', async () => {
  const { deps } = scriptedDeps({
    texts: { [pathA]: flutterCv, [pathB]: flutterCv },
  });

  const result = await handleSelectCv(
    request({ internshipKey, cvPaths: [pathA, pathB], defaultPath: pathA }),
    deps,
    'key',
  );

  assert.equal(result.storagePath, pathA);
});

test('an unreadable CV still scores on the Profile skills', async () => {
  const { deps } = scriptedDeps({
    texts: { [pathA]: '', [pathB]: plainCv },
    profileSkills: ['Flutter', 'Dart'],
  });

  const result = await handleSelectCv(
    request({ internshipKey, cvPaths: [pathA, pathB] }),
    deps,
    'key',
  );

  // Both score 100 from Profile skills alone; no default, so the first wins.
  assert.equal(result.percent, 100);
  assert.equal(result.cvReadable, false);
});

test('a model failure falls back to a deterministic reason', async () => {
  const { deps } = scriptedDeps({
    texts: { [pathA]: flutterCv, [pathB]: flutterCv },
    modelError: new Error('down'),
  });

  const result = await handleSelectCv(
    request({ internshipKey, cvPaths: [pathA, pathB] }),
    deps,
    'key',
  );

  assert.equal(result.reason, 'This CV covers every skill the internship lists.');
});

test('the model is skipped when only one CV is sent', async () => {
  const { deps, calls } = scriptedDeps({ texts: { [pathA]: flutterCv } });

  const result = await handleSelectCv(
    request({ internshipKey, cvPaths: [pathA] }),
    deps,
    'key',
  );

  assert.equal(result.storagePath, pathA);
  assert.equal(calls.model, 0);
});

test('another student\'s path is refused', async () => {
  const { deps } = scriptedDeps();

  await assert.rejects(
    () =>
      handleSelectCv(
        request({ internshipKey, cvPaths: [pathA] }, 'user-2'),
        deps,
        'key',
      ),
    (error: unknown) =>
      error instanceof HttpsError && error.code === 'permission-denied',
  );
});

test('a missing login is refused', async () => {
  const { deps } = scriptedDeps();

  await assert.rejects(
    () =>
      handleSelectCv(
        request({ internshipKey, cvPaths: [pathA] }, null),
        deps,
        'key',
      ),
    (error: unknown) =>
      error instanceof HttpsError && error.code === 'unauthenticated',
  );
});

test('an unknown internship is not found', async () => {
  const { deps } = scriptedDeps({ internship: null });

  await assert.rejects(
    () => handleSelectCv(request({ internshipKey, cvPaths: [pathA] }), deps, 'key'),
    (error: unknown) =>
      error instanceof HttpsError && error.code === 'not-found',
  );
});

test('more than 10 CVs is an invalid request', async () => {
  const { deps } = scriptedDeps();
  const many = Array.from({ length: 11 }, (_, i) => `cvs/${uid}/${i}.pdf`);

  await assert.rejects(
    () => handleSelectCv(request({ internshipKey, cvPaths: many }), deps, 'key'),
    (error: unknown) =>
      error instanceof HttpsError && error.code === 'invalid-argument',
  );
});

test('parseSelectionReason trims, rejects junk and caps length', () => {
  assert.equal(parseSelectionReason('{"reason": " Best CV. "}'), 'Best CV.');
  assert.equal(parseSelectionReason('not json'), null);
  assert.equal(parseSelectionReason('{"reason": 3}'), null);
  assert.equal(parseSelectionReason('{"reason": ""}'), null);
  assert.equal(parseSelectionReason('{"reason": "x"}')?.length, 1);
  assert.ok((parseSelectionReason(`{"reason": "${'x'.repeat(500)}"}`) ?? '').length <= 200);
});

test('fallbackReason explains no requirements and full coverage', () => {
  assert.equal(
    fallbackReason({
      storagePath: pathA,
      percent: 0,
      matchedCount: 0,
      totalRequired: 0,
      matched: [],
      missing: [],
      cvReadable: true,
    }),
    'This internship does not list specific skills to compare.',
  );
  assert.equal(
    fallbackReason({
      storagePath: pathA,
      percent: 100,
      matchedCount: 2,
      totalRequired: 2,
      matched: ['Flutter', 'Dart'],
      missing: [],
      cvReadable: true,
    }),
    'This CV covers every skill the internship lists.',
  );
});
