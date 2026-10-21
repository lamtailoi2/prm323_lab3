# Test plan: ARTEMIS end-to-end tests

End-to-end tests drive the **Android** app with [Google ARTEMIS](https://github.com/google/artemis) from natural-language instructions (Lab 3 §7). Flutter unit, ViewModel and widget tests are reported in [`test-report.md`](test-report.md).

| Item | Value |
|---|---|
| ARTEMIS commit | `351ca8422f7b5b54e80a9c1ce03a222e02415b6b` (2026-09-29), pinned in `e2e_test/pyproject.toml` and README |
| SDK | `artemis-client` (`ArtemisClient.run(goal, expected_output=…, locked_app_package=…)`) |
| Profiles | **Flash** for every regression test; **Pro** only for the exploratory session |
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

```bash
# 1. ARTEMIS host (once): clone google/artemis at the pinned commit, add the model API key
#    to its own .env, then start the daemon and connect the device.
git clone https://github.com/google/artemis && cd artemis
git checkout 351ca8422f7b5b54e80a9c1ce03a222e02415b6b
./start.sh

# 2. App: install a debug build with Firebase configured and the SerpAPI key.
flutter build apk --debug --dart-define-from-file=.env && adb install -r build/app/outputs/flutter-apk/app-debug.apk

# 3. Tests (from the repository root)
cd e2e_test && cp .env.example .env   # fill in DEVICE_SERIAL, TEST_ACCOUNT_EMAIL
uv sync
uv run pytest --count 3 -v            # every test 3 times (pytest-repeat)
```

Each run appends `{test_id, status, trace_id, seconds}` to `e2e_test/artifacts/runs.jsonl`. Copy the run table, trace IDs and screenshots / replays into `evidence/artemis/`.

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
| TC-03 | Flow 1 | Signed in | Home → search `Flutter intern` → Filters → `Remote` → Show results | `result_count > 0`; first card title not empty; every visible card shows `Remote` | Happy | `test_search.py` | Planned |
| TC-04 | Flow 1a | Signed in | Search a keyword with no results (e.g. `zzqx intern`) | Empty state text `No results found` and a `Clear filters` button | Error | `test_search.py` | Planned |
| TC-05 | Flow 1 → detail | Signed in | Search `Flutter intern` → open the first card | Detail title and company == the card's; `Apply now` visible; report the job title | Happy | `test_detail.py` | Planned |
| TC-06 | Flow 2 + 2d | Signed in; profile complete with skills that do not cover every requirement | From a listing not applied to: Apply now → Continue → read CV Match Check → Continue to review → Submit | Match summary `N of M` with `N < M`; at least 1 suggestion; Success shows the same title and company | Happy | `test_apply.py` | Planned |
| TC-07 | Flow 2c | Signed in; TC-06 listing already applied (test applies first if needed) | Open the same listing again | `You applied on …` visible; `Apply now` not visible; `View application` opens status `Submitted` | Alt | `test_apply.py` | Planned |
| TC-08 | Flow 2e (+2e.1) | Signed in; Saved list emptied by the test first | Open a listing → Save → Saved tab → open the saved card; back; Unsave → Undo | Snackbar `Saved to your list`; saved count == 1; detail shows `Apply now`; after Undo the card is back | Alt | `test_saved.py` | Planned |
| TC-09 | Flow 3 | Signed in; at least one application (test creates one if needed) | Applications tab → open the first application | List item shows position, company, date, status label; detail status label == list label | Happy | `test_applications.py` | Planned |
| TC-10 | Flow 3b | Signed in | Turn on airplane mode (Quick Settings) → open Applications → turn it off → tap Retry | Error state with `Retry` while offline; list visible after Retry | Error · Native | `test_applications.py` | Planned |
| TC-11 | Export and upload | Signed in; at least one application | Profile → Firebase demo → Export report → wait | Progress shown; success with file name `*.pdf` and a URL; report listed with today's date | Happy | `test_export.py` | Planned |
| TC-12 | Remote Config | Console values set to non-defaults before the run (e.g. `home_recommended_limit = 3`) | Profile → Firebase demo → read Remote Config values; open Home | Reported values == console values; Home shows exactly that many recommended cards | Happy | `test_profile.py` | Planned |
| TC-13 | Notifications | Signed in; app in background; test message sent from the console | Open the notification from the shade | App opens the screen named in the message; Notification Center lists the message title | Native | `test_notifications.py` | Planned |
| TC-14 | Sign-out | Signed in (test signs in first if needed) | Profile → Sign out → press Back | Login visible; bottom navigation not visible | Happy | `test_auth.py` | Ready |
| TC-15 | Permission | Fresh install on Android 13+ | First launch after sign-in | Notification permission dialog shown; after Allow, the Firebase demo area shows permission granted | Native | `test_notifications.py` | Planned |

### Coverage (Lab 3 §7)

| Required | Test cases |
|---|---|
| Each Lab 2 flow end to end incl. alternative and error paths | Flow 1: TC-03/04/05 · Flow 2: TC-06/07/08 · Flow 3: TC-09/10 |
| Sign-in · sign-out | TC-01 · TC-14 |
| Main search / primary action | TC-03, TC-06 |
| Each top-level tab | TC-02 |
| Each kind of detail screen | Internship Detail TC-05 · Application Detail TC-09 |
| Export and upload | TC-11 |
| Remote Config values on screen | TC-12 |
| ≥ 1 error path | TC-04, TC-10 |
| ≥ 1 native interaction | TC-01 (account picker), TC-10 (Quick Settings), TC-13 (notification shade), TC-15 (permission dialog) |
| ≥ 1 analytics check | TC-01 (`login` in Logcat) |
| Exploratory session (Pro) | §5 |

## 4. Results (≥ 3 runs per test)

Fill from `e2e_test/artifacts/runs.jsonl`; link traces / replays stored in `evidence/artemis/`.

| Test ID | Runs | Passed | Pass rate | Avg time (s) | Trace IDs / evidence | Notes |
|---|---|---|---|---|---|---|
| TC-01 | | | | | | |
| … | | | | | | |

**Flaky / failed / skipped tests:** a test that does not pass 3 of 3 is flaky. For each one, record the cause (app bug, timing, or ambiguous instruction) and the fix.

| Test ID | Pass rate | Cause | Fix (commit / instruction change) |
|---|---|---|---|

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
3. Ask for a JSON report in `expected_output` and assert on its values.
4. Tests never depend on each other's order: start from `SIGNED_IN` / `SIGNED_OUT` or create the needed data inside the instruction.
5. Add `Semantics` labels / tooltips to every widget a test needs (shared components already expose them).
6. Never commit `.env`, account credentials or model API keys.
