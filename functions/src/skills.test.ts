import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import test from 'node:test';

import { findKnownSkills, KNOWN_SKILLS } from './skills';

test('the TypeScript vocabulary matches the Dart vocabulary', () => {
  const dartPath = join(
    process.cwd(),
    '..',
    'lib',
    'core',
    'utils',
    'skill_matcher.dart',
  );
  const source = readFileSync(dartPath, 'utf8');
  const block = source.match(
    /const List<String> knownSkills = <String>\[([\s\S]*?)\];/,
  );
  assert.ok(block, 'knownSkills block not found in the Dart file');
  const dartSkills = [...block[1].matchAll(/'([^']+)'/g)].map(
    (match) => match[1],
  );
  assert.deepEqual([...KNOWN_SKILLS], dartSkills);
});

test('findKnownSkills honours word boundaries and longer matches', () => {
  assert.deepEqual(findKnownSkills('React Native and Flutter'), [
    'React Native',
    'Flutter',
  ]);
  assert.deepEqual(findKnownSkills('We use JavaScript'), ['JavaScript']);
  assert.deepEqual(findKnownSkills('MySQL and C#'), ['MySQL', 'C#']);
  assert.deepEqual(findKnownSkills('C++ and C#'), ['C++', 'C#']);
  assert.deepEqual(findKnownSkills('communication skills only'), []);
  assert.deepEqual(findKnownSkills(''), []);
});

test('skills are returned in order of first mention', () => {
  assert.deepEqual(findKnownSkills('Python, then Dart, then Python again'), [
    'Python',
    'Dart',
  ]);
});
