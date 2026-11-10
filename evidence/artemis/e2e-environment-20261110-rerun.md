# ARTEMIS runs — 2026-11-10 (TC-19 rerun, TC-14 counted 3/3)

Status: **TC-19 passed 3 of 3** after the case was corrected, and **TC-14 reached its counted 3 of 3** (fourth attempt overall). 10 runs in this batch (1 smoke, 3 TC-19 before the last wording fix, 3 counted TC-19, 3 counted TC-14). Every run was checked against its step history.

The 10 lines were copied from the git-ignored `e2e_test/artifacts/runs.jsonl` (lines 41–50) to [`runs-20261110-rerun.jsonl`](runs-20261110-rerun.jsonl).

## Environment

| Item | Value |
|---|---|
| App | Profile build of `dev` `ac7322e` (installed 2026-11-09 21:34, unchanged since the morning batch) |
| Suite | Working tree with the TC-19 wording + assertion fix (uncommitted at run time) |
| Device | `emulator-5554`, `Medium_Phone_API_37.0`, API 37, `-gpu swiftshader_indirect`, cold-booted on this host |
| Host | Windows, `uv` 0.13.6, Android SDK at `%LOCALAPPDATA%\Android\sdk` |
| ARTEMIS | `351ca84` + [`artemis-local.patch`](../../e2e_test/artemis-local.patch); daemon `artemis ui --no-open` on `127.0.0.1:8000`; planner `gemini-3.5-flash-lite` (fallback `gemini-3.1-flash-lite`) |
| Recording | `adb shell screenrecord` (540×1170, 2 Mbit/s, 170 s segments). ARTEMIS's own scrcpy recording fails on this host (`Failed to start scrcpy recording: [WinError 2]`) |
| Account | signed in as the test account; 2 CVs in Profile (`Mai_Duy_Lập_Resume.pdf` marked default, `MaiDuyLap_CV_Fullstack.pdf`) |

Commands (from `e2e_test/`, a screen recording runs in parallel):

```bash
uv run pytest test_apply_form.py -k tc19 -v                 # smoke
uv run pytest test_apply_form.py -k tc19 --count 3 -v       # counted batch
uv run pytest test_auth.py -k tc14 --count 3 -v             # counted batch
```

## Runs

| # | Test | Trace | pytest | Time (s) | Note |
|---|---|---|---|---|---|
| 1 | TC-19 | `09d195fb` | passed | 292.6 | smoke run of the corrected case; not counted |
| 2 | TC-19 | `bb54f7e8` | passed | 221.5 | counted batch 1 |
| 3 | TC-19 | `5a96d3a7` | passed | 282.3 | counted batch 1 |
| 4 | TC-19 | `f1779886` | failed | 172.1 | letter check: ARTEMIS tapped mid-letter, so the text was not at the end; the assertion was too strict |
| 5 | TC-19 | `09f62a37` | passed | 198.4 | counted |
| 6 | TC-19 | `1927e4f8` | passed | 371.1 | counted |
| 7 | TC-19 | `23c38220` | passed | 119.4 | counted |
| 8 | TC-14 | `29074354` | passed | 41.3 | counted; already signed in, so no sign-in step |
| 9 | TC-14 | `f88d29bc` | passed | 171.6 | counted; signs in first |
| 10 | TC-14 | `4d59b7cd` | passed | 90.9 | counted; signs in first |

## Result (counted runs)

| Test | Passed | Average time (s) | Counted traces |
|---|---|---|---|
| TC-19 | 3/3 | 229.6 | `09f62a37`, `1927e4f8`, `23c38220` |
| TC-14 | 3/3 | 101.3 | `29074354`, `f88d29bc`, `4d59b7cd` |

Every counted run was checked through `GET /api/sessions/{id}/steps`:

- **TC-19:** Search → `Intern` → first non-applied card → `Apply now` → scroll to `CV / Resume` → `Change CV` → tap the other CV (the sheet closes on the tap) → the section shows the new name → tap the cover letter and type ` Test line.` → `report_task_status` with `cv_after_change == selected_cv` and `letter_edited: true`.
- **TC-14:** `Profile` → swipe up past `CV library` and `Technical skills` → `Sign out` → Login → Android Back → Android home, no bottom navigation → relaunch Internly → Login.

## Why a run failed or was not counted

- **TC-19 `f1779886`.** Test-side expectation error: the instruction says to move the cursor to the end, but ARTEMIS taps a screen point (`[300,300]`), which landed in the middle of the letter. The typed ` Test line.` was inserted there, so `letter_tail` still read `Sincerely,\nMai Duy Lập`. The case now asks whether the letter contains `Test line.` (`letter_edited`) instead of checking the last words, which does not depend on where the caret landed.
- **TC-19 `be05e6e5`, `0aba4890`, `83edba2d` (earlier on 2026-11-10).** Two runs were cancelled by the operator. `83edba2d` was the emulator dropping off ADB: `Device emulator-5554 is not available (adb does not list it)` / `adb install failed: device 'emulator-5554' not found` in `~/artemis/traces/83edba2d-…/stdout.log`; not an app or case defect. The device was cold-booted before this batch and stayed connected.
- **TC-14 `d84b3a90`, `0f1910f3` (earlier).** Cancelled by the operator; no fix implied. This batch passed 3/3.

## Recordings

Device screen only (the ARTEMIS console/terminal were not captured). Segments are consecutive parts of one batch; a batch is a single command run.

