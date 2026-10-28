# Test report

Records every test run that a pull request or milestone relies on. Paste real output summaries only; a run that was not executed is recorded as **Not run** with the reason.

## Run 1: initialization (2026-10-21)

**Environment:** macOS 26.5.1 (arm64) · Flutter 3.47.3 stable · Dart 3.13.3 · Xcode 26.5 · CocoaPods 1.16.2 · JDK 26.0.1 · Android SDK incomplete (platform-tools only, no cmdline-tools / platforms). Commit: initialization branch (`main`).

| # | Command | Result |
|---|---|---|
| 1 | `dart format lib test` | Completed; files formatted |
| 2 | `flutter analyze` | **No issues found!** (strict casts / inference / raw types, extra lint rules from `analysis_options.yaml`) |
| 3 | `flutter test` | **65 tests, all passed** (`All tests passed!`) |
| 4 | `flutter build ios --simulator --debug` with Swift Package Manager | **Failed**: `Could not resolve package dependencies`: firebase-ios-sdk 13.0.0 needs gtm-session-fetcher 4.0.0..<6.0.0, GoogleSignIn-iOS 9.x needs 3.3.0..<4.0.0 (G-20) |
| 5 | `flutter build ios --simulator --debug` with CocoaPods (SPM disabled in `pubspec.yaml`) | **Passed**: `pod install` 228.7 s, Xcode build 330.6 s, `✓ Built build/ios/iphonesimulator/Runner.app`. Pods: Firebase 12.19.0, GoogleSignIn 9.2.0, GTMSessionFetcher 3.5.0 |
| 6 | `flutter build apk --debug` | **Not run**: Android toolchain incomplete on this machine (`flutter doctor`: "cmdline-tools component is missing"). Run it on a machine with a full Android SDK. |
| 7 | App launch on device / simulator | **Not run**: Firebase is not configured (placeholder `firebase_options.dart`), so the app would show the setup screen by design |
| 8 | Firestore rules (emulator) | **Not run**: Firebase CLI not installed. The foundation rules only contain shared ownership rules; collection rules and their tests ship with each feature |
| 9 | End-to-end | **Not run**: feature screens not built yet (later replaced by ARTEMIS, see Run 2) |

### What the 65 tests cover

| File | Focus |
|---|---|
| `test/theme/app_theme_test.dart` | Color, typography and elevation tokens = DESIGN.md / Figma; 48 dp buttons, radius 12; disabled, pressed and secondary button styles; cards; bottom-navigation colors |
| `test/core/utils/firestore_reader_test.dart` | Required / optional fields, wrong types, `Timestamp` / `DateTime` / millis / ISO dates, pending server timestamps, enum rejection, nested maps, error messages with document path |
| `test/core/utils/validators_test.dart` | `Validators`; analytics event-name rules (length, characters, reserved prefixes) |
| `test/core/widgets/app_button_test.dart` | Taps, 48 dp targets (`androidTapTargetGuideline`), loading (blocks taps, spinner, default look, semantics label), disabled, full width |
| `test/core/widgets/state_view_test.dart` | Labeled loading; empty and error states at **360 and 412 dp**: 24 dp icon, one primary full-width action, Retry callback, no overflow |
| `test/core/widgets/components_test.dart` | Text Field (label above, error icon + message, ≥ 48 dp); Search Field (clear / filter actions, tap targets, no overflow); Internship Card (360 / 412 dp, saved state, 48 dp save target, tap vs save); Status Badge; App Bar main / back; Dialog result values; Skeleton |
| `test/features/auth/auth_viewmodels_test.dart` | Login: idle → loading → idle, `login` event, double-tap guard, cancelled picker is not an error, network error message. Sign-out: `logout` event, failure state |
| `test/app/router_test.dart` | `authRedirect` for loading / signed-out / error / signed-in; full app: Login → Google sign-in → Home; five tabs with icon + label at 360 and 412 dp; tab switching logs `screen_view`; sign-out returns to Login |

Layout tests load the bundled Inter font (`test/flutter_test_config.dart`), so widths at 360 / 412 dp are measured with real glyph metrics.

### Blockers and follow-ups

- Install the Android SDK command-line tools and platform 36, then run `flutter build apk --debug` (row 6).
- Configure Firebase (`docs/guides/firebase-setup.md`), then do a manual sign-in and sign-out check on Android and iOS (row 7).
- Add the Firestore emulator rules tests with the first feature collection (row 8).

## Run 2: Lab 3 alignment (2026-10-21)

