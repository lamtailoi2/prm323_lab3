# Running the ARTEMIS E2E tests

How to set up Google ARTEMIS and run the suite in [`e2e_test/`](../../e2e_test/). The test cases and the results table are in [`test-plan.md`](../test-plan.md). This guide was written after the first real runs on 2026-11-05 (macOS, Apple M1, 8 GB, Android emulator API 36). What went wrong and why is recorded in [`evidence/artemis/e2e-environment-20261105.md`](../../evidence/artemis/e2e-environment-20261105.md).

There are two parts:

- **ARTEMIS host.** The `google/artemis` checkout. Its daemon talks to the model (Gemini) and drives the device through ADB.
- **The suite.** pytest in `e2e_test/`. It sends one instruction per test to the daemon and checks the JSON report.

## 0. Before you start

- An Android emulator or phone connected over ADB (`adb devices` lists it). The debug build of Internly must be installed and the **test Google account added on the device**. Google Sign-In only works with the shared debug key from `.env` (see [`firebase-setup.md`](firebase-setup.md)).
- Python ≥ 3.12, [`uv`](https://docs.astral.sh/uv/) (`brew install uv` on macOS), Git, and `adb` on `PATH`.
- A **Gemini API key** from [Google AI Studio](https://aistudio.google.com/app/apikey):
  - Create a new project for it and check that the key's Billing Tier reads **Free tier**.
  - Never press "Set up billing". G-26 requires zero cost.
  - The key stays on your machine. Do not put it in the repository, in `e2e_test/.env` or in chat.

## 1. Install the ARTEMIS host (once)

Clone it to a path **without spaces** (for example `~/artemis`, not inside `Study Space/`):

```bash
cd ~ && git clone https://github.com/google/artemis.git && cd artemis
git checkout 351ca8422f7b5b54e80a9c1ce03a222e02415b6b   # pinned in README and e2e_test/pyproject.toml
uv sync --python 3.12
cp .env.example .env        # then set GEMINI_API_KEY=<your key> in ~/artemis/.env
```

Optional, for the live screen and video replays (`brew` also installs `ffmpeg`):

```bash
brew install scrcpy
```

You do not need `./start.sh`. It also upgrades Node.js, builds the Angular console with npm and offers to install MCP configs into every IDE. That is heavy on an 8 GB machine and can break the Node 22 used by `functions/`. The daemon in §3 serves a prebuilt console anyway.

### 1.1 Apply the team's local patch (required)

```bash
git -C ~/artemis apply "<path to prm323_lab3>/e2e_test/artemis-local.patch"
git -C ~/artemis diff --stat     # adb_driver.py and config/artemis.jsonc changed
```

[`artemis-local.patch`](../../e2e_test/artemis-local.patch) makes two changes. Without them the suite cannot pass:

| Change | Why |
|---|---|
| `config/artemis.jsonc`: primary model `gemini-3.1-flash-lite`, fallback `gemini-3.5-flash-lite` (default, hopper, step summarizer, memory chunking) | The default `gemini-3.8-flash` allows only **20 requests per day** on the free tier, and one test uses 11–15. It and `gemini-3.7-flash` also returned 503 "high demand" for hours. ARTEMIS never reached its fallback: retrying the primary used up the 180 s call timeout. `gemini-2.5-flash` is no longer available to new keys. |
| `artemis/drivers/android/adb_driver.py`: ASCII text is typed with `adb shell input text` instead of clipboard + `KEYCODE_PASTE` | A Flutter `TextField` ignores `KEYCODE_PASTE`, but ARTEMIS still reported the text as typed. Every step that types (search, skills, form fields) silently left the field empty. |

To undo: `git -C ~/artemis checkout .`. If the overload moves to `gemini-3.1-flash-lite`, swap the primary and fallback in `config/artemis.jsonc` and restart the daemon.

## 2. Configure the suite (once)

```bash
cd e2e_test
cp .env.example .env
uv sync
```

In `e2e_test/.env` (git-ignored), set:

- `DEVICE_SERIAL=emulator-5554`, or your device's serial from `adb devices`.
- `TEST_ACCOUNT_EMAIL=`: the Google account that is already on the device. No password goes anywhere.

Keep `ARTEMIS_BASE_URL=http://127.0.0.1:8000` and `ARTEMIS_PROFILE=flash`.

## 3. Start a session

Use a separate terminal for each long-running step.

1. Start the device:
   ```bash
   flutter emulators --launch Pixel_API_36
   ```
   Check it is listed with `adb devices`.
2. If the app code changed since the last install, rebuild and reinstall the app. Use a **profile** build: under ARTEMIS the debug build froze on Home ("isn't responding") and made TC-16 fail, while the profile build had no freeze in 15 runs (2026-11-06). It is signed with the same shared debug key, so Google Sign-In works and the sign-in session survives the reinstall.
   ```bash
   flutter build apk --profile --dart-define-from-file=.env && adb install -r build/app/outputs/flutter-apk/app-profile.apk
   ```
   Then grant the notification permission, which the app asks for after sign-in. Otherwise its system dialog can cover the screen in the middle of a case. TC-15 tests that dialog on a fresh install instead.
   ```bash
   adb shell pm grant com.group3.internly android.permission.POST_NOTIFICATIONS
   ```
3. Start the ARTEMIS daemon and leave it running. It reads `~/artemis/.env` and the config only at startup, so restart it after changing either.
   ```bash
   cd ~/artemis && uv run python -m artemis ui --no-open
   ```
4. Check the setup. Every row must be ✔:
   ```bash
   cd ~/artemis && uv run python -m artemis doctor
   ```

The web console at <http://localhost:8000> shows the device live and every past session with its steps and replay.

The first task on a device installs the **Artemis accessibility helper** on it. It shows as a notification and an entry under Settings → Accessibility. Remove it with `uv run python -m artemis helper uninstall`.

## 4. Run tests

From `e2e_test/`:

```bash
uv run pytest test_detail.py -v              # one file, once (try a case first)
uv run pytest test_detail.py --count 3 -v    # the 3 runs the lab requires
uv run pytest -k tc05 --count 3 -v           # one case by name
uv run pytest --count 3 -v                   # whole suite: mind the daily quota (§6)
```

What `conftest.py` does for every test:

1. **Cold start.** Before each run it force-stops the app, launches it and waits 10 s. Text or screens left by the previous run then cannot make a case pass. The wait also avoids the "isn't responding" dialog that a debug build shows when input arrives during its splash.
2. **JSON report.** The pinned ARTEMIS never runs its Outputter, so a run returns no `output`. `run_case()` adds a request to every instruction: the agent's final `report_task_status` must contain only the JSON in `expected_output`. `final_report()` then reads that report back from `GET /api/sessions/{id}/steps`.

## 5. Read and record the results

- **The pytest result is the test result.** Each line of `e2e_test/artifacts/runs.jsonl` is written when the test ends, with `"pytest": "passed"` or `"failed"` and, for a failure, its message in `failure`. `succeeded` is only ARTEMIS's own status: it is `true` even when the report was missing or wrong. Lines written before 2026-11-06 have no `pytest` field.
- To see what the agent did, open the session in the web console. You can also read its steps (each action, the screenshots' names and the final report):
  ```bash
  curl -s http://127.0.0.1:8000/api/sessions/<trace_id>/steps
  ```
  Logs and the replay video are in `~/artemis/traces/`.
- Record every run, passed or failed (AGENTS.md, "Logs and evidence"):
  1. Copy the day's lines of `runs.jsonl` to `evidence/artemis/runs-YYYYMMDD.jsonl`.
  2. Fill `test-plan.md` §4: runs, passed, pass rate, average time, trace IDs.
  3. Add one row to the flaky / failed table for every failure, with its cause and fix.
  4. Never mark a case Done before 3 of 3 pass.
- Replays and step screenshots can show the signed-in account. Commit them only with the account owner's agreement.

## 6. Free-tier limits

- Limits apply **per AI Studio project**, not per key. See AI Studio → **Rate Limit**. On 2026-11-05 `gemini-3.5-flash-lite` allowed 15 requests per minute and 250K tokens per minute.
- Daily quotas reset at **midnight Pacific time**: 15:00 in Vietnam in winter, 14:00 in summer. Afternoons in Vietnam are night in the US, so 503 overloads were less likely then.
- Each Flash-Lite model allows **500 requests per day** on the free tier (429 `GenerateRequestsPerDayPerProjectPerModel-FreeTier`, `quotaValue: 500`), counted per model. When `gemini-3.1-flash-lite` runs out, swap primary and fallback in `~/artemis/config/artemis.jsonc` for the rest of the day and restart the daemon. Note in the evidence which model each run used.
- One run used 5–29 model calls (up to 39 while recovering from dialogs), so about 25 runs fit in one model's daily quota. Run the suite file by file rather than all at once.

## 7. Troubleshooting

| Symptom | Cause | What to do |
|---|---|---|
| `LLM call timed out after 180 seconds`; `503 UNAVAILABLE … high demand` in the daemon output | The primary model is overloaded | Wait, or put a model that answers first in `config/artemis.jsonc` and restart the daemon |
| `429 RESOURCE_EXHAUSTED … limit: N` | Daily or per-minute quota used up (`…PerDay…` with `quotaValue: 500` is the daily one) | Per minute: ARTEMIS waits and retries by itself. Per day: swap to the other Flash-Lite model (§6) or wait for the reset; do not enable billing |
| `no structured output (trace …)` | The model wrote a sentence instead of the JSON | Look at the report through `/steps`. If the flow was right, it is a reporting miss: rerun and record it as flaky |
| The agent "typed" but the field stays empty | The patch in §1.1 is not applied | `git -C ~/artemis diff --stat` must list `adb_driver.py`; restart the daemon |
| "internly isn't responding" on the device | A debug build on a busy machine | Install the profile build (§3, step 2); close other apps (browser tabs) |
| `NetworkError` / connection refused | The daemon is not running | Start it (§3, step 3) |
| `FileNotFoundError: 'adb'` | `adb` is not on `PATH` for pytest | Add `$ANDROID_HOME/platform-tools` to `PATH` |
| The emulator closes with "hanging thread" | Not enough free memory | Close other apps and start the emulator again |

## 8. Stop

```bash
cd ~/artemis && uv run python -m artemis stop
```

Then close the emulator window. To remove everything: `rm -rf ~/artemis`, `uv cache clean`, and `brew uninstall scrcpy ffmpeg uv && brew autoremove`.
