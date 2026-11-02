# ARTEMIS environment check — 2026-10-31

Status: **E2E not run**. This file records the real environment check instead of
a fabricated run. No `runs.jsonl` entry, trace ID or replay exists for this
date, and no test case was executed.

## Commands and output

```text
$ Get-Date -Format "yyyy-MM-dd HH:mm:ss zzz"
2026-10-31 19:47:51 +07:00

$ & "C:\Users\Lenovo\AppData\Local\Android\sdk\platform-tools\adb.exe" devices
List of devices attached
emulator-5554	device

$ & "...\adb.exe" -s emulator-5554 shell getprop ro.build.version.sdk
37

$ & "...\adb.exe" -s emulator-5554 shell pm list packages | Select-String internly

package:com.group3.internly

$ Invoke-WebRequest -Uri "http://127.0.0.1:8000/health" -TimeoutSec 3
FAILED: Unable to connect to the remote server (no listener on port 8000)

$ Get-Command uv
uv: not found on PATH

$ Get-Command python; python --version
python: C:\Users\Lenovo\AppData\Local\Microsoft\WindowsApps\python.exe
Python was not found; run without arguments to install from the Microsoft
Store, or disable this shortcut from Settings > Apps > Advanced app settings >
App execution aliases.

$ Test-Path D:\PRM\artemis
False   (no D:\PRM\artemis checkout)

$ flutter devices
Found 3 connected devices:
  sdk gphone64 x86 64 (mobile) • emulator-5554 • android-x64 • Android 17 (API 37) (emulator)
  Chrome (web)                 • chrome        • web-javascript • Google Chrome 156.0.8078.79
  Edge (web)                   • edge          • web-javascript • Microsoft Edge 156.0.4314.50
```

## Why it cannot run

- **No ARTEMIS daemon** is listening on `127.0.0.1:8000`. The pytest suite talks
  to the daemon through `artemis-client`; without it no instruction can be run.
- **No ARTEMIS host checkout** (`google/artemis` at the pinned commit) and no
  model API key (`GEMINI_API_KEY` belongs to the host, see `docs/test-plan.md`
  §0). The daemon cannot be started here.
- **No Python toolchain**: `uv` is not installed and the `python` on PATH is the
  Microsoft Store alias stub, so `uv sync` / `uv run pytest` cannot run.
- **No `e2e_test/.env`** (only `.env.example`), so `DEVICE_SERIAL`,
  `TEST_ACCOUNT_EMAIL` and `ARTEMIS_BASE_URL` are unset.

The Android side is ready: `emulator-5554` (API 37) is connected and
`com.group3.internly` is installed. The blocker is the ARTEMIS host, not the
device.

## What is needed before a real run

1. Clone `google/artemis` at `351ca8422f7b5b54e80a9c1ce03a222e02415b6b`, set
   `GEMINI_API_KEY` in the host `.env`, start `./start.sh` and connect
   `emulator-5554`.
2. Install `uv`; run `cd e2e_test && uv sync`.
3. Copy `.env.example` → `e2e_test/.env` and fill `DEVICE_SERIAL=emulator-5554`
   and `TEST_ACCOUNT_EMAIL`.
4. Run `uv run pytest --count 3 -v`; copy the resulting
   `e2e_test/artifacts/runs.jsonl` rows, trace IDs and replays here and into
   `docs/test-plan.md` §4.

These screenshots, if any, are **not** an E2E pass; every Ready case still needs
three Android runs with the ARTEMIS host before it can be marked Done.

## Update — 2026-10-31 ~20:05 +07 (host prepared, still not run)

Progress after the checks above:

- `uv 0.13.6` installed at `C:\Users\Lenovo\.local\bin\uv.exe`.
- ARTEMIS checkout found at `C:\Users\Lenovo\artemis`, `HEAD=351ca84` (the
  pinned commit).
- `uv sync --python 3.12` succeeded (Python 3.12.16, 190 packages). Python 3.15
  was rejected because `regex` had no wheel and needed MSVC.
- `C:\Users\Lenovo\artemis\.env` created from `.env.example`; **`GEMINI_API_KEY`
  is still empty**.
- Daemon started with
  `uv run python -m artemis ui --port 8000 --no-open`;
  `GET http://127.0.0.1:8000/health` returned **HTTP 200**.

An earlier `pytest --count 3` run against a stopped daemon failed all 15 tests
(12 × `NetworkError` connection refused, 3 × `FileNotFoundError` because `adb`
was not on PATH). No `artifacts/runs.jsonl` was written, because `run_case`
never reached `_record`.

Remaining blockers before a real run:

1. Put a free `GEMINI_API_KEY` in `C:\Users\Lenovo\artemis\.env` and restart the
   daemon (`python-dotenv` reads it at startup).
2. Put `adb` on PATH for the pytest process:
   `C:\Users\Lenovo\AppData\Local\Android\sdk\platform-tools` (needed by TC-01's
   Logcat check).
