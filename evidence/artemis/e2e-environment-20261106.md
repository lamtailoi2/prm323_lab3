# ARTEMIS runs — 2026-11-06 (TC-01, TC-02, TC-14, TC-16, TC-17)

Status: **TC-01, TC-02, TC-14, TC-16 and TC-17 each passed 3 of 3** on the final setup.

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

Replays and step screenshots of every trace are on the ARTEMIS host in `~/artemis/traces/`. They are not committed because they show the signed-in account.
