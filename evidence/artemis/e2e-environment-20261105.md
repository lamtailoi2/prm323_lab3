# ARTEMIS environment and first runs — 2026-11-05

Status: **TC-05 passed 3 of 3** on the final setup (runs 9–11, 23:35–23:38 +07). Runs 1–8 were made while the environment and the harness were being fixed. They are all listed below with their causes. Nothing here is reconstructed: run data comes from `e2e_test/artifacts/runs.jsonl` (copied to [`runs-20261105.jsonl`](runs-20261105.jsonl)) and from the daemon's session API.

How to reproduce this setup: [`docs/guides/artemis-e2e.md`](../../docs/guides/artemis-e2e.md). Setup and diagnosis were done with Claude Code (P-50).

## Environment

| Item | Value |
|---|---|
| Host | MacBook Air M1, 8 GB, macOS (Darwin 25.6), Python 3.12.2, `uv` 0.13.6 |
| ARTEMIS | `~/artemis` at `351ca84` (also `origin/main` on 2026-11-05: no newer commit), `uv sync --python 3.12`; daemon `uv run python -m artemis ui --port 8000 --no-open`; `scrcpy` 5.0.1 + FFmpeg for replays |
| `artemis doctor` | All checks ✔ (Python, configuration, Gemini API key, device, FFmpeg + scrcpy) |
| Model key | Google AI Studio project `internly-artemis`, **Free tier**, no billing |
| Device | Emulator `Pixel_API_36` (`emulator-5554`, Android API 36, arm64, Play Store), test Google account on the device |
| App | `com.group3.internly` debug build installed 2026-11-05 20:53 from branch `test/e2e-flow1`; no app code changed after that build |
| Suite | `e2e_test` (`uv sync`), `DEVICE_SERIAL=emulator-5554`, profile `flash` |

## Problems found

### 1. The free-tier models were overloaded or capped

Small requests sent directly to the Gemini API with the same key returned:

| Model | Result on 2026-11-05 evening |
|---|---|
| `gemini-3.8-flash` (ARTEMIS default) | 503 "This model is currently experiencing high demand" from 22:21; then 429 "Quota exceeded … generate_content_free_tier_requests, **limit: 20**" (requests per day) |
| `gemini-3.7-flash` (default fallback) | 503 or read timeout |
| `gemini-3.5-flash-lite` | 200 at 22:42; 503 at about 22:55 |
| `gemini-3.1-flash-lite` | 200; used for runs 2–11 |
| `gemini-2.5-flash`, `gemini-2.5-flash-lite` | 404 "no longer available to new users" |

ARTEMIS never switched to the fallback model: the daemon output has no "Falling back" line. The primary model's 503 retries use up the 180 s hard timeout of one call first. In a separate smoke task (Settings → read the first three items, 22:42–22:45) run on `gemini-3.5-flash-lite`, the agent answered "Google, Network & internet, Connected devices" correctly.

**Change:** the primary model in the ARTEMIS checkout is now `gemini-3.1-flash-lite`, with `gemini-3.5-flash-lite` as fallback ([`e2e_test/artemis-local.patch`](../../e2e_test/artemis-local.patch)).

### 2. ARTEMIS returns no structured output

The suite passes `expected_output` and asserts on `result.output`. At `351ca84`, nothing calls the Outputter agent (`artemis/agents/outputter/outputter.py`). `GET /api/sessions/{id}` returns only the session id, goal, times, status, device info, video path and pid, so `result.output` was always `None`. The agent's answer is only in the explanation of its last `report_task_status` step (`GET /api/sessions/{id}/steps`).

**Change:** `e2e_test/conftest.py` asks for the JSON in that final report and reads it back (`final_report()`), commit `6fe33a9`.

### 3. Typed text never reached Flutter text fields

In run 4, the step after `input_text("Intern")` still showed the empty Search field. "Intern" sat in Android's clipboard overlay instead ([`tc05-20261105-input-text-not-typed.jpg`](tc05-20261105-input-text-not-typed.jpg)). ARTEMIS types by setting the clipboard and sending `KEYCODE_PASTE`.

