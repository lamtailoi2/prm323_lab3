import assert from 'node:assert/strict';
import test from 'node:test';

import { HttpsError } from 'firebase-functions/v2/https';

import {
  assertOwnedCvPath,
  handleValidateCv,
  MIN_CV_TEXT_LENGTH,
  parseValidationResponse,
  ValidateCvDeps,
  ValidateCvRequest,
} from './validate-cv';

const uid = 'user-1';
const cvPath = `cvs/${uid}/cv-abc.pdf`;
const apiKey = 'test-key';
const cvText =
  'Minh Nguyen - CV\nEmail: minh@example.com\nExperience: Flutter intern\n' +
  'Education: VNU\nSkills: Dart, Flutter, SQL';

interface Calls {
  download: number;
  extract: number;
  gemini: number;
}

function request(data: unknown, userId: string | null = uid): ValidateCvRequest {
  return { auth: userId === null ? null : { uid: userId }, data };
}

function scriptedDeps(
  options: {
    text?: string;
    modelResponse?: string;
    downloadError?: Error;
    extractError?: Error;
    geminiError?: Error;
    calls?: Calls;
  } = {},
): { deps: ValidateCvDeps; calls: Calls } {
  const calls = options.calls ?? { download: 0, extract: 0, gemini: 0 };
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
        return options.text ?? cvText;
      },
      async askGemini() {
        calls.gemini += 1;
        if (options.geminiError) throw options.geminiError;
        return options.modelResponse ?? '{"isValid": true, "reason": ""}';
      },
    },
  };
}

async function expectHttpsError(
  promise: Promise<unknown>,
  code: string,
): Promise<void> {
  await assert.rejects(
    promise,
    (error: unknown) => {
      assert.ok(error instanceof HttpsError, 'expected an HttpsError');
      assert.equal(error.code, code);
      return true;
    },
  );
}

test('only the caller\'s own cvs/{uid}/ path is accepted', () => {
  assert.equal(assertOwnedCvPath(uid, cvPath), cvPath);

  assert.throws(
    () => assertOwnedCvPath(undefined, cvPath),
    (error: unknown) =>
      error instanceof HttpsError && error.code === 'unauthenticated',
  );
  assert.throws(
    () => assertOwnedCvPath(uid, 'cvs/another-user/cv.pdf'),
    (error: unknown) =>
      error instanceof HttpsError && error.code === 'permission-denied',
  );
  assert.throws(
    () => assertOwnedCvPath(uid, `cvs/${uid}/../another-user/cv.pdf`),
    (error: unknown) =>
      error instanceof HttpsError && error.code === 'permission-denied',
  );
  assert.throws(
    () => assertOwnedCvPath(uid, ''),
    (error: unknown) =>
      error instanceof HttpsError && error.code === 'invalid-argument',
  );
});

test('model JSON is parsed defensively, including markdown fences', () => {
  assert.deepEqual(parseValidationResponse('{"isValid": true}'), {
    isValid: true,
  });
  assert.deepEqual(
    parseValidationResponse(
      '```json\n{"isValid": false, "reason": "No experience section."}\n```',
    ),
    { isValid: false, reason: 'No experience section.' },
  );
  assert.deepEqual(parseValidationResponse('{"isValid": false}'), {
    isValid: false,
    reason: 'This file does not look like a usable CV. Update your CV and try again.',
  });

  assert.equal(parseValidationResponse('not json at all'), null);
  assert.equal(parseValidationResponse('{"isValid": "yes"}'), null);
  assert.equal(parseValidationResponse(''), null);
});

test('an unauthenticated call is rejected before any work', async () => {
  const { deps, calls } = scriptedDeps();
  await expectHttpsError(
    handleValidateCv(request({ storagePath: cvPath }, null), deps, apiKey),
    'unauthenticated',
  );
  assert.deepEqual(calls, { download: 0, extract: 0, gemini: 0 });
});

test('reading another user\'s CV is rejected', async () => {
  const { deps, calls } = scriptedDeps();
  await expectHttpsError(
    handleValidateCv(
      request({ storagePath: 'cvs/another-user/cv.pdf' }),
      deps,
      apiKey,
    ),
    'permission-denied',
  );
  assert.deepEqual(calls, { download: 0, extract: 0, gemini: 0 });
});

test('a valid CV returns the model verdict', async () => {
  const { deps, calls } = scriptedDeps();
  const result = await handleValidateCv(
    request({ storagePath: cvPath }),
    deps,
    apiKey,
  );

  assert.deepEqual(result, { isValid: true });
  assert.deepEqual(calls, { download: 1, extract: 1, gemini: 1 });
});

test('an invalid CV returns the model reason', async () => {
  const { deps } = scriptedDeps({
    modelResponse:
      '{"isValid": false, "reason": "No contact details or experience."}',
  });
  const result = await handleValidateCv(
    request({ storagePath: cvPath }),
    deps,
    apiKey,
  );

  assert.deepEqual(result, {
    isValid: false,
    reason: 'No contact details or experience.',
  });
});

test('too little extracted text short-circuits without calling Gemini', async () => {
  const { deps, calls } = scriptedDeps({
    text: ' '.repeat(MIN_CV_TEXT_LENGTH - 1),
  });
  const result = await handleValidateCv(
    request({ storagePath: cvPath }),
    deps,
    apiKey,
  );

  assert.deepEqual(result, {
    isValid: false,
    reason: 'CV appears to be empty or unreadable.',
  });
  assert.deepEqual(calls, { download: 1, extract: 1, gemini: 0 });
});

test('unparseable model output fails open', async () => {
  const { deps } = scriptedDeps({ modelResponse: 'Sure, this looks fine!' });
  const result = await handleValidateCv(
    request({ storagePath: cvPath }),
    deps,
    apiKey,
  );

  assert.deepEqual(result, { isValid: true });
});

test('the prompt is truncated to the maximum CV text length', async () => {
  let received = '';
  const { deps } = scriptedDeps({ text: 'x'.repeat(20_000) });
  deps.askGemini = async (text: string) => {
    received = text;
    return '{"isValid": true}';
  };

  await handleValidateCv(
    request({ storagePath: cvPath }),
    deps,
    apiKey,
  );
  assert.equal(received.length, 12_000);
  assert.ok(received.length < 'x'.repeat(20_000).length);
});

test('a missing Gemini key is a configuration error', async () => {
  const { deps, calls } = scriptedDeps();
  await expectHttpsError(
    handleValidateCv(request({ storagePath: cvPath }), deps, '  '),
    'failed-precondition',
  );
  assert.deepEqual(calls, { download: 0, extract: 0, gemini: 0 });
});

test('download, extraction and Gemini failures become safe HttpsErrors', async () => {
  const download = scriptedDeps({
    downloadError: new Error('bucket exploded: secret internal text'),
  });
  await expectHttpsError(
    handleValidateCv(
      request({ storagePath: cvPath }),
      download.deps,
      apiKey,
    ),
    'not-found',
  );

  const extract = scriptedDeps({
    extractError: new Error('pdf parser stack trace'),
  });
  await expectHttpsError(
    handleValidateCv(request({ storagePath: cvPath }), extract.deps, apiKey),
    'invalid-argument',
  );

  const gemini = scriptedDeps({ geminiError: new Error('quota details') });
  await expectHttpsError(
    handleValidateCv(request({ storagePath: cvPath }), gemini.deps, apiKey),
    // The provider failing is not the student's connection.
    'failed-precondition',
  );
});
