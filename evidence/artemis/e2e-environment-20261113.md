# ARTEMIS environment and TC-21 runs — 2026-11-13

First run of **TC-21 (Flow 3e, student-reported stage)** after PR #50 added
`Update status` on Application Detail. The case was run three times as the lab
requires.

The 3 lines in [`runs-20261113.jsonl`](runs-20261113.jsonl) were copied from
the git-ignored `e2e_test/artifacts/runs.jsonl` (lines 137–139, every TC-21
line).

## Environment

| Item | Value |
|---|---|
| App | Profile build of `dev` `b97f7a4` (`flutter build apk --profile --dart-define-from-file=.env`), installed 2026-11-13 08:44, `com.group3.internly` 0.1.0 |
| Suite | `e2e_test/test_applications.py::test_tc21_student_reports_a_stage` (made repeatable first, see below) |
| Device | `emulator-5554`, AVD `Pixel_API_36`, API 36, started with `-gpu swiftshader_indirect` |
| Host | macOS (Apple M1, 8 GB) · `uv` · Android SDK command-line tools |
| ARTEMIS | `351ca84` + [`artemis-local.patch`](../../e2e_test/artemis-local.patch); daemon `uv run python -m artemis ui --no-open` on port 8000; planner `gemini-3.5-flash-lite`, fallback `gemini-3.1-flash-lite` |
| Recording | ARTEMIS's own `recording.mp4` per session (scrcpy + FFmpeg); no desktop recording |
| Account | the test account on that emulator; the first open application is `[ APAC D&A HUB ] - DATA ENGINEER INTERN` (`Submitted`) |

## Command

```bash
# from e2e_test/
uv run pytest test_applications.py -k tc21 --count 3 -v 2>&1 | tee artifacts/logs/20261113-tc21.log
```

## Change before the batch

As written in PR #50, the case always picked `Interview` and never restored the
stage. `Save status` is disabled while the picked stage equals the stored one
(`update_status_sheet.dart`), so after one pass the next run would find
`Interview` already set and could not save. The instruction now opens the first
card that is not `Withdrawn` / `Accepted` / `Rejected`, picks `Interview` (or
`Under review` when it already reads `Interview`), checks the detail and the
list, then sets the stage read first back and reports it. The assertions check
the target, the detail badge, the list badge and the restored badge. This
matches the test-plan row, which already said the case restores the stage.

## Runs

| # | Trace | pytest | Time (s) | Steps | Report |
|---|---|---|---|---|---|
| 1 | `5a7c9816` | passed | 115.4 | 13 | `Submitted` → `Interview` (detail and list) → restored `Submitted` |
| 2 | `e43bff07` | passed | 87.4 | 13 | same |
| 3 | `de3f6664` | passed | 87.4 | 13 | same |

Batch: `3 passed, 6 deselected in 360.18s`, 2026-11-13 08:45:37 – 08:51:38.
Pass rate 3/3 (100%), average 96.7 s.

Each session's step history (`GET /api/sessions/{id}/steps`) was read after the
batch to make sure the agent really did the steps it reported: `Applications` →
the card → `Update status` → `Interview` → `Save status` → wait → `Back` → the
same card (its label read `Status: Interview`) → `Update status` → `Submitted` →
`Save status` → `report_task_status`.

## Videos

| Trace | File (git-ignored copy) | Length | Size |
|---|---|---|---|
| `5a7c9816` | `e2e_test/artifacts/recordings/20261113/TC-21_5a7c9816.mp4` | 106.6 s | 2.8 MB |
| `e43bff07` | `e2e_test/artifacts/recordings/20261113/TC-21_e43bff07.mp4` | 75.8 s | 2.6 MB |
| `de3f6664` | `e2e_test/artifacts/recordings/20261113/TC-21_de3f6664.mp4` | 74.9 s | 2.8 MB |

The originals are in `~/artemis/traces/web_*_<trace>_PASS_*/recording.mp4`. They
show the test account, so they stay outside the repository.

## Not checked

- `application_update` in Logcat and `Step 3 of 4 (75% completed)`: the case
  does not assert them and they were not checked in this batch.
- After the batch the emulator crashed once (exit 139) during the UAT-B7 retest;
  that happened after the three TC-21 runs and does not affect them.
