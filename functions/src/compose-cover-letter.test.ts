import assert from 'node:assert/strict';
import test from 'node:test';

import { HttpsError } from 'firebase-functions/v2/https';

import {
  fallbackCoverLetter,
  handleComposeCoverLetter,
  looksVietnamese,
  parseCoverLetterResponse,
  type ComposeDeps,
  type ProfileSnapshot,
} from './compose-cover-letter';

const uid = 'user-1';
const internshipKey = 'job-1';
const apiKey = 'test-key';

const internship = {
  raw: {
    title: 'Flutter Intern',
    company_name: 'Northstar Labs',
    description:
      'Work with Flutter and Dart. Send your CV to hr@northstarlabs.vn.',
    job_highlights: [
      { title: 'Qualifications', items: ['Flutter and Dart experience'] },
    ],
  },
};

const vietnameseInternship = {
  raw: {
    title: 'Thực tập Flutter',
    company_name: 'Công ty Sao Bắc',
    description: 'Ứng viên gửi CV đến hr@saobac.vn. Yêu cầu Flutter và Dart.',
  },
};

const profile: ProfileSnapshot = {
  fullName: 'Minh Nguyen',
  university: 'HCMUT',
  yearOfStudy: 3,
  skills: ['Flutter', 'Dart'],
  bio: 'Flutter club member.',
};

interface DepsOptions {
  internship?: Record<string, unknown> | null;
  profile?: ProfileSnapshot;
  cv?: string;
  downloadError?: Error;
  modelResponse?: string;
  modelError?: Error;
  prompt?: { value: string };
  calls?: { download: number; extract: number; model: number };
}

function deps(options: DepsOptions = {}): ComposeDeps {
  const calls = options.calls ?? { download: 0, extract: 0, model: 0 };
  return {
    async loadInternship() {
      return options.internship === undefined ? internship : options.internship;
    },
    async loadProfile() {
      return options.profile ?? profile;
    },
    async downloadPdf() {
      calls.download += 1;
      if (options.downloadError) throw options.downloadError;
      return Buffer.from('%PDF-1.7');
    },
    async extractText() {
      calls.extract += 1;
      return options.cv ?? 'Minh Nguyen - Flutter and Dart projects.';
    },
    async askModel(prompt: string) {
      calls.model += 1;
      if (options.prompt) options.prompt.value = prompt;
      if (options.modelError) throw options.modelError;
      return (
        options.modelResponse ??
        '{"subject":"Application for Flutter Intern - Minh Nguyen","body":"Dear Hiring Team at Northstar Labs, I would like to apply."}'
      );
    },
  };
}

function request(
  data: unknown,
  userId: string | null = uid,
): { auth?: { uid?: string } | null; data?: unknown } {
  return { auth: userId === null ? null : { uid: userId }, data };
}

test('writes the subject and letter from the model', async () => {
  const capture = { value: '' };
  const result = await handleComposeCoverLetter(
    request({ internshipKey, storagePath: `cvs/${uid}/cv.pdf`, studentName: 'Minh Nguyen' }),
    deps({ prompt: capture }),
    apiKey,
  );

  assert.equal(result.source, 'ai');
  assert.equal(result.subject, 'Application for Flutter Intern - Minh Nguyen');
  assert.match(result.body, /Dear Hiring Team/);
  assert.match(capture.value, /Flutter Intern/);
  assert.match(capture.value, /Northstar Labs/);
  assert.match(capture.value, /Minh Nguyen/);
});

test('falls back to a template without a model key', async () => {
  const result = await handleComposeCoverLetter(
    request({ internshipKey }),
    deps(),
    '   ',
  );

  assert.equal(result.source, 'template');
  assert.match(result.subject, /Flutter Intern/);
  assert.match(result.body, /Dear Hiring Team/);
  assert.match(result.body, /Minh Nguyen/);
});

test('falls back to a template when the model fails', async () => {
  const result = await handleComposeCoverLetter(
    request({ internshipKey }),
    deps({ modelError: new Error('Groq down') }),
    apiKey,
  );

  assert.equal(result.source, 'template');
  assert.match(result.body, /Dear Hiring Team/);
});

test('falls back to a template when the model output is not usable', async () => {
  const result = await handleComposeCoverLetter(
    request({ internshipKey }),
    deps({ modelResponse: 'not json at all' }),
    apiKey,
  );

  assert.equal(result.source, 'template');
});

test('uses Vietnamese for a Vietnamese listing', async () => {
  const result = await handleComposeCoverLetter(
    request({ internshipKey }),
    deps({ internship: vietnameseInternship }),
    '',
  );

  assert.equal(result.source, 'template');
  assert.match(result.subject, /Ứng tuyển/);
  assert.match(result.body, /Kính gửi/);
});

test('a CV read failure does not fail the letter', async () => {
  const result = await handleComposeCoverLetter(
    request({ internshipKey, storagePath: `cvs/${uid}/cv.pdf` }),
    deps({ downloadError: new Error('storage down') }),
    apiKey,
  );

  assert.equal(result.source, 'ai');
});

test('rejects a missing internship', async () => {
  await assert.rejects(
    handleComposeCoverLetter(
      request({ internshipKey }),
      deps({ internship: null }),
      apiKey,
    ),
    (error: unknown) =>
      error instanceof HttpsError && error.code === 'not-found',
  );
});

test('rejects a request without a signed-in user', async () => {
  await assert.rejects(
    handleComposeCoverLetter(request({ internshipKey }, null), deps(), apiKey),
    (error: unknown) =>
      error instanceof HttpsError && error.code === 'unauthenticated',
  );
});

test('rejects a missing internship key', async () => {
  await assert.rejects(
    handleComposeCoverLetter(request({}), deps(), apiKey),
    (error: unknown) =>
      error instanceof HttpsError && error.code === 'invalid-argument',
  );
});

test('refuses a CV path outside the caller folder', async () => {
  await assert.rejects(
    handleComposeCoverLetter(
      request({ internshipKey, storagePath: 'cvs/other-user/cv.pdf' }),
      deps(),
      apiKey,
    ),
    (error: unknown) =>
      error instanceof HttpsError && error.code === 'permission-denied',
  );
});

test('looksVietnamese detects diacritics', () => {
  assert.equal(looksVietnamese('Thực tập Flutter'), true);
  assert.equal(looksVietnamese('Flutter internship'), false);
});

test('parseCoverLetterResponse validates the shape', () => {
  assert.deepEqual(
    parseCoverLetterResponse('{"subject":"Hi","body":"Hello"}'),
    { subject: 'Hi', body: 'Hello' },
  );
  assert.equal(parseCoverLetterResponse('{"subject":""}'), null);
  assert.equal(parseCoverLetterResponse('no braces'), null);
});

test('fallbackCoverLetter names the role and the student', () => {
  const letter = fallbackCoverLetter({
    title: 'Flutter Intern',
    companyName: 'Northstar Labs',
    studentName: 'Minh Nguyen',
    university: 'HCMUT',
    yearOfStudy: 3,
    skills: ['Flutter', 'Dart'],
    matched: ['Flutter'],
    bio: '',
    vietnamese: false,
  });

  assert.match(letter.subject, /Flutter Intern/);
  assert.match(letter.body, /Northstar Labs/);
  assert.match(letter.body, /Minh Nguyen/);
});
