import assert from 'node:assert/strict';
import test from 'node:test';

import { buildSearchUrl, hasNoResults, parseJobs } from './serp';

test('parseJobs keeps complete jobs and skips malformed entries', () => {
  const jobs = parseJobs([
    {
      job_id: 'one',
      title: 'Flutter Intern',
      company_name: 'Northstar Labs',
      location: 'Ho Chi Minh City',
    },
    { job_id: 'two', title: 'Missing company' },
    { job_id: 3, title: 'Bad id', company_name: 'Company' },
    null,
  ]);

  assert.equal(jobs.length, 1);
  assert.equal(jobs[0].job_id, 'one');
  assert.equal(jobs[0].location, 'Ho Chi Minh City');
});

test('parseJobs returns an empty list for a missing payload', () => {
  assert.deepEqual(parseJobs(undefined), []);
  assert.deepEqual(parseJobs({}), []);
});

test('location is sent only when a filter provides it', () => {
  const nationwide = buildSearchUrl({
    apiKey: 'key',
    keyword: 'thực tập IT',
  });
  assert.equal(nationwide.searchParams.has('location'), false);

  const filtered = buildSearchUrl({
    apiKey: 'key',
    keyword: 'thực tập IT',
    location: 'Hanoi, Vietnam',
  });
  assert.equal(filtered.searchParams.get('location'), 'Hanoi, Vietnam');
});

test('hasNoResults recognises an empty Google Jobs page', () => {
  assert.equal(
    hasNoResults("Google hasn't returned any results for this query."),
    true,
  );
  assert.equal(hasNoResults('Invalid API key'), false);
});