Branch `chore/lab3-spec-alignment`. Same environment as Run 1.

| # | Command | Result |
|---|---|---|
| 1 | `dart format lib test` | Completed |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **79 tests, all passed** (+14: `ViewState`, SerpAPI client incl. key-leak check, Remote Config defaults asset, cancel message, card semantics, `currentUserIdProvider`, Crashlytics `last_screen` key) |
| 4 | `flutter test` × 3 consecutive runs | 79/79 each time. A flaky test was found and fixed first: `FakeAuthService` subscribed to its change stream late and could drop an event; it now subscribes on listen |
| 5 | `python3 -m py_compile e2e_test/*.py` | Passed (syntax only, local Python 3.9) |
| 6 | ARTEMIS suite (`uv run pytest --count 3`) | **Not run**: needs an Android device, Firebase config, and the ARTEMIS host with a model key |

## Run 3: docs reorganization + Cloudinary storage (2026-10-21)

| # | Command | Result |
|---|---|---|
| 1 | `dart format lib test` | Completed |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **84 tests, all passed** (79 + 5 Cloudinary storage tests) |
| 4 | Markdown link and anchor check (script) | 0 problems, except the known `ai/…` links in the verbatim Lab 2 README |

## Run 4: Cloud Storage for Firebase (2026-10-21)

| # | Command | Result |
|---|---|---|
| 1 | `flutter analyze` | **No issues found!** |
| 2 | `flutter test` | **85 tests, all passed** (storage: path in own folder, signed-out rejection, PDF / size checks, file-name sanitizing, error-code mapping) |
| 3 | `flutter build ios --simulator --debug` (CocoaPods) | **Passed**: `pod install` 29.0 s, Xcode build 317.1 s, `✓ Built build/ios/iphonesimulator/Runner.app`; FirebaseStorage 12.19.0 resolved with GoogleSignIn 9.2.0 / GTMSessionFetcher 3.5.0 |
| 4 | Real upload to Cloud Storage | **Not run**: no Firebase project configured on this machine |

## Run 5: Home UI + SerpAPI → Firestore sync (2026-10-22)

Branch: working tree on top of `main` (Home feature slice). Environment: macOS (arm64), Flutter 3.47.3, Dart 3.13.3, Node 24.15.0 (functions target Node 22).

| # | Command | Result |
|---|---|---|
| 1 | `dart format lib test` | Completed; files formatted |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **119 tests, all passed** (Home ViewModel + Home screen at 360/412 dp, model `fromFirestore` / on-site parsing, stream-based fakes; removed the obsolete SerpAPI client tests) |
| 4 | `cd functions && npm test` | **5 tests, all passed** (job-key parity, keyword rotation, malformed SerpAPI results) |
| 5 | `npm run build` (functions) | Passed (`tsc`, no errors) |
| 6 | Deploy `functions` + `firestore:rules` | **Not run**: needs the owner's Firebase project and the `SERPAPI_KEY` Secret Manager value |
| 7 | Real SerpAPI sync evidence | **Not run**: see row 6; `sync/state` and console screenshots are required in `evidence/` after deployment |
| 8 | `flutter build apk --debug` | **Not run**: Android toolchain still incomplete on this machine (Run 1 row 6) |

## Run 6: Home roles + SerpAPI keywords (2026-10-22)

Branch: working tree on top of `main`. Environment: macOS (arm64), Flutter 3.47.3, Dart 3.13.3, Node 24.15.0 (functions target Node 22), Firebase project `prm-lab3`.

| # | Command | Result |
|---|---|---|
| 1 | `dart format lib test functions/src` | Completed; no further diffs |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **124 tests, all passed** (role classifier, role filtering, non-IT exclusion, Home chips at 360/412 dp) |
| 4 | `cd functions && npm test` | **7 tests, all passed** (keyword rotation, optional location in the search URL, malformed results) |
| 5 | `npm run build` (functions) | Passed (`tsc`, no errors) |
| 6 | `firebase deploy --only functions --project prm-lab3 --force` | **Passed**: `syncInternshipsJob` updated |
| 7 | Scheduler run + `sync/state` | **Passed**: 5 keywords (`IT internship Vietnam`, `thực tập IT`, `thực tập backend`, `thực tập data`, `thực tập tester`), `fetched=40`, `written=40`, `backfill=true`, no `lastError` |
| 8 | `flutter build apk --debug` | **Not run**: Android toolchain still incomplete on this machine (Run 1 row 6) |
| 9 | Rebuilt app screenshot of role chips | **Passed**: after hot restart, the iOS simulator shows `Browse by Role`, role chips and a `Frontend Developer Intern` card; saved as `evidence/screens/home-roles-actions-20261022.png` |
| 10 | ARTEMIS suite | **Not run**: no Android device/emulator and no ARTEMIS daemon; see Run 7 row 5 |

