# ARTEMIS environment check — 2026-10-22

Status: **E2E not run**. This file records the real environment check instead of
a fabricated run. No `runs.jsonl` entry, trace ID or replay exists for this
date.

## Commands and output

```text
$ date '+%Y-%m-%d %H:%M:%S %Z'
2026-10-22 14:29:48 +07

$ adb devices
List of devices attached

$ curl -sS --max-time 3 http://127.0.0.1:8000/health
curl: (7) Failed to connect to 127.0.0.1 port 8000 after 0 ms: Couldn't connect to server
exit=7

$ flutter devices
Found 3 connected devices:
  iPhone 17 Pro (mobile) • 2E311954-DCD7-4551-B8C2-693F676CC600 • ios • com.apple.CoreSimulator.SimRuntime.iOS-26-5 (simulator)
  macOS (desktop)        • macos • darwin-arm64 • macOS 26.5.1 25F80 darwin-arm64
  Chrome (web)           • chrome • web-javascript • Google Chrome 155.0.8059.85
```

## Why it cannot run

- `adb devices` lists no Android device or emulator. ARTEMIS drives Android.
- Nothing is listening on the ARTEMIS daemon at `127.0.0.1:8000`.
- The only mobile target is an iOS simulator, which is not supported by this
  Android ARTEMIS setup.

## Supporting UI evidence (not ARTEMIS)

- `evidence/screens/home-roles-actions-20261022.png` — rebuilt iOS simulator,
  Home with `Browse by Role` and `All roles`.
- `evidence/screens/home-actions-transparent-20261022.png` — `View all` on the
  page background, no white action pill.

These screenshots prove the UI state only. They are **not** an E2E pass.
TC-16 still needs three runs on Android with the ARTEMIS host before it can be
marked Done.
