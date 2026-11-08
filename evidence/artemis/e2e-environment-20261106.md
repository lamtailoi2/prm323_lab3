# ARTEMIS runs — 2026-11-06 (TC-01 – TC-05, TC-07 – TC-10, TC-14 – TC-20)

Status: **TC-01, TC-02, TC-07, TC-09, TC-14, TC-16 and TC-17 each passed 3 of 3** on the final setup. **Flow 1 (TC-03, TC-04, TC-05, TC-18, TC-19, TC-20) passed 3 of 3 each** from 10:30, after one app fix and two case fixes (see [Flow 1](#flow-1-1030--1229)). **TC-08 passed 0 of 3 and TC-10 failed its exploratory run**: both expectations were wrong, and both cases were rewritten in `f9b5f43` but not run again yet (see [Flow 2 and Flow 3](#flow-2-and-flow-3-0804--0830)).

- TC-02, TC-16, TC-17 ran 07:12–07:24 +07 on `gemini-3.1-flash-lite`.
- TC-14 and TC-01 ran 07:35–07:47 on `gemini-3.5-flash-lite`, because 3.1 had used up its daily quota.

The six exploratory runs made just after midnight on the older debug build are listed too, with their causes. All 21 runs come from `e2e_test/artifacts/runs.jsonl` (copied to [`runs-20261106.jsonl`](runs-20261106.jsonl), now with the `pytest` result on each line) and from the daemon's session API.

Host, ARTEMIS checkout and the team patch are the same as on [2026-11-05](e2e-environment-20261105.md). How to run: [`docs/guides/artemis-e2e.md`](../../docs/guides/artemis-e2e.md). Runs and records were done with Claude Code (P-63).

## Environment

| Item | Value |
|---|---|
| App | **Profile build** of `origin/dev` `a5d1e4a` (PR #24: CV Match, FCM, Notification Center). Built with `flutter build apk --profile --dart-define-from-file=.env` in 98 s and installed at 07:11 over the earlier debug build. It is signed with the same shared debug key, so the sign-in session stayed. |
| Notification permission | Granted before the runs with `adb shell pm grant com.group3.internly android.permission.POST_NOTIFICATIONS`. This build asks for it after sign-in, and TC-15 covers that dialog separately. |
| Suite | `test/e2e-flow1` at `9eafd9e` (the merge of `dev`), `cold_start_app` fixture, JSON report read back from `/api/sessions/{id}/steps` |
| Device | `emulator-5554`, Android API 36 |
| ARTEMIS | `351ca84` + [`e2e_test/artemis-local.patch`](../../e2e_test/artemis-local.patch) |

## Why a profile build

The exploratory TC-16 at 00:52 ran on the 2026-11-05 debug build. It froze on Home after tapping `Frontend`: "internly isn't responding" appeared three times. One `Wait` tap fell through onto the first recommended card, which opened `Internship details` instead of Search.

On the profile build there were no such dialogs in any of the 15 counted runs, and a cold start (`am start -W`) took 4.4 s against 6.7 s for the debug build.

## Model and quota

- The 3.1-flash-lite free tier allows **500 requests per day** per project and model (429 `GenerateRequestsPerDayPerProjectPerModel-FreeTier`, `quotaValue: 500`). The daily count resets at midnight Pacific time, 15:00 in Vietnam. It ran out at about 07:25, after the 2026-11-05 evening runs and batch 1.
- The first TC-14 attempt at 07:25 (session `0a061c60`) kept retrying on that 429. It was cancelled; no `runs.jsonl` line was written and it is not counted.
- For TC-14 and TC-01 the ARTEMIS host's `config/artemis.jsonc` was switched for the day to primary `gemini-3.5-flash-lite` (fallback `gemini-3.1-flash-lite`). A direct call to 3.5-flash-lite answered 200 just before. The committed patch still sets 3.1 as primary.
- One run used 5–29 model calls.

## Runs

| # | Start (+07) | Test | Trace | pytest | Time (s) | Model calls | Build / model | Note |
|---|---|---|---|---|---|---|---|---|
| 1 | 00:51 | TC-02 | `bd33a94b` | passed | 53.0 | 11 | debug 11-05 / 3.1 | exploratory |
| 2 | 00:52 | TC-16 | `681590be` | **failed** | 62.8 | 15 | debug 11-05 / 3.1 | exploratory; ANR ×3, a `Wait` tap opened a card → `'Internship details' == 'Search'` |
| 3 | 00:53 | TC-17 | `ece6eded` | passed | 132.9 | 12 | debug 11-05 / 3.1 | exploratory |
| 4 | 00:57 | TC-14 | `5e93964f` | **failed** | 48.5 | 11 | debug 11-05 / 3.1 | exploratory; old expectation: Back from Login closed the app (correct) but the test wanted Login on screen; fixed in `512c8f4` |
| 5 | 00:58 | TC-01 | `931bbeb4` | passed | 151.5 | 29 | debug 11-05 / 3.1 | exploratory |
| 6 | 01:06 | TC-14 | `8931aed1` | passed | 104.2 | 15 | debug 11-05 / 3.1 | exploratory, rewritten TC-14 |
| 7 | 07:13 | TC-02 | `07d88fd1` | passed | 50.5 | 11 | profile `a5d1e4a` / 3.1 | counted |
| 8 | 07:14 | TC-02 | `ac4bb584` | passed | 42.5 | 9 | profile / 3.1 | counted |
| 9 | 07:15 | TC-02 | `8198585d` | passed | 53.5 | 11 | profile / 3.1 | counted |
| 10 | 07:16 | TC-16 | `e1dd7211` | passed | 33.3 | 9 | profile / 3.1 | counted |
| 11 | 07:17 | TC-16 | `ec6fb253` | passed | 31.3 | 5 | profile / 3.1 | counted |
| 12 | 07:18 | TC-16 | `4747eea1` | passed | 64.5 | 5 | profile / 3.1 | counted |
| 13 | 07:19 | TC-17 | `01670a2f` | passed | 116.0 | 19 | profile / 3.1 | counted |
| 14 | 07:21 | TC-17 | `0d75120d` | passed | 76.7 | 19 | profile / 3.1 | counted |
| 15 | 07:23 | TC-17 | `30344dfd` | passed | 99.7 | 21 | profile / 3.1 | counted |
| — | 07:25 | TC-14 | `0a061c60` | — | — | — | profile / 3.1 | cancelled: daily quota of 3.1 used up; no line written |
| 16 | 07:36 | TC-14 | `a0e01cc7` | passed | 108.8 | 18 | profile / 3.5 | counted |
| 17 | 07:38 | TC-14 | `0ac66774` | passed | 172.3 | 26 | profile / 3.5 | counted |
| 18 | 07:41 | TC-14 | `86a6bc0d` | passed | 126.1 | 26 | profile / 3.5 | counted |
| 19 | 07:43 | TC-01 | `cebfd52e` | passed | 48.4 | 11 | profile / 3.5 | counted |
| 20 | 07:45 | TC-01 | `dd7ba1ab` | passed | 77.2 | 17 | profile / 3.5 | counted |
| 21 | 07:46 | TC-01 | `5b765e36` | passed | 66.7 | 17 | profile / 3.5 | counted |

Commands for the counted runs, from `e2e_test/`:

```bash
uv run pytest test_navigation.py test_home_roles.py test_profile_skills.py --count 3 -v   # 9 passed in 724.66s
uv run pytest "test_auth.py::test_tc14_sign_out_returns_to_login" "test_auth.py::test_tc01_google_sign_in_opens_home" --count 3 -v   # 6 passed in 717.43s
```

## Result (counted runs)

| Test | Passed | Average time (s) |
|---|---|---|
| TC-01 | 3/3 | 64.1 |
| TC-02 | 3/3 | 48.8 |
| TC-14 | 3/3 | 135.7 |
| TC-16 | 3/3 | 43.0 |
| TC-17 | 3/3 | 97.5 |

TC-01 also checked the `login` analytics event in Logcat on each run. TC-17 adds `Docker` to the test account's profile skills, removing it first when it is already there.

## Flow 2 and Flow 3 (08:04 – 08:30)

Same profile build and device; model `gemini-3.5-flash-lite` (the 3.1 daily quota was still used up).

### The one application used by TC-07, TC-09 and TC-10

The test account had no application ("You have not applied yet"). So that the cases share **one** application instead of each creating its own, it was submitted by hand with `adb` taps (no ARTEMIS run, no model calls) at 08:04: **Client Success Intern — Wegrow**. It is the third card of the `Intern` results, chosen so that TC-05's `Recruitment Intern` keeps its `Apply now` button.

The Profile CV `Sample_CV.pdf` (609 B, uploaded 2026-11-02, the old one-line sample) has too little text:
- CV match showed "We could not read your CV".
- Validate CV stopped with "We could not use this CV — CV appears to be empty or unreadable." (`validateCv` needs at least 50 characters).

For this application only, it was replaced with the full fictional CV that `conftest.py` builds (1218 B; `pdf-parse` 2.4.5, the library the function uses, reads 522 characters from it locally). The application then went through CV match → Validate CV → Review → `Application submitted!`.

Note for Lập's TC-06: it uses the Profile CV, so it will stop at Validate CV until the Profile CV is replaced.

### Runs

| # | Start (+07) | Test | Trace | pytest | Time (s) | Model calls | Note |
|---|---|---|---|---|---|---|---|
| 22 | 08:10 | TC-09 | `ea708962` | passed | 29.3 | 5 | exploratory |
| 23 | 08:10 | TC-07 | `b08c12ee` | passed | 65.6 | 13 | exploratory |
| 24 | 08:12 | TC-08 | `7da3ef7c` | passed | 116.8 | 32 | exploratory |
| 25 | 08:14 | TC-10 | `f1e857a4` | **failed** | 193.5 | 48 | exploratory; airplane mode on, but Applications still showed the cached list, with no error and no `Retry` (the case expected both) |
| 26 | 08:18 | TC-07 | `b3c12d02` | passed | 50.7 | 13 | counted |
| 27 | 08:19 | TC-07 | `c293b71d` | passed | 50.5 | 13 | counted |
| 28 | 08:20 | TC-07 | `789431b9` | passed | 57.4 | 13 | counted |
| 29 | 08:21 | TC-08 | `437397d9` | **failed** | 122.9 | 34 | counted; `first_saved_title` was another card (see below) |
| 30 | 08:24 | TC-08 | `a3dc0d3b` | **failed** | 116.7 | 32 | counted; same cause |
| 31 | 08:26 | TC-08 | `e1d1565d` | **failed** | 102.8 | 28 | counted; Undo was missed, and the count went 7 → 5 |
| 32 | 08:28 | TC-09 | `58144485` | passed | 21.2 | 5 | counted |
| 33 | 08:28 | TC-09 | `b44e3547` | passed | 23.2 | 5 | counted |
| 34 | 08:29 | TC-09 | `dfe47b1a` | passed | 27.2 | 5 | counted |

Counted command: `uv run pytest "test_apply.py::test_tc07_…" "test_saved.py::test_tc08_…" "test_applications.py::test_tc09_…" --count 3 -v` → 6 passed, 3 failed in 703.80 s.

| Test | Passed | Average time (s) |
|---|---|---|
| TC-07 | 3/3 | 52.9 |
| TC-08 | 0/3 | 114.1 |
| TC-09 | 3/3 | 23.9 |

### Why TC-08 and TC-10 failed

**TC-08.** The case assumed that the listing it had just saved is the first card on Saved. Saved is ordered by the listing's **posting date**, not by when it was saved: `saved_screen.dart` notes that the service does not expose `savedAt`. The `Recent` label suggests otherwise, so this is raised with the Saved owner.

In run 31 the agent also missed `Undo`, because the Snackbar lasts about 4 s. Over the four TC-08 runs, the account's Saved list changed:
- **"Thực Tập Sinh IT Developer Tiếng Nhật – Trình N3" (SENZU BASE) was unsaved.**
- "Intern AI Software Engineer" (Nexlab) was added.

This is known from Saved screenshots taken before and after. The account owner chose to leave the list as it is.

Rewritten in `f9b5f43`:
- The case finds the saved card by its title.
- It never touches another card, so a missed Undo can only remove what the case added.

**TC-10.** Offline, the app kept showing the applications from Firestore's offline cache. That is the app working as intended, and the case expected an error state instead. The agent also needed 11 swipes to find the Airplane mode tile.

Rewritten in `f9b5f43`:
- Wi-Fi and data are turned off with `adb`, as in TC-20.
- It asserts that the list, with its count line, stays visible offline with no error and no `Retry`.

Model use for this block was about 250 calls (13 runs).

Replays and step screenshots of every trace are on the ARTEMIS host in `~/artemis/traces/`. They are not committed because they show the signed-in account.

## Flow 1 (10:30 – 12:29)

Runs 35–65 in [`runs-20261106.jsonl`](runs-20261106.jsonl). Runs and records were done with Claude Code (P-70).

### Environment

| Item | Value |
|---|---|
| App | Profile build of `dev` `b08b47f` (PR #27: Search empty query and the field after Search Results), installed about 10:04. From 12:12, a profile build of `fix/filter-chips-and-skills-sheet` (P-70: `Job type` / allowance chips, Edit skills waits for the profile). |
| Suite | `test/e2e-flow1` at `b08b47f`, plus the TC-18 / TC-19 / `UPLOAD_SAMPLE_CV` wording changes below (uncommitted during the runs) |
| Device | `emulator-5554`, Android API 36; notification permission granted with `adb` before the runs |
| API key | A free-tier key from another team member's own AI Studio project (no billing), shared privately with their consent and kept only in `~/artemis/.env`. The owner's key had used its 3.1 quota for the day. |
| Model | 10:30–11:12 `gemini-3.5-flash-lite` (fallback 3.1). That key's 3.5 quota (500 per day) ran out at 11:12; from 11:17 the host config was switched back to the team patch: primary `gemini-3.1-flash-lite`, fallback 3.5. |

The 31 runs used 735 model calls (9–43 per run). The Apply Form cases cost the most: 22–43 calls, against 9–22 for Search and Detail.

### Runs

| # | Start (+07) | Test | Trace | pytest | Time (s) | Model calls | Build / model | Note |
|---|---|---|---|---|---|---|---|---|
| 35 | 10:31 | TC-03 | `9cb45bff` | **failed** | 104.1 | 20 | dev `b08b47f` / 3.5 | app bug: no `Job type` chip → `'Internship' in ['Intern']` |
| 36 | 10:33 | TC-03 | `a039c385` | **failed** | 51.6 | 17 | dev `b08b47f` / 3.5 | same |
| 37 | 10:34 | TC-03 | `bab18c1a` | **failed** | 59.8 | 15 | dev `b08b47f` / 3.5 | same |
| 38 | 10:35 | TC-04 | `c90faf15` | passed | 45.4 | 11 | dev `b08b47f` / 3.5 |  |
| 39 | 10:36 | TC-04 | `a824cd6a` | passed | 37.4 | 9 | dev `b08b47f` / 3.5 |  |
| 40 | 10:37 | TC-04 | `63631ad3` | passed | 57.5 | 11 | dev `b08b47f` / 3.5 |  |
| 41 | 10:39 | TC-05 | `108cf8ac` | passed | 44.4 | 13 | dev `b08b47f` / 3.5 |  |
| 42 | 10:40 | TC-05 | `e0ada1d5` | passed | 56.6 | 13 | dev `b08b47f` / 3.5 |  |
| 43 | 10:41 | TC-05 | `1ab4c069` | passed | 49.4 | 13 | dev `b08b47f` / 3.5 |  |
| 44 | 10:43 | TC-18 | `51b07205` | **failed** | 114.3 | 26 | dev `b08b47f` / 3.5 | wrong expectation: next screen `CV match` |
| 45 | 10:45 | TC-18 | `25aa5d78` | **failed** | 109.9 | 26 | dev `b08b47f` / 3.5 | same |
| 46 | 10:47 | TC-18 | `1b4ba996` | **failed** | 107.9 | 28 | dev `b08b47f` / 3.5 | same |
| 47 | 10:49 | TC-19 | `ec0bf776` | **failed** | 136.2 | 30 | dev `b08b47f` / 3.5 | ambiguous: reported the size line `2 KB · PDF` |
| 48 | 10:52 | TC-19 | `964deb59` | **failed** | 160.5 | 33 | dev `b08b47f` / 3.5 | same |
| 49 | 10:55 | TC-19 | `eeb2d83d` | **failed** | 171.3 | 43 | dev `b08b47f` / 3.5 | same |
| 50 | 10:58 | TC-20 | `774a3906` | passed | 152.1 | 33 | dev `b08b47f` / 3.5 |  |
| 51 | 11:00 | TC-20 | `32d3c95c` | passed | 158.6 | 35 | dev `b08b47f` / 3.5 |  |
| 52 | 11:03 | TC-20 | `69f090e2` | passed | 103.1 | 31 | dev `b08b47f` / 3.5 |  |
| 53 | 11:06 | TC-18 | `92169173` | passed | 103.7 | 31 | dev `b08b47f` / 3.5 | rewritten case |
| 54 | 11:08 | TC-18 | `5a13af8f` | passed | 131.0 | 30 | dev `b08b47f` / 3.5 | rewritten case |
| 55 | 11:10 | TC-18 | `655227ed` | passed | 89.8 | 22 | dev `b08b47f` / 3.5 | rewritten case |
| 56 | 11:12 | TC-19 | `683d1708` | **failed** | 223.3 | 9 | dev `b08b47f` / 3.5 | environment: 3.5 daily quota (500) used at 11:12, LLM call timed out after 180 s |
| 57 | 11:18 | TC-19 | `ba904dd4` | **failed** | 63.6 | 15 | dev `b08b47f` / 3.1 | ambiguous: reported the Profile CV without uploading |
| 58 | 11:20 | TC-19 | `a75cd4e1` | passed | 171.9 | 43 | dev `b08b47f` / 3.1 | second wording, not counted |
| 59 | 11:23 | TC-19 | `7e2b8eb6` | **failed** | 68.5 | 15 | dev `b08b47f` / 3.1 | ambiguous: reported the Profile CV without uploading |
| 60 | 11:25 | TC-19 | `a1482888` | passed | 141.1 | 34 | dev `b08b47f` / 3.1 | final wording |
| 61 | 12:16 | TC-03 | `55c7985d` | passed | 102.2 | 22 | fix `filter-chips` / 3.1 | after the chip fix |
| 62 | 12:18 | TC-03 | `2b271938` | passed | 49.5 | 15 | fix `filter-chips` / 3.1 | after the chip fix |
| 63 | 12:19 | TC-03 | `c07e2122` | passed | 71.8 | 15 | fix `filter-chips` / 3.1 | after the chip fix |
| 64 | 12:23 | TC-19 | `58225e0a` | passed | 141.1 | 42 | fix `filter-chips` / 3.1 | final wording |
| 65 | 12:25 | TC-19 | `7a1e3528` | passed | 202.8 | 35 | fix `filter-chips` / 3.1 | final wording |
Not in `runs.jsonl`: session `b6763c92` (11:16, TC-19), cancelled by stopping the daemon after the quota ran out; session `2f5ac78e` (11:27, TC-19), cancelled at the operator's request to use the emulator by hand.

### Result (counted runs)

| Test | Passed | Average time (s) | Counted traces |
|---|---|---|---|
| TC-03 | 3/3 | 74.5 | `55c7985d`, `2b271938`, `c07e2122` (after the chip fix) |
| TC-04 | 3/3 | 46.8 | `c90faf15`, `a824cd6a`, `63631ad3` |
| TC-05 | 3/3 | 50.1 | `108cf8ac`, `e0ada1d5`, `1ab4c069` (case that skips applied / saved cards) |
| TC-18 | 3/3 | 108.2 | `92169173`, `5a13af8f`, `655227ed` (rewritten case) |
| TC-19 | 3/3 | 161.7 | `a1482888`, `58225e0a`, `7a1e3528` (final wording) |
| TC-20 | 3/3 | 137.9 | `774a3906`, `32d3c95c`, `69f090e2` |

TC-03 also checked the `search` and `search_filter_apply` events in Logcat, and TC-18 `apply_start`. TC-19 and TC-20 upload the fictional `Sample_CV.pdf` to `cvs/{uid}/` for the chosen listing; no application is submitted in Flow 1.

### Why runs failed

- **TC-03, app bug (0/3).** The agent chose `Job type: Internship` and the list went from 54 to 23 results, but the only chip shown was `Intern`. The Filters badge counted the job type, yet `_ActiveFiltersRow` had no chip for job type or allowance. Fixed in the app (P-70, test-report Run 32); the reruns passed 3/3.
- **TC-18, wrong expectation (0/3).** Since CV Match (PR #24, DC-30), `Continue to review` opens `CV match` while Remote Config `cv_match_enabled` is on. The case expected `Validate CV` and now accepts either.
- **TC-19, ambiguous instruction (0/3).** The upload worked each time, but the CV card now shows two lines under the file name (`2 KB · PDF`, then `Uploaded for this internship`), and the agent reported the first one for "the line under it". The case now asks for every line and checks that the source line is among them.
- **TC-19, environment (run 56, `683d1708`).** Every call returned 429 for the 3.5 daily quota; ARTEMIS timed out after 180 s instead of using its fallback. Not counted.
- **TC-19, ambiguous instruction (runs 57 and 59).** On 3.1 the agent saw the CV from the Profile and reported it without replacing it. `UPLOAD_SAMPLE_CV` now says to replace the CV even if one is shown, and the case asks for the report only after `Update CV`. Run 58 passed on that intermediate wording and is not counted.

Also seen: `Choose file` often needed a second tap before the Android picker opened (in runs on both models). Not investigated; it did not fail a run.

## TC-08, TC-10, TC-15 (12:50 – 14:30)

Runs 66–87 in [`runs-20261106.jsonl`](runs-20261106.jsonl), 438 model calls. Records done with Claude Code (P-76; first logged as P-72, see the AI log).

### Environment

| Item | Value |
|---|---|
| App | Profile build of `dev` `35799c3` (runs 66–71), then of `dev` `d4674ee` (PR #30: Firebase demo screen; runs 72–87). After the 14:07 emulator crash the APK was reinstalled. |
| Emulator | `Pixel_API_36`, API 36. It crashed three times: 13:00 and 13:44 when the host hung (hang detector, "no response for 15 s"; swap 5.2 of 6 GB in use), 14:07 in the GPU backend (`libgfxstream_backend` `createColorBuffer`, SIGSEGV). The Mac was restarted at 13:50, and from 14:08 the emulator runs with `-gpu swiftshader_indirect` (software rendering). A quick boot from an old snapshot had also reverted the installed app; it was reinstalled and the snapshot saved again. |
| API keys | Key A: a team member's free-tier project (runs 66–77). A second borrowed key was refused: its project uses prepaid billing (HTTP 402 "prepayment credits are depleted"), against G-26. Key B: another member's project, confirmed Free in AI Studio by the operator (runs 78–87). |
| Model | `gemini-3.1-flash-lite` primary (team patch) until 14:20; from 14:20 `gemini-3.5-flash-lite` primary, fallback 3.1, because 3.1 skipped steps and invented results in TC-08 (below). |
| Recording | From 13:44 the operator screen-recorded the emulator, the ARTEMIS console and Terminal for each batch (video kept outside the repository: it shows the account), with the command typed in Terminal and its output saved with `tee` to `e2e_test/artifacts/logs/`. ARTEMIS also saves `recording.mp4` and `stdout.log` for each session under `~/artemis/traces/`. |

Commands (from `e2e_test/`):

```bash
uv run pytest test_saved.py --count 3 -v 2>&1 | tee artifacts/logs/20261106-tc08.log
uv run pytest test_applications.py -k tc10 --count 3 -v
uv run pytest test_notifications.py -k tc15 --count 3 -v
```

### Runs

| # | Start (+07) | Test | Trace | pytest | Time (s) | Model calls | Build / key / model | Note |
|---|---|---|---|---|---|---|---|---|
| 66 | 12:50 | TC-08 | `ac1990bb` | **failed** | 113.0 | 30 | `35799c3` / borrowed key A / 3.1 | old case: Undo missed (4 s Snackbar) |
| 67 | 12:52 | TC-08 | `12e44b75` | **failed** | 152.5 | 36 | `35799c3` / borrowed key A / 3.1 | old case: read the button `Saved` as the message; Undo missed |
| 68 | 12:55 | TC-08 | `aa985d75` | **failed** | 143.3 | 25 | `35799c3` / borrowed key A / 3.1 | old case: misread counts and the message; Undo missed |
| 69 | 12:59 | TC-10 | `e6299835` | **failed** | 28.5 | 3 | `35799c3` / borrowed key A / 3.1 | environment: emulator crashed (13:00) during the network toggle |
| 70 | 13:04 | TC-10 | `9b123960` | passed | 30.7 | 3 | `35799c3` / borrowed key A / 3.1 | build of `dev` `35799c3`, not counted |
| 71 | 13:04 | TC-10 | `0b3103aa` | passed | 26.6 | 3 | `35799c3` / borrowed key A / 3.1 | build of `dev` `35799c3`, not counted |
| 72 | 13:11 | TC-10 | `2956f83e` | passed | 51.6 | 9 | `d4674ee` / borrowed key A / 3.1 | counted |
| 73 | 13:12 | TC-10 | `8cbd2938` | passed | 36.4 | 3 | `d4674ee` / borrowed key A / 3.1 | counted |
| 74 | 13:13 | TC-10 | `395acd45` | passed | 20.4 | 3 | `d4674ee` / borrowed key A / 3.1 | counted |
| 75 | 13:14 | TC-15 | `7c9ea8f9` | **failed** | 92.9 | 20 | `d4674ee` / borrowed key A / 3.1 | test bug: app launched twice, dialog gone |
| 76 | 13:16 | TC-15 | `b7c1b34d` | **failed** | 21.6 | 6 | `d4674ee` / borrowed key A / 3.1 | test bug: dialog gone before the tap, tap opened a card |
| 77 | 13:16 | TC-15 | `7587d519` | **failed** | 38.7 | 6 | `d4674ee` / borrowed key A / 3.1 | same |
| 78 | 13:44 | TC-08 | `ad1c4f88` | **failed** | 64.6 | 11 | `d4674ee` / free key B / 3.1 | environment: emulator crashed (13:44, hang detector); 2 more runs errored on adb |
| 79 | 13:55 | TC-08 | `d29c9d13` | passed | 168.3 | 19 | `d4674ee` / free key B / 3.1 | first rewrite, not counted |
| 80 | 13:58 | TC-08 | `b68c9c82` | **failed** | 129.2 | 26 | `d4674ee` / free key B / 3.1 | skipped opening the card from Saved, invented `View application` |
| 81 | 14:00 | TC-08 | `6bec2030` | **failed** | 75.7 | 17 | `d4674ee` / free key B / 3.1 | read the accessibility label `Saved. Remove from saved` |
| 82 | 14:11 | TC-08 | `049a9ddd` | passed | 135.1 | 31 | `d4674ee` / free key B / 3.1 | **invalid pass**: stopped after the Saved tab and invented the rest; its listing stayed saved |
| 83 | 14:13 | TC-08 | `cdda7c80` | **failed** | 131.0 | 28 | `d4674ee` / free key B / 3.1 | skipped opening the card; misread the count (9 → 10) |
| 84 | 14:16 | TC-08 | `af95ee7f` | passed | 149.1 | 37 | `d4674ee` / free key B / 3.1 | genuine, but before the switch to 3.5; not counted |
| 85 | 14:21 | TC-08 | `7bda5a47` | passed | 105.9 | 30 | `d4674ee` / free key B / 3.5 | counted; steps checked |
| 86 | 14:23 | TC-08 | `1d1f3d20` | passed | 202.4 | 47 | `d4674ee` / free key B / 3.5 | counted; steps checked |
| 87 | 14:27 | TC-08 | `1753334f` | passed | 229.9 | 45 | `d4674ee` / free key B / 3.5 | counted; steps checked |
### Result (counted runs)

| Test | Passed | Average time (s) | Counted traces |
|---|---|---|---|
| TC-08 | 3/3 | 179.4 | `7bda5a47`, `1d1f3d20`, `1753334f` (case without Undo, `gemini-3.5-flash-lite`; each run's step history shows Save → open from Saved → Back → unsave) |
| TC-10 | 3/3 | 36.1 | `2956f83e`, `8cbd2938`, `395acd45` (`dev` `d4674ee`) |
| TC-15 | 0/3 | — | Test fixed, not run again yet |

### Why runs failed

- **TC-08, `Undo` (runs 66–68).** One ARTEMIS step (screenshot + model call) takes 5–15 s, the Snackbar stays 4 s (design-system), so the agent never reached `Undo`; it also read the button text `Saved` as the Snackbar. The case now ends with the unsave and checks `Removed from Saved`; `Undo` and `Saved to your list` are covered by widget tests.
- **TC-15, test bug (runs 75–77).** `reset_notification_permission()` relaunched the app, then the case's "Open the Internly app" made ARTEMIS open it again, which closed the system dialog: no dialog at all (run 75), or a tap on `Allow` that landed on a Home card after the dialog had gone (runs 76–77). The helper now leaves the app stopped so the case opens it once.
- **TC-08 on `gemini-3.1-flash-lite` (runs 80–84).** The agent skipped steps of a long case and filled the report from the instruction: it never opened the card from Saved (runs 80, 83) and in run 82 stopped after the Saved tab and reported a full, plausible pass. That listing ("Intern C/C++ Embedded Systems Engineer Qt") stayed saved. Run 81 read the accessibility label `Saved. Remove from saved`. The case was split into numbered steps, accepts a label that starts with `Saved`, asks for the title on the detail opened from Saved, and runs on 3.5. pytest results alone are not trusted for this case: each counted run was checked against its step history.
- **Environment (runs 69, 78).** Emulator crashes, above. Not counted.

Side effect on the account: across the TC-08 runs today Saved went from 6 (13:39) to 9; the runs on the final case leave it unchanged.