## Run 7: Transparent Home actions + E2E case (2026-10-22)

Branch: working tree on top of `main`. Environment: macOS (arm64), Flutter 3.47.3, Dart 3.13.3, iPhone 17 Pro simulator (iOS 26.5), Firebase project `prm-lab3`.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | Completed; 74 files checked, 0 changed |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **125 tests, all passed** (adds: text button background is transparent in default and disabled states) |
| 4 | Hot reload + simulator screenshot | **Passed**: `All roles` / `View all` have no white pill; sampled background is RGB `248,250,252`; saved as `evidence/screens/home-actions-transparent-20261022.png` |
| 5 | ARTEMIS TC-16 (`test_home_roles.py`) | **Not run**: `adb devices` is empty and `http://127.0.0.1:8000/health` refuses connection; evidence in `evidence/artemis/e2e-environment-20261022.md` |
| 6 | `flutter build apk --debug` | **Not run**: Android toolchain still incomplete on this machine (Run 1 row 6) |

## Run 8: Profile feature (2026-10-28)

Branch `feat/profile-ui`, on top of `main` `2621e10`. Environment: macOS 26.5 (arm64), Flutter 3.47.3, Dart 3.13.3. Final state of the branch; the session's intermediate runs are summarised in the notes below the table.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib/features lib/services lib/models lib/core test` | 0 changed (`lib/app/bootstrap.dart` on `main` lacks a final newline and is left untouched in this PR) |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **198 tests, all passed** (125 on `main`, +73). Covers `UserProfile` parsing (valid, missing optional, wrong types, malformed CV, `TargetRole` storage values, round trip), `formatShortDate` / `formatFileSize`, `Validators.phone`, `AppTextField` options and `AppTag` sizes; every Profile ViewModel (load, live update, error + Retry, sign-out scoping, validation, save, failure, repeated tap, picker years, location prefilled from the current city, CV 10 MB pre-check, progress, upload and picker failures, open CV); Profile, the three sheets, the Academic standing picker (graduation years scroll to the stored year) and Edit profile at 360 and 412 dp (sections, states, 44 dp tags and chips, 36 dp Quick select without a check, tap targets ≥ 48 dp, discard dialog); router (Sign out from Settings & support, `/profile/edit` without bottom navigation) |
| 4 | `flutter test` × 3 consecutive runs | 186/186 each time at the first complete version; later runs green after every change |
| 5 | `flutter build ios --simulator --debug` | **Passed**: `pod install` 17.4 s (adds `file_selector_ios`, `url_launcher_ios` to `ios/Podfile.lock`), Xcode build 288.0 s |
| 6 | `flutter build apk --debug` | **Not run**: Android SDK not installed on this machine (Run 1 row 6) |
| 7 | DebugView for `profile_update`, `cv_upload` | **Not run**: needs a device with Analytics debug mode |
| 8 | ARTEMIS TC-17 (`test_profile_skills.py`), TC-14 (updated steps) | **Not run**: no Android device/emulator and no ARTEMIS daemon |

Notes from the intermediate runs: two test failures were found and fixed during the session. (a) Outlined chips measured 46 dp instead of 44 dp, because Material adds the 1 dp outline to the height, so the padding now subtracts it. (b) A widget render at 360 dp cut `Year 3 · Graduating 2026`, so the academic field now wraps and has no dropdown chevron.

## Run 9: Profile on the iOS simulator with Firebase (2026-10-28)

iPhone 17 Pro simulator (iOS 26.5), `flutter run --dart-define-from-file=.env`, Firebase project `prm-lab3`, the student's own Google account. Screens were opened through the Dart VM service (`GoRouter.go`, `showProfileSheet`) because this machine cannot click in the Simulator; the student also used the app by hand.

