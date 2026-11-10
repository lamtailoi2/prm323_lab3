# Test plan: ARTEMIS end-to-end tests

End-to-end tests drive the **Android** app with [Google ARTEMIS](https://github.com/google/artemis) from natural-language instructions (Lab 3 §7). Flutter unit, ViewModel and widget tests are reported in [`test-report.md`](records/test-report.md).

| Item | Value |
|---|---|
| ARTEMIS commit | `351ca8422f7b5b54e80a9c1ce03a222e02415b6b` (2026-09-29), pinned in `e2e_test/pyproject.toml` and README |
| SDK | `artemis-client` (`ArtemisClient.run(goal, expected_output=…, locked_app_package=…)`) |
| Profiles | **Flash** for every regression test; **Pro** only for the exploratory session |
| Model | `gemini-3.1-flash-lite`, fallback `gemini-3.5-flash-lite` (free tier), set on the host by [`e2e_test/artemis-local.patch`](../e2e_test/artemis-local.patch) since 2026-11-05: the default `gemini-3.8-flash` allows 20 requests per day on the free tier and was overloaded. Each Flash-Lite model allows 500 requests per day (reset 15:00 in Vietnam); when 3.1 runs out, swap primary and fallback for the day (done 2026-11-06 for TC-01 / TC-14) |
| App build | **Profile** build (`flutter build apk --profile`): the debug build froze on Home under ARTEMIS ("isn't responding", 2026-11-06) |
| Device | Android device or emulator (API 33+ for the notification permission case) |
| Account | Dedicated Google test account added on the device; no password stored anywhere |
| CV library | TC-19 needs at least 2 CVs in Profile → `CV library`; `Change CV` and auto-select need 2+ |
| Email app | Gmail signed in on the device for TC-18; the test replaces the recipient with the test account before sending |
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

# 2. App: install a profile build (signed with the shared debug key) and pre-grant notifications
#    (the app asks after sign-in; TC-15 tests that dialog on a fresh install instead).
flutter build apk --profile --dart-define-from-file=.env && adb install -r build/app/outputs/flutter-apk/app-profile.apk
adb shell pm grant com.group3.internly android.permission.POST_NOTIFICATIONS

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
| TC-01 | Sign-in | App installed, signed out (test signs out first if needed); Analytics debug mode | Tap `Continue with Google` → pick the test account in the native picker | Highlighted tab `Home` (since UI v2 the Home header shows a greeting and the name, DC-31); nav labels `[Home, Search, Saved, Applications, Profile]`; Login button gone; **`login` event in Logcat** | Native | `test_auth.py` | Done (3/3, 2026-11-08, UI v2) |
| TC-02 | Navigation | Signed in | Tap Search, Saved, Applications, Profile, Home | For each tap: the tab is selected; app bar title == tab, except Home, whose header shows a greeting and the name since UI v2 (DC-31) | Happy | `test_navigation.py` | Done (3/3, 2026-11-08, UI v2) |
| TC-03 | Flow 1 (Search → Filter & Sort → Job Listing) | Signed in; Analytics debug mode | Search tab → `Intern` → `Find Internships` → `Filters` → `Job type: Internship` → `Show … results` | `N internships found` with `N > 0`; active chips include `Internship` and `Intern`; first card title not empty; **`search` and `search_filter_apply` in Logcat** | Happy | `test_search.py` | Done (3/3, 2026-11-08, UI v2) |
| TC-04 | Flow 1a | Signed in | Search `zzqx intern` → read the empty state → tap its button | Empty title `No internships found`, button `Clear filters`; after it, `N internships found` with `N > 0` | Error | `test_search.py` | Done (3/3, 2026-11-08, UI v2) |
| TC-05 | Flow 1 → Job Detail | Signed in | Search `Intern` → the first card with no `Applied` badge and not saved → open it → Back | App bar `Internship details`; Detail title and company == the card's; `Apply now` and `Save` visible; search field still `Intern` after Back | Happy | `test_detail.py` | Done (3/3, 2026-11-08, UI v2) |
| TC-06 | Flow 2 (Compose → `I've sent it`) | Signed in; a `Developer` listing not applied to (each run records a real application) | Search `Developer` → that listing → `Apply now` → read `To`, `Subject`, the cover letter and the draft notice → `I've sent it` | App bar `Apply by email`; `Subject` and the letter are non-empty; the notice names the AI draft or the template; `Open email app` and `I've sent it` visible; Success shows the same title and company | Happy | `test_apply.py` | Done (3/3, 2026-11-09; traces `5dab06b9`, `038180be`, `9bd3dc18`) |
| TC-07 | Flow 2c | Signed in; TC-06 has applied to at least one `Developer` listing | Search `Developer` → first card with `Applied` → read the banner and the bottom bar → `View application` → read `Applicant & Submitted CV` | Banner starts with `You applied on `; `Apply now` not visible, `View application` visible; `Application Detail` shows the card's position, company, banner status, a non-empty CV file name, its `Uploaded` / `Submitted` details line, `Preview` visible and no `Replace CV` | Alt | `test_apply.py` | Done (3/3 counted 2026-11-10; traces `e37d7261`, `38871e13`, `5116dc27`; one earlier run failed on the title check) |
| TC-08 | Flow 2e (+2e.1) | Signed in; a `Python` listing neither saved nor applied. Saved is not emptied: counts are compared, and the case unsaves the card it saved | Read the Saved count → Search `Python` → first card not saved / not applied → `Save` → Saved tab → find that card by its title (Saved is ordered by posting date) → open it → Back → unsave only that card (no `Undo`) | The detail button reads `Saved`; count + 1; the card is in Saved; its detail shows `Apply now`; Snackbar `Removed from Saved`; count back to the start and the card gone. `Undo` and the `Saved to your list` Snackbar are covered by widget tests (`saved_screen_test.dart`, `internship_detail_screen_test.dart`): each ARTEMIS step takes 5–15 s and the Snackbar shows for 4 s | Alt | `test_saved.py` | Done (3/3, 2026-11-08, UI v2) |
| TC-09 | Flow 3 | Signed in; at least one application with a CV snapshot (the case only reads; TC-06 creates one) | Applications tab → open the first application → read the list item, the detail badges and `Applicant & Submitted CV` | List item shows position, company, date, status label; detail status label == list label; detail shows a non-empty CV file name, its `Uploaded` / `Submitted` details line, `Preview` visible and no `Replace CV` | Happy | `test_applications.py` | Done (3/3 counted 2026-11-10; traces `5192a465`, `f1233bb8`, `8c04b889`; one earlier run failed on the title check) |
| TC-10 | Flow 3b | Signed in; at least one application; the test turns Wi-Fi and data off with `adb` and back on afterwards | Offline → open Applications | The cached list stays visible: a card with a position and the `N application(s)` line; no error, no `Retry` (Firestore offline cache, run `f1e857a4`) | Error | `test_applications.py` | Done (3/3, 2026-11-08, UI v2) |
| TC-11 | Export and upload | Signed in; at least one application | Profile → Firebase demo → Export report → wait | Progress shown; success with file name `*.pdf` and a download URL; report listed with today's date | Happy | — | Planned (case not written) |
| TC-12 | Remote Config | Signed in; for evidence, `home_recommended_limit` set to a non-default value in the console (e.g. 3; in-app default 5) | Profile → `Firebase demo` → read the `home_recommended_limit` line (`N · source`) → Home → count the cards under `Recommended for you` | Source is `From Firebase`, `In-app default` or `Static value`; Home shows exactly N recommended cards | Happy | `test_profile.py` | Done (3/3, 2026-11-08, UI v2) |
| TC-13 | Notifications | Signed in; the test sends the app to the background, then waits up to 180 s while the operator sends one FCM message with route `/saved` (admin dashboard or Firebase console: the suite holds no project credentials) | Open the new internly notification from the shade → wait 3 s → bell → Notifications | **`screen_view` `saved` in Logcat** after the tap (the app reaches the route about 2 s later, often after the agent has read the screen; ARTEMIS brings the app to the front before the tap); the Notifications screen lists the same title, marked `Read` | Native | `test_notifications.py` | Done (3/3, 2026-11-08, UI v2) |
| TC-14 | Sign-out | Signed in (test signs in first if needed) | Profile → scroll past `CV library` and `Technical skills` to Settings & support → Sign out → press Back → reopen the app if Back closed it | Login after sign-out; after Back either Login or the Android home screen (Login is the root, so Back may close the app), never a signed-in screen, no bottom navigation; Login again after reopening | Happy | `test_auth.py` | Ready (2/4, 2026-11-10; `4991c7dc`, `0f1910f3` passed; `d84b3a90`, `bec24fcb` cancelled) |
| TC-15 | Permission | Signed in, Android 13+; the test revokes `POST_NOTIFICATIONS`, clears its flags with `adb` (the state of a fresh install, checked by hand 2026-11-06) and leaves the app stopped, so the case opens it once; it grants the permission back afterwards | App start → system dialog → `Allow` | Dialog "Allow internly to send you notifications?" with `Allow`; the `Home` tab highlighted after it (the Home header shows a greeting since UI v2); permission granted (`dumpsys package`) | Native | `test_notifications.py` | Done (3/3, 2026-11-08, UI v2) |
| TC-16 | Home role discovery | Signed in; at least one Frontend listing in the pool | Home → read `Browse by Role` / `All roles` → tap `Frontend` → tap `All roles` | `selected_role == "Frontend"` with a check mark; at least one recommended title; `after_all_roles_screen_title == "Search"` | Happy | `test_home_roles.py` | Done (3/3, 2026-11-08, UI v2) |
| TC-18 | Flow 2 (Compose → Gmail → `I've sent it`) | Signed in; Analytics debug mode; Gmail on the device | Search `Intern` → first card with no `Applied` badge → `Apply now` → wait for the draft → read the banner, title, company, `To`, `Subject` and letter → `Open email app` → in Gmail replace `To` with the test account → `Send` → Back to Internly → `I've sent it` | App bar `Apply by email`; banner says `Drafted from the job description` or `template`; subject and letter non-empty; Gmail opens with the draft; after the edit Gmail's `To` == `lap262005@gmail.com`; `Send` tapped and Gmail shows the sent state; back in the app; success heading `Application submitted!` with the same title and company; **`apply_start` and `application_create` in Logcat** | Native | `test_apply_form.py` | Done (3/3, 2026-11-09, full email flow) |
| TC-19 | Flow 2 (CV change + letter edit) | Signed in; 2+ CVs in Profile | Compose screen → scroll to `CV / Resume` → read the CV → `Change CV` → choose another library CV → `Done` → wait for the draft → append ` Test line.` to the letter | Sheet title `Change CV`; the chosen CV differs from the first one and is shown in `CV / Resume`; the character count under the letter is > 0 | Happy | `test_apply_form.py` | Ready (0/3, 2026-11-10; `be05e6e5`, `0aba4890` cancelled, `83edba2d` failed after 10.8 s) |
| TC-20 | ~~Flow 1 alt. (CV upload failed)~~ | — | — | Removed with the Apply Form (DC-31): the compose screen has no upload. A failed AI draft shows the message + `Retry` and is covered by `ApplyComposeViewModel` unit tests. The old 3/3 result stays as history in §4. | — | — | Removed |
| TC-17 | Profile upkeep (Flow 2 alt., 2d `Edit skills`) | Signed in; `Docker` not yet in the profile skills (test removes it first if needed) | Profile → scroll to `Technical skills` below `CV library` → `Add skill` → search `dock` → tap `Docker` → `Save changes` | Sheet closed; `Technical skills` lists `Docker`; reported skills include `Docker` | Alt | `test_profile_skills.py` | Done (3/3, 2026-11-10; traces `aacb86b6`, `23eed7a8`, `765a86e0`) |

### Coverage (Lab 3 §7)

| Required | Test cases |
|---|---|
| Each Lab 2 flow end to end incl. alternative and error paths | Flow 1: TC-03/04/05 + pre-submit TC-18/19 · Flow 2: TC-06/07/08 · Flow 3: TC-09/10 |
| Sign-in · sign-out | TC-01 · TC-14 |
| Main search / primary action | TC-03, TC-06 |
| Each top-level tab | TC-02 |
| Home role discovery | TC-16 |
| Profile (edit skills, Flow 2d target) | TC-17 |
| Each kind of detail screen | Internship Detail TC-05 · Application Detail TC-09 |
| Export and upload | TC-11 |
| Remote Config values on screen | TC-12 |
| ≥ 1 error path | TC-04, TC-10 |
| ≥ 1 native interaction | TC-01 (account picker), TC-13 (notification shade), TC-15 (permission dialog), TC-18 (Gmail compose/send) |
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

**Run 2026-11-06 (profile build of `dev` `a5d1e4a`):** TC-01, TC-02, TC-14, TC-16
and TC-17, three counted runs each, after six exploratory runs on the older debug
build. TC-01 and TC-14 ran on `gemini-3.5-flash-lite` because `gemini-3.1-flash-lite`
had used its 500 requests for the day. From 08:04 one application was submitted by hand
(no ARTEMIS) and shared by TC-07, TC-09 and TC-10; TC-07, TC-08 and TC-09 then ran three times each. All 34
runs, the cancelled attempt and the causes are in
[`../evidence/artemis/e2e-environment-20261106.md`](../evidence/artemis/e2e-environment-20261106.md).

| Test ID | Runs | Passed | Pass rate | Avg time (s) | Trace IDs / evidence | Notes |
|---|---|---|---|---|---|---|
| TC-05 | 3 | 3 | 100% | 65.7 | `505846be`, `045c4d16`, `ebe3d568` ([evidence](../evidence/artemis/e2e-environment-20261105.md), [`runs-20261105.jsonl`](../evidence/artemis/runs-20261105.jsonl)) | `uv run pytest test_detail.py --count 3 -v`, 2026-11-05 23:35–23:38, `gemini-3.1-flash-lite`. All 11 runs that day: 6 passed (one of them not valid, run 3), 5 failed; causes below |
| TC-01 | 3 | 3 | 100% | 64.1 | `cebfd52e`, `dd7ba1ab`, `5b765e36` ([evidence](../evidence/artemis/e2e-environment-20261106.md), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 07:43–07:47, `gemini-3.5-flash-lite`; `login` in Logcat each run. Exploratory run `931bbeb4` (debug build) also passed |
| TC-02 | 3 | 3 | 100% | 48.8 | `07d88fd1`, `ac4bb584`, `8198585d` ([evidence](../evidence/artemis/e2e-environment-20261106.md), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 07:13–07:15, `gemini-3.1-flash-lite`. Exploratory run `bd33a94b` also passed |
| TC-14 | 3 | 3 | 100% | 135.7 | `a0e01cc7`, `0ac66774`, `86a6bc0d` ([evidence](../evidence/artemis/e2e-environment-20261106.md), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 07:36–07:43, `gemini-3.5-flash-lite`, rewritten case (`512c8f4`); attempt `0a061c60` cancelled on the 3.1 daily quota. Exploratory: old case failed, rewritten case passed (below) |
| TC-16 | 3 | 3 | 100% | 43.0 | `e1dd7211`, `ec6fb253`, `4747eea1` ([evidence](../evidence/artemis/e2e-environment-20261106.md), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 07:16–07:19, `gemini-3.1-flash-lite`, no ANR on the profile build. Exploratory run on the debug build failed (below) |
| TC-17 | 3 | 3 | 100% | 97.5 | `01670a2f`, `0d75120d`, `30344dfd` ([evidence](../evidence/artemis/e2e-environment-20261106.md), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 07:19–07:24, `gemini-3.1-flash-lite`; adds `Docker` to the account's skills. Exploratory run `ece6eded` also passed |
| TC-07 | 3 | 3 | 100% | 52.9 | `b3c12d02`, `c293b71d`, `789431b9` ([evidence](../evidence/artemis/e2e-environment-20261106.md), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 08:18–08:21, `gemini-3.5-flash-lite`, on the Client Success Intern application. Exploratory run `b08c12ee` also passed |
| TC-08 | 3 | 0 | 0% | 114.1 | `437397d9`, `a3dc0d3b`, `e1d1565d` ([evidence](../evidence/artemis/e2e-environment-20261106.md), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 08:21–08:28: wrong expectation (top card) and a missed Undo, causes below; rewritten `f9b5f43`, to rerun. Exploratory run `7da3ef7c` passed |
| TC-08 | 3 | 3 | 100% | 179.4 | `7bda5a47`, `1d1f3d20`, `1753334f` ([evidence](../evidence/artemis/e2e-environment-20261106.md#tc-08-tc-10-tc-15-1250--1430), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 14:21–14:30, case without `Undo`, `gemini-3.5-flash-lite`; step history checked for each run (Save → open from Saved → Back → unsave). 12 earlier runs failed or were not counted (below) |
| TC-09 | 3 | 3 | 100% | 23.9 | `58144485`, `b44e3547`, `dfe47b1a` ([evidence](../evidence/artemis/e2e-environment-20261106.md), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 08:28–08:30, `gemini-3.5-flash-lite`. Exploratory run `ea708962` also passed |
| TC-10 | 3 | 3 | 100% | 36.1 | `2956f83e`, `8cbd2938`, `395acd45` ([evidence](../evidence/artemis/e2e-environment-20261106.md#tc-08-tc-10-tc-15-1250--1430), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 13:11–13:13, `dev` `d4674ee`, `gemini-3.1-flash-lite`; network off with `adb`. Earlier: exploratory `f1e857a4` failed (wrong expectation, below), `e6299835` failed on an emulator crash, 2 passes on the older build not counted |
| TC-03 | 3 | 3 | 100% | 74.5 | `55c7985d`, `2b271938`, `c07e2122` ([evidence](../evidence/artemis/e2e-environment-20261106.md#flow-1-1030--1229), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 12:16–12:19, `gemini-3.1-flash-lite`, after the app fix for the missing `Job type` chip (P-70); `search` and `search_filter_apply` in Logcat. The first 3 runs failed (below) |
| TC-04 | 3 | 3 | 100% | 46.8 | `c90faf15`, `a824cd6a`, `63631ad3` ([evidence](../evidence/artemis/e2e-environment-20261106.md#flow-1-1030--1229), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 10:35–10:37, `gemini-3.5-flash-lite` |
| TC-05 | 3 | 3 | 100% | 50.1 | `108cf8ac`, `e0ada1d5`, `1ab4c069` ([evidence](../evidence/artemis/e2e-environment-20261106.md#flow-1-1030--1229), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 10:39–10:41, `gemini-3.5-flash-lite`, case that skips applied / saved cards (P-68) |
| TC-18 | 3 | 3 | 100% | 108.2 | `92169173`, `5a13af8f`, `655227ed` ([evidence](../evidence/artemis/e2e-environment-20261106.md#flow-1-1030--1229), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 11:06–11:10, `gemini-3.5-flash-lite`, case accepting `CV match`; `apply_start` in Logcat. The first 3 runs failed (below). Old Apply Form, removed with DC-31: not valid for the email flow |
| TC-19 | 3 | 3 | 100% | 161.7 | `a1482888`, `58225e0a`, `7a1e3528` ([evidence](../evidence/artemis/e2e-environment-20261106.md#flow-1-1030--1229), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 11:25–12:25, `gemini-3.1-flash-lite`, final wording. Six earlier runs failed (below). Old Apply Form, removed with DC-31: not valid for the email flow |
| TC-20 | 3 | 3 | 100% | 137.9 | `774a3906`, `32d3c95c`, `69f090e2` ([evidence](../evidence/artemis/e2e-environment-20261106.md#flow-1-1030--1229), [`runs-20261106.jsonl`](../evidence/artemis/runs-20261106.jsonl)) | 2026-11-06 10:58–11:03, `gemini-3.5-flash-lite`; Wi-Fi and data off with `adb`. Old Apply Form, removed with DC-31: the case is removed |
| … | | | | | | |

**Run 2026-11-06 Flow 1 (10:30–12:29):** TC-03, TC-04, TC-05, TC-18, TC-19 and TC-20, with a free-tier key from another team member's own project (the owner's 3.1 quota was used up). 31 runs, 735 model calls. TC-03 found an app bug (no `Job type` chip), fixed in P-70 before its counted runs; TC-18 and TC-19 were reworded. Every run and cause is in [`../evidence/artemis/e2e-environment-20261106.md`](../evidence/artemis/e2e-environment-20261106.md#flow-1-1030--1229).

**Run 2026-11-06 TC-08 / TC-10 / TC-15 (12:50–14:30):** 22 runs, 438 model calls, on two borrowed free-tier keys (a prepaid one was refused, G-26). TC-10 passed 3/3 on `dev` `d4674ee`. TC-08 passed 3/3 after dropping `Undo` and switching the primary model to `gemini-3.5-flash-lite`: on 3.1 the agent skipped steps and once reported an invented pass. TC-15 failed 0/3 on a test bug (double app launch), fixed, not rerun. Details in [`../evidence/artemis/e2e-environment-20261106.md`](../evidence/artemis/e2e-environment-20261106.md#tc-08-tc-10-tc-15-1250--1430).

**Run 2026-11-07 night – 2026-11-08 (UI v2, `dev` `b5d1209`; TC-13 on `88b3382` + DC-34):** TC-01, TC-02, TC-03, TC-04, TC-05, TC-08, TC-10, TC-12, TC-13, TC-15 and TC-16, three counted runs each, all passed; screen-recorded with the Terminal command. 38 runs, 453 model calls, `gemini-3.5-flash-lite`. Each counted run was checked against its step history. Details in [`../evidence/artemis/e2e-environment-20261108.md`](../evidence/artemis/e2e-environment-20261108.md); screen recordings in the Drive folder [Record Artemis Test - PRM323](https://drive.google.com/drive/folders/1B44bE_K5JY06eAhTU0FrJZrbmcfe7LCf), one per test, matched to the runs in the evidence file.

| Test ID | Runs | Passed | Pass rate | Avg time (s) | Trace IDs / evidence | Notes |
|---|---|---|---|---|---|---|
| TC-01 | 3 | 3 | 100% | 93.7 | `d9aac3bb`, `9313b9ac`, `720cd8ed` ([evidence](../evidence/artemis/e2e-environment-20261108.md), [`runs-20261108.jsonl`](../evidence/artemis/runs-20261108.jsonl)) | 2026-11-08 |
| TC-02 | 3 | 3 | 100% | 47.6 | `a8c08b49`, `115f7fc3`, `55b503e0` ([evidence](../evidence/artemis/e2e-environment-20261108.md), [`runs-20261108.jsonl`](../evidence/artemis/runs-20261108.jsonl)) | 2026-11-08 |
| TC-03 | 3 | 3 | 100% | 75.1 | `256e2ee3`, `05fe9f84`, `27385523` ([evidence](../evidence/artemis/e2e-environment-20261108.md), [`runs-20261108.jsonl`](../evidence/artemis/runs-20261108.jsonl)) | 2026-11-08 |
| TC-04 | 3 | 3 | 100% | 53.6 | `7660a5b0`, `f0fc3eb3`, `3b0c99f6` ([evidence](../evidence/artemis/e2e-environment-20261108.md), [`runs-20261108.jsonl`](../evidence/artemis/runs-20261108.jsonl)) | 2026-11-08 |
| TC-05 | 3 | 3 | 100% | 61.7 | `0973f1e6`, `9451d0c1`, `fecf6a78` ([evidence](../evidence/artemis/e2e-environment-20261108.md), [`runs-20261108.jsonl`](../evidence/artemis/runs-20261108.jsonl)) | 2026-11-08 |
| TC-08 | 3 | 3 | 100% | 106.7 | `146db8f2`, `8a6cb91b`, `f195878e` ([evidence](../evidence/artemis/e2e-environment-20261108.md), [`runs-20261108.jsonl`](../evidence/artemis/runs-20261108.jsonl)) | 2026-11-08 |
| TC-10 | 3 | 3 | 100% | 37.2 | `f74f0ce3`, `5fd55b20`, `7db0d8ae` ([evidence](../evidence/artemis/e2e-environment-20261108.md), [`runs-20261108.jsonl`](../evidence/artemis/runs-20261108.jsonl)) | 2026-11-08 |
| TC-12 | 3 | 3 | 100% | 77.0 | `070f4a53`, `96edd424`, `c99322ce` ([evidence](../evidence/artemis/e2e-environment-20261108.md), [`runs-20261108.jsonl`](../evidence/artemis/runs-20261108.jsonl)) | 2026-11-08 |
| TC-13 | 3 | 3 | 100% | 65.0 | `48f3319d`, `a381427b`, `1e6f3b6c` ([evidence](../evidence/artemis/e2e-environment-20261108.md), [`runs-20261108.jsonl`](../evidence/artemis/runs-20261108.jsonl)) | 2026-11-08 |
| TC-15 | 3 | 3 | 100% | 31.7 | `0c3dfc7e`, `ffc73388`, `2fa04a74` ([evidence](../evidence/artemis/e2e-environment-20261108.md), [`runs-20261108.jsonl`](../evidence/artemis/runs-20261108.jsonl)) | 2026-11-08 |
| TC-16 | 3 | 3 | 100% | 31.5 | `d9094540`, `d68cd6ca`, `658a1882` ([evidence](../evidence/artemis/e2e-environment-20261108.md), [`runs-20261108.jsonl`](../evidence/artemis/runs-20261108.jsonl)) | 2026-11-08 |

**Run 2026-11-09 (`dev` `ac7322e`, profile build, `emulator-5554` API 37, `gemini-3.5-flash-lite`):** TC-18 was rewritten to the full email flow: compose → `Open email app` → Gmail (`To` replaced with the test account) → `Send` → back to Internly → `I've sent it` → `Application submitted!`. One smoke run (`3658371e`, 363.2 s) passed before the counted batch; it is not counted. The three counted runs passed; the video is `e2e_test/artifacts/recordings/20261109/TC-18_Compose_CV.mp4` (pending upload to the Drive folder).

| Test ID | Runs | Passed | Pass rate | Avg time (s) | Trace IDs / evidence | Notes |
|---|---|---|---|---|---|---|
| TC-18 | 3 | 3 | 100% | 151.8 | `5e99ca80`, `2adcba49`, `fd62333f` ([evidence](../evidence/artemis/e2e-environment-20261109.md), [`runs-20261109.jsonl`](../evidence/artemis/runs-20261109.jsonl)) | 2026-11-09, full flow incl. Gmail send to `lap262005@gmail.com` and `I've sent it`; `apply_start` + `application_create` in Logcat |

**Run 2026-11-09 night – 2026-11-10 (Compose/CV regression, `dev` `ac7322e` + the E2E wording fixes `5c27ddd`, profile build, `emulator-5554` API 37, host model `gemini-3.5-flash-lite` — the run log has no per-run model field):** TC-06, TC-07, TC-09, TC-14, TC-17 and TC-19 re-run after the CV library and Compose changes; 25 runs in total. TC-06, TC-07, TC-09 and TC-17 reached 3 of 3 on their last three consecutive runs. TC-14 passed 2 of 4 (two runs cancelled) and TC-19 passed 0 of 3 (two cancelled, one failed after 10.8 s). Every run, cause and recording is in [`../evidence/artemis/e2e-environment-20261110.md`](../evidence/artemis/e2e-environment-20261110.md); the day's lines are in [`runs-20261110.jsonl`](../evidence/artemis/runs-20261110.jsonl).

| Test ID | Runs | Passed | Pass rate | Avg time (s) | Trace IDs / evidence | Notes |
|---|---|---|---|---|---|---|
| TC-06 | 3 | 3 | 100% | 94.2 | `5dab06b9`, `038180be`, `9bd3dc18` ([evidence](../evidence/artemis/e2e-environment-20261110.md), [`runs-20261110.jsonl`](../evidence/artemis/runs-20261110.jsonl)) | 2026-11-09 23:53; all three runs passed |
| TC-07 attempt | 1 | 0 | 0% | 73.2 | `c67149d6` | First run: the card title appends the skills, so the exact comparison with the detail position failed; fixed with `_same_position` in `test_apply.py` |
| TC-07 counted | 3 | 3 | 100% | 82.0 | `e37d7261`, `38871e13`, `5116dc27` | Last three consecutive passes; five of the six runs passed in total |
| TC-09 attempt | 1 | 0 | 0% | 73.2 | `cee108da` | First run: `startswith` compared the list card with the detail position; fixed with `_same_position` in `test_applications.py` |
| TC-09 counted | 3 | 3 | 100% | 65.9 | `5192a465`, `f1233bb8`, `8c04b889` | Last three consecutive passes; five of the six runs passed in total |
| TC-14 | 4 | 2 | 50% | 215.0 | `4991c7dc`, `0f1910f3` passed; `d84b3a90`, `bec24fcb` cancelled | No 3/3 yet |
| TC-17 | 3 | 3 | 100% | 75.3 | `aacb86b6`, `23eed7a8`, `765a86e0` | 2026-11-10 00:35 |
| TC-19 | 3 | 0 | 0% | 74.6 | `be05e6e5`, `0aba4890` cancelled; `83edba2d` failed | 2026-11-09 23:47 – 2026-11-10 00:37; no 3/3 yet |

**Flaky / failed / skipped tests:** a test that does not pass 3 of 3 is flaky. For each one, record the cause (app bug, timing, or ambiguous instruction) and the fix.

| Test ID | Pass rate | Cause | Fix (commit / instruction change) |
|---|---|---|---|
| TC-05 run 1 (`1d8523a8`) | 0/1 | Environment: `gemini-3.5-flash-lite` returned 503 "high demand"; the call timed out after 180 s before ARTEMIS tried its fallback | Primary model `gemini-3.1-flash-lite` ([`artemis-local.patch`](../e2e_test/artemis-local.patch)) |
| TC-05 run 2 (`ea95f1be`) | 0/1 | Harness: ARTEMIS `351ca84` never runs its Outputter, so `result.output` is `None` (`no structured output`) | `run_case()` asks for the JSON in `report_task_status` and `final_report()` reads it from `/api/sessions/{id}/steps` (`6fe33a9`) |
| TC-05 run 3 (`56300b5c`) | passed, not counted | Test isolation: the agent did not type; "Intern" was left in the field by run 2 | `cold_start_app` fixture force-stops the app before each run (`6fe33a9`) |
| TC-05 run 4 (`d3b8a433`) | 0/1 | Tool: ARTEMIS types by clipboard + `KEYCODE_PASTE`, which a Flutter `TextField` ignores while ARTEMIS reports success; the report was also prose | ASCII text typed with `adb shell input text` ([`artemis-local.patch`](../e2e_test/artemis-local.patch)) |
| TC-05 run 5 (`d589c61d`) | 1/1 (197 s) | Timing: "internly isn't responding" twice during the debug build's cold start; the agent recovered | Fixture launches the app with `am start -W` and waits 10 s (`6fe33a9`) |
| TC-05 runs 6–8 (`a0ee4316`, `a96423d9`, `fced7607`) | 1/3 | Ambiguous instruction: `gemini-3.1-flash-lite` wrote a sentence instead of the JSON in 2 of 3 runs (the flow itself was right) | Stricter request naming `report_task_status` and "exactly one JSON object" (`6fe33a9`); runs 9–11 then passed 3/3 |
| TC-16 exploratory (`681590be`) | 0/1 | Timing: on the 2026-11-05 debug build Home froze after tapping `Frontend` ("isn't responding" ×3); a `Wait` tap fell through onto the first recommended card, so `Internship details` opened instead of Search | E2E on a profile build (test-plan §1); counted runs then had no ANR and passed 3/3 |
| TC-14 exploratory (`5e93964f`) | 0/1 | Wrong expectation: after sign-out, Back from Login closes the app (Login is the root), but the case required Login to stay on screen | Case rewritten: Login or the Android home screen after Back, no bottom navigation, Login again after reopening (`512c8f4`); passed in `8931aed1` and 3/3 counted |
| TC-08 runs 1–2 (`437397d9`, `a3dc0d3b`) | 0/2 | Wrong expectation: the case took the first Saved card as the listing it had just saved, but Saved is ordered by posting date (`saved_screen.dart`: the service does not expose `savedAt`) | Find the saved card by its title (`f9b5f43`); "Recent" label raised with the Saved owner |
| TC-08 run 3 (`e1d1565d`) | 0/1 | Timing: the agent missed `Undo` (Snackbar about 4 s). Across the TC-08 runs one of the account's own saved listings (SENZU BASE) was unsaved and one listing was added; the owner left Saved as it is | The case unsaves only the card it saved and taps Undo as one quick sequence (`f9b5f43`) |
| TC-10 exploratory (`f1e857a4`) | 0/1 | Wrong expectation: offline, Applications keeps showing the Firestore-cached list instead of an error with `Retry`; the agent also needed 11 Quick Settings swipes (48 model calls) | Network off with `adb`; asserts the cached list, no error (`f9b5f43`) |
| TC-14 attempt (`0a061c60`) | not counted | Environment: `gemini-3.1-flash-lite` free tier used its 500 requests per day; the run kept retrying on 429 and was cancelled, no `runs.jsonl` line | Primary model swapped to `gemini-3.5-flash-lite` for the day; reruns passed 3/3 |
| TC-03 runs 1–3 (`9cb45bff`, `a039c385`, `bab18c1a`) | 0/3 | App bug: `Job type: Internship` was applied (54 → 23 results) and counted on the Filters badge, but Search Results showed no chip for it, only `Intern` | Chips for job type and allowance added to the active filter row (P-70, test-report Run 32); reruns 3/3 |
| TC-18 runs 1–3 (`51b07205`, `25aa5d78`, `1b4ba996`) | 0/3 | Wrong expectation: since CV Match (PR #24, DC-30) the next screen is `CV match` while `cv_match_enabled` is on | Case accepts `CV match` or `Validate CV`; reruns 3/3 |
| TC-19 runs 1–3 (`ec0bf776`, `964deb59`, `eeb2d83d`) | 0/3 | Ambiguous instruction: the upload worked, but the CV card has two lines under the name and the agent reported `2 KB · PDF` for "the line under it" | Case asks for every line and checks `Uploaded for this internship` is among them |
| TC-19 run `683d1708` | not counted | Environment: the borrowed key's `gemini-3.5-flash-lite` used its 500 requests for the day at 11:12; ARTEMIS timed out after 180 s instead of falling back. The next run `b6763c92` was cancelled | Host config back to the team patch (primary `gemini-3.1-flash-lite`) |
| TC-19 runs `ba904dd4`, `7e2b8eb6` | 0/2 | Ambiguous instruction: on 3.1 the agent saw the Profile CV and reported it without replacing it (`a75cd4e1` passed on the same wording, not counted) | `UPLOAD_SAMPLE_CV`: replace the CV even if one is shown; report only after `Update CV`; reruns 3/3 |
| TC-08 runs `ac1990bb`, `12e44b75`, `aa985d75` | 0/3 | Tool limit: one ARTEMIS step takes 5–15 s and the Snackbar 4 s, so `Undo` was always missed; the agent also read the button `Saved` as the message | `Undo` and `Saved to your list` left to widget tests; the case ends with the unsave and `Removed from Saved` |
| TC-08 runs `b68c9c82`, `6bec2030`, `049a9ddd`, `cdda7c80` | 0/4 (`049a9ddd` passed in pytest, invalid) | Agent on `gemini-3.1-flash-lite`: skipped opening the card from Saved and invented the report (`049a9ddd` stopped after the Saved tab and reported a full pass; its listing stayed saved), read the accessibility label, misread a count | Numbered steps, title of the detail opened from Saved, label check `startswith("Saved")`, primary model `gemini-3.5-flash-lite`; step history checked for counted runs |
| TC-08 `ad1c4f88`, TC-10 `e6299835` | not counted | Environment: emulator crashed (host hang at 13:00 and 13:44, GPU backend at 14:07) | Mac restarted; emulator with `-gpu swiftshader_indirect` |
| TC-15 runs `7c9ea8f9`, `b7c1b34d`, `7587d519` | 0/3 | Test bug: the helper relaunched the app and ARTEMIS opened it again, which closed the permission dialog (no dialog, or a tap on `Allow` landing on a Home card) | `reset_notification_permission()` leaves the app stopped; not run again yet |
| TC-15 runs `7757f9b9`, `c79f4fde`, `f5a17165` (2026-11-08) | 0/3 | Wrong expectation: since UI v2 the Home header shows `Find your next internship` and a greeting, not the title `Home`; the dialog and `Allow` worked | The case checks the highlighted tab (`61d86fc`); reruns 3/3 |
| TC-13, 7 runs moved to `practice-runs.jsonl` (2026-11-08) | not counted | Operator sent route `/applications` (4 runs); then the agent read the screen before the app reached the route about 2 s after the tap (Logcat showed `my_applications` / `saved`), so it reported Home. The app followed the route every time | Wait 3 s in the instruction, and the landing screen checked in Logcat (`logged_screen_views()`), the agent's reading kept in the report only; reruns 3/3 |
| TC-01 `6cae0c7c`, `47ef0815` (2026-11-08) | not counted | Cancelled by the operator | — |
| TC-18 runs `f59f986c`, `11be6c72`, `8d925cec` | 0/3 | Wrong element: the instruction's "notice above `To`" pointed at the To helper text, not the draft banner | Read the top banner |
| TC-18 runs `58e68828`, `b68df440`, `7ec30db6` | 0/3 | The CV block sits below the fold; the agent reported "not visible" instead of scrolling | CV/`Change CV` moved to TC-19, which scrolls to the block |
| TC-18 run `4d27dad3` | 0/1 | Same CV-below-fold issue; `Change CV` was never reached | CV assertions removed from TC-18 |
| TC-18 run `82cb8ea0` | 0/1 | The agent tapped `Open email app` but reported no mail app, no message and no snackbar | Full flow now follows Gmail, sends and asserts `I've sent it` |
| TC-18 run `fa6cca85` | not counted | No structured output (`assert {}`); the agent did not return the JSON | Rerun; counted runs returned the report |
| TC-18 runs `f2397408`, `87130171` | 0/2 | Environment: `gemini-3.1-flash-lite` overloaded; daemon `TimeoutError: LLM call timed out after 180 seconds` | Swapped primary to `gemini-3.5-flash-lite`; counted runs passed 3/3 |
| TC-18 run `3658371e` | passed, not counted | Smoke run of the full flow before the counted batch | Counted runs `5e99ca80`, `2adcba49`, `fd62333f` |
| TC-07 run `c67149d6` (2026-11-10) | 0/1 | Wrong expectation: the card title appends the skills (`Junior Fullstack Developer TypeScript, Node.js, API`) while the detail shows the core position (`Junior Fullstack Developer`) | `_same_position` normalises and checks containment in `test_apply.py`; the next runs passed |
| TC-09 run `cee108da` (2026-11-10) | 0/1 | Wrong expectation: `startswith` compared the list card (`[ TIGER TRIBE ] - FRONTEND DEVELOPER INTERN`) with the detail position | `_same_position` in `test_applications.py`; the next runs passed |
| TC-14 runs `d84b3a90`, `bec24fcb` (2026-11-10) | not counted | Cancelled by the operator during the batch; the two runs before them passed in 263.4 s and 295.9 s | No fix; TC-14 still needs a counted 3/3 |
| TC-19 run `be05e6e5` | cancelled | Operator stopped after the CV change was observed; the To edit kept clearing/retyping, so that step was removed | TC-19 now checks CV change + letter edit; 3 counted runs pending |
| TC-19 run `0aba4890` (2026-11-10) | cancelled | Operator stopped the run | — |
| TC-19 run `83edba2d` (2026-11-10) | 0/1 | The agent session failed after 10.8 s and returned no report; cause not diagnosed | Rerun with the CV library seeded (2+ CVs); 3 counted runs still pending |

## 5. Exploratory session (Pro profile, 15–30 min)

Command: `uv run artemis run "<charter>" --profile pro` on the ARTEMIS host.

- **Charter:** "As a third-year IT student, explore Internly for 20 minutes: add and manage two CVs in the Profile library, set a default, apply to a listing, change the CV on the compose screen, open the submitted application and preview its CV, then search, save, track and export. Report crashes, dead ends, missing Back behavior, overflow, unreadable text and slow screens."
- **Date / build / device:** Not run/recorded yet — no Pro-profile session is stored in `evidence/artemis/` (the case-level exploratory runs on 2026-11-06 and 2026-11-08 are in §4).
- **Trace ID / replay:** —

| # | Issue found | Screen | Severity | Action (issue / fix commit) |
|---|---|---|---|---|

## 6. Rules for writing tests

1. One pytest function = one instruction through `run_case()` (`e2e_test/conftest.py`).
2. The instruction states the starting point, the steps and exactly what must be visible; "check that the app works" is not a test.
3. Ask for a JSON report in `expected_output` and assert on its values. `run_case()` repeats that schema in the instruction and reads the JSON from the agent's final `report_task_status`, because ARTEMIS `351ca84` returns no `output`.
4. Tests never depend on each other's order: start from `SIGNED_IN` / `SIGNED_OUT` or create the needed data inside the instruction.
5. Add `Semantics` labels / tooltips to every widget a test needs (shared components already expose them).
6. Never commit `.env`, account credentials or model API keys.
