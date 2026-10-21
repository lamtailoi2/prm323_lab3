# Internly — Internship Finder

Internly is a mobile app (Android and iOS) that helps university IT and Software Engineering students **find internships that match their skills, save the ones they like, apply with a stored CV, and track every application in one place**.

This repository is the Lab 3 implementation (Flutter + Firebase) of the Lab 2 UI/UX design. **Lab 2 is the source of truth for the UI**: screens, flows, tokens and components come from the [Lab 2 handoff](docs/lab2-handoff/README.md) and are not reinvented here.

> **Status: initialized foundation.** The design system, shared components, app shell, authenticated routing, Firebase bootstrap and docs are in place. Feature screens are placeholders that each owner replaces (see [Feature ownership](#feature-ownership)).

## Product overview

| | |
|---|---|
| Target users | Third- and fourth-year IT / Software Engineering students in Vietnam looking for an internship |
| Persona | Minh, 21: searches in 2–5 minute mobile sessions, one-handed, on unstable campus Wi-Fi; applies to several companies and loses track of them ([persona](docs/lab2-handoff/ux/persona.md)) |
| Problem | Listings are scattered across many sources, and students lose track of where they have applied |
| Success criteria | Find an internship by skill and work mode in **< 30 s**; submit an application from Internship Detail in **< 2 min** with a stored CV |

### Core user flows

One journey in three flows: **search → apply (now, or later via Saved) → track**. Revised in Lab 3 (DC-08): Save is now a sub-flow of Apply, and Apply has a new CV match check (DC-09).

| Flow | Path | Branches |
|---|---|---|
| **1. Search Internship** | Home → Search → Filters → Results → Internship Detail | No results → Clear filters, results/detail load error + Retry |
| **2. Apply Internship** | Internship Detail → Apply → Application Form → **CV Match Check** → Review → Success | CV upload error + Retry, empty profile, already applied (no duplicates), CV gaps → suggestions → improve or continue; **2e Save for later**: Save → Saved Internships → open → Apply (unsave + Undo, empty list, save error + Retry) |
| **3. Track Application** | Applications → Application Detail → status | No applications, list/detail load errors, withdraw + Undo |

Details: [`user-flow.md`](docs/lab2-handoff/ux/user-flow.md) · screen content and states: [`screen-spec.md`](docs/lab2-handoff/design/screen-spec.md).

### Screens

Bottom navigation (fixed): **Home · Search · Saved · Applications · Profile**.

| Lab 2 screens | Lab 3 additions (not designed in Lab 2) |
|---|---|
| Home, Search, Search Results, Internship Detail, Saved Internships, Application Form, Application Review, Application Success, My Applications, Application Detail, Profile | CV Match Check (Apply step, DC-09), Login (Google Sign-In), Notification Center, PDF report export, Remote Config display, Crashlytics test controls (see [handoff gaps](docs/handoff-gaps.md)) |

### Tech stack

| Concern | Choice |
|---|---|
| Framework | Flutter 3.47 / Dart 3.13, Material 3 |
| Architecture | MVVM (View → ViewModel → Service) |
| State management and DI | Riverpod 3 (`flutter_riverpod`) |
| Navigation | `go_router` (stateful shell for the 5 tabs, auth redirect) |
| Backend | Firebase: Auth (Google Sign-In), Cloud Firestore, Analytics, Crashlytics, Remote Config; FCM planned |
| Design | Inter (bundled), Material Symbols Rounded (`material_symbols_icons`), tokens from Lab 2 `DESIGN.md` |
| Platforms | Android (min SDK 24) and iOS (15.0, CocoaPods) |

## Repository structure

```
lib/
  app/            bootstrap, app, router (auth guard), bottom-nav shell
  theme/          design tokens → ThemeData
  core/           errors, utils (FirestoreReader, Validators), shared widgets (Figma components)
  models/         shared domain models
  services/       Auth, Analytics, Crashlytics, Remote Config (+ Riverpod providers)
  features/       auth, home, internships (search), saved, applications, profile
firebase/         firestore.rules, firestore.indexes.json
test/             unit, ViewModel, widget and routing tests
mobai_tests/      the 10 end-to-end scenarios
docs/             architecture, design system, setup, plans, logs, Lab 2 snapshot
assets/fonts/     Inter (OFL)
```

More: [`docs/architecture.md`](docs/architecture.md) · coding rules for contributors and AI agents: [`AGENTS.md`](AGENTS.md).

## Getting started

### Prerequisites

- Flutter **3.47+** (stable) with Dart 3.13+. Check with `flutter doctor`.
- **Android:** Android SDK with `cmdline-tools`, platform 36, JDK 17, and an emulator or device.
- **iOS (macOS only):** Xcode and CocoaPods.
- For Firebase: Node.js LTS, `firebase-tools`, `flutterfire_cli` (see setup).

### Install

```bash
git clone <repo-url> && cd <repo>
flutter pub get
```

### Configure Firebase (required to get past the setup screen)

The repo ships **without** Firebase config. Follow [`docs/firebase-setup.md`](docs/firebase-setup.md):

1. Create a Firebase project and run `flutterfire configure` (Android `com.group3.internly`, iOS `com.group3.internly`).
2. **Google Sign-In:** enable the Google provider, add each developer's **SHA-1 and SHA-256** (Android), and add the `REVERSED_CLIENT_ID` URL scheme (iOS).
3. Create Firestore and deploy rules: `firebase deploy --only firestore:rules,firestore:indexes`.
4. Enable Crashlytics; create the Remote Config parameters.
5. Storage for CV and PDF uploads (Cloudinary or another provider) is an open decision: [`firebase-setup.md` §10](docs/firebase-setup.md#10-file-storage-cv-upload-pdf-report), [G-12](docs/handoff-gaps.md#g-12-file-storage-and-privacy).

Without configuration the app starts on "Firebase is not configured". That is intended: it never fakes a connection.

### Run

```bash
flutter devices                 # list emulators / devices
flutter run -d <android-device-id>
flutter run -d <ios-simulator-id>
flutter build apk --debug       # Android build
flutter build ios --simulator   # iOS simulator build (uses CocoaPods)
```

### Test and quality gate

```bash
dart format lib test            # format
flutter analyze                 # must report "No issues found!"
flutter test                    # unit, ViewModel, widget and routing tests
flutter test --coverage         # optional coverage report in coverage/
```

End-to-end scenarios: [`mobai_tests/README.md`](mobai_tests/README.md). Latest results: [`docs/test-report.md`](docs/test-report.md).

## Feature ownership

Shared code (`theme/`, `core/`, `app/`, `services/`) is in place. Each feature owner builds their screens on top of it, on a feature branch, through a pull request:

| Feature | Screens | Folder |
|---|---|---|
| Home | Home | `features/home/` |
| Search | Search, Search Results, Internship Detail | `features/internships/` |
| Saved | Saved Internships | `features/saved/` |
| Apply | Application Form, CV Match Check, Review, Success | `features/applications/` |
| Track | My Applications, Application Detail | `features/applications/` |
| Profile | Profile, Remote Config display, diagnostics | `features/profile/` |
| Auth | Login (final design) | `features/auth/` |
| Notifications | Notification Center, FCM | `features/notifications/` |
| Report | PDF export and upload | `features/report_export/` |

## Documentation

| Document | Purpose |
|---|---|
| [`AGENTS.md`](AGENTS.md) | Coding conventions and rules (people and AI agents) |
| [`docs/architecture.md`](docs/architecture.md) | Layers, DI, navigation, data ownership |
| [`docs/lab2-handoff/design/design-system.md`](docs/lab2-handoff/design/design-system.md) | Tokens and components, Figma ↔ code cross-check, contrast results |
| [`docs/firebase-setup.md`](docs/firebase-setup.md) | Firebase, Google Sign-In, Firestore, FCM, storage setup |
| [`docs/handoff-gaps.md`](docs/handoff-gaps.md) | Missing / conflicting requirements and open decisions |
| [`docs/design-change-log.md`](docs/design-change-log.md) | Every UI deviation from Lab 2 and why |
| [`docs/analytics-plan.md`](docs/analytics-plan.md) | Analytics events and privacy rules |
| [`docs/fidelity-check.md`](docs/fidelity-check.md) | Screen-by-screen comparison with Figma |
| [`docs/test-report.md`](docs/test-report.md) | Test runs and results |
| [`docs/code-review.md`](docs/code-review.md) | AI-assisted code review log |
| [`docs/implementation-ai-log.md`](docs/implementation-ai-log.md) | Prompts, outputs, verification and decisions |
| [`docs/lab2-handoff/`](docs/lab2-handoff/README.md) | Read-only snapshot of the Lab 2 design |

## Known limitations

- Feature screens are placeholders; the Login screen is an interim design (DC-01).
- Firebase is not configured in the repository; Google Sign-In needs per-developer SHA fingerprints.
- The Android build was not verified on the machine that initialized the repo (incomplete Android SDK); see [`test-report.md`](docs/test-report.md).
- iOS uses CocoaPods because Swift Package Manager cannot resolve Firebase iOS SDK 13 together with GoogleSignIn-iOS 9 ([G-20](docs/handoff-gaps.md#g-20-ios-dependency-resolution)).
- Open product decisions (main CRUD entity, storage provider, notifications source, Remote Config parameters) are tracked in [`handoff-gaps.md`](docs/handoff-gaps.md).
- Firestore rules only cover the shared foundation; each feature adds validated rules for its collections.
