import assert from 'node:assert/strict';
import test from 'node:test';

import { askGroq, GROQ_ENDPOINT, GROQ_MODEL } from './groq';

interface Captured {
  url?: string;
  init?: RequestInit;
}

function fakeFetch(
  payload: unknown,
  options: { status?: number; body?: string; capture?: Captured } = {},
): typeof fetch {
  return (async (url: string | URL | Request, init?: RequestInit) => {
    if (options.capture) {
      options.capture.url = String(url);
      options.capture.init = init;
    }
    const status = options.status ?? 200;
    if (status >= 400) {
      return new Response(options.body ?? 'rate limited', { status });
    }
    return new Response(JSON.stringify(payload), { status: 200 });
  }) as typeof fetch;
}

test('askGroq posts a JSON-mode chat request and returns the content', async () => {
  const capture: Captured = {};
  const content = await askGroq({
    prompt: 'Gaps: Dart',
    apiKey: 'groq-key',
    system: 'Reply with strict JSON only.',
    fetchImpl: fakeFetch(
      { choices: [{ message: { role: 'assistant', content: '{"summary":"ok"}' } }] },
      { capture },
    ),
  });

  assert.equal(content, '{"summary":"ok"}');
  assert.equal(capture.url, GROQ_ENDPOINT);
  assert.equal(capture.init?.method, 'POST');
  assert.equal(
    (capture.init?.headers as Record<string, string>).Authorization,
    'Bearer groq-key',
  );
  const body = JSON.parse(String(capture.init?.body)) as Record<string, unknown>;
  assert.equal(body.model, GROQ_MODEL);
  assert.equal(body.temperature, 0);
  assert.equal(body.max_completion_tokens, 4_096);
  assert.equal(body.reasoning_effort, 'low');
  assert.deepEqual(body.response_format, { type: 'json_object' });
  assert.deepEqual(body.messages, [
    { role: 'system', content: 'Reply with strict JSON only.' },
    { role: 'user', content: 'Gaps: Dart' },
  ]);
});

test('an HTTP error is reported without the API key', async () => {
  await assert.rejects(
    askGroq({
      prompt: 'x',
      apiKey: 'groq-key',
      system: 's',
      fetchImpl: fakeFetch(null, { status: 429, body: 'slow down' }),
    }),
    (error: unknown) => {
      assert.ok(error instanceof Error);
      assert.match(error.message, /429/);
      assert.doesNotMatch(error.message, /groq-key/);
      return true;
    },
  );
});

test('missing content or a blank key is an error', async () => {
  await assert.rejects(
    askGroq({
      prompt: 'x',
      apiKey: 'groq-key',
      system: 's',
      fetchImpl: fakeFetch({ choices: [] }),
    }),
    /no message content/,
  );
  await assert.rejects(
    askGroq({
      prompt: 'x',
      apiKey: '   ',
      system: 's',
      fetchImpl: fakeFetch({}),
    }),
    /not configured/,
  );
});
