# Internly — Internship Finder

Internly is a mobile app that helps university IT and Software Engineering students **find internships that match their skills, save the ones they like, apply with a stored CV, and track every application in one place**.

This repository is the PRM393 **Lab 3** implementation (Flutter + Firebase, graded on Android) of the Lab 2 UI/UX design. **Lab 2 is the source of truth for the UI**: screens, flows, tokens and components come from the [Lab 2 handoff](docs/design/README.md); every deviation is recorded in [`docs/design-traceability.md`](docs/design-traceability.md).

> **Status: foundation ready; Home reads the synced listing pool.** Design system, shared components, app shell, authenticated routing, Firebase bootstrap, the scheduled SerpAPI → Firestore sync, rules and docs are in place. The remaining feature screens are placeholders that each owner replaces ([Feature ownership](#feature-ownership)).

**Demo video:** _link to be added_

## Product overview

| | |
|---|---|
| Topic | Internship finder and application tracker for IT students (approved Lab 2 topic) |
| Persona | Minh, 21, third-year Software Engineering student: searches in 2–5 minute mobile sessions, one-handed, on unstable campus Wi-Fi; applies to several companies and loses track of them ([persona](docs/design/persona.md)) |
| Problem | Listings are scattered across many sources, and students lose track of where they have applied |
| Success criteria | Find an internship by skill and work mode in **< 30 s**; submit an application from Internship Detail in **< 2 min** with a stored CV |
| Data | **SerpAPI — Google Jobs** (`engine=google_jobs`), mirrored into a shared **Cloud Firestore** listing pool by a scheduled function every 6 hours; **Cloud Firestore** for each student's own data (profile, saved, applications, notifications, report metadata); **Cloud Storage for Firebase** for CV and PDF report files |

### User flows

One journey in three flows: **search → apply (now, or later via Saved) → track**. Revised in Lab 3: Save is a sub-flow of Apply (DC-08), and Apply is the **email-based Compose flow** (DC-31) with optional CV match (DC-30) and validation (DC-19) checks.

| Flow | Path | Alternative / error paths |
|---|---|---|
| **1. Search** | Home → Search → Filters → Results → Internship Detail | No results → Clear filters; results / detail load error → Retry |
| **2. Apply** | Internship Detail → Apply → **Compose application** (recipient + AI subject/letter) → Open email app → I've sent it → Success | Missing recipient email; AI draft failure → template; already applied; empty profile CV (optional); CV gaps → suggestions → improve or continue; **2e Save for later** → Saved → open → Apply (unsave + Undo, empty list, save error + Retry) |
| **3. Track** | Applications → Application Detail → status | No applications; list / detail load errors; withdraw + Undo |

Details: [`user-flow.md`](docs/design/user-flow.md) · screens: [`screen-spec.md`](docs/design/screen-spec.md) · route / widget / data source per screen: [`design-traceability.md`](docs/design-traceability.md).

### Screens

Bottom navigation (fixed): **Home · Search · Saved · Applications · Profile**. Lab 2 screens: Home, Search, Search Results, Internship Detail, Saved Internships, Application Form, Application Review, Application Success, My Applications, Application Detail, Profile. Lab 3 additions: Login, the Profile **CV library** (several CVs, one default), CV Match Check, and a **Firebase demo area on Profile** (Notification Center, report export and upload, Remote Config values, Crashlytics test actions). The Lab 2 Application Form / Review / Success screens were replaced by the email-based Compose flow (DC-31).

## Tech stack and pinned versions

| Component | Version |
|---|---|
| Flutter / Dart | **3.47.3** stable / **3.13.3** |
| `flutter_riverpod` (state + DI) | 3.4.3 |
| `go_router` | 18.1.1 |
| `firebase_core` / `firebase_auth` / `cloud_firestore` | 5.0.0 / 7.0.0 / 7.0.0 |
| `firebase_analytics` / `firebase_crashlytics` / `firebase_remote_config` | 13.0.0 / 6.0.0 / 7.0.0 |
| `google_sign_in` | 7.2.0 |
| `firebase_storage` | 14.0.0 |
| `material_symbols_icons` | 4.2960.0 |
| Inter font | 4.1 (bundled, OFL) |
| Google ARTEMIS | commit `351ca8422f7b5b54e80a9c1ce03a222e02415b6b` (2026-09-29) |
| E2E Python deps | Python ≥ 3.12, `artemis-client` @ that commit, pytest 9.1.1, pytest-asyncio 1.4.0, pytest-repeat 0.9.4, python-dotenv 1.2.4 |
| Platforms | Android (min SDK 24, target 36), the graded platform · iOS 15.0 (CocoaPods) also builds |

Exact versions are pinned in [`pubspec.yaml`](pubspec.yaml) and [`e2e_test/pyproject.toml`](e2e_test/pyproject.toml). **Runs at $0**: Firebase within its no-cost quotas (Blaze only for Storage, US bucket, $1 budget alert), SerpAPI free, Gemini API free tier for ARTEMIS; see [handoff-gaps G-26](docs/records/handoff-gaps.md#g-26-zero-cost-plan).

## Getting started

### Prerequisites

- Flutter **3.47.3** (stable). Check with `flutter doctor`.
- **Android:** Android SDK with `cmdline-tools`, platform 36, JDK 17, and a device or emulator.
- Firebase: Node.js 22 (Cloud Functions runtime), `firebase-tools`, `flutterfire_cli`.
- A free SerpAPI key (**owner only**, for the sync function secret).
- E2E tests: Python 3.12+, `uv`, ADB, a Google ARTEMIS checkout with [`e2e_test/artemis-local.patch`](e2e_test/artemis-local.patch) applied ([guide](docs/guides/artemis-e2e.md)).

### Install and configure

```bash
git clone https://github.com/lamtailoi2/prm323_lab3.git && cd prm323_lab3
flutter pub get
# Owner: cp .env.example .env and fill it (docs/guides/firebase-setup.md §15).
# Teammates: put the .env you received in the repository root.
```

Then follow [`docs/guides/firebase-setup.md`](docs/guides/firebase-setup.md):

1. **Firebase:** create the project, run `flutterfire configure` (Android `com.group3.internly`), and commit `android/app/google-services.json`.
2. **Google Sign-In:** enable the Google provider and add each developer's **SHA-1 and SHA-256**.
3. **Rules:** `firebase deploy --only firestore:rules,firestore:indexes,storage`.
4. **Cloud Storage:** upgrade to Blaze, set a **$1 budget alert**, create the bucket in **US-CENTRAL1 / US-EAST1 / US-WEST1** ([§10](docs/guides/firebase-setup.md#10-cloud-storage-cv-upload-pdf-report-on-blaze-at-0)).
5. **Internship sync:** store `SERPAPI_KEY` in Secret Manager and deploy `functions/` ([§13](docs/guides/firebase-setup.md#13-serpapi-sync-cloud-function-internship-data)).
6. **Crashlytics** enabled; **Remote Config** parameters created from [`firebase/remote-config-defaults.json`](firebase/remote-config-defaults.json).

Without Firebase configuration the app starts on "Firebase is not configured". This is intended: it never fakes a connection.

### Run

```bash
flutter devices
flutter run -d <android-device-id> --dart-define-from-file=.env
flutter build apk --debug --dart-define-from-file=.env

# Internship data (owner once): see docs/guides/firebase-setup.md §13
cd functions && npm install && cd ..
firebase deploy --only functions,firestore:rules
```

### Tests

```bash
dart format lib test        # format
flutter analyze             # must print "No issues found!"
flutter test                # unit, ViewModel, widget and routing tests

# End-to-end (Google ARTEMIS, Android device, see docs/guides/artemis-e2e.md)
cd e2e_test && cp .env.example .env && uv sync
uv run pytest --count 3 -v  # every test 3 times
```

Results: [`docs/records/test-report.md`](docs/records/test-report.md) (Flutter) and [`docs/test-plan.md`](docs/test-plan.md) §4 (ARTEMIS).

## Deliverables map

| Lab 3 deliverable | Location |
|---|---|
| App code (MVVM layers) | [`lib/`](lib/) |
| Design traceability | [`docs/design-traceability.md`](docs/design-traceability.md) |
| Architecture | [`docs/architecture.md`](docs/architecture.md) |
| Analytics event plan | [`docs/analytics-plan.md`](docs/analytics-plan.md) |
| Test plan + ARTEMIS suite | [`docs/test-plan.md`](docs/test-plan.md), [`e2e_test/`](e2e_test/) |
| AI code review record | [`docs/code-review.md`](docs/code-review.md) |
| Firebase config and rules | [`firebase/`](firebase/) (`firestore.rules`, `storage.rules`, `remote-config-defaults.json`), `android/app/google-services.json` |
| Scheduled internship sync | [`functions/`](functions/) (TypeScript Cloud Function, SerpAPI → Firestore) |
| Evidence (console, DebugView, Crashlytics, ARTEMIS) | [`evidence/`](evidence/) |
| Final report, slides | Submitted separately (not in the repository) |
| Demo video | Link at the top of this README |

## Feature ownership

| Feature | Screens | Folder |
|---|---|---|
| Home | Home | `features/home/` |
| Search | Search, Search Results, Internship Detail | `features/internships/` |
| Saved | Saved Internships | `features/saved/` |
| Apply | Application Form, CV Match Check, Review, Success | `features/applications/` |
| Track | My Applications, Application Detail | `features/applications/` |
| Profile | Profile, Firebase demo area | `features/profile/` |
| Auth | Login (final design) | `features/auth/` |
| Notifications | Notification Center, FCM | `features/notifications/` |
| Report | PDF export and upload | `features/report_export/` |

Coding rules for people and AI agents: [`AGENTS.md`](AGENTS.md).

## Other documentation

| Document | Purpose |
|---|---|
| [`docs/design/design-system.md`](docs/design/design-system.md) | Tokens and components, Figma ↔ code cross-check, contrast results |
| [`docs/guides/firebase-setup.md`](docs/guides/firebase-setup.md) | Firebase, Google Sign-In, Storage, Remote Config, SerpAPI sync secret |
| [`docs/business-rules.md`](docs/business-rules.md) | User and Admin actors, swimlanes, `BR-xx` branch codes, application state machine and test traceability |
| [`docs/records/handoff-gaps.md`](docs/records/handoff-gaps.md) | Missing / conflicting requirements and decisions |
| [`docs/records/implementation-ai-log.md`](docs/records/implementation-ai-log.md) | Prompts, outputs, verification and decisions for AI-assisted work |
| [`tools/admin-dashboard/README.md`](tools/admin-dashboard/README.md) | Local admin dashboard: send FCM notifications, find device tokens, inspect/delete notification history |

## AI tools used

| Tool | Purpose |
|---|---|
| Google Stitch | Lab 2 screen generation (design phase) |
| Claude Code (Opus 5.5) | Repository initialization: theme, shared widgets, services, routing, tests, documentation; review of the Lab 3 requirements; Profile feature (P-21); Login screen from the Login frame (P-31); Saved empty state opens Search (P-33); Internship Detail, Search filters and analytics, Apply Form, Job type and Applied badge (P-34 – P-43); fixes from the AI review (P-44); ARTEMIS host setup, E2E harness fixes, the run guide and ARTEMIS cases (P-57, P-59 – P-61) ([log](docs/records/implementation-ai-log.md)) |
| OpenCode (`deepseek-v4.1-flash-free`) | Home UI, scheduled SerpAPI → Firestore sync, rules and docs for the Home slice; Saved list, the Home Save Toggle, unsave with Undo and the Saved loading state; Search bookmark merged onto the Saved write path (P-58); Compose CV auto-select and `Change CV` (P-83) ([log](docs/records/implementation-ai-log.md)) |
| Command Code | CV validation vertical slice: callable `validateCv` + Gemini free tier, `CvValidationService`, ViewModel, step widget, tests and docs (P-32); work mode read from the listing text so the Search filter no longer returns an empty list (P-45); Filter Skills from the current pool instead of a fixed list (P-46); Flow 2 completion: Validate CV screen, Application Review, Success, `ApplicationService.createApplication()` and `application_create` (P-47); FCM in all three app states and the Notification Center (P-50, P-51); local admin dashboard for FCM, users and notification history (P-52); email-based Apply flow: Compose application, callable `composeCoverLetter` (Groq + template fallback), `mailto:` draft and optional CV checks (P-74); SerpAPI fresher/junior keywords and Detail role/level badges (P-79); Profile experience band and Home ranking tiebreaker (P-80); ARTEMIS CV-library cases TC-06/07/09/14/17/18/19 with the two-CV seed and video-run guide (P-84); GA4 realtime card on the admin dashboard (P-85); testing-doc sync for the 2026-11-09/10 ARTEMIS batch (P-86) ([log](docs/records/implementation-ai-log.md)) |
| Google ARTEMIS + Gemini (free tier) | End-to-end tests and the exploratory session |
| Claude Code review subagents (Opus 5.5) | AI code review R1 of PRs #11–#15: 20 findings, decisions and fixes ([`code-review.md`](docs/code-review.md), raw output in `evidence/code-review/`) |
| Claude Code (Sonnet 5) | DC-09 deviation record, `application_update` / `application_delete` logging on withdraw / undo (P-48) ([log](docs/records/implementation-ai-log.md)) |

## Known limitations

- Search, Saved and Applications are still placeholders; the Login screen is interim (DC-01). Profile settings rows other than Sign out have no screens yet (G-28).
- Firebase is not configured in the repository yet; Google Sign-In needs per-developer SHA fingerprints.
- SerpAPI is called by the scheduled sync function, not the app; the free plan still has a small monthly quota, so the pool refreshes gradually (G-25).
- Cloud Storage needs the Blaze plan: budgets only alert and cannot cap spending, so the bucket must stay in a US no-cost region (G-12).
- The Android build was not verified on the machine that initialized the repo (incomplete Android SDK); the iOS simulator build was ([`test-report.md`](docs/records/test-report.md)).
- iOS uses CocoaPods because Swift Package Manager cannot resolve Firebase iOS SDK 13 with GoogleSignIn-iOS 9 (G-20).
- Open decisions are tracked in [`handoff-gaps.md`](docs/records/handoff-gaps.md).
