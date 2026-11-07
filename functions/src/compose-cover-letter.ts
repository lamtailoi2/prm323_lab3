import { getFirestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { HttpsError } from 'firebase-functions/v2/https';

import {
  assertOwnedCvPath,
  downloadPdfFromStorage,
  extractPdfText,
  readStoragePath,
} from './cv-shared';
import { parseInternshipDocument, readInternshipKey } from './match-cv';
import { findKnownSkills } from './skills';

/** Keeps the prompt inside the free-tier request size. */
const MAX_CV_TEXT_LENGTH = 6_000;

/** Protects the `mailto:` draft from clients that truncate long bodies. */
const MAX_BODY_LENGTH = 2_500;

const MAX_SUBJECT_LENGTH = 160;

export interface ComposeRequest {
  auth?: { uid?: string } | null;
  data?: unknown;
}

export interface ProfileSnapshot {
  fullName: string;
  university: string;
  yearOfStudy: number | null;
  skills: string[];
  bio: string;
}

/** Every external effect is injected so tests run without Firestore, Storage
 * or Groq. */
export interface ComposeDeps {
  loadInternship: (key: string) => Promise<Record<string, unknown> | null>;
  loadProfile: (uid: string) => Promise<ProfileSnapshot>;
  downloadPdf: (storagePath: string) => Promise<Buffer>;
  extractText: (pdf: Buffer) => Promise<string>;
  askModel: (prompt: string, apiKey: string) => Promise<string>;
}

export interface CoverLetterResponse {
  subject: string;
  body: string;
  source: 'ai' | 'template';
}

export const COVER_LETTER_RUBRIC = `You write one short cover letter for a student applying to a specific
internship by email. Reply with strict JSON only, without markdown:
{"subject": "one line", "body": "the letter"}

Rules:
- Write in the same language as the job listing: Vietnamese when the listing
  is in Vietnamese, otherwise English.
- 120 to 170 words, plain text, no markdown, no bullet lists, no placeholders
  such as [Company] or [Skill].
- Only mention skills, education and experience the student actually has,
  taken from the Profile and CV below. Never invent employers, projects,
  grades, languages or years of experience.
- Greet the hiring team, name the exact role and company, mention at most three
  skills the job asks for that the student also has, and end with a short call
  to action and the student's name.
- The subject is one line, for example
  "Application for <role> at <company> - <student name>".`;

/**
 * Drafts the subject and cover letter, in the listing's language, from the
 * job document and the student's Profile (plus CV text when available).
 *
 * The model failure path is not an error: it returns a deterministic
 * template, so the email flow never dead-ends on a model quota or outage.
 */
export async function handleComposeCoverLetter(
  request: ComposeRequest,
  deps: ComposeDeps,
  apiKey: string,
): Promise<CoverLetterResponse> {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError(
      'unauthenticated',
      'Sign in to draft your cover letter.',
    );
  }

  const internshipKey = readInternshipKey(request.data);
  const data = asRecord(request.data) ?? {};
  const inputName =
    typeof data.studentName === 'string'
      ? data.studentName.trim().slice(0, 80)
      : '';

  const rawStoragePath = readStoragePath(request.data);
  const storagePath =
    typeof rawStoragePath === 'string' && rawStoragePath.trim() !== ''
      ? assertOwnedCvPath(uid, rawStoragePath)
      : null;

  let internship: Record<string, unknown> | null;
  try {
    internship = await deps.loadInternship(internshipKey);
  } catch (error) {
    logger.error('composeCoverLetter: could not read the internship', {
      internshipKey,
      error: error instanceof Error ? error.message : String(error),
    });
    throw new HttpsError(
      'unavailable',
      'We could not load this internship. Please try again.',
    );
  }
  if (!internship) {
    throw new HttpsError(
      'not-found',
      'This internship is no longer available.',
    );
  }

  const parsed = parseInternshipDocument(internship);
  if (!parsed) {
    throw new HttpsError(
      'not-found',
      'This internship is no longer available.',
    );
  }

  let profile: ProfileSnapshot = {
    fullName: '',
    university: '',
    yearOfStudy: null,
    skills: [],
    bio: '',
  };
  try {
    profile = await deps.loadProfile(uid);
  } catch (error) {
    // The letter can still be written from the listing alone.
    logger.warn('composeCoverLetter: profile unavailable', {
      error: error instanceof Error ? error.message : String(error),
    });
  }

  const studentName = inputName || profile.fullName;
  let cvText = '';
  if (storagePath) {
    try {
      const pdf = await deps.downloadPdf(storagePath);
      cvText = (await deps.extractText(pdf)).trim().slice(0, MAX_CV_TEXT_LENGTH);
    } catch (error) {
      logger.warn('composeCoverLetter: CV text unavailable', {
        storagePath,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  const vietnamese = looksVietnamese(parsed.jobText);
  const matched = matchingSkills(parsed.jobText, profile.skills, cvText);
  const fallback = fallbackCoverLetter({
    title: parsed.title,
    companyName: parsed.companyName,
    studentName,
    university: profile.university,
    yearOfStudy: profile.yearOfStudy,
    skills: profile.skills,
    matched,
    bio: profile.bio,
    vietnamese,
  });

  if (apiKey.trim() === '') {
    logger.warn('composeCoverLetter: model key is not configured, using template');
    return { ...fallback, source: 'template' };
  }

  try {
    const raw = await deps.askModel(
      buildPrompt({
        title: parsed.title,
        companyName: parsed.companyName,
        jobText: parsed.jobText,
        profile,
        studentName,
        cvText,
        matched,
        vietnamese,
      }),
      apiKey,
    );
    const draft = parseCoverLetterResponse(raw);
    if (draft) return { ...draft, source: 'ai' };
    logger.warn('composeCoverLetter: unparseable model output, using template', {
      sample: raw.slice(0, 200),
    });
  } catch (error) {
    logger.warn('composeCoverLetter: model request failed, using template', {
      error: error instanceof Error ? error.message : String(error),
    });
  }

  return { ...fallback, source: 'template' };
}

/** Reads `{ subject, body }` from model output; `null` when unusable. */
export function parseCoverLetterResponse(
  raw: string,
): { subject: string; body: string } | null {
  if (typeof raw !== 'string' || raw.trim() === '') return null;

  const start = raw.indexOf('{');
  const end = raw.lastIndexOf('}');
  if (start === -1 || end <= start) return null;

  let parsed: unknown;
  try {
    parsed = JSON.parse(raw.slice(start, end + 1));
  } catch {
    return null;
  }

  const record = asRecord(parsed);
  if (!record) return null;

  const subject = record.subject;
  const body = record.body;
  if (typeof subject !== 'string' || typeof body !== 'string') return null;

  const cleanSubject = subject.trim().slice(0, MAX_SUBJECT_LENGTH);
  const cleanBody = body.trim().slice(0, MAX_BODY_LENGTH);
  if (cleanSubject === '' || cleanBody === '') return null;
  return { subject: cleanSubject, body: cleanBody };
}

/** True when the listing is written in Vietnamese. */
export function looksVietnamese(text: string): boolean {
  return /[àáảãạăằắẳẵặâầấẩẫậđèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵ]/i.test(
    text,
  );
}

/** The job's known skills that the student actually declares or shows. */
export function matchingSkills(
  jobText: string,
  profileSkills: string[],
  cvText: string,
): string[] {
  const jobSkills = findKnownSkills(jobText);
  const student = new Set(
    [...profileSkills, ...findKnownSkills(cvText)].map((skill) =>
      skill.toLowerCase(),
    ),
  );
  return jobSkills.filter((skill) => student.has(skill.toLowerCase())).slice(0, 6);
}

/** The honest, deterministic letter used when the model is unavailable. */
export function fallbackCoverLetter(input: {
  title: string;
  companyName: string;
  studentName: string;
  university: string;
  yearOfStudy: number | null;
  skills: string[];
  matched: string[];
  bio: string;
  vietnamese: boolean;
}): { subject: string; body: string } {
  const name = input.studentName || (input.vietnamese ? 'Ứng viên' : 'Applicant');
  const roleAtCompany = input.companyName
    ? `${input.title} tại ${input.companyName}`
    : input.title;
  const roleAtCompanyEn = input.companyName
    ? `the ${input.title} position at ${input.companyName}`
    : `the ${input.title} position`;

  if (input.vietnamese) {
    const study = `Hiện em là sinh viên${
      input.yearOfStudy ? ` năm ${input.yearOfStudy}` : ''
    }${input.university ? ` tại ${input.university}` : ''}.`;
    const skills = input.matched.length > 0
      ? `Em đã có kinh nghiệm với ${input.matched.slice(0, 3).join(', ')}.`
      : input.skills.length > 0
        ? `Em có nền tảng về ${input.skills.slice(0, 3).join(', ')}.`
        : '';
    const bio = input.bio ? `\n\n${input.bio}` : '';
    return {
      subject: truncateSubject(`Ứng tuyển vị trí ${roleAtCompany} - ${name}`),
      body: [
        `Kính gửi${input.companyName ? ` ${input.companyName}` : ' Quý công ty'},`,
        '',
        `Em viết thư này để ứng tuyển vị trí ${roleAtCompany}. ${study}${
          skills ? ` ${skills}` : ''
        }${bio}`,
        '',
        'Em gửi kèm CV để anh/chị xem xét. Em rất mong có cơ hội trao đổi thêm về vị trí này.',
        '',
        'Trân trọng,',
        name,
      ].join('\n'),
    };
  }

  const study = `I am a student${
    input.yearOfStudy ? ` in year ${input.yearOfStudy}` : ''
  }${input.university ? ` at ${input.university}` : ''}.`;
  const skills = input.matched.length > 0
    ? `I have hands-on experience with ${input.matched.slice(0, 3).join(', ')}.`
    : input.skills.length > 0
      ? `I have a foundation in ${input.skills.slice(0, 3).join(', ')}.`
      : '';
  const bio = input.bio ? `\n\n${input.bio}` : '';
  const subject = input.companyName
    ? `Application for ${input.title} at ${input.companyName} - ${name}`
    : `Application for ${input.title} - ${name}`;
  return {
    subject: truncateSubject(subject),
    body: [
      `Dear Hiring Team${input.companyName ? ` at ${input.companyName}` : ''},`,
      '',
      `I am writing to apply for ${roleAtCompanyEn}. ${study}${
        skills ? ` ${skills}` : ''
      }${bio}`,
      '',
      'I have attached my CV for your review. I would welcome the opportunity to discuss how my skills can contribute to your team.',
      '',
      'Best regards,',
      name,
    ].join('\n'),
  };
}

/** Default dependency: the internship document written by the sync function. */
export async function loadInternshipFromFirestore(
  key: string,
): Promise<Record<string, unknown> | null> {
  const snapshot = await getFirestore().collection('internships').doc(key).get();
  if (!snapshot.exists) return null;
  return (snapshot.data() as Record<string, unknown> | undefined) ?? null;
}

/** Default dependency: the student's Profile. */
export async function loadProfileFromFirestore(
  uid: string,
): Promise<ProfileSnapshot> {
  const snapshot = await getFirestore().collection('users').doc(uid).get();
  const data = snapshot.data() ?? {};
  const skills = Array.isArray(data.skills)
    ? data.skills.filter(
        (entry): entry is string =>
          typeof entry === 'string' && entry.trim() !== '',
      )
    : [];
  return {
    fullName: typeof data.fullName === 'string' ? data.fullName.trim() : '',
    university:
      typeof data.university === 'string' ? data.university.trim() : '',
    yearOfStudy:
      typeof data.yearOfStudy === 'number' ? data.yearOfStudy : null,
    skills,
    bio: typeof data.bio === 'string' ? data.bio.trim() : '',
  };
}

export { downloadPdfFromStorage, extractPdfText };

function buildPrompt(options: {
  title: string;
  companyName: string;
  jobText: string;
  profile: ProfileSnapshot;
  studentName: string;
  cvText: string;
  matched: string[];
  vietnamese: boolean;
}): string {
  const { profile, studentName, cvText, matched, vietnamese } = options;
  return [
    `Language: ${vietnamese ? 'Vietnamese' : 'English'} (match the listing).`,
    `Job title: ${options.title}`,
    `Company: ${options.companyName || '(not given)'}`,
    'Job description:',
    options.jobText.slice(0, 10_000),
    'Student:',
    `Name: ${studentName || '(not given)'}`,
    `University: ${profile.university || '(not given)'}`,
    `Year of study: ${profile.yearOfStudy ?? '(not given)'}`,
    `Profile skills: ${profile.skills.join(', ') || '(none)'}`,
    `Bio: ${profile.bio || '(none)'}`,
    `Skills the job asks for that the student has: ${
      matched.join(', ') || '(none detected)'
    }`,
    'CV text:',
    cvText || '(the CV text is not available)',
  ].join('\n');
}

function truncateSubject(subject: string): string {
  return subject.slice(0, MAX_SUBJECT_LENGTH);
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;
}