| Test | Files | Size |
|---|---|---|
| TC-19 smoke | `e2e_test/artifacts/recordings/20261110/TC-19_Change_CV_smoke_09d195fb.mp4` | 1.5 MiB |
| TC-19 batch 1 | `e2e_test/artifacts/recordings/20261110/tc19-batch1/tc19_1.mp4` … `tc19_5.mp4` | 11.9 MiB |
| TC-19 counted | `e2e_test/artifacts/recordings/20261110/tc19-counted/tc19b_1.mp4` … `tc19b_5.mp4` | 13.0 MiB |
| TC-14 counted | `e2e_test/artifacts/recordings/20261110/tc14-counted/tc14_1.mp4` … `tc14_3.mp4` | 10.1 MiB |

Recordings are git-ignored (`e2e_test/artifacts/`). They show the test account, so they stay out of the repository and are uploaded to the Drive folder [Record Artemis Test - PRM323](https://drive.google.com/drive/folders/1B44bE_K5JY06eAhTU0FrJZrbmcfe7LCf).

## Recorded rerun with ARTEMIS's own screen recording (same evening)

The host had no `scrcpy` and no `ffmpeg`, so ARTEMIS logged `Failed to start scrcpy recording: [WinError 2]` and every earlier session was recorded with `adb shell screenrecord` instead. Both tools are now installed on the host with `winget`, and the daemon is started with them on `PATH`:

```powershell
winget install --id Genymobile.scrcpy --accept-package-agreements --accept-source-agreements --disable-interactivity
winget install --id Gyan.FFmpeg --accept-package-agreements --accept-source-agreements --disable-interactivity
```

- `scrcpy 5.0.1` → `%LOCALAPPDATA%\Microsoft\WinGet\Packages\Genymobile.scrcpy_…\scrcpy-win64-v5.0.1`
- `ffmpeg 9.0.2` (gyan.dev full build) → `%LOCALAPPDATA%\Microsoft\WinGet\Packages\Gyan.FFmpeg_…\ffmpeg-9.0.2-full_build\bin`

A probe with ARTEMIS's exact flags (`--no-window --record <file>.mkv --record-format mkv --video-bit-rate 2M --capture-orientation=@`) produced a valid 4.3 s MKV, and the ffmpeg remux to MP4 succeeded. ARTEMIS then wrote a `recording.mp4` for every session in its trace folder (`~/artemis/traces/web_<id>_<trace>_<status>_<time>/recording.mp4`), one per run, full length, 1080 × 2400 h264 + opus.

Both cases were rerun with that setup (cold app start per run, `gemini-3.5-flash-lite`):

| Test | Trace | pytest | Time (s) | Video |
|---|---|---|---|---|
| TC-19 | `05bb60a9` | passed (smoke, not counted) | 236.1 | 223.9 s, 11.0 MiB |
| TC-19 | `0dcf9e76` | passed | 140.2 | 132.2 s, 8.1 MiB |
| TC-19 | `a3b7aa33` | passed | 179.3 | 171.6 s, 7.3 MiB |
| TC-19 | `8304537f` | passed | 140.4 | 132.5 s, 9.0 MiB |
| TC-14 | `8f5fb339` | passed | 71.5 | 63.4 s, 3.5 MiB |
| TC-14 | `ca206198` | passed | 114.5 | 107.3 s, 5.3 MiB |
| TC-14 | `7103ec00` | passed | 106.0 | 98.7 s, 5.0 MiB |

Result: **TC-19 3/3 (avg 153.3 s), TC-14 3/3 (avg 97.3 s)**, with the same step checks as the batch above (TC-19 changed `Mai_Duy_Lập_Resume.pdf` → `MaiDuyLap_CV_Fullstack.pdf` and edited the letter; TC-14 signed out, pressed Back to Android home and reopened to Login). Lines in [`runs-20261110-recorded.jsonl`](runs-20261110-recorded.jsonl).

Videos copied out of the ARTEMIS traces to `e2e_test/artifacts/recordings/20261110/artemis/`:

| Test | File | Size |
|---|---|---|
| TC-19 smoke | `TC-19_smoke_05bb60a9.mp4` | 11.0 MiB |
| TC-19 counted | `TC-19_0dcf9e76.mp4`, `TC-19_a3b7aa33.mp4`, `TC-19_8304537f.mp4` | 8.1 / 7.3 / 9.0 MiB |
| TC-14 counted | `TC-14_8f5fb339.mp4`, `TC-14_ca206198.mp4`, `TC-14_7103ec00.mp4` | 3.5 / 5.3 / 5.0 MiB |

One merged file per test, made with `ffmpeg -f concat -c copy` from the three counted runs (lossless, same codec parameters; the smoke run is not included). The merge boundary is seamless — frames at 134 s and 300 s show the second and third TC-19 runs, and at 172 s the third TC-14 run:

| Test | Merged file | Duration | Size |
|---|---|---|---|
| TC-19 | `TC-19_Change_CV.mp4` | 436.3 s (132.2 + 171.6 + 132.5) | 24.4 MiB |
| TC-14 | `TC-14_Sign_out.mp4` | 269.3 s (63.4 + 107.3 + 98.7) | 13.7 MiB |

These are device-screen videos without the ARTEMIS console or terminal. The originals stay in `~/artemis/traces/` and are also git-ignored.
