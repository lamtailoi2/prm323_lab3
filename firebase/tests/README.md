# Firebase rules tests

Emulator tests for `firebase/firestore.rules` and `firebase/storage.rules`, plus a local page that runs the same checks for a recorded demo. They use `@firebase/rules-unit-testing` with Node's built-in test runner, so no Firebase project, credentials or network data are needed.

## Prerequisites

| Requirement | Value |
|---|---|
| Node.js | 24.12+ (the package pins `@firebase/rules-unit-testing` 6) |
| Firebase CLI | `firebase --version` works (`npm i -g firebase-tools`) |
| Java | A JDK 11+ on `PATH`: `java -version` must work. The Firebase CLI checks `java`, not `JAVA_HOME` |
| Working directory | The **repository root**; the emulator config is in `firebase.json` there |

Windows (Android Studio ships a JDK), for the current PowerShell window:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:PATH = "C:\Program Files\Android\Android Studio\jbr\bin;$env:PATH"
java -version
```

macOS / Linux:

```bash
export JAVA_HOME="$(/usr/libexec/java_home)"   # macOS
export PATH="$JAVA_HOME/bin:$PATH"
```

Each terminal window has its own environment, so a new window needs these again unless you set them permanently.

## Install (once)

```bash
npm --prefix firebase/tests install
```

The tools are regular `dependencies` on purpose: a global `npm config omit=dev` would otherwise install nothing.

## Run the suite

```bash
firebase emulators:exec --only firestore,storage --project demo-internly "npm --prefix firebase/tests test"
```

It prints `15 tests, 15 passed` in about 3 s and exits non-zero on any failure. The first run downloads the emulator jars, so it takes longer.

## Recorded demo (video evidence)

```bash
firebase emulators:exec --only firestore,storage --project demo-internly "npm --prefix firebase/tests run demo"
```

Open <http://localhost:5500>, press **Run all checks**, and record the browser. Every row shows who makes the request, what it does, whether the rules should allow or deny it, and the streaming PASS/FAIL with its time. <http://localhost:4000> is the Emulator UI, where the Firestore documents and Storage files created by the run appear, so the video can include both views.

Stop with `Ctrl+C` (it stops the page and the emulators). To run the same 19 checks without the page:

```bash
firebase emulators:exec --only firestore,storage --project demo-internly "npm --prefix firebase/tests run demo:check"
```

## What is covered

| File | Rules under test |
|---|---|
| `firestore.rules.test.mjs` | `users/{uid}` and its subcollections are owner-only (read, create, update, delete, and the 50-field limit); `internships/{key}` is readable only by signed-in users and never writable by a client; `sync/**` is closed to clients |
| `storage.rules.test.mjs` | `reports/{uid}` and `cvs/{uid}` are owner-only, PDF only, non-empty and at most 10 MB; every other path is denied |
| `demo/server.mjs` | The same decisions as 19 rows, streamed to `index.html`; `--self-test` runs them in the terminal |

Each case asserts a real result: `assertSucceeds` for an allowed request and `assertFails` (permission denied) for a denied one.

## Add a case

Add an `it(...)` to the matching `*.rules.test.mjs` file; that is the source of truth. Use `testEnv.authenticatedContext(uid)` for a signed-in client, `testEnv.unauthenticatedContext()` for a signed-out one, and `testEnv.withSecurityRulesDisabled(...)` only to seed data a client may not write. `afterEach` clears Firestore and Storage, so cases do not leak.

If the case should also appear in the recorded demo, add one entry to the `scenarios` array in `demo/server.mjs` with `group`, `actor`, `expected`, `action` and `run(env)`. The demo streams the plan from the same array, so the page and the terminal stay in sync.

## Troubleshooting

| Message | Cause | Fix |
|---|---|---|
| `Could not spawn 'java -version'` | No JDK on `PATH` in this terminal | Run the export/`$env:` block above in the same window |
| `Could not find config (firebase.json)` | Started outside the repository root | `cd` to the repository root first |
| `port 8080 is not open` / `port taken` | Another emulator still running | `Get-NetTCPConnection -LocalPort 8080 -State Listen \| ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }` (macOS/Linux: `lsof -ti :8080 \| xargs kill`) |
| `invalid config prefix=true` | The command was split across lines inside the quotes | Paste it as one line; `Ctrl+C` if the prompt shows `>>` |
| `npm install` adds 0 packages | `omit=dev` in the npm config | Do not pass `--omit=dev`; the package lists its tools as `dependencies` |
| `sun.misc.Unsafe` warning | Storage rules runtime on JDK 25 | Harmless; results are unaffected |

`demo-internly` is a demo project ID, so every request stays local and can never reach a real project.

Results of the latest run are in [`docs/records/test-report.md`](../../docs/records/test-report.md).