A manual check on the same Search field:

| Command | Field afterwards |
|---|---|
| `adb shell input keyevent 279` (`KEYCODE_PASTE`) | Still empty ([`input-check-20261105-keycode-paste.png`](input-check-20261105-keycode-paste.png)) |
| `adb shell input text Intern` | Shows `Intern` ([`input-check-20261105-adb-input-text.png`](input-check-20261105-adb-input-text.png)) |

The app code was checked too. Search → Results passes `q` and pre-fills the results field (`search_screen.dart` `_submit`, `search_results_screen.dart`), so this is not an app bug.

**Change:** the local ARTEMIS patch types ASCII text with `adb shell input text` ([`artemis-local.patch`](../../e2e_test/artemis-local.patch)).

### 4. Leftover state and the cold-start dialog

- Run 3 passed without typing: the Search field still held "Intern" from run 2.
- After the first fix (force-stop before each test), run 5's cold start showed "internly isn't responding" twice. The agent tapped Close app, relaunched and recovered, but the run took 197 s.

**Change:** `cold_start_app` in `conftest.py` force-stops the app, launches it with `am start -W` (6.7 s) and waits 10 s before the case (`6fe33a9`).

## Runs (TC-05, `uv run pytest test_detail.py …`)

| # | Start (+07) | Trace | pytest | Time (s) | Model calls | Setup / cause |
|---|---|---|---|---|---|---|
| 1 | 22:51 | `1d8523a8` | FAILED | 359.3 | 12 | `gemini-3.5-flash-lite` primary; 503 overload → `LLM call timed out after 180 seconds` while typing in Search (problem 1) |
| 2 | 23:01 | `ea95f1be` | FAILED | 64.8 | 15 | `gemini-3.1-flash-lite`; flow finished but `no structured output` (problem 2) |
| 3 | 23:08 | `56300b5c` | PASSED (not valid) | 65.7 | 11 | First JSON report read back; the agent never typed, the field still held "Intern" (problem 4) |
| 4 | 23:15 | `d3b8a433` | FAILED | 225.5 | 29 | Force-stop added; typing failed (problem 3) and the report was prose |
| 5 | 23:24 | `d589c61d` | PASSED | 196.8 | 39 | Typing patch applied; typed "Intern", JSON correct; cold-start dialog twice (problem 4) |
| 6 | 23:30 | `a0ee4316` | FAILED | 49.7 | 11 | Launch + 10 s wait added; flow right, but the report was a sentence, not JSON |
| 7 | 23:31 | `a96423d9` | PASSED | 53.4 | 11 | — |
| 8 | 23:32 | `fced7607` | FAILED | 125.8 | 13 | Report was a sentence, not JSON |
| 9 | 23:35 | `505846be` | PASSED | 66.8 | 13 | Stricter JSON request (names `report_task_status`, "exactly one JSON object") |
| 10 | 23:36 | `045c4d16` | PASSED | 62.8 | 13 | — |
| 11 | 23:38 | `ebe3d568` | PASSED | 67.5 | 15 | — |

Runs 9–11 (`--count 3`) are the result reported in `docs/test-plan.md` §4: **3/3 passed, average 65.7 s**. Each run typed "Intern" and reported:

```json
{"card_title": "Recruitment Intern", "card_company": "Công ty TNHH Manpower Việt Nam",
 "detail_app_bar_title": "Internship details", "detail_title": "Recruitment Intern",
 "detail_company": "Công ty TNHH Manpower Việt Nam", "apply_now_visible": true,
 "save_visible": true, "search_text_after_back": "Intern"}
```

In `runs-20261105.jsonl`, `succeeded` is ARTEMIS's own status. It reads `true` for runs 2–11, including the pytest failures.

Replays (`recording.mp4`) and step screenshots of every trace are on the ARTEMIS host in `~/artemis/traces/`. They are not committed because they show the signed-in account.