| # | Scenario | Result |
|---|---|---|
| 1 | Profile with no `users/{uid}` document | **Passed**: name, avatar and email from Google; hints for university, CV, skills and preferences |
| 2 | Sheets and Edit profile after matching the frames | **Passed by eye**: Edit skills, Update preferences, Academic standing and Edit profile match their frames (DC-14, DC-16 list the differences); stored `targetRoles: [frontend]` reads as `Frontend Intern`. Evidence: `evidence/screens/profile-edit-skills-sheet-matched-20261028.png`, `…/profile-update-preferences-sheet-matched-20261028.png`, `…/profile-academic-standing-sheet-20261028.png` (cropped so no account data shows; Profile and Edit profile screenshots contain the account's name, email and phone and are not stored) |
| 3 | Save Edit profile, skills and preferences by hand | **Passed (data)**: a server read (`GetOptions(source: Source.server)`) returned the saved values with `updatedAt`; no pending writes in the cache |
| 4 | Preferences sheet after `Save preferences` | **Failed once (reported by the student)**: the button kept spinning although the data was already on the server. Not reproduced: two repeats with timing breadcrumbs acknowledged in **890 ms** and **742 ms** and closed the sheet |
| 5 | Upload a real CV PDF; save the new Edit profile fields | **Not run** |

Follow-up for row 4: the form waits for the server acknowledgement of the Firestore write, so a slow connection keeps the button spinning. `FirestoreUserProfileService` now leaves a Crashlytics breadcrumb per save (`profile: saving …` / `saved … in N ms`, no profile values). Proposed fix, pending a team decision: stop waiting after a timeout and say the change is saved on the phone and will sync.

## Run 10: Home allowance from the description (2026-10-28)

Branch `feat/home-allowance` on top of `dev` `2621e10` (numbered after the Profile PR's Runs 8–9). Same environment as Run 8.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib/core lib/models test` | 0 changed |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **159 tests, all passed** (125 on `dev`, +34): `allowanceFromText` on 29 sentences copied from real listings plus two rules (an amount beats "negotiable"; `formatAllowance` keeps the result) (amounts, ranges, `triệu` / `tr` / `M` / `K` / `million`, currency stuck to the number, `Up to` / `From` / `About`, monthly or not, USD, negotiable, and the rejected cases: "Lương tháng 13", "13th-month salary", "100% salary", meal / lunch / home-office allowances, post-hire salary); `Internship.fromSerpApi` falls back to the description and keeps Google's salary when present |
| 4 | Parser over the real pool (322 listings, via the Dart VM service on the simulator) | Before: 0 listings with pay. After: **73 amounts, 70 negotiable, 179 not disclosed**. A first pass found four misreadings (a "VND" suffix stuck to the number made the parser take the home-office allowance, a meal allowance, a missing `Up to` / `From`, and `7 -> 10 triệu` read as 10 M); all were fixed and added as tests, then every amount was checked against its listing text |
| 5 | Home on the iPhone 17 Pro simulator | **Passed by eye**: cards show e.g. `From 5,000,000 VND / mo` and `3,000,000 VND / mo`, others `Not disclosed`. Evidence: `evidence/screens/home-allowance-recommended-20261028.png`, `evidence/screens/home-allowance-recent-20261028.png` |

## Run 11: Recommended for you by preferred location (2026-10-28)

Branch `feat/home-recommend-location` on top of `feat/profile-ui` (PR #2), numbered after Run 10 (PR #3). Same environment as Run 8.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib/core lib/features test` | 0 changed |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **208 tests, all passed** (198 on `feat/profile-ui`, +10): `foldText`; `matchesPreferredLocation` with the pool's real spellings (HCM, Hà Nội, Đà Nẵng, "Việt Nam" only, none, "All Vietnam", typed places, whole words); `HomeViewModel` keeps the preferred city in Recommended and every listing in Recently Posted, "All Vietnam" / no preference unfiltered, re-filters when the location changes without a new subscription, unfiltered when the profile fails to load. Home tests now override `currentUserIdProvider` and `UserProfileService` |
| 4 | Real pool on the simulator (location = Ho Chi Minh City) | **Passed**: the 5 Recommended cards are all in Hồ Chí Minh; Recently Posted still shows 10 listings from every city. Pool spellings checked first: 99 "Việt Nam", 94 "Hà Nội", 89 HCM ("Thành phố Hồ Chí Minh, Hồ Chí Minh" / "Hồ Chí Minh"), 22 Đà Nẵng. Evidence: `evidence/screens/home-recommended-preferred-location-20261028.png` |

---

## Run template

```markdown
## Run N: <PR / milestone> (<date>)

Environment: <OS, Flutter, device / emulator, commit>

| # | Command / scenario | Result |
|---|---|---|
| 1 | flutter analyze | |
| 2 | flutter test | <passed>/<total> |
| 3 | <build / other check> | |

Failures and follow-ups: <links to issues / commits>
```
