import assert from 'node:assert/strict';
import test from 'node:test';

import {
  fallbackSuggestions,
  mergeSuggestions,
  parseMatchCommentary,
  requirementsFromInternship,
  scoreMatch,
} from './match-cv-score';

test('required skills exclude ones from a nice-to-have section', () => {
  const requirements = requirementsFromInternship({
    skills: ['Flutter', 'Dart', 'Git', 'Flutter'],
    highlights: [
      { title: 'Qualifications', items: ['Flutter and Dart experience'] },
      { title: 'Nice to have', items: ['Git and Docker'] },
    ],
  });
  assert.deepEqual(requirements.required, ['Flutter', 'Dart']);
  assert.deepEqual(requirements.niceToHave, ['Git']);
});

test('a preferred/bonus section is also optional', () => {
  const requirements = requirementsFromInternship({
    skills: ['SQL', 'AWS'],
    highlights: [{ title: 'Preferred / bonus', items: ['AWS'] }],
  });
  assert.deepEqual(requirements.required, ['SQL']);
  assert.deepEqual(requirements.niceToHave, ['AWS']);
});

test('a listing without skills or highlights has no requirements', () => {
  assert.deepEqual(requirementsFromInternship({}), {
    required: [],
    niceToHave: [],
  });
  assert.deepEqual(requirementsFromInternship(null), {
    required: [],
    niceToHave: [],
  });
});

test('a skill counts when it is in the Profile or in the CV text', () => {
  const score = scoreMatch({
    requiredSkills: ['Flutter', 'Dart', 'SQL', 'Git'],
    profileSkills: ['flutter', 'SQL'],
    cvSkills: ['Dart'],
  });
  assert.deepEqual(score.matched, ['Flutter', 'Dart', 'SQL']);
  assert.deepEqual(score.missing, ['Git']);
  assert.equal(score.matchedCount, 3);
  assert.equal(score.missingCount, 1);
  assert.equal(score.totalRequired, 4);
  assert.equal(score.percent, 75);
});

test('percent rounds and empty requirements give zero', () => {
  assert.equal(
    scoreMatch({
      requiredSkills: ['A', 'B', 'C'],
      profileSkills: ['A'],
      cvSkills: [],
    }).percent,
    33,
  );
  assert.deepEqual(
    scoreMatch({ requiredSkills: [], profileSkills: [], cvSkills: [] }),
    {
      matched: [],
      missing: [],
      matchedCount: 0,
      missingCount: 0,
      totalRequired: 0,
      percent: 0,
    },
  );
});

test('fallback suggestions cover every gap honestly', () => {
  assert.deepEqual(fallbackSuggestions(['Git']), [
    {
      skill: 'Git',
      text: 'Add Git to your skills if you have used it, or mention it in your CV.',
    },
  ]);
});

test('commentary parsing keeps only real gaps and caps the text', () => {
  const parsed = parseMatchCommentary(
    '```json\n{"summary":"Solid CV.","suggestions":[' +
      '{"skill":"git","text":"  Add your Git coursework.  "},' +
      '{"skill":"Kubernetes","text":"Invented gap"},' +
      '{"skill":"Git","text":"duplicate"}]}\n```',
    ['Git', 'SQL'],
  );
  assert.deepEqual(parsed, {
    summary: 'Solid CV.',
    suggestions: [{ skill: 'Git', text: 'Add your Git coursework.' }],
  });

  const long = parseMatchCommentary(
    JSON.stringify({
      summary: 'x'.repeat(400),
      suggestions: [{ skill: 'SQL', text: 'y'.repeat(400) }],
    }),
    ['SQL'],
  );
  assert.equal(long?.summary.length, 240);
  assert.equal(long?.suggestions[0].text.length, 160);

  const words = parseMatchCommentary(
    JSON.stringify({
      summary: 'short',
      suggestions: [
        {
          skill: 'SQL',
          text:
            'Mention the SQL queries you wrote for the reporting dashboard ' +
            'and the joins you used to combine tables for weekly metrics, ' +
            'then explain how you checked the results.',
        },
      ],
    }),
    ['SQL'],
  );
  const clipped = words?.suggestions[0].text ?? '';
  assert.ok(clipped.length <= 160);
  assert.ok(clipped.endsWith('…'));
  assert.doesNotMatch(clipped, /\s…$/);
  assert.ok(!clipped.includes('…'.repeat(2)));
});

test('malformed or empty commentary returns null', () => {
  assert.equal(parseMatchCommentary('not json', ['Git']), null);
  assert.equal(parseMatchCommentary('{"suggestions":[]}', ['Git']), null);
  assert.equal(parseMatchCommentary('', ['Git']), null);
});

test('mergeSuggestions fills missing gaps with the fallback', () => {
  const merged = mergeSuggestions(['Git', 'SQL'], [
    { skill: 'git', text: 'Mention your Git project.' },
  ]);
  assert.equal(merged.length, 2);
  assert.equal(merged[0].text, 'Mention your Git project.');
  assert.match(merged[1].text, /Add SQL to your skills/);
});
