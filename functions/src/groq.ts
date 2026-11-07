/**
 * Groq client for the advisory CV Match commentary (OpenAI-compatible API).
 *
 * Only `matchCv` uses it; the blocking Validate CV gate stays on Gemini. The
 * key is a Secret Manager secret (`GROQ_API_KEY`) bound only to that callable,
 * never in the app. The free tier is enough because the call runs only when a
 * match has gaps and any failure falls back to deterministic suggestions.
 */
export const GROQ_MODEL = 'openai/gpt-oss-20b';
export const GROQ_ENDPOINT =
  'https://api.groq.com/openai/v1/chat/completions';

const DEFAULT_TIMEOUT_MS = 25_000;

export interface GroqRequest {
  prompt: string;
  apiKey: string;
  system: string;
  model?: string;
  /** Injected in tests; defaults to the runtime fetch. */
  fetchImpl?: typeof fetch;
  timeoutMs?: number;
  /**
   * `gpt-oss` spends tokens on hidden reasoning; without a cap and a low
   * effort the content can come back empty and JSON mode fails validation.
   */
  maxCompletionTokens?: number;
  reasoningEffort?: 'low' | 'medium' | 'high';
}

/** Sends [prompt] to Groq in JSON mode and returns the raw model output. */
export async function askGroq({
  prompt,
  apiKey,
  system,
  model = GROQ_MODEL,
  fetchImpl = fetch,
  timeoutMs = DEFAULT_TIMEOUT_MS,
  maxCompletionTokens = 4_096,
  reasoningEffort = 'low',
}: GroqRequest): Promise<string> {
  if (typeof apiKey !== 'string' || apiKey.trim() === '') {
    throw new Error('GROQ_API_KEY is not configured');
  }

  const response = await fetchImpl(GROQ_ENDPOINT, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      temperature: 0,
      max_completion_tokens: maxCompletionTokens,
      reasoning_effort: reasoningEffort,
      // Requires the word "JSON" in the messages, which the system prompt has.
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: prompt },
      ],
    }),
    signal: AbortSignal.timeout(timeoutMs),
  });

  if (!response.ok) {
    const detail = await response.text().catch(() => '');
    throw new Error(
      `Groq request failed (${response.status}): ${detail.slice(0, 200)}`,
    );
  }

  const payload: unknown = await response.json();
  const content = readContent(payload);
  if (content === null) {
    throw new Error('Groq returned no message content');
  }
  return content;
}

function readContent(payload: unknown): string | null {
  if (typeof payload !== 'object' || payload === null) return null;
  const choices = (payload as Record<string, unknown>).choices;
  if (!Array.isArray(choices) || choices.length === 0) return null;
  const first = choices[0];
  if (typeof first !== 'object' || first === null) return null;
  const message = (first as Record<string, unknown>).message;
  if (typeof message !== 'object' || message === null) return null;
  const content = (message as Record<string, unknown>).content;
  return typeof content === 'string' && content.trim() !== '' ? content : null;
}
