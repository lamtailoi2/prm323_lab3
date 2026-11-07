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

Built on `feat/profile-ui` (PR #2), then added to PR #3: `feat/home-allowance` merged `dev` (with PR #2) and took these commits. Same environment as Run 8.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib/core lib/features test` | 0 changed |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **208 tests, all passed** (198 on `feat/profile-ui`, +10): `foldText`; `matchesPreferredLocation` with the pool's real spellings (HCM, Hà Nội, Đà Nẵng, "Việt Nam" only, none, "All Vietnam", typed places, whole words); `HomeViewModel` keeps the preferred city in Recommended and every listing in Recently Posted, "All Vietnam" / no preference unfiltered, re-filters when the location changes without a new subscription, unfiltered when the profile fails to load. Home tests now override `currentUserIdProvider` and `UserProfileService` |
| 4 | Real pool on the simulator (location = Ho Chi Minh City) | **Passed**: the 5 Recommended cards are all in Hồ Chí Minh; Recently Posted still shows 10 listings from every city. Pool spellings checked first: 99 "Việt Nam", 94 "Hà Nội", 89 HCM ("Thành phố Hồ Chí Minh, Hồ Chí Minh" / "Hồ Chí Minh"), 22 Đà Nẵng. Evidence: `evidence/screens/home-recommended-preferred-location-20261028.png` |
| 5 | Combined branch after merging `dev` (PR #3: allowance + preferred location) | `dart format` 0 changed; `flutter analyze` **No issues found!**; `flutter test` **242 tests, all passed**. Merge conflicts were only in the shared docs (test report, AI log, Home row in traceability) and kept both sides |

## Run 12: Recommended ordered by the profile (2026-10-28)

Branch `feat/home-recommend-profile` on top of `dev` `175b999`. Same environment as Run 8.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib/core lib/features lib/models test` | 0 changed (`lib/app/bootstrap.dart` left as on `dev`) |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **252 tests, all passed** (242 on `dev`, +10): `recommendationScore` (targeted role, Full-stack partial, shared skills case-insensitive and capped, empty profile), `TargetRole.jobRoles`, `jobRoleFor` keeps three real non-IT titles out of every role; `HomeViewModel` keeps the sync order without a profile, puts the best match first with ties in sync order, re-ranks when skills change without a new subscription, never removes listings by role, and shows a job synced under two keywords once |
| 4 | Pool check before coding (322 listings) | IT 289; roles: Other IT 97, Full-stack 48, Data/AI 46, Backend 44, Tester 29, Frontend 16, Mobile 7, DevOps 2; work mode known for 1 of 289; 53 listings share ≥ 1 skill with the test profile; **171 duplicates** by title + company |
| 5 | Simulator, profile Hanoi · Frontend Intern · Flutter, Dart, React Native, React, Vue | First run showed the same job three times and "Executive Assistant Intern" as Frontend (fixed: duplicates removed, non-IT words added). Final: five distinct Frontend listings in Hà Nội, the two sharing Vue / React first; Recently Posted 10. Evidence: `evidence/screens/home-recommended-profile-match-20261028.png` |

---

## Run 13: Login from the Login frame (2026-10-28)

Branch `feat/auth-login-ui` on top of `dev` `175b999`. Same environment as Run 8; simulator iPhone 17 Pro (iOS 26.5, 402 dp wide).

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format --output=none --set-exit-if-changed lib test` | 1 file would change: `lib/app/bootstrap.dart` (already unformatted on `dev`, not touched here) |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **250 tests, all passed** (242 on `dev`, +8 in `test/features/auth/login_screen_test.dart`): frame content at 360 and 412 dp (wordmark, headline, pitch, Google button with the "G", photo, legal line on one line, button ≥ 48 dp, `androidTapTargetGuideline`, `labeledTapTargetGuideline`); sign-in calls the service and logs `login:google`; loading shows a spinner instead of the "G", the `Continue with Google, loading` label and ignores a second tap; error message above the button; cancelled picker shown as info; `Terms` / `Privacy` show their coming-soon SnackBars without signing in; 2× text on a 360 × 640 screen scrolls instead of overflowing. The existing router test still signs in through `Continue with Google` |
| 4 | Layout check before the tests (temporary golden renders at 360 × 800, 412 × 915, 360 × 640 with an error; deleted afterwards) | First render wrapped the legal line onto two lines at 360 dp; fixed by giving it the standard 16 dp padding (DC-18). Second render matched the frame at both widths |
| 5 | Simulator, signed out (`flutter run --dart-define-from-file=.env`) | **Passed**: Login matches the frame (photo, scrim, wordmark, white Google button, one-line legal text), light status-bar icons. Evidence: `evidence/auth/auth-login-redesign-20261028.png`, `evidence/screens/login-frame-vs-app-20261028.png` (frame left, app right) |
| 6 | Simulator taps (Google sign-in, cancelled picker, `Terms` / `Privacy`) | **Not run** on the simulator in this run (no tap automation available here); covered by the widget tests in row 3 and by ARTEMIS TC-01 / TC-14, whose labels did not change |
| 7 | Combined branch after merging `dev` (PR #4: Recommended by profile) | `dart format` only `lib/app/bootstrap.dart` (as on `dev`); `flutter analyze` **No issues found!**; `flutter test` **260 tests, all passed** (252 on `dev`, +8). Merge conflicts were only in the shared docs (Home / Login rows in traceability, P-30 / P-31 in the AI log) and kept both sides |

---

## Run 9: Search Results UI & Real Firebase Data (2026-10-28)

Branch: `feat/search-results`. Environment: Windows 11 (win32) · Flutter 3.47.8 stable · Dart 3.13.3.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | Completed; **86 files checked, 0 changed** |
| 2 | `flutter analyze` | **No issues found!** (ran in 1.6 s) |
| 3 | `flutter test` | **170 tests, all passed** (+19 from Run 8: SearchResultsViewModel 11 tests + SearchResultsScreen 8 tests) |
| 4 | `flutter build apk --debug` | **Not run**: Android toolchain still missing cmdline-tools on this machine (Run 1 row 6) |

### What the +17 tests cover

| File | Focus |
|---|---|
| `test/features/internships/search_results_viewmodel_test.dart` | SearchResultsViewModel: live Firestore pool querying, query filtering across titles and skills, work arrangement filtering, combined filters, clearing filters, sorting (most recent / best match), empty and error states with retry, save/unsave toggle |
| `test/features/internships/search_results_screen_test.dart` | SearchResultsScreen at 360 and 412 dp: search bar with filter count badge, active filter chips (`✓ Remote ✕`, `✓ Flutter ✕`, `Clear filters`), dynamic result count header with green indicator, sort options, `InternshipCard` display with real data, footer notice, removing chips, clearing filters, bookmark toggle, touch targets ≥ 48 dp |

---

## Run 14: Saved empty state opens Search (2026-11-02)

Branch `fix/saved-empty-search` on top of `dev` `55ad128`. Environment: macOS 26.5.1 · Flutter 3.47.3 stable · Dart 3.13.3.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `flutter analyze` / `flutter test` on `dev` `55ad128`, before any change | **8 errors, 3 warnings**; `test/features/saved`, `test/features/home` and `test/features/internships` fail to compile: the merge `b025509` dropped the `saved_internship_service.dart` import and the `FakeSavedService` class from `test/helpers/fakes.dart` |
| 2 | `dart format lib test` | 1 file changed: `lib/core/widgets/main_tab_app_bar.dart`, already unformatted on `dev` and reverted (not part of this change) |
| 3 | `flutter analyze` | **No issues found!** |
| 4 | `flutter test` | **351 tests, all passed**, including the new `empty state Search internships opens Search (Flow 2e.2)` case in `test/features/saved/saved_screen_test.dart` |
| 5 | Device check of the empty Saved tab → Search | **Not run** (no signed-in device session in this run); covered by the widget test in row 4 |

---

## Run 15: Internship Detail (2026-11-02)

Branch `feat/internship-detail` (from `origin/dev` at `7f7a1dd`, fast-forwarded to `3c2c313` after Search and My Applications landed), uncommitted working tree. Environment: macOS 26.7.1 (arm64, MacBook Air M1 8 GB) · Flutter 3.47.6 / Dart 3.13.5 · JDK 21 · Android SDK 36 (command-line tools) · emulator `Pixel_API_36` (Android 16, Google Play image).

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | Completed; 129 files, last run 1 changed (test formatting) |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **339 tests, all passed**; after the no-skills card fix (P-35) **342 passed**. New: `skill_match_test.dart` (4), `internship_test.dart` detail fields (3), `internship_detail_viewmodel_test.dart` (11: loading → data + match, `view_internship` once with its parameters, unavailable, saved-copy fallback, deleted while open, error + retry, retry ignored while loading, `cv_match_enabled` live, Profile skill changes, no known skill, profile load error), `internship_detail_screen_test.dart` (12 at 360 / 412 dp incl. `androidTapTargetGuideline`, `Not disclosed`, skeleton, unavailable + Back, error + Retry, Save → `Saved to your list` → `View saved`, failed save + Retry, `Apply now` message, Show more / Show all, card hidden by Remote Config, bell), `saved_viewmodel_test.dart` `toggleAndReport` (4), `router_test.dart` Home card → Detail above the shell → Back (1) |
| 4 | `flutter build apk --debug --dart-define-from-file=.env` | **✓ Built** in 216 s; `apksigner` signer SHA-1 `ced3b710…2ef0` = the SHA-1 registered for `com.group3.internly` in Firebase `prm-lab3` |
| 5 | Install + launch on `Pixel_API_36` | **Passed**: the app starts on Login and `Continue with Google` opens Google's account chooser (Firebase + team key work). The `.env` had two `DEBUG_KEYSTORE_BASE64` lines; the first was not a keystore with password `android` and is now commented out so Gradle uses the matching key |
| 6 | On device: Home card → Internship Detail, scroll | **Passed** after the developer signed in on the emulator (screen recording 2026-11-02 12:30): Home card opens Detail with real Firestore data; the stretch seen at the top / bottom edge is Android 12+ stretch overscroll (same on Home and Profile), not a layout bug. The recording showed `0% skill match` / `Low match` for a profile without skills, fixed in P-35 |
| 7 | DebugView: `view_internship`, `internship_save(source=detail)` | **`view_internship` passed** (2026-11-02 16:38–16:41): 4 events with `internship_id`, `internship_title`, `company_name` and `source` = `home` / `saved` / `search` — `evidence/analytics/analytics-view-internship-source-20261102.png`, `…-company-20261102.png`. `internship_save(source=detail)` fired (Save → `Saved to your list`) but its DebugView row could not be captured: the Top events list does not scroll in the small browser window; to redo on a larger screen |
| 8 | ARTEMIS TC-05 (Flow 1 → detail) | **Not run**: no ARTEMIS daemon on this machine yet |
| 9 | After updating to `dev` `3c2c313` (Search Results, My Applications) + Search Results card → Detail + Applied state | `flutter analyze` **No issues found!**; `flutter test` **426 tests, all passed** (+3 ViewModel and +2 screen cases for the Applied state at 360 / 412 dp) |
| 10 | On device (Pixel_API_36, 412 dp and 360 dp via `wm size 945x2100`, then `wm size reset`) | **Passed**: Home card → Detail; Save → `Saved to your list` → `View saved` → Saved tab → Detail shows `Saved` → unsave → Saved list empty again; Search `intern` (120 results) → card → Detail (Techcombank logo from the network) → Back keeps the query and the 120 results; no overflow at 360 dp. Screenshots: `evidence/screens/internship-detail-frame-vs-app-20261102.png`, `…-save-20261102.png`, `…-from-search-20261102.png`, `…-360-20261102.png`. Applied banner **not run** (no application documents exist yet). Finding: some descriptions show raw Markdown (`## Job Purpose`) from Google Jobs; to clean up in a follow-up |
| 11 | Markdown cleanup (`core/utils/listing_text.dart`, P-38) | `flutter analyze` **No issues found!**; `flutter test` **433 passed** (+6 `listing_text_test.dart`, +1 model case). On device: the Techcombank listing now reads `Job Purpose` and `• Thực tập sinh (TTS) …` instead of `## Job Purpose` / `- …`; with a Profile skill the card shows `14% skill match` / `Low match` and a checked `TypeScript` tag |

---

## Run 16: Search Field on one line (2026-11-02)

Branch `fix/search-field-one-line` from `origin/dev` `3c2c313`. Environment: macOS 26.7.1 (arm64) · Flutter 3.47.6 / Dart 3.13.5.

| # | Command / scenario | Result |
|---|---|---|
| 1 | Hint width measured inside `AppSearchField` with the filter action (temporary widget test, deleted) | Hint area **224 dp** at 360 dp, **276 dp** at 412 dp; `Search internships, companies, or skills` = 319.5 dp (wraps at both), `Search role, company, skill` = 215.9 dp (fits both) |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **385 tests, all passed**; the old "long placeholder wraps" case is replaced by "default placeholder stays on one line" at 360 / 412 dp (`maxLines == 1`, not exceeded) and a `wrapHint` case (two lines, no overflow) |
| 4 | On device (Pixel_API_36, 412 dp and 360 dp via `wm size 945x2100`) | **Passed**: `Search role, company, skill` on one line at both widths — `evidence/screens/search-field-one-line-20261102.png` (before / after). Seen, not changed here: the `Applications` bottom-navigation label still wraps at 360 dp |
| 5 | Filter sheet from Search, location matching, single drag handle (P-39) | `flutter analyze` **No issues found!**; `flutter test` **391 passed** (Search: filter icon opens the sheet, `Show 3 → 1 results`, starts from the selected work mode and query and records the query; Search Results applies `initialCriteria`; `SearchViewModel.countMatching`; `search_filter_criteria_test.dart` for Vietnamese / English city spellings) |
| 6 | On device (Pixel_API_36, 412 dp) | **Passed**: Search filter icon → Filter sheet (one handle) `Show 195 results`; Skills `Flutter` → `Show 4 results` → Search Results with the `Flutter` chip; Location `Ho Chi Minh City` 50, `Da Nang` 6, `Ha Noi` 42 (before the fix these matched only English spellings) → results all in `Hà Nội`. Evidence: `evidence/screens/search-filter-sheet-20261102.png`, `search-filter-location-20261102.png`. Seen, not changed: Search Results shows the same job twice when it was synced under two keywords (Home de-duplicates, Search Results does not); `search_filter_apply` (analytics row 5) is still not logged |

---

## Run 17: Search analytics and distinct results (2026-11-02)

Branch `fix/search-analytics` from `origin/dev` `a2d9b85`. Environment: macOS 26.7.1 (arm64) · Flutter 3.47.6 / Dart 3.13.5.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `flutter analyze` | **No issues found!** |
| 2 | `flutter test` | **451 tests, all passed** (+10): `distinct_listings_test.dart` (best rank kept, accents and case folded, newest copy without rank); Search Results lists a job synced under two keywords once and `countMatching` agrees; `search` logged once with term, distinct count and `source = search`, also when the pool arrives after navigation (a new snapshot does not log again); blank search, sorting, removing chips and Clear filters log nothing; `search_filter_apply` from the Search Results sheet (`work_mode = on_site,remote`, `source = search_results`) and from the Search tab (`any` / `any`, `source = search`); Search trending and filter preview count a duplicated job once; Home `search` carries `source = home` |
| 3 | On device (Pixel_API_36, 412 dp): Search tab → `Developer` → Search Results | **Passed**: `8 internships found`, 8 different title / company pairs read from the accessibility tree while scrolling (no repeated job). Evidence: `evidence/screens/search-results-distinct-20261102.png` (left) |
| 4 | On device: Search Results field `Intern` → submit | **Passed**: logcat `search` with `search_term=Intern`, `result_count=53`, `source=search`; DebugView shows the event with `result_count 53` and `source search` |
| 5 | On device: Filter sheet `On-site` + `Java` → `Show 0 results` | **Passed**: empty state `No internships found` + `Clear filters` (TC-04 copy updated to match); logcat and DebugView `search_filter_apply` with `work_mode=on_site`, `location=any`, `skill_count=1`, `result_count=0`, `source=search_results`. Evidence: `evidence/analytics/analytics-search-events-20261102.png` (DebugView, one parameter open at a time), `analytics-search-logcat-20261102.txt` (all parameters), `evidence/screens/search-results-distinct-20261102.png` (right) |
| 6 | Not checked | DebugView row for `search_term` (the panel shows two rows in the small browser window; the value is in the logcat file); `search_filter_apply` with `source=search` on device (covered by the ViewModel test only) |

---

## Run 18: Apply Form, Flow 1 pre-submit (2026-11-02)

Branch `feat/apply-pre-submit` from `origin/dev` `9ab527c`. Environment: macOS 26.7.1 (arm64) · Flutter 3.47.6 / Dart 3.13.5.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `flutter analyze` | **No issues found!** |
| 2 | `flutter test` | **475 tests, all passed** (+24): `apply_form_viewmodel_test.dart` (13: `apply_start` once with `internship_id` and the Detail tab; listing + Profile CV selected; unavailable listing; load error + Retry; Continue without a CV flags it; Continue hands over the CV; upload progress then a CV for this internship only, Profile not written, `cv_upload` `source=apply_form`; failed upload keeps the file and Retry sends it again; file over 10 MB rejected without Retry; closed picker; `Use CV from Profile`; taps ignored while uploading; Preview opens the URL or returns the failure); `apply_form_screen_test.dart` (10: CV from Profile and no-CV states at 360 / 412 dp, uploading disables `Continue to review`, failure with `Retry` / `Use CV from Profile`, `Edit profile` opens Profile, unavailable, load error, 48 dp tap targets); router (Detail → `Apply now` → `home_apply_form` with `apply_start`, Back → Detail); Detail `Apply now` opens the Apply Form instead of the coming-soon message |
| 3 | On device (Pixel_API_36, 412 dp; signed-in account without a Profile CV; test file `Sample_CV.pdf`, 609 B, no personal data) | **Passed**: Home card → Detail → `Apply now` → Apply Form (`home_apply_form`, logcat `apply_start` `source=home`); tip banner; `Continue to review` without a CV → red upload area + `Add a CV to continue…`; `Upload CV` → Android picker (phone storage + Drive) → `Uploading… 0%` with `Continue to review` disabled → `Uploaded for this internship`, logcat `cv_upload` `source=apply_form`; `Continue to review` → `Your CV is ready. The review step is coming soon.`; 360 dp (`wm size 945x2100`) fits; Back → Detail. Evidence: `evidence/screens/apply-form-states-20261102.png`, `apply-form-continue-360-20261102.png`, `evidence/analytics/analytics-apply-logcat-20261102.txt` |
| 4 | On device, offline (`svc wifi/data disable`) → `Replace` → same file | **Bug found and fixed**: the bar stayed at `Uploading… 0%` because Firebase Storage retries uploads for 10 minutes by default (logcat `ExponenentialBackoff: network unavailable, sleeping`). `FileStorageService` now sets `setMaxUploadRetryTime(30 s)` (also used by Profile). After the fix: `CV could not be uploaded` + `We could not upload the file. Check your connection and try again.` + `Retry` after **36 s**; network back → `Retry` → `Uploaded for this internship`, second `cv_upload` |
| 5 | After the fix | `flutter analyze` **No issues found!**; `flutter test` **475 passed** |
| 6 | Summary facts, skill match line and the shared CV sheet (P-42) | `flutter analyze` **No issues found!**; `flutter test` **483 passed** (+8): summary location fallback + `Allowance: …` / `Job type: …`, skill match line with `Missing: … +N more` / `Add skills`, `cv_match_enabled` off hides it; Choose file selects without uploading, `Remove`, upload from the sheet (progress, `For this internship` CV, Profile not written), failure shown in the sheet and `Cancel` drops it, an upload still running after `Cancel` finishes on the form, failure after closing → form `Retry` / `Use CV from Profile`; Profile tests unchanged (55 passed) after `ProfileSheet` → `AppSheet` and `UpdateCvSheet` → `CvUploadSheet` |
| 7 | On device (412 dp; the account now has a Profile CV, uploaded by the user from Profile) | **Passed**: Apply Form shows `Techcombank · Việt Nam`, `Negotiable` / `Not disclosed`, `You have 3 of 11 required skills` · `Missing: SQL, REST API, Java +5 more`, the Profile banner and `From your Profile`; `Replace` opens the same sheet as Profile (`Update CV`, `Use a different CV for this internship`, `Current active CV` · `From your Profile`, `Choose file`, `Update CV`, `Cancel`); picking the test PDF → `Selected for update` + `Remove` → `Update CV` → sheet closes → `Uploaded for this internship`, logcat `cv_upload` `source=apply_form`. Evidence: `evidence/screens/apply-form-cv-sheet-20261102.png` |
| 8 | Banner above the skill line, `Show all skills` / `Show fewer` | `flutter analyze` **No issues found!**; `flutter test` **483 passed** (screen tests: banner above `You have 2 of 6 required skills`; `Show all skills` → `Missing: Java, Kotlin, Swift, SQL` + `You have: Flutter, Dart`; `Show fewer` collapses; without Profile skills → `Skills: Flutter, Dart`) |
| 9 | On device (412 and 360 dp) | **Passed** for the order (banner → skill line → CV) and the `Show all skills` / `Edit skills` buttons at both widths: `evidence/screens/apply-form-banner-skills-20261102.png`. The expanded state was not captured on device (the emulator was in use at the time); it is covered by the widget test |
| 10 | Not checked | DebugView screenshots for `apply_start` / `cv_upload` (logcat only) |

---

## Run 19: Job type filter and Applied badge (2026-11-02)

Branch `fix/job-type-applied-badge` from `origin/dev` `fe286dc`. Environment: macOS 26.7.1 (arm64) · Flutter 3.47.6 / Dart 3.13.5.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `flutter analyze` | **No issues found!** |
| 2 | `flutter test` | **490 tests, all passed** (+7): `search_filter_criteria_test.dart` job type (English and Vietnamese schedule types, combined value, another type, missing type left out, `Any job type`); `Applied` badge on Search Results (card text and Semantics summary), Home and Saved with `appliedInternshipKeysProvider` overridden |
| 3 | On device, first try (Pixel_API_36, `-gpu swiftshader_indirect` after two emulator crashes) | **Failed**: Search › Filters, 83 listings; `Internship`, `Full-time` and `Part-time` each → `Show 0 results` |
| 4 | Firestore console, 28 `/internships` documents (read only) | **Cause found**: no document has `detected_extensions`; `raw.extensions` holds `Toàn thời gian`, `Thực tập`, `Bán thời gian`, `Toàn thời gian và Thực tập` and, in 15 of 28, the posted age (`3 ngày trước`). Fixed in the parser (G-25 #8) |
| 5 | After the parser fix | `flutter analyze` **No issues found!**; `flutter test` **500 passed** (+10: `listing_extensions_test.dart` schedule chips in Vietnamese / English / mixed with age and pay, posted chip, Vietnamese `parsePostedAge`, `formatPostedAgeLong`; model test without `detected_extensions`; Detail `Posted 3 days ago`) |
| 7 | `Saved to your list` SnackBar (Detail) stayed on screen (user report with screenshot) | **Bug fixed**: a SnackBar with an action persists by default in this Flutter version; Detail now sets `persist: false` (design-system: 4 s even with an action; the save-failure SnackBar with `Retry` still stays). New Detail test: hidden after 5 s; it fails without the fix. `flutter test` **501 passed** |
| 6 | On device after the fix | **Passed** for `Internship` → `Show 38 results` of 83, and cards now show a posted age (`… ago`). Evidence: `evidence/screens/search-job-type-filter-20261102.png` (before / after). Not counted on device: `Full-time` / `Part-time` (the emulator was in use), Detail `Posted …` and the `Applied` badge (no application documents until Flow 4 writes them) |

---

## Run 20: Fixes from the AI code review R1 (2026-11-02)

Branch `fix/code-review-r1` from `origin/dev` `4d2aeda`. Environment: macOS 26.7.1 (arm64) · Flutter 3.47.6 / Dart 3.13.5. Findings and decisions: `docs/code-review.md` (CR-01 – CR-20).

| # | Command / scenario | Result |
|---|---|---|
| 1 | Each accepted bug first reproduced by a test that fails on `dev` | CR-01 (`Bad state: Using "ref" … unmounted`), CR-02 (no semantics tap action), CR-03, CR-04 (`Skills: C`), CR-07, CR-08 (0 instead of 1 result), CR-09, CR-10 (navigation never happens), CR-12, CR-15, CR-20 failed before their fix and pass after it |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **525 tests, all passed** (+24 from 501) |
| 4 | On device | **Not run** for these fixes |

---

## Run 21: Apply flow after Pre-submit — Validate CV → Confirm → employer website (2026-11-03)

Environment: Windows 11 · Flutter 3.47.6 / Dart 3.13.5 · no device or Firebase project on this machine. Changes: P-45, DC-27.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | **177 files formatted, 0 changed** after the final edits |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **551 tests, all passed** (+26): `internship_test.dart` apply options / share link (+4); `apply_confirm_viewmodel_test.dart` (+7: open → awaitingReturn, failed redirect + retry, `onReturned` only while waiting, submit writes + `application_create` with `cv_source` and `duration_sec`, failed write + retry, repeated tap writes once, no CV writes nothing); `apply_validate_screen_test.dart` (+8: checking, valid auto-continues, invalid → Retry / Update CV back to the form, failed check, Cancel → Detail, no CV, 360 / 412 dp); `apply_confirm_screen_test.dart` (+7: content, open → resume → record → `/applications`, failed redirect + retry, no employer link + Google Jobs fallback + `Mark as applied`, failed write + Retry, 360 / 412 dp); updated `apply_form_screen_test.dart` (Continue opens Validate CV, `Step 1 of 3`) |
| 4 | Not run | Real browser round trip, Firestore write on a device, DebugView screenshots for `cv_validation_result` / `application_create`, a deployed `validateCv` with a real `GEMINI_API_KEY`, and ARTEMIS E2E (no device / Firebase project / model key here) |

---

## Run 22: SerpAPI fresher/junior keywords + Detail role/level badges (2026-11-07)

Environment: Windows 11 · Flutter 3.47.6 / Dart 3.13.5 · Node 24.6.0 (functions declare Node 22) · no device or Firebase project on this machine. Changes: P-46, DC-28.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `cd functions && npm ci && npm test` | **20 tests, all passed** (+2: `config.test.ts` checks the keyword list contains intern, fresher and junior queries and computes the rotation against the 250-search free plan and the 7-day expiry) |
| 2 | `dart format lib test` | **174 files formatted, 0 changed** |
| 3 | `flutter analyze` | **No issues found!** |
| 4 | `flutter test` | **557 tests, all passed** (+6): `job_level_test.dart` (5: title levels incl. Vietnamese/`TTS`/`new grad`, fresher/junior over internship, senior titles excluded, “international”, no level), Detail screen (+1: level badge hidden when the listing states no level; the assertion reads the semantics label) and `Internship.level` wiring in the model test; role/level badge assertions at 360/412 dp |
| 5 | Deployed `syncInternshipsJob` + manual Cloud Scheduler run (2026-11-07) | **Real backfill passed**: `sync/state` → `backfill=true`, `fetched=65`, `written=65`, `expiredDeleted=0`, all eight keywords, no `lastError`; Firestore shows 10 `IT fresher Vietnam` and 10 `IT junior Vietnam` listings; the Pixel 6 emulator shows the `DevOps/Cloud` + `Intern` badges on Detail. One earlier trigger hit a 20 s SerpAPI timeout and succeeded on retry. Evidence: `evidence/sync/2026-11-07-p46-sync.md` + screenshot |

---

## Run 23: Experience band + ranking tiebreaker (2026-11-07)

Environment: Windows 11 · Flutter 3.47.6 / Dart 3.13.5 · no device or Firebase project on this machine. Changes: P-47, DC-29, DC-30.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | **174 files formatted, 5 changed** before the final run (the edited model, ViewModel, Home and three test files), then 0 changed |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **571 tests, all passed** (+14 over Run 22). Coverage added/updated: `user_profile_test.dart` (parse/store, legacy profile without `experience`, band → level mapping, equality/hashCode by experience); `profile_viewmodels_test.dart` (seeded band, single-select + clear, other fields keep the draft, save with `item_count`, unanswered experience stored null and not counted, failed save keeps the draft); `recommendation_test.dart` (level matrix incl. `null`, experience does not change the score); `home_viewmodel_test.dart` (level match beats sync rank, no experience keeps sync order, level cannot outrank a better role/skill score); `profile_screen_test.dart` (the Update preferences sheet runs at 360 and 412 dp and saves an experience chip; Profile asserts the `1–2 years` tag and four "Not set" groups) |
| 4 | Not run | On-device sheet/tag screenshots, Firestore round trip on a real project, DebugView for the new `profile_update.item_count` (no device / Firebase project here) |

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
