# Test plan: ARTEMIS end-to-end tests

End-to-end tests drive the **Android** app with [Google ARTEMIS](https://github.com/google/artemis) from natural-language instructions (Lab 3 §7). Flutter unit, ViewModel and widget tests are reported in [`test-report.md`](records/test-report.md).

| Item | Value |
|---|---|
| ARTEMIS commit | `351ca8422f7b5b54e80a9c1ce03a222e02415b6b` (2026-09-29), pinned in `e2e_test/pyproject.toml` and README |
| SDK | `artemis-client` (`ArtemisClient.run(goal, expected_output=…, locked_app_package=…)`) |
| Profiles | **Flash** for every regression test; **Pro** only for the exploratory session |
| Model | `gemini-3.1-flash-lite`, fallback `gemini-3.5-flash-lite` (free tier), set on the host by [`e2e_test/artemis-local.patch`](../e2e_test/artemis-local.patch) since 2026-11-05: the default `gemini-3.8-flash` allows 20 requests per day on the free tier and was overloaded |
| Device | Android device or emulator (API 33+ for the notification permission case) |
| Account | Dedicated Google test account added on the device; no password stored anywhere |
| Secrets | `e2e_test/.env` (from `.env.example`, git-ignored); the model API key stays on the ARTEMIS host |

## 0. Cost: everything at $0

| Part | Free option |
|---|---|
| ARTEMIS | Open source (Apache 2.0) |
| Model (on the ARTEMIS host) | `GEMINI_API_KEY` from Google AI Studio **without enabling billing** (free tier). ARTEMIS's default `config/artemis.jsonc` already uses Gemini models. Limits: free-tier rate limits (spread the 3 runs out), and free-tier prompts may be used by Google to improve its products, so the test account must hold test data only. If a configured model is not on the free tier, switch that node to a free Flash / Flash-Lite model. |
| Device | Own Android phone, or the Android Emulator |
| SerpAPI searches | Free plan quota: keep the suite small; TC-03…TC-12 each need only one or two searches per run |

Never add a payment method to the Google AI Studio project or SerpAPI account used for testing.

## 1. How to run

Step-by-step guide with troubleshooting: [`guides/artemis-e2e.md`](guides/artemis-e2e.md).

```bash
# 1. ARTEMIS host (once): clone google/artemis at the pinned commit, apply the team's patch
#    (model + text input, required), add the model API key to its own .env, start the daemon.
git clone https://github.com/google/artemis ~/artemis && cd ~/artemis
git checkout 351ca8422f7b5b54e80a9c1ce03a222e02415b6b
git apply <repo>/e2e_test/artemis-local.patch
uv sync --python 3.12 && cp .env.example .env   # set GEMINI_API_KEY
uv run python -m artemis ui --no-open           # daemon on http://127.0.0.1:8000

# 2. App: install a debug build with Firebase configured and the SerpAPI key.
flutter build apk --debug --dart-define-from-file=.env && adb install -r build/app/outputs/flutter-apk/app-debug.apk

# 3. Tests (from the repository root)
cd e2e_test && cp .env.example .env   # fill in DEVICE_SERIAL, TEST_ACCOUNT_EMAIL
uv sync
uv run pytest --count 3 -v            # every test 3 times (pytest-repeat)
```

Each run appends `{test_id, status, succeeded, trace_id, seconds, error, pytest, failure}` to `e2e_test/artifacts/runs.jsonl` once the test ends; `pytest` (`passed` / `failed`) is the result, `succeeded` only ARTEMIS's status. Copy the run table, trace IDs and screenshots / replays into `evidence/artemis/`.

## 2. Critical flows → screens

| Flow | Screens |
|---|---|
| Sign-in / sign-out | Splash, Login, Google account picker (native), Home, Profile |
| Flow 1 Search | Home, Search, Filter sheet, Search Results, Internship Detail |
| Flow 2 Apply (incl. 2e Save) | Internship Detail, Saved Internships, Application Form, CV Match Check, Application Review, Application Success |
| Flow 3 Track | My Applications, Application Detail, Withdraw dialog |
| Export and upload | Profile → Report export |
| Firebase demo | Profile → Firebase demo area (Remote Config values, Crashlytics actions), Notification Center, notification shade (native) |

## 3. Test cases

Type: **Happy** · **Alt** (alternative path) · **Error** (error / recovery path) · **Native** (Android system UI). Status: **Ready** (runnable now) · **Planned** (screens not built yet; implement with the feature).

Every instruction states the start, the steps and what must be visible, and asks for a JSON report (`expected_output`). Assertions compare the reported values, never `status == "SUCCESS"` alone.

| ID | Flow | Precondition | Instruction (summary) | Expected result (asserted values) | Type | File | Status |
|---|---|---|---|---|---|---|---|
| TC-01 | Sign-in | App installed, signed out (test signs out first if needed); Analytics debug mode | Tap `Continue with Google` → pick the test account in the native picker | `screen_title == "Home"`; nav labels `[Home, Search, Saved, Applications, Profile]`; Login button gone; **`login` event in Logcat** | Native | `test_auth.py` | Ready |
| TC-02 | Navigation | Signed in | Tap Search, Saved, Applications, Profile, Home | For each tap: app bar title == tab and the tab is selected | Happy | `test_navigation.py` | Ready |
| TC-03 | Flow 1 (Search → Filter & Sort → Job Listing) | Signed in; Analytics debug mode | Search tab → `Intern` → `Find Internships` → `Filters` → `Job type: Internship` → `Show … results` | `N internships found` with `N > 0`; active chips include `Internship` and `Intern`; first card title not empty; **`search` and `search_filter_apply` in Logcat** | Happy | `test_search.py` | Ready (not run) |
| TC-04 | Flow 1a | Signed in | Search `zzqx intern` → read the empty state → tap its button | Empty title `No internships found`, button `Clear filters`; after it, `N internships found` with `N > 0` | Error | `test_search.py` | Ready (not run) |
| TC-05 | Flow 1 → Job Detail | Signed in | Search `Intern` → note the first card → open it → Back | App bar `Internship details`; Detail title and company == the card's; `Apply now` and `Save` visible; search field still `Intern` after Back | Happy | `test_detail.py` | Done (3/3, 2026-11-05) |
| TC-06 | Flow 4 Application (Apply Form → Validate CV → Review → Submit → Success) | Signed in; a `Developer` listing not applied to (each run applies to a new one: applications cannot be deleted); the test pushes `Sample_CV.pdf`; Analytics debug mode | Search `Developer` → first card without `Applied` → `Apply now` → upload `Sample_CV.pdf` → fill empty personal fields → `Continue to review` → Validate CV moves on by itself → `Submit application` | Review app bar `Review application` with `Ready to submit`; Success heading `Application submitted!` and `Your application for {card title} at {card company} is saved in My Applications.`; `View my applications` visible; **`application_create` in Logcat**. CV Match Check (2d) is not built (DC-09); add its checks when it is | Happy · Native | `test_apply.py` | Ready (not run) |
| TC-07 | Flow 2c | Signed in; at least one applied `Developer` listing (TC-06 creates one) | Search `Developer` → first card with `Applied` → read the banner and the bottom bar → `View application` | Banner starts with `You applied on `; `Apply now` not visible, `View application` visible; `Application Detail` shows the card's position and company and the banner's status | Alt | `test_apply.py` | Ready (not run) |
| TC-08 | Flow 2e (+2e.1) | Signed in; a `Python` listing neither saved nor applied. Saved is not emptied: counts are compared, and each run leaves one more saved listing | Read the Saved count → Search `Python` → first card not saved / not applied → `Save` → Saved tab → open the top card → Back → unsave it → `Undo` | Snackbar `Saved to your list`; count + 1; top saved card == that listing; its detail shows `Apply now`; Snackbar `Removed from Saved`; after Undo the count is still + 1 and the card is back | Alt | `test_saved.py` | Ready (not run) |
| TC-09 | Flow 3 | Signed in; at least one application (test creates one if needed) | Applications tab → open the first application | List item shows position, company, date, status label; detail status label == list label | Happy | `test_applications.py` | Ready (not run) |
| TC-10 | Flow 3b | Signed in | Turn on airplane mode (Quick Settings) → open Applications → turn it off → tap Retry | Error state with `Retry` while offline; list visible after Retry | Error · Native | `test_applications.py` | Ready (not run) |
| TC-11 | Export and upload | Signed in; at least one application | Profile → Firebase demo → Export report → wait | Progress shown; success with file name `*.pdf` and a download URL; report listed with today's date | Happy | `test_export.py` | Planned |
| TC-12 | Remote Config | Console values set to non-defaults before the run (e.g. `home_recommended_limit = 3`) | Profile → Firebase demo → read Remote Config values; open Home | Reported values == console values; Home shows exactly that many recommended cards | Happy | `test_profile.py` | Planned |
| TC-13 | Notifications | Signed in; app in background; test message sent from the console | Open the notification from the shade | App opens the screen named in the message; Notification Center lists the message title | Native | `test_notifications.py` | Planned |
| TC-14 | Sign-out | Signed in (test signs in first if needed) | Profile → scroll to Settings & support → Sign out → press Back → reopen the app if Back closed it | Login after sign-out; after Back either Login or the Android home screen (Login is the root, so Back may close the app), never a signed-in screen, no bottom navigation; Login again after reopening | Happy | `test_auth.py` | Ready |
| TC-15 | Permission | Fresh install on Android 13+ | First launch after sign-in | Notification permission dialog shown; after Allow, the Firebase demo area shows permission granted | Native | `test_notifications.py` | Planned |
| TC-16 | Home role discovery | Signed in; at least one Frontend listing in the pool | Home → read `Browse by Role` / `All roles` → tap `Frontend` → tap `All roles` | `selected_role == "Frontend"` with a check mark; at least one recommended title; `after_all_roles_screen_title == "Search"` | Happy | `test_home_roles.py` | Ready (not run) |
| TC-18 | Flow 1 pre-submit (Check CV → Continue) | Signed in; Analytics debug mode | Search `Intern` → first card → `Apply now` → read the CV section → fill empty personal fields (`Test Student`, `0908123456`, `FPT University`, `Year 3`) → `Continue to review` | App bar `Apply Form`; step `Step 1 of 2 · Your details`; with a CV: next screen `Validate CV` (Flow 4 starts there; its result is not asserted); without: still `Apply Form` with `Add a CV to continue…`; **`apply_start` in Logcat** | Happy | `test_apply_form.py` | Ready (not run) |
| TC-19 | Flow 1 pre-submit (Upload / Select CV) | Signed in; the test pushes `Sample_CV.pdf` (no personal data) to Downloads | Apply Form → `Replace` / `Upload CV` → `Choose file` → pick the file in the Android picker → `Update CV` / `Upload CV` | CV file name ends in `.pdf`; line under it `Uploaded for this internship` | Native | `test_apply_form.py` | Ready (not run) |
| TC-20 | Flow 1 alt. (CV upload failed) | Signed in; the test turns Wi-Fi and data off with `adb` and back on afterwards; listings from the Firestore cache | Apply Form → `Replace` → pick `Sample_CV.pdf` → `Update CV` → wait for the error | Error `We could not upload the file. Check your connection and try again.` (upload retries are capped at 30 s) | Error · Native | `test_apply_form.py` | Ready (not run) |
| TC-17 | Profile upkeep (Flow 2 alt., 2d `Edit skills`) | Signed in; `Docker` not yet in the profile skills (test removes it first if needed) | Profile → `Add skill` → search `dock` → tap `Docker` → `Save changes` | Sheet closed; `Technical skills` lists `Docker`; reported skills include `Docker` | Alt | `test_profile_skills.py` | Ready (not run) |

### Coverage (Lab 3 §7)

| Required | Test cases |
|---|---|
| Each Lab 2 flow end to end incl. alternative and error paths | Flow 1: TC-03/04/05 + pre-submit TC-18/19/20 · Flow 2: TC-06/07/08 · Flow 3: TC-09/10 |
| Sign-in · sign-out | TC-01 · TC-14 |
| Main search / primary action | TC-03, TC-06 |
| Each top-level tab | TC-02 |
| Home role discovery | TC-16 |
| Profile (edit skills, Flow 2d target) | TC-17 |
| Each kind of detail screen | Internship Detail TC-05 · Application Detail TC-09 |
| Export and upload | TC-11 |
| Remote Config values on screen | TC-12 |
| ≥ 1 error path | TC-04, TC-10, TC-20 |
| ≥ 1 native interaction | TC-01 (account picker), TC-10 (Quick Settings), TC-13 (notification shade), TC-15 (permission dialog), TC-19 / TC-20 (Android document picker) |
| ≥ 1 analytics check | TC-01 (`login` in Logcat), TC-03 (`search`, `search_filter_apply`), TC-18 (`apply_start`) |
| Exploratory session (Pro) | §5 |

## 4. Results (≥ 3 runs per test)

Fill from `e2e_test/artifacts/runs.jsonl`; link traces / replays stored in `evidence/artemis/`.

**Attempt 2026-10-31 (not run):** the Android side is ready — `emulator-5554`
(API 37) is connected and `com.group3.internly` is installed — but the ARTEMIS
daemon at `127.0.0.1:8000` is not running, `uv` and a real Python are not
installed, and there is no `google/artemis` checkout or model API key on this
machine. No test was executed and no `runs.jsonl` entry was written. See
[`../evidence/artemis/e2e-environment-20261031.md`](../evidence/artemis/e2e-environment-20261031.md).

**Run 2026-11-05 (macOS host, `emulator-5554` API 36):** first real runs. TC-05
was run 11 times while the model choice, the report read-back, typing and the
cold start were fixed. Every run and its cause is in
[`../evidence/artemis/e2e-environment-20261105.md`](../evidence/artemis/e2e-environment-20261105.md)
and in the flaky / failed table below. The row reports the final three runs on
the fixed setup (`6fe33a9` + `artemis-local.patch`).

| Test ID | Runs | Passed | Pass rate | Avg time (s) | Trace IDs / evidence | Notes |
|---|---|---|---|---|---|---|
| TC-05 | 3 | 3 | 100% | 65.7 | `505846be`, `045c4d16`, `ebe3d568` ([evidence](../evidence/artemis/e2e-environment-20261105.md), [`runs-20261105.jsonl`](../evidence/artemis/runs-20261105.jsonl)) | `uv run pytest test_detail.py --count 3 -v`, 2026-11-05 23:35–23:38, `gemini-3.1-flash-lite`. All 11 runs that day: 6 passed (one of them not valid, run 3), 5 failed; causes below |
| TC-01 | 0 | 0 | n/a | n/a | **Not run 2026-10-31**: no ARTEMIS daemon/toolchain (`evidence/artemis/e2e-environment-20261031.md`) | Ready case; must pass 3/3 before marked Done |
| TC-02 | 0 | 0 | n/a | n/a | **Not run 2026-10-31**: same environment blocker | Ready case; must pass 3/3 before marked Done |
| TC-14 | 0 | 0 | n/a | n/a | **Not run 2026-10-31**: same environment blocker | Ready case; must pass 3/3 before marked Done |
| TC-16 | 0 | 0 | n/a | n/a | **Not run**: no Android device/emulator and no ARTEMIS daemon (`evidence/artemis/e2e-environment-20261022.md`); still not run 2026-10-31 (no ARTEMIS daemon/toolchain, `evidence/artemis/e2e-environment-20261031.md`) | Case added 2026-10-22; must pass 3/3 before marked Done |
| TC-17 | 0 | 0 | n/a | n/a | **Not run**: no Android device/emulator and no ARTEMIS daemon on this machine; still not run 2026-10-31 (no ARTEMIS daemon/toolchain, `evidence/artemis/e2e-environment-20261031.md`) | Case added 2026-10-28; must pass 3/3 before marked Done |
| TC-09 | 0 | 0 | n/a | n/a | **Not run 2026-11-04**: case written, but no ARTEMIS daemon/toolchain on this machine (`evidence/artemis/e2e-environment-20261031.md`) | Ready case; must pass 3/3 before marked Done |
| TC-10 | 0 | 0 | n/a | n/a | **Not run 2026-11-04**: same environment blocker | Ready case; must pass 3/3 before marked Done |
| … | | | | | | |

**Flaky / failed / skipped tests:** a test that does not pass 3 of 3 is flaky. For each one, record the cause (app bug, timing, or ambiguous instruction) and the fix.

| Test ID | Pass rate | Cause | Fix (commit / instruction change) |
|---|---|---|---|
| TC-05 run 1 (`1d8523a8`) | 0/1 | Environment: `gemini-3.5-flash-lite` returned 503 "high demand"; the call timed out after 180 s before ARTEMIS tried its fallback | Primary model `gemini-3.1-flash-lite` ([`artemis-local.patch`](../e2e_test/artemis-local.patch)) |
| TC-05 run 2 (`ea95f1be`) | 0/1 | Harness: ARTEMIS `351ca84` never runs its Outputter, so `result.output` is `None` (`no structured output`) | `run_case()` asks for the JSON in `report_task_status` and `final_report()` reads it from `/api/sessions/{id}/steps` (`6fe33a9`) |
| TC-05 run 3 (`56300b5c`) | passed, not counted | Test isolation: the agent did not type; "Intern" was left in the field by run 2 | `cold_start_app` fixture force-stops the app before each run (`6fe33a9`) |
| TC-05 run 4 (`d3b8a433`) | 0/1 | Tool: ARTEMIS types by clipboard + `KEYCODE_PASTE`, which a Flutter `TextField` ignores while ARTEMIS reports success; the report was also prose | ASCII text typed with `adb shell input text` ([`artemis-local.patch`](../e2e_test/artemis-local.patch)) |
| TC-05 run 5 (`d589c61d`) | 1/1 (197 s) | Timing: "internly isn't responding" twice during the debug build's cold start; the agent recovered | Fixture launches the app with `am start -W` and waits 10 s (`6fe33a9`) |
| TC-05 runs 6–8 (`a0ee4316`, `a96423d9`, `fced7607`) | 1/3 | Ambiguous instruction: `gemini-3.1-flash-lite` wrote a sentence instead of the JSON in 2 of 3 runs (the flow itself was right) | Stricter request naming `report_task_status` and "exactly one JSON object" (`6fe33a9`); runs 9–11 then passed 3/3 |

## 5. Exploratory session (Pro profile, 15–30 min)

Command: `uv run artemis run "<charter>" --profile pro` on the ARTEMIS host.

- **Charter:** "As a third-year IT student, explore Internly for 20 minutes: search internships, save, apply, track, export a report and change screens quickly. Report crashes, dead ends, missing Back behavior, overflow, unreadable text and slow screens."
- **Date / build / device:** _
- **Trace ID / replay:** _

| # | Issue found | Screen | Severity | Action (issue / fix commit) |
|---|---|---|---|---|

## 6. Rules for writing tests

1. One pytest function = one instruction through `run_case()` (`e2e_test/conftest.py`).
2. The instruction states the starting point, the steps and exactly what must be visible; "check that the app works" is not a test.
3. Ask for a JSON report in `expected_output` and assert on its values. `run_case()` repeats that schema in the instruction and reads the JSON from the agent's final `report_task_status`, because ARTEMIS `351ca84` returns no `output`.
4. Tests never depend on each other's order: start from `SIGNED_IN` / `SIGNED_OUT` or create the needed data inside the instruction.
5. Add `Semantics` labels / tooltips to every widget a test needs (shared components already expose them).
6. Never commit `.env`, account credentials or model API keys.
