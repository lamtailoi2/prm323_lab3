# ARTEMIS runs — 2026-11-07 night to 2026-11-08 (TC-01 – TC-05, TC-08, TC-10, TC-12, TC-13, TC-15, TC-16)

Status: **TC-01, TC-02, TC-03, TC-04, TC-05, TC-08, TC-10, TC-12, TC-13, TC-15 and TC-16 each passed 3 of 3** on the UI v2 build (DC-31). TC-15 needed one case fix (Home's header text) and TC-13 two (wait for the route, then a Logcat check). The cases that wait on the CV library (TC-06, TC-07, TC-09, TC-14, TC-17, TC-18, TC-19) and the exploratory session are run by Lập.

All 38 runs below are lines 99–136 of `e2e_test/artifacts/runs.jsonl`, copied to [`runs-20261108.jsonl`](runs-20261108.jsonl). Seven TC-13 runs were moved to `practice-runs.jsonl` (not evidence; listed under [Not counted](#not-counted)). Every counted run was also checked against its ARTEMIS step history (the actions the agent took, not only its report), after the invented TC-08 pass of 2026-11-06. Runs and records were done with Claude Code (P-82).

## Environment

| Item | Value |
|---|---|
| App, runs 1–35 | Profile build made at 22:36 from `test/e2e-flow1` `6d10771`, whose app code is `dev` `b5d1209` (UI v2 and the email apply flow, PRs #33–#34) |
| App, runs 36–38 (TC-13) | Profile build of `feat/notification-unread-badge` `6e4985c` = `dev` `88b3382` plus the bell badge and `Mark all as read` (DC-34), installed 00:48. Neither change touches a label the case uses |
| Suite | `test/e2e-flow1` → `test/e2e` (renamed 2026-11-08): `4547b70` case review + TC-12, `61d86fc` TC-15, and the uncommitted TC-13 Logcat check |
| Device | `emulator-5554`, `Pixel_API_36`, API 36, started with `-gpu swiftshader_indirect` (the GPU backend crashed on 2026-11-06) |
| ARTEMIS | `351ca84` + [`artemis-local.patch`](../../e2e_test/artemis-local.patch); primary model `gemini-3.5-flash-lite`, fallback `gemini-3.1-flash-lite` (since 2026-11-06 14:20) |
| API key | Free tier. The operator switched `~/artemis/.env` from borrowed key B to the owner's own key during the evening; the time of the switch was not logged. No daily-quota 429 occurred |
| Recording | The operator screen-recorded the emulator, the ARTEMIS console (`localhost:8000/workspace`) and Terminal for each test, with the command typed in Terminal and its output saved with `tee` to `e2e_test/artifacts/logs/`. ARTEMIS also keeps `recording.mp4` and `stdout.log` per session under `~/artemis/traces/`. Videos show the account and stay outside the repository |
| Remote Config | `home_recommended_limit` = 6 in the console for TC-12 (in-app default 5) |
| TC-13 sender | `tools/admin-dashboard` on the operator's machine (own service-account key in `~/.internly-admin/`, outside the repository), one message per run, route `/saved` |

The 38 runs used 453 model calls.

Commands (from `e2e_test/`; each with `2>&1 | tee artifacts/logs/<date>-tcNN.log`):

```bash
uv run pytest test_auth.py -k tc01 --count 3 -v
uv run pytest test_navigation.py --count 3 -v
uv run pytest test_search.py --count 3 -v
uv run pytest test_detail.py --count 3 -v
uv run pytest test_saved.py --count 3 -v
uv run pytest test_applications.py -k tc10 --count 3 -v
uv run pytest test_profile.py --count 3 -v
uv run pytest test_notifications.py -k tc15 --count 3 -v
uv run pytest test_home_roles.py --count 3 -v
uv run pytest test_notifications.py -k tc13 --count 3 -s -v
```

## Runs

| # | Start (+07) | Test | Trace | pytest | Time (s) | Model calls | App | Note |
|---|---|---|---|---|---|---|---|---|
| 1 | 22:52 | TC-01 | `6cae0c7c` | **failed** | 18.2 | 1 | `b5d1209` | cancelled by the operator |
| 2 | 23:20 | TC-01 | `47ef0815` | **failed** | 125.0 | 0 | `b5d1209` | cancelled by the operator |
| 3 | 23:25 | TC-01 | `d9aac3bb` | passed | 108.1 | 24 | `b5d1209` | counted |
| 4 | 23:27 | TC-01 | `9313b9ac` | passed | 81.9 | 17 | `b5d1209` | counted |
| 5 | 23:28 | TC-01 | `720cd8ed` | passed | 91.0 | 19 | `b5d1209` | counted |
| 6 | 23:32 | TC-02 | `a8c08b49` | passed | 39.7 | 11 | `b5d1209` | counted |
| 7 | 23:33 | TC-02 | `115f7fc3` | passed | 48.5 | 11 | `b5d1209` | counted |
| 8 | 23:34 | TC-02 | `55b503e0` | passed | 54.6 | 11 | `b5d1209` | counted |
| 9 | 23:36 | TC-03 | `256e2ee3` | passed | 77.8 | 17 | `b5d1209` | counted |
| 10 | 23:37 | TC-03 | `05fe9f84` | passed | 67.7 | 15 | `b5d1209` | counted |
| 11 | 23:39 | TC-03 | `27385523` | passed | 79.8 | 19 | `b5d1209` | counted |
| 12 | 23:40 | TC-04 | `7660a5b0` | passed | 53.6 | 11 | `b5d1209` | counted |
| 13 | 23:42 | TC-04 | `f0fc3eb3` | passed | 49.6 | 11 | `b5d1209` | counted |
| 14 | 23:43 | TC-04 | `3b0c99f6` | passed | 57.6 | 11 | `b5d1209` | counted |
| 15 | 23:47 | TC-05 | `0973f1e6` | passed | 58.7 | 13 | `b5d1209` | counted |
| 16 | 23:48 | TC-05 | `9451d0c1` | passed | 63.7 | 13 | `b5d1209` | counted |
| 17 | 23:49 | TC-05 | `fecf6a78` | passed | 62.6 | 13 | `b5d1209` | counted |
| 18 | 23:52 | TC-08 | `146db8f2` | passed | 97.0 | 28 | `b5d1209` | counted |
| 19 | 23:54 | TC-08 | `8a6cb91b` | passed | 113.0 | 26 | `b5d1209` | counted |
| 20 | 23:56 | TC-08 | `f195878e` | passed | 110.2 | 26 | `b5d1209` | counted |
| 21 | 23:59 | TC-10 | `f74f0ce3` | passed | 39.6 | 5 | `b5d1209` | counted |
| 22 | 00:00 | TC-10 | `5fd55b20` | passed | 33.4 | 5 | `b5d1209` | counted |
| 23 | 00:01 | TC-10 | `7db0d8ae` | passed | 38.5 | 5 | `b5d1209` | counted |
| 24 | 00:06 | TC-12 | `070f4a53` | passed | 80.8 | 19 | `b5d1209` | counted |
| 25 | 00:07 | TC-12 | `96edd424` | passed | 76.7 | 21 | `b5d1209` | counted |
| 26 | 00:09 | TC-12 | `c99322ce` | passed | 73.6 | 19 | `b5d1209` | counted |
| 27 | 00:12 | TC-15 | `7757f9b9` | **failed** | 31.7 | 5 | `b5d1209` | wrong expectation: header title, Home shows `Find your next internship` |
| 28 | 00:13 | TC-15 | `c79f4fde` | **failed** | 30.7 | 5 | `b5d1209` | same |
| 29 | 00:14 | TC-15 | `f5a17165` | **failed** | 29.5 | 5 | `b5d1209` | same |
| 30 | 00:16 | TC-15 | `0c3dfc7e` | passed | 26.8 | 3 | `b5d1209` | counted |
| 31 | 00:17 | TC-15 | `ffc73388` | passed | 30.8 | 5 | `b5d1209` | counted |
| 32 | 00:17 | TC-15 | `2fa04a74` | passed | 37.6 | 5 | `b5d1209` | counted |
| 33 | 00:25 | TC-16 | `d9094540` | passed | 34.5 | 5 | `b5d1209` | counted |
| 34 | 00:25 | TC-16 | `d68cd6ca` | passed | 28.5 | 5 | `b5d1209` | counted |
| 35 | 00:26 | TC-16 | `658a1882` | passed | 31.4 | 5 | `b5d1209` | counted |
| 36 | 01:28 | TC-13 | `48f3319d` | passed | 56.8 | 11 | `88b3382` + badge | counted; Logcat `saved` |
| 37 | 01:30 | TC-13 | `a381427b` | passed | 74.8 | 17 | `88b3382` + badge | counted; Logcat `saved` (the agent itself read Home before the route) |
| 38 | 01:31 | TC-13 | `1e6f3b6c` | passed | 63.5 | 11 | `88b3382` + badge | counted; Logcat `saved` |
## Result (counted runs)

| Test | Passed | Average time (s) | Counted traces |
|---|---|---|---|
| TC-01 | 3/3 | 93.7 | `d9aac3bb`, `9313b9ac`, `720cd8ed` |
| TC-02 | 3/3 | 47.6 | `a8c08b49`, `115f7fc3`, `55b503e0` |
| TC-03 | 3/3 | 75.1 | `256e2ee3`, `05fe9f84`, `27385523` |
| TC-04 | 3/3 | 53.6 | `7660a5b0`, `f0fc3eb3`, `3b0c99f6` |
| TC-05 | 3/3 | 61.7 | `0973f1e6`, `9451d0c1`, `fecf6a78` |
| TC-08 | 3/3 | 106.7 | `146db8f2`, `8a6cb91b`, `f195878e` |
| TC-10 | 3/3 | 37.2 | `f74f0ce3`, `5fd55b20`, `7db0d8ae` |
| TC-12 | 3/3 | 77.0 | `070f4a53`, `96edd424`, `c99322ce` |
| TC-13 | 3/3 | 65.0 | `48f3319d`, `a381427b`, `1e6f3b6c` |
| TC-15 | 3/3 | 31.7 | `0c3dfc7e`, `ffc73388`, `2fa04a74` |
| TC-16 | 3/3 | 31.5 | `d9094540`, `d68cd6ca`, `658a1882` |
What the counted runs showed: TC-03 `28 internships found` with chips `Internship` and `Intern`; TC-04 `No internships found` → `Clear filters` → `117 internships found`; TC-08 Saved 9 → 10 → 9 with the card opened from Saved before the unsave; TC-12 `6 · From Firebase` and 6 cards under `Recommended for you`; TC-15 the system dialog `Allow internly to send you notifications?` with `Allow` / `Don't allow`, then the `Home` tab; TC-13 each message listed and `Read`.

## Why runs failed or were not counted

- **TC-01 runs 1–2 (`6cae0c7c`, `47ef0815`).** Cancelled by the operator while setting up. Not counted.
- **TC-15 runs 27–29.** Wrong expectation: the dialog and `Allow` worked, but the case expected the screen title `Home` and the UI v2 Home header shows `Find your next internship` and a greeting. Fixed in `61d86fc` (the highlighted tab must be `Home`); runs 30–32 passed.
- **TC-13, before the counted runs** (moved to `practice-runs.jsonl`):
  - 4 runs (`6c406dae`, `f7a8c3b4`, `749e6f5d`, `81e1b42a`, 00:37–01:06): the message was sent with route `/applications` instead of `/saved`. Logcat showed the app opening `my_applications` about 2 s after each tap, so the app followed the route; the agent had read the screen before that and reported Home.
  - `ffbbce6b` (01:17): route `/saved`, Logcat `saved` 2 s after the tap, but the agent again reported Home before the route. The case was changed to check the app's own `screen_view` in Logcat (`logged_screen_views()`); the agent's reading stays in the report only. `49046dc0` (passed) and `60fae94a` (cancelled) were the first runs on that case before the operator restarted the batch.
  - ARTEMIS brings the app to the front when a session starts, so the tap reaches a running app rather than one in the background.

## Not counted

Seven TC-13 runs in `e2e_test/artifacts/practice-runs.jsonl` (above) and the two cancelled TC-01 runs. Their notifications were deleted from the account's history at the operator's request.
