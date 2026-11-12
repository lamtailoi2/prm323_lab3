# ARTEMIS environment and TC-11 runs — 2026-11-12

First run of **TC-11 (Export and upload)** after the report export feature landed
(G-05, DC-36, P-71). The case was run three times as the lab requires, with a
full-desktop screen recording that shows the emulator, the ARTEMIS workspace and
the terminal in one frame.

The 16 lines in [`runs-20261112.jsonl`](runs-20261112.jsonl) were copied from
the git-ignored `e2e_test/artifacts/runs.jsonl` (lines 58–73; every TC-11 line
from the smoke run onwards).

## Environment

| Item | Value |
|---|---|
| App | Profile build of `dev` working tree (report export, P-71), installed 2026-11-12 21:27, `com.group3.internly` 0.1.0 |
| Suite | `e2e_test/test_report_export.py` + `conftest.py` with the `final_report()` retry fix (see below) |
| Device | `emulator-5554`, `Medium_Phone_API_37.0`, API 37, booted on this host |
| Host | Windows 11 · Flutter 3.47.8 / Dart 3.13.7 · `uv` · Android SDK at `%LOCALAPPDATA%\Android\sdk` |
| ARTEMIS | `351ca84` + [`artemis-local.patch`](../../e2e_test/artemis-local.patch); daemon `artemis ui --no-open` on `127.0.0.1:8000`; planner `gemini-3.5-flash-lite` |
| Recording | `ffmpeg` `gdigrab` full desktop, 8 fps, h264, 3200 × 2000 (the desktop is 1600 × 1000 at 200 % scaling) |
| Account | signed in as the test account; 9 applications; 2 CVs in Profile |

`uv run python -m artemis doctor` → every row ✔ (Python 3.12.16, planner
`gemini-3.5-flash-lite`, device 1080 × 2400, FFmpeg 9.0.2 + scrcpy 5.0.1).

## Commands

```powershell
# from e2e_test/
uv run pytest test_report_export.py -k tc11 -v                 # smoke
uv run pytest test_report_export.py -k tc11 --count 3 -v       # counted batch (recorded)
```

## Runs

| # | Trace | pytest | Time (s) | Note |
|---|---|---|---|---|
| 1 | `4dac10ef` | passed | 201.0 | smoke run before the counted batches; not counted |
| 2 | `59da6690` | **failed** | 154.1 | `AssertionError: no structured output` — the flow was correct; see below |
| 3 | `41e95a20` | passed | 208.6 | counted batch 1 |
| 4 | `b66e5ecb` | passed | 408.7 | |
| 5 | `946e46e9` | passed | 99.8 | |
| 6 | `3511a428` | passed | 215.6 | |
| 7 | `16f46a69` | passed | 157.4 | |
| 8 | `da0bef27` | passed | 151.2 | |
| 9 | `bc0782fa` | passed | 153.0 | |
| 10 | `2a8ec04e` | passed | 326.1 | |
| 11 | `49ad58c3` | passed | 81.6 | |
| 12 | `6c614d54` | passed | 156.1 | |
| 13 | `fbba7cf6` | passed | 2718.7 | batch aborted by an emulator crash mid-run; rerun below |
| 14 | `f27d53d0` | passed | 441.3 | **counted batch (recorded)** |
| 15 | `a4cbf99a` | passed | 264.4 | **counted batch (recorded)** |
| 16 | `0fb3220a` | passed | 551.2 | **counted batch (recorded)** |

**Counted result: TC-11 3/3, average 418.9 s** (traces `f27d53d0`, `a4cbf99a`,
`0fb3220a`; total 1299.9 s including collection and teardown).

Each counted run performed: `Profile` → scroll to `Diagnostics` → `Firebase demo`
→ `Report export` → read the application count → `Export report` → wait for the
upload → read `Last exported` and the `Your reports` row with its `Open` action
→ `report_task_status` with
`{"application_count":"9 applications","export_finished":true,`
`"last_exported":"application-report-2026-11-12.pdf",`
`"report_files":["application-report-2026-11-12.pdf"],`
`"report_rows_have_open":true}`.

## Why a run failed or was not counted

- **`59da6690` — harness race, not an app defect.** The agent finished the whole
  flow and its `report_task_status` explanation was valid JSON, but
  `final_report()` read `/api/sessions/{id}/steps` before that last step was
  persisted, so `parse_report()` returned `{}` and the case failed with
  `no structured output`. Fix: `final_report()` now retries the read up to 10
  times, one second apart (`e2e_test/conftest.py`). Verified against this trace:
  the step exists and parses.
- **`fbba7cf6` (2718.7 s) — environment.** The emulator disappeared from ADB
  mid-batch (`adb shell am force-stop` returned exit 1, `adb devices` empty),
  and the ARTEMIS daemon exited with it. The emulator was cold-booted, the
  daemon restarted, and the counted batch was recorded afterwards.
- **Duplicate rows found during the smoke run.** The first build used Firestore
  auto-ids, so exporting twice in one day produced two identical
  `application-report-2026-11-12.pdf` rows. The metadata document id is now
  `application-report-YYYY-MM-DD`, so a second export replaces the same
  document. The four leftover test documents were deleted with the admin SDK
  (owner-approved) before the recorded batch; the video starts with one report
  in `Your reports` and still shows a single row after the export.

## Recording

| File | Duration | Size | Shows |
|---|---|---|---|
| `e2e_test/artifacts/recordings/20261112/TC-11_Report_Export_recorded.mp4` | 1343.8 s | 71.8 MiB | emulator (left), ARTEMIS workspace with the live steps and the ● Recording marker (top right), and the terminal running `uv run pytest … --count 3 -v` (bottom right) |
| `e2e_test/artifacts/recordings/20261112/TC-11_attempt1_2pass1fail.mp4` | 1607.8 s | 454.1 MiB | the earlier batch (2 passed, 1 failed on `no structured output`) before the harness fix |

The recording starts ~12 s before pytest, so the command itself and all three
`PASSED` lines plus `3 passed in 1299.88s` are in frame. Frames checked at
30 s, 700 s and 1300 s.

`e2e_test/artifacts/` is git-ignored: the videos show the signed-in test
account, so they stay out of the repository and are uploaded to the Drive folder
[Record Artemis Test - PRM323](https://drive.google.com/drive/folders/1B44bE_K5JY06eAhTU0FrJZrbmcfe7LCf).
