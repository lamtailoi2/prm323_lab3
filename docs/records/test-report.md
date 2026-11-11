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

## Run 21: Work mode from the listing text (2026-11-02)

Branch `dev` on Windows 11. Environment: Flutter 3.47.8 / Dart 3.13.7.

| # | Command / scenario | Result |
|---|---|---|
| 1 | Cause check (code + earlier pool checks) | **Cause found**: `Internship.fromSerpApi` read the work mode only from `title` and `extensions`; `hl=vi` listings have no `detected_extensions` and the chips hold only the schedule and posted age, so work mode was known for **1 of 289** IT listings (Run 12) and a Work mode filter hid all the rest → `Show 0 results` |
| 2 | `dart format lib test` | Completed; 1 file changed |
| 3 | `flutter analyze` | **No issues found!** |
| 4 | `flutter test` | **533 tests, all passed** (+8): `internship_test.dart` work mode from title/chips/location, explicit Vietnamese and English wording in the description, both arrangements → hybrid, "hybrid app" / "remote server" false positives rejected, no wording → `null`; `search_filter_criteria_test.dart` work mode (selected modes, unknown left out, no mode keeps all) |
| 5 | On device | **Not run**: needs the emulator and a signed-in account to measure how many of the current listings state their arrangement |

---

## Run 22: Filter skills from the pool (2026-11-02)

Branch `dev` on Windows 11. Environment: Flutter 3.47.8 / Dart 3.13.7.

| # | Command / scenario | Result |
|---|---|---|
| 1 | Cause check | **Found**: the sheet's Skills chips were a fixed `Flutter / React / NestJS / Java / UI/UX / Data` list, unrelated to CV validation, the Profile or the pool |
| 2 | `dart format lib test` | Completed; 0 changed |
| 3 | `flutter analyze` | **No issues found!** |
| 4 | `flutter test` | **538 tests, all passed** (+5): `skill_suggestions_test.dart` (most common first, `knownSkills` tie, alphabetical tie, empty pool, 6-chip cap); the sheet test now asserts the pool's `Flutter`, `Dart` and `Node.js` chips, that fixed `React` is gone, and that tapping `Flutter` narrows the count |
| 5 | On device | **Not run** |

---

## Run 23: Flow 2 completion — Validate CV, Review, Success (2026-11-03)

Branch `feat/apply-ui`. Environment: Windows 11 × Flutter 3.47.8 / Dart 3.13.7 (no device or emulator attached).

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | formatted (5 files changed on the first run, none after the last edit) |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test test/features/internships/application_review_viewmodel_test.dart test/features/internships/application_review_screen_test.dart` | **15 passed** (ViewModel 8: load, no write before the listing, submit + `application_create` parameters, failed write then retry, signed out, double tap ignored, listing error + Retry, profile error + Retry; screen 7: both widths + 48 dp guideline, submit → success with the recap, failure message, loading state, missing form data, profile error) |
| 4 | `flutter test test/features/internships/application_success_screen_test.dart` | **5 passed** (both widths + 48 dp guideline, no recap, `View my applications`, `Back to home`) |
| 5 | `flutter test` (full suite, after Smart App Control was turned off and `build/unit_test_assets` was rebuilt) | **547 tests, all passed** (+22 from the 525 on `dev`). Before that, the suite showed 9 failures, all `Asset 'shaders/ink_sparkle.frag' not found`, because this machine's Application Control policy blocked `impellerc.exe` (SAC `VerifiedAndReputablePolicyState = 1`); the asset was never built. After turning SAC off the asset is generated and the whole suite is green |
| 6 | `flutter run -d emulator-5554 --dart-define-from-file=.env` (sdk gphone64 x86 64, Android 17 / API 37) | **Built, installed and launched**: `com.group3.internly/.MainActivity` holds the focus. Before SAC was off this same command failed in `:app:compileFlutterBuildDebug` on the blocked `impellerc.exe` |
| 7 | Device logcat while walking the flow | **Bug found and fixed**: opening Validate CV logged Riverpod's *"Tried to modify a provider while the widget tree was building"* — `CvValidationStep.initState` starts `CvValidationViewModel.validate()`, which sets `state`, through `listenManual(..., fireImmediately: true)`; the uid is already known when the step opens from the Apply flow. The check now starts in a post-frame callback; regression test added (it fails without the fix). `flutter analyze` **No issues found!**, `flutter test` **547 passed** after the fix |
| 8 | Complete flow on the device (Apply → Validate CV → Review → Submit → Success → My Applications) | **Not walked end to end yet** |
| 9 | DebugView (`application_create`) | **Not run** |

Environment: Windows 11 × Flutter 3.47.8 / Dart 3.13.7, Android emulator `sdk gphone64 x86 64` (API 37), `--dart-define-from-file=.env`. Notes: the 9 earlier failures were environmental, not related to this change — `test/core/widgets/components_test.dart`, which touches no changed file, failed the same way; turning Smart App Control off (a one-way Windows setting) removed them. E2E TC-06–TC-08 are still to be written.

---

## Run 24: Track evidence — DC-09 deviation, application_update/application_delete (2026-11-05)

Branch `chore/analytics-evidence-artemis` (off `main`, worktree). Environment: Windows 11 × Flutter 3.47.3 / Dart 3.13.3 (no device or emulator attached).

| # | Command | Result |
|---|---|---|
| 1 | `dart format lib test` | formatted (2 files changed: `application_detail_viewmodel.dart`, `application_detail_viewmodel_test.dart`) |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test test/features/applications/application_detail_viewmodel_test.dart` | **10 passed**, including the two new tests for `application_update` / `application_delete` on withdraw, and `application_update` on undo |
| 4 | `flutter test` (full suite) | **585 tests, all passed** (`All tests passed!`) |

Scope: row 5 (DC-09 CV Match Check recorded as a deviation in `design-traceability.md` §4 and `handoff-gaps.md` G-24, no code change) and row 16 (logged `application_update` / `application_delete` on withdraw / undo in `ApplicationDetailViewModel`, per `docs/analytics-plan.md` rows 12-13). DebugView screenshots for these two events, and for rows 14-15 and 20 (auth console), are a separate manual step — not captured in this run; recorded as **Not run** until a device/emulator session is available.

---

## Run 24: Flow 3 Application Detail audit (2026-11-04)

Branch `feat/application-detail` on Windows 11. Environment: Flutter 3.47.8 / Dart 3.13.7 (no device or emulator attached).

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format --output=none --set-exit-if-changed lib test` | **Formatted 186 files (0 changed)** |
| 2 | `flutter analyze` | **No issues found!** (47.5 s) |
| 3 | `flutter test test/features/applications/application_detail_viewmodel_test.dart test/features/applications/application_detail_screen_test.dart test/app/router_test.dart` | **33 passed** (ViewModel 7: load + `view_application` once, empty, error + Retry, withdraw keeps the previous status, Undo window, failed withdraw, double tap; screen 10: both widths with tracker/CV/facts, withdraw dialog → Undo, Cancel, Undo, Preview, error, empty, loading skeleton, no applicant snapshot; router 16) |
| 4 | `flutter test` (full suite) | **583 tests, all passed** |
| 5 | E2E TC-09/TC-10 (`e2e_test/test_applications.py`) | **Not run**: the cases are written, but this machine has no ARTEMIS daemon or toolchain (`evidence/artemis/e2e-environment-20261031.md`) |
| 6 | Device screenshots (`evidence/screens/application-*.png`) | **5 captured** on the Android emulator (1080 × 2400) with the real signed-in test account: `application-list`, `application-detail-submitted`, `application-detail-applicant`, `application-detail-withdraw-dialog`, `application-detail-withdrawn`. `empty`, `rejected`, `error` and `loading` were not captured: the account has one application, there is no UI to set another status, and a network error cannot be produced deterministically |
| 7 | DebugView (`view_application`) | **Not run** |

Notes: the audit found the Flow 3 code already implemented and green; this run covers the documentation/status corrections, the new E2E source and the state screenshots. No product code changed in this run, so the suite count is unchanged from the previous full run on this branch.

---

## Run 25: Flow 3 Application Detail — Figma alignment (2026-11-04)

Branch `feat/application-detail` on Windows 11. Environment: Flutter 3.47.8 / Dart 3.13.7 (no device or emulator attached). Follows Run 24: Option 1 ("Đồng bộ hoàn toàn với Figma") from the P-48 audit, implemented in P-49.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | **189 files, 1 changed** (`applicant_card.dart`, then `application_detail_screen_test.dart` on a second pass) |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test test/models/internship_application_test.dart test/features/applications/ test/app/router_test.dart` | **88 passed** |
| 4 | `flutter test` (full suite) | **593 tests, all passed** |
| 5 | E2E TC-09/TC-10 | **Not run** (same as Run 24: no ARTEMIS daemon/toolchain on this machine) |
| 6 | Device screenshots (`evidence/screens/application-*.png`) | **Not recaptured.** No emulator was run in this session; the 5 screenshots from Run 24 predate this run's UI changes (4-step tracker with progress, destructive withdraw styling, chip facts, new CV tile copy) and no longer match the current build. Recapturing them is open work, not fabricated here |
| 7 | DebugView (`view_application`) | **Not run** |

Code changed in this run (unlike Run 24, which was docs-only): `application_status_tracker.dart`, `application_identity_card.dart`, `applicant_card.dart`, `application_detail_screen.dart`, `internship_application.dart`, `application_service.dart`, `application_review_viewmodel.dart`, `test/helpers/fakes.dart`, plus the four Flow 3 test files. The suite count rose from 583 (Run 24) to 593: +10 net (new tracker/CV/nav/badge/colour/error-message tests, two new `cvSizeBytes` model-parsing assertions, no tests removed).

---

## Run 26: FCM in all app states + Notification Center (2026-11-05)

Branch `dev`, uncommitted working tree. Environment: Windows 11 · Flutter
3.47.8 · Dart 3.13.7 · Android emulator `Medium_Phone_API_37.0`
(Android 17 / API 37, Google Play image, 1080 × 2400) · Firebase project
`prm-lab3` · signed-in test account.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | 202 files checked; formatted (files changed by the edits, 0 after the final pass) |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test test/models/app_notification_test.dart test/core/utils/notification_target_test.dart test/core/utils/display_format_test.dart test/services/notification_message_test.dart test/features/notifications test/features/profile/profile_screen_test.dart` | **44 passed** |
| 4 | `flutter test` (full suite) | **624 tests, all passed** (+30 from 594 on `dev`: notification model, message mapping, target validation, relative time, Notification Center ViewModel + screen, FCM token tile) |
| 5 | `flutter build apk --debug --dart-define-from-file=.env` | **✓ Built** in 73.7 s; FCM plugin and manifest merge compile |
| 6 | Install + launch on `emulator-5554` | **Passed**: Home opens signed in; Android 13+ notification permission dialog shown by the coordinator |
| 7 | Allow the permission | **Passed**: `dumpsys package com.group3.internly` → `POST_NOTIFICATIONS: granted=true` |
| 8 | Profile → Diagnostics → **Copy FCM token** | **Passed**: SnackBar `FCM token copied.` (token obtained from Firebase Messaging on this device) |
| 9 | Bell → Notification Center | **Passed**: screen opens with `No notifications yet` and Back returns to Profile |
| 10 | FCM delivery in foreground / background / terminated + a message in the history | **Not run**: needs test messages sent from the Firebase console and screenshots in `evidence/fcm/`; no message was sent in this session |
| 11 | DebugView (`notification_center_open`) | **Not run** |

Open work: send the console test message in the three states, capture
`evidence/fcm/`, and check the event in DebugView.

---

## Run 27: FCM evidence follow-up (2026-11-06)

Branch `dev`, uncommitted working tree. Environment: Windows 11 · Flutter
3.47.8 · Dart 3.13.7 · Android emulator `Medium_Phone_API_37.0`
(Android 17 / API 37, Google Play image, 1080 × 2400) · Firebase project
`prm-lab3` · signed-in test account. Code changes in this run: the Search tab
now uses `MainTabAppBar` (bell + avatar, per design-system §2.6) and
`NotificationService.tokenRefreshes()` keeps `users/{uid}.fcmToken` current.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `flutter analyze` | **No issues found!** |
| 2 | `flutter test test/app/notification_coordinator_test.dart test/features/notifications test/features/profile/profile_screen_test.dart test/features/internships/search_screen_test.dart` | **58 passed** |
| 3 | `flutter test` (full suite) | **627 tests, all passed** (+3: rotated token stored / ignored when signed out, Search bell opens the Notification Center; the Search header also asserts both actions at 360 and 412 dp) |
| 4 | Console test messages | **Delivered**: foreground (`Internly foreground test`, in-app SnackBar), background and terminated (both shown in the notification shade). Screenshots in `evidence/fcm/` (6 files). |
| 5 | Notification Center after the three states | **Passed**: `notification_center_open` screen lists every received message with read / unread state (6 entries; one terminated entry is `Read`, the rest `Unread`) |
| 6 | Analytics debug mode (`setprop debug.firebase.analytics.app com.group3.internly`, `log.tag.FA`/`FA-SVC` verbose, restart, bell) | **Passed**: `adb logcat -d -s FA:V FA-SVC:V` → `Logging event: ... name=notification_center_open ... unread_count=7` |
| 7 | Tap a notification → destination screen | **Not captured**: the stored entries were sent without a valid `route` payload, so no screenshot shows the destination |
| 8 | DebugView console screenshot | **Not captured**: the event is proven in logcat (row 6); the browser capture is still open |

Open work: send one message per state with a valid `route` (`/saved`,
`/applications`), capture the destination screen after the tap, and save the
DebugView screenshot showing `notification_center_open`.

---

## Run 28: Local admin dashboard (2026-11-06)

Branch `dev`, uncommitted working tree. Environment: Windows 11 · Node 24.22.1
· npm 11.19.1 · Firebase project `prm-lab3` · Android emulator
`Medium_Phone_API_37.0` (API 37, 1080 × 2400) · signed-in test account.
Service-account key stored at `%USERPROFILE%\.internly-admin\service-account.json`
(outside the repository).

| # | Command / scenario | Result |
|---|---|---|
| 1 | `npm test` (dashboard) | **7 passed** (route validation, chunking, required text, timestamps, send summary, message-ID normalisation) |
| 2 | `node --check server.js lib/admin.js public/app.js` | clean |
| 3 | `node server.js` (port 4318 for the check; the developer's 4317 instance kept running) | UI, CSS and `app.js` return **200**; `/api/status` → `project=prm-lab3 ready=True found=True` |
| 4 | `GET /api/users` with the real key | **8 users**; Firebase Auth join returns names and emails; one user has a device token |
| 5 | `POST /api/send` (one user, title `Dashboard test 2`, route `/saved`, history on) | **`requested=1 success=1 failure=0 historyWritten=1`**; the app showed the foreground SnackBar with **View** |
| 6 | Tap **View** on the SnackBar | **Passed**: the app opened the **Saved** tab — screenshot `evidence/fcm/fcm-notification-tap-saved-20261106.png` |
| 7 | `GET /api/notifications?uid=…` | the entry is stored with the FCM message ID, `route=/saved`, `read=false` |
| 8 | `DELETE /api/notifications/:uid/:id` for the two test entries | **2 deleted**, the list went from 10 to 9 (the query is capped at 10) |

Finding and fix in this run: the first send stored no history document — Firebase Admin returns `messageId` as
`projects/prm-lab3/messages/<id>`, and Firestore rejects a document path with an odd number of components.
`normaliseMessageId()` now takes the trailing ID (the value `RemoteMessage.messageId` carries), so the
server-side entry merges with the one the app writes. The send response now reports `historyError` instead of
failing a message that was already delivered.

---

## Run 29: CV Match Check (G-24 / DC-09) — 2026-11-06

Branch `dev`, uncommitted working tree. Environment: Windows 11 · Flutter
3.47.8 · Dart 3.13.7 · Node 24.22.1 · Firebase project `prm-lab3` (Functions
not deployed in this run).

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | 212 files; 0 changed after the edits |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test test/services/cv_match_service_test.dart test/features/applications/cv_match_viewmodel_test.dart test/features/applications/cv_match_step_test.dart test/features/applications/cv_match_screen_test.dart test/features/internships/apply_form_screen_test.dart` | **38 passed** |
| 4 | `flutter test` (full suite) | **649 tests, all passed** (+22: model/service parsing and error mapping, ViewModel success/gaps/all-matched/no-requirements/failure/double-tap/signed-out, step widget states and 360/412 dp, screen route guard + `Continue`, Apply Form flag on/off) |
| 5 | `cd functions && npm test` | **41 tests, all passed** (+23: score/requirement split, commentary parsing and fallback, message-ID-independent match handler cases, skill-vocabulary parity with Dart). The 18 existing `validateCv` tests still pass after the shared-helper refactor |
| 6 | `cd functions && npm run build` | `tsc` passed |
| 7 | Deploy `matchCv` + device walk (Apply → CV Match → Validate CV → Review → Submit) | **Not run**: needs an owner deploy with `GEMINI_API_KEY` and a signed-in emulator session |
| 8 | DebugView (`cv_match_check`) | **Not run** |
| 9 | ARTEMIS TC-06 (`e2e_test/test_apply.py`) | **Written, not run** (no ARTEMIS host on this machine) |

Open work: deploy the function, walk the flow on the emulator with the flag on
and off, capture the gaps / all-matched / error screens, and check
`cv_match_check` in DebugView.

---

## Run 30: CV Match Check on device (Groq commentary) — 2026-11-06

Branch `dev`, uncommitted working tree. Environment: Windows 11 · Node 24.22.1
· Flutter 3.47.8 · Firebase project `prm-lab3` · Android emulator
`Medium_Phone_API_37.0` (API 37, 1080 × 2400) · signed-in test account
`Mai Duy Lập` (has a Profile CV, no Profile skills). `validateCv` stays on
Gemini; the advisory commentary uses Groq with `GROQ_API_KEY`.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `cd functions && npm test` | **45 tests, all passed** (+4 over Run 29: Groq client request/JSON mode, HTTP error without key leak, empty content/blank key, real Firestore shape parsing) |
| 2 | `cd functions && npm run build` | `tsc` passed |
| 3 | `firebase deploy --only functions` | `matchCv`, `validateCv`, `syncInternshipsJob` updated successfully (secret `GROQ_API_KEY` attached to `matchCv`) |
| 4 | Groq model probe (`/openai/v1/models`, JSON-mode request) | `llama-3.3-70b-versatile` → **404** (retired from this project); `openai/gpt-oss-20b` → **200** with valid JSON |
| 5 | Device walk with the vocabulary fallback (before extraction worked) | **Passed**: `50% match`, `1 of 2 requirements matched`; `PostgreSQL` matched, `SQL` a gap |
| 6 | Device walk with model extraction enabled | **Passed**: `17% match`, `Low match`, `1 of 6 requirements matched`; `PostgreSQL` matched; gaps `SQL`, `Data Studio`, `Metabase`, `Power BI`, `Looker Studio` (all named in the JD). Summary: `Your CV shows strong backend and PostgreSQL experience, but lacks explicit evidence of SQL, Data Studio, Metabase, Power BI, and Looker Studio skills.` |
| 7 | `Continue` from CV Match | **Passed**: Validate CV ran on Gemini and continued to **Review application** (`Step 2 of 2`, `Ready to submit`); submission not tapped |
| 8 | Flutter suite | Not re-run: no client file changed. Run 29 remains valid (649 passed) |
| 9 | DebugView (`cv_match_check`) | **Not run** |

Findings and fixes during this run:

1. **Firestore shape.** The sync function stores the raw SerpAPI object under
   `raw` and no parsed `title` / `skills` fields. `matchCv` first read the root,
   so it saw no requirements; it now parses `raw` exactly like
   `Internship.fromFirestore` (title, company, `job_highlights`, description;
   skills via `findKnownSkills`). A unit test covers the real shape.
2. **Groq model retired.** `llama-3.3-70b-versatile` answers 404 on this key;
   the model is now `openai/gpt-oss-20b`. Error logging was improved to keep
   the actual message (`{}` before).
3. **Suggestion truncation.** Long suggestions were cut mid-word at 160 chars;
   `clip()` now cuts at a word boundary and adds a single ellipsis.
4. **Extraction call used the commentary rubric.** The extraction request sent
   the commentary system prompt, so Groq returned a summary and parsing fell
   back. `askExtraction` now uses `SKILL_EXTRACTION_RUBRIC`.
5. **Empty `content` in JSON mode.** `gpt-oss-20b` spent its default completion
   budget on hidden reasoning and returned an empty `content`, so Groq replied
   `400 json_validate_failed`. Fixed with `reasoning_effort: low` and
   `max_completion_tokens: 4096`; verified directly: status 200 with the three
   skill lists.

Evidence: `evidence/screens/cv-match-extraction-20261106.png` (model
extraction), `evidence/screens/cv-match-groq-20261106.png` (vocabulary
fallback), `evidence/screens/cv-match-gaps-20261106.png`.

## Run 31: Search — empty query and the field after Search Results (2026-11-06)

Branch `fix/search-empty-query` from `dev` `1255677`, uncommitted working tree.
Environment: macOS 26.7.1 (Apple M1) · Flutter 3.47.6 stable · Android emulator
`Pixel_API_36`. AI log P-69. Device screenshots show the signed-in account, so
they are not committed (results read from `uiautomator dump`).

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format --output=none --set-exit-if-changed lib test` | 211 files, 0 changed |
| 2 | `flutter analyze` | No issues found! |
| 3 | `flutter test` (full suite) | **654 tests, all passed**; 6 new: `Find Internships` disabled without a query or a work mode, a work mode alone enables it, `syncQuery` keeps the trimmed term and the work mode, later snapshots keep the query, a query cleared on Results is not back on Search (Home → Home's search bar), a new query on Results shows on Search |
| 4 | Negative check: field update in `SearchScreen` switched off | Both new router tests **fail** (`Expected: empty` / `'Dart'`, `Actual: 'inter'`), so they catch the reported bug; code restored afterwards |
| 5 | `flutter build apk --profile --dart-define-from-file=.env` + `adb install -r` on emulator `Pixel_API_36` (API 36, 1080 × 2400), signed-in test account | Built (107.8 MB), installed |
| 6 | Device: Search tab with an empty field | **Passed**: `Find Internships` shown disabled (`enabled=false` in the UI dump); tapping it stays on Search |
| 7 | Device: type `inter` | **Passed**: the button turns blue (enabled); tapping it opens Search Results (`54 internships found`) |
| 8 | Device, reported path: `Clear search` on Results → Home → Home's search bar | **Passed**: Search opens with an empty field (`Search role, company, skill` hint) and `Find Internships` disabled; before the fix it showed `inter` |
| 9 | Device: recent search `Developer` → type `Python` on Results + Enter → tap the Search tab | **Passed**: Results `27 internships found`; the Search field shows `Python` |

Findings:

1. One router test and one Search test typed and tapped `Find Internships` in
   the same frame; the button only enables after a rebuild, so they now pump
   one frame in between. The two other router failures in the first run only
   followed that one and pass unchanged.
2. After a failing router test, `flutter test` waited instead of exiting;
   passing runs exit normally. Not investigated in this change.

## Run 35: Home greeting uses the Google given name; long names fit (2026-11-07)

Branch `feat/home-given-name` from `dev` `8f1f174`, uncommitted working tree.
Environment: macOS 26.7.1 (Apple M1) · Flutter 3.47.6 stable. No device run.
AI log P-78.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | 0 files changed |
| 2 | `flutter analyze` | No issues found! |
| 3 | `flutter test` | `+663: All tests passed!` (6 new: given name saved / not written / save failure ignored, `givenName` parsing, long-name heading at 360 and 412 dp) |
| 4 | Sign in on a device and check the Home name | **Not run** |

Findings: `LoginViewModel` now reads `userProfileServiceProvider`, so the
Login screen and ViewModel tests override it with `FakeUserProfileService`.
The `676` in the UI v2 run below was the compact reporter's running counter,
not the number of tests.

## Run 33: UI v2 headers, Job Hero Card, Application Detail tweaks (2026-11-06)

Branch `feat/ui-v2` from `dev` `ab6c8d3`, uncommitted working tree.
Environment: macOS 26.7.1 (Apple M1) · Flutter 3.47.6 stable. No device run.
AI log P-73.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | 0 files changed (after the edits were formatted) |
| 2 | `flutter analyze` | No issues found! |
| 3 | `flutter test` | 676 / 676 passed (final state: Home without the summary) |
| 4 | Device / emulator check of the new headers and cards | **Not run** |

Findings:

1. 36 tests failed on the first run: they asserted the old UI. The avatar
   was then kept on the non-Home tabs (DC-20), and the tests were updated for
   `Company · City` on one line, the student's name on Home, three
   `Not disclosed` facts instead of four, and a taller header that shows
   fewer application cards (the count line is checked instead).
2. Two Internship Detail taps needed an extra scroll so the link was not
   under the bottom action bar.

## Run 32: Job type / allowance chips; Edit skills from the Apply Form (2026-11-06)

Branch `fix/filter-chips-and-skills-sheet` from `dev` `b08b47f`, uncommitted
working tree. Environment: macOS 26.7.1 (Apple M1) · Flutter 3.47.6 stable ·
Android emulator `Pixel_API_36`. AI log P-70.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format --output=none --set-exit-if-changed lib test` | 211 files, 0 changed |
| 2 | `flutter analyze` | No issues found! |
| 3 | `flutter test` (full suite) | **660 tests, all passed** (+6: Results VM clears job type / allowance alone; Results widget chips shown and removable, none for `Any …`; Edit skills opened before the profile loaded waits, ignores edits and save, then seeds; later snapshots keep the draft; Apply Form `Add skill` keeps the Profile skills) |
| 4 | Negative check: old `edit_skills_viewmodel.dart` / `edit_skills_sheet.dart` from `dev` | The new Apply Form test **fails** (`Found 0 widgets with text "2 chosen"`); code restored afterwards |
| 5 | Probe on the old code (temporary test, deleted) | Profile `[Flutter, Dart, Git]`, sheet opened before the profile loaded: selected `[]`; saving `Python` left `[Python]` |
| 6 | Profile build installed on the emulator | The first launch after install showed "internly isn't responding": the host was short of memory (emulator about 7 GB, Gradle daemon 1.4 GB on an 8 GB Mac). After `./gradlew --stop` the app started in 3.6 s |
| 7 | Device: cold start, Profile tab not opened → Search `Recruitment` → card → `Apply now` → `Add skill` | **Passed**: the sheet shows the 4 Profile skills (`4 chosen`: Git, React, Next.js, JavaScript); before the fix it opened empty. Closed with `Cancel`, nothing saved |
| 8 | Device: Search `Intern` → Filters → `Job type: Internship` → `Show 23 results` | **Passed**: chips `Internship` and `Intern`, Filters badge `2`, `23 internships found`; removing the `Internship` chip → `54 internships found` |

---

## Run 31: Firebase demo area (G-06) — 2026-11-06

Branch `feat/fcm-notification-center`, working tree with the Firebase demo screen. Environment: Windows 11 · Flutter 3.47.8.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib/features/profile lib/app/router.dart test/features/profile` | 1 file reformatted, the rest already formatted |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test test/features/profile/firebase_demo_viewmodel_test.dart test/features/profile/firebase_demo_screen_test.dart test/features/profile/profile_screen_test.dart` | **39 passed** |
| 4 | `flutter test` | **663 passed** |
| 5 | Device walk on `emulator-5554` after `adb install`: `/profile/firebase` | **Passed** after the source fix: `cv_match_enabled = true`, `home_recent_limit = 10`, `home_recommended_limit = 6`, all **`From Firebase`**; `Send a non-fatal error` showed the confirmation SnackBar. Test crash **not tapped** in this run |
| 6 | Evidence screenshots | App states saved as `evidence/remote-config/remote-config-app-from-firebase-20261106.png` and `evidence/crashlytics/crashlytics-nonfatal-sent-20261106.png`. Console before/after and the Crashlytics dashboard are **not captured** |

Fix found during the device walk: `RemoteConfigValue.source.name` returns `valueRemote` / `valueDefault` / `valueStatic`, not `remote` / `default` / `static`, so the demo screen labelled remote values `In-app default`. `FirebaseRemoteConfigService.snapshot()` now maps the enum through `sourceName()`, with a unit test and a widget test for the `From Firebase` label.

Follow-ups: capture `evidence/crashlytics/` (dashboard with fatal + non-fatal, user ID and custom keys) and the Console side of `evidence/remote-config/` (values before/after a change) as described in [`evidence/README.md`](../evidence/README.md). Test crash not run yet. Figma updates for DC-24, DC-25 and DC-26 remain open.

---

## Run 33: Admin dashboard refactor + admin crash command — 2026-11-06

Environment: Windows 11 · Flutter 3.47.8 · Node 24 · `emulator-5554` (1080 × 2400) · Firebase project `prm-lab3` · signed-in test account.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `cd tools/admin-dashboard && npm test` | **9 passed** |
| 2 | `node --check server.js`, `lib/admin.js`, `public/app.js` | Clean |
| 3 | `flutter analyze` | **No issues found!** |
| 4 | `flutter test` | **676 passed** |
| 5 | `POST /api/test-crash` to the signed-in UID | `successCount: 1`; logcat showed `FATAL EXCEPTION: FirebaseCrashlyticsTestCrash` on the app PID, then the app closed |
| 6 | Rebuilt and reinstalled the APK; Profile → Diagnostics | Both `Simulate app crash` and `Firebase demo` are present |
| 7 | `agent-browser` visual check | Recipient select lists all 9 users plus `Everyone with a token (5)`; no-token users are disabled; selecting `Mai Duy Lập` enabled `Send notification` and changed the chip to `To Mai Duy Lập`; the crash acknowledgment enabled `Send test crash` |
| 8 | Crashlytics dashboard for the admin crash | **Not checked** (the fatal report uploads on the next launch) |

Notes: the app must be rebuilt after the `test_crash` handler lands; the first attempt used the earlier APK and did not close. The dashboard is served only on `127.0.0.1:4317`.

---

## Run 34: Email-based apply flow (DC-31) — 2026-11-06

Environment: Windows 11 · Flutter 3.47.8 · Dart 3.13.3 · Node 24.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | Formatted 216 files (8 changed on the first run, then clean) |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **653 passed** |
| 4 | `cd functions && npm test` | **59 passed** (`npm run build` + `node --test`; 13 new for `composeCoverLetter`) |
| 5 | Unit: `contact_email_test.dart`, `mailto_test.dart`, `cover_letter_service_test.dart` | Passed (in the 653) |
| 6 | ViewModel: `apply_compose_viewmodel_test.dart` | Passed: prefill from the JD, AI draft, empty / invalid recipient, `mailto:`, `I've sent it` record fields (`appliedVia: email`, `recipientEmail`, cover letter, optional CV), repeated tap, failed draft, no name, late profile snapshot, `buildSession` |
| 7 | Widget: `apply_compose_screen_test.dart` | Passed at 360 / 412 dp: drafted subject and letter, found / absent address helper, CV card, error + Retry, `Open email app` hands the draft to the fake mail service, 48 dp guideline |
| 8 | Router: `router_test.dart` | `home_apply_email` for `Apply now`; new `/apply/match`, `/apply/validation`, `/apply/success` paths |
| 9 | Deploy `composeCoverLetter` / a real Groq call | **Not run** (no owner deploy or secret in this session) |
| 10 | Device walk (open Gmail, attach the CV, `I've sent it`) | **Not run** (no device session owned by this agent) |
| 11 | `cover_letter_generate` / `application_create` in DebugView | **Not run** |
| 12 | `uv run --no-sync python -m py_compile e2e_test/test_apply.py e2e_test/test_apply_form.py e2e_test/conftest.py` | Clean (TC-06 / TC-18 / TC-19 rewritten for the email flow; TC-20 removed with the form) |

Notes: the compose screen replaces the six-field Application Form and the Review step (DC-31, G-33). The callable's unit tests cover the AI path, the template fallback (blank key, model error, unparseable JSON), Vietnamese listings, a missing internship / key / auth, another user's CV path and a failed CV read.

---

## Run 36: SerpAPI fresher/junior keywords + Detail role/level badges (2026-11-07)

Environment: Windows 11 · Flutter 3.47.6 / Dart 3.13.5 · Node 24.6.0 (functions declare Node 22) · merge of `dev` (UI v2, compose apply flow) into the feature branch. Changes: P-79, DC-28.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `cd functions && npm test` | **20 tests, all passed** (config keywords, rotation and quota) |
| 2 | `dart format lib test` | **222 files formatted, 0 changed** |
| 3 | `flutter analyze` | **No issues found!** |
| 4 | `flutter test` | **687 tests, all passed** (full suite after the merge; includes the level parser, `Internship.level` and the Detail badge assertions at 360 / 412 dp) |
| 5 | Deployed `syncInternshipsJob` + manual Cloud Scheduler run (2026-11-07) | **Real backfill passed**: `sync/state` → `backfill=true`, `fetched=65`, `written=65`, `expiredDeleted=0`, all eight keywords, no `lastError`; Firestore shows 10 `IT fresher Vietnam` and 10 `IT junior Vietnam` listings; the Pixel 6 emulator shows the `DevOps/Cloud` + `Intern` badges on Detail. Evidence: `evidence/sync/2026-11-07-p46-sync.md` + screenshot (files keep the original P-46 label) |

---

## Run 37: Experience band + ranking tiebreaker (2026-11-07)

Environment: Windows 11 · Flutter 3.47.6 / Dart 3.13.5 · no device or Firebase project on this machine. Changes: P-80, DC-32, DC-33.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | **222 files formatted, 0 changed** |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **687 tests, all passed** (full suite after the merge). Coverage: `user_profile_test.dart` (parse/store, legacy profile without `experience`, band → level mapping, equality/hashCode by experience); `profile_viewmodels_test.dart` (seeded band, single-select + clear, other fields keep the draft, save with `item_count`, unanswered experience stored null and not counted, failed save keeps the draft); `recommendation_test.dart` (level matrix incl. `null`, experience does not change the score); `home_viewmodel_test.dart` (level match beats sync rank, no experience keeps sync order, level cannot outrank a better role/skill score); `profile_screen_test.dart` (the Update preferences sheet runs at 360 and 412 dp and saves an experience chip; Profile asserts the `1–2 years` tag and four "Not set" groups) |
| 4 | Not run | On-device sheet/tag screenshots, Firestore round trip on a real project, DebugView for the new `profile_update.item_count` (no device / Firebase project here) |

---

## Run 38: Unread badge on the bell + Mark all as read (2026-11-08)

Branch `feat/notification-unread-badge` from `dev` `88b3382`, uncommitted
working tree. Environment: macOS 26.7.1 (Apple M1) · Flutter 3.47.6 stable.
AI log P-81.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format --output=none --set-exit-if-changed lib test` | 0 changed |
| 2 | `flutter analyze` | No issues found! |
| 3 | `flutter test` (full suite) | **697 tests, all passed** (+10: header badge with 3 and `9+`, none at 0; unread count follows snapshots and is 0 signed out; `markAllRead` marks only the unread, ignores loading / all read, retries after a failure; Notification Center shows `Mark all as read` only while something is unread and hides it after the snapshot) |
| 4 | Profile build of this branch on emulator `Pixel_API_36`, 1 unread notification | **Passed**: red badge `1` on the bell of Home, Saved and Profile |
| 5 | Device: bell → Notifications | **Passed**: `Mark all as read` shown in the app bar; the unread item has its dot |
| 6 | Device: tap `Mark all as read` | **Passed**: the item reads `Read`, the action disappears; Back to Profile shows the bell without a badge |

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

## Run 32: CV library (G-33) — 2026-11-07

**Environment:** Windows 11 Home Single Language 10.0.26200 · Flutter 3.47.3 stable · Dart 3.13.3 · branch `feat/cv-library`. No Firebase project or device configured on this machine; build/device runs happen on another machine.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | **Completed**; 215 files, 0 changed (already formatted) |
| 2 | `flutter analyze` | **No issues found!** (strict casts / inference / raw types, extra lint rules from `analysis_options.yaml`) |
| 3 | `flutter test` | **687 tests, all passed** (`All tests passed!`); new/changed: `test/core/utils/cv_library_test.dart`, `test/models/user_profile_test.dart`, `test/services/file_storage_service_test.dart`, `test/features/profile/profile_viewmodels_test.dart` (CV library add/set default/remove + referenced-file guard), `test/features/profile/profile_screen_test.dart` (CV library section at 360/412 dp) |
| 4 | `flutter build apk --debug` | **Not run**: Android toolchain incomplete on this machine. Run on the device-owner machine before opening the PR. |
| 5 | App launch / Firebase (Auth, Storage, Firestore `users/{uid}/cvs`) on device | **Not run**: Firebase not configured here; requires the device-owner machine. |

Findings:

1. Two `removeCv` bugs were found while reviewing the work-in-progress before logging, and fixed in this session: (a) removing a non-default CV promoted another CV to default even when the legacy `users/{uid}.cv` mirror was the active default (`defaultCvId == null`); (b) removing the legacy mirror cleared `cv` to `null` while library entries survived, so the Apply Form prefill went empty. The legacy-mirror branch now promotes the newest library entry to `defaultCvId` + mirror, and the library-entry branch leaves a surviving legacy mirror as the default. Tests still pass after the fix.
2. DebugView evidence for `cv_library_change` (`action`, `cv_count`, `kept_file`) is **not captured here**; it needs a running app + Firebase Console and is recorded separately by the device-owner.

---

## Run 33: CV auto-select (G-33 item 8) — 2026-11-08

**Environment:** Windows 11 Home Single Language 10.0.26200 · Flutter 3.47.3 stable · Dart 3.13.3 · branch `feat/cv-library`. No Firebase project or device configured on this machine.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | **Completed**; 215 files, 0 changed |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **687 tests, all passed**; existing apply-form tests still pass after ViewModel refactor |
| 4 | `npm run build && npm test` (Cloud Functions) | **57/57 tests passed** including new `select-cv.test.ts` (12 cases) |
| 5 | `flutter build apk --debug` | **Not run**: Android toolchain incomplete on this machine |

Findings:

1. Two ViewModel logic bugs discovered during review and fixed: `removeCv` guard for legacy-mirror default (2026-11-07); `_onProfile` and `_applyLibrary` ordering that caused `profileCv` to go null when the CV library stream arrived (2026-11-08).
2. `cv_auto_select` event now Implemented; DebugView screenshot still pending device run.

---

## Run 39: Post-merge CV/profile regression fixes (2026-11-08)

**Environment:** Windows 11 · branch `feat/cv-library`, HEAD `3f5eb24` plus an uncommitted working tree. No Firebase login on this machine.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | **230 files, 0 changed** |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` (full suite) | **729 tests, all passed** |
| 4 | `npm run build && npm test` (`functions/`) | **72/72 tests passed** |
| 5 | `flutter pub get` | **Got dependencies** (37 newer versions held back by constraints) |
| 6 | `npm install` (`functions/`) | **up to date**, 259 packages audited (9 vulnerabilities reported by npm) |
| 7 | `npx firebase-tools deploy --only functions:selectCv --project prm-lab3` | **Passed after one retry**: the first attempt created the function but failed to set the Cloud Run invoker IAM policy; the second run printed `Deploy complete!`, and `functions:list` shows `selectCv` (callable, `us-central1`, `nodejs22`) |

Findings:

1. The merge with `dev` dropped `UserProfile.givenName` / `UserProfile.defaultCvId` from the model fields, `fromFirestore`, `==` and `hashCode`; this broke the Home greeting and Profile default-CV selection. Restored all four places and added an equality regression test.
2. The merge kept two `updateCv` implementations; removed the old mirror-only one so uploads add to the library and set the new CV as default.
3. `functions/src/index.ts` imported `handleSelectCv` / `SELECT_RUBRIC` and defined `selectGroq`, but the merge lost the `selectCv` export; restored the callable and `npm run build` passes.
4. `FakeUserProfileService` dropped `givenName` / `defaultCvId` on merge writes; both are now preserved.
5. The first deploy created `selectCv` but failed with `Failed to set the IAM Policy on the Service`; an immediate retry completed successfully, so the callable is now deployed.

---

## Run 40: Compose CV auto-select + manual Change CV (2026-11-09)

**Environment:** Windows 11 → Flutter 3.47.3 stable / Dart 3.13.3 → branch `feat/cv-library` with an uncommitted working tree. No Firebase project or device configured on this machine.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | **230 files, 0 changed** |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` (full suite) | **735 tests, all passed** (+6: auto-select success, failed fallback, manual choice during the comparison, one-CV skip, and the screen suggestion + `Change CV` sheet at 360 and 412 dp) |
| 4 | DebugView for `cv_auto_select` | **Not run** (no Firebase project / device here) |

Findings:

1. The earlier auto-select only existed in the removed Apply Form; the Compose flow now owns the library, the suggestion and the manual override. Drafting waits for the comparison so the cover letter is composed against the chosen CV.
2. `Change CV` applies to this application only. The Profile default is never written from Compose (DC-35).

---

## Run 41: Test docs sync + admin dashboard analytics (2026-11-10)

**Environment:** Windows 11 · Node 24.22.1 · npm 11.19.1 · branch `dev`, HEAD `5c27ddd` (documentation, E2E suite and admin dashboard changes). No Flutter or ARTEMIS run in this session.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `cd tools/admin-dashboard && npm test` | **14 tests, all passed** (`node --test test/*.test.js`): the 9 cases from Run 33 plus 5 in `analytics.test.js` (GA4 realtime totals, row fallback, event-only rows, malformed reports, quota bucket) |
| 2 | `flutter analyze` / `flutter test` | **Not re-run**: `5c27ddd` changes no `lib/` or `test/` Dart file, so Run 40 (735 tests) remains the latest full suite |
| 3 | ARTEMIS suite | **Run separately** on 2026-11-09/10 (TC-06, TC-07, TC-09, TC-14, TC-17, TC-19). Results, counted traces and causes are in `test-plan.md` §4 and [`evidence/artemis/e2e-environment-20261110.md`](../../evidence/artemis/e2e-environment-20261110.md); the day's lines were copied to [`runs-20261110.jsonl`](../../evidence/artemis/runs-20261110.jsonl) because `e2e_test/artifacts/` is git-ignored |

Findings: TC-06, TC-07, TC-09 and TC-17 now have 3 of 3 counted passes; TC-14 (2 of 4) and TC-19 (0 of 3) still need a counted batch. The two title-check failures (TC-07 `c67149d6`, TC-09 `cee108da`) were test expectations, fixed by `_same_position`, not app defects.

---

## Run 42: CR-07 Saved part + CR-11 filter count (2026-11-11)

**Environment:** macOS 26 (Apple M1) → Flutter 3.47.6 stable / Dart 3.13.5 → branch `fix/cr-07-cr-11-saved-identity-filter-count` from `dev` `1317527`: CR-07 committed as `1f591c3`, CR-11 and these records in the `fix(CR-11)` commit after it. No Firebase project or device used.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | **230 files, 0 changed** |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` (full suite) | **741 tests, all passed** (+6: `saved_viewmodel_test` CR-07 group — identity provider, unsave of another copy, two legacy copies removed, same title at another company still saved; Search Results card saved under another copy; Search filter sheet opened before the pool loads) |
| 4 | New screen tests against the old `lib/` (`git stash push -- lib`) | **Both fail as expected**: CR-07 finds no `Remove from saved` bookmark; CR-11 stays at `Show 0 results →`. Restored with `git stash pop` before row 3 |
| 5 | Device run / ARTEMIS | **Not run** |

Findings:

1. CR-07 (Saved part): the Save Toggle on Home, Search Results and Detail now reads `savedJobsProvider` (job identities). `SavedViewModel.toggleAndReport` removes the saved copies of the job, not the key of the copy on the card, so the job can no longer be saved twice.
2. CR-11: `SearchResultsFilterSheet.show` takes `listingsChanged` (the provider the listings live in) and rebuilds from it; the criteria being edited stay in the sheet's `State`.

---

## Run 43: Firestore and Storage rules tests (2026-11-11)

**Environment:** Windows 11 · Node 24.22.1 · npm 11.19.1 · firebase-tools 15.34.1 · JDK 25.0.3 (Android Studio `jbr`, added to `PATH`; the CLI checks `java -version` and ignores `JAVA_HOME` alone) · branch `dev`, HEAD `1317527` with an uncommitted working tree. Emulators only (`demo-internly`); no Firebase project, device or network data.

| # | Command | Result |
|---|---|---|
| 1 | `npm --prefix firebase/tests install` | **136 packages installed** (`@firebase/rules-unit-testing` 6.0.0, `firebase` 13.2.0). These are `dependencies`, not `devDependencies`, because this machine sets `omit=dev` |
| 2 | `firebase emulators:exec --only firestore,storage --project demo-internly "npm --prefix firebase/tests test"` | **15 tests, 15 passed, 0 failed** (`node --test --test-concurrency=1`, 2.9 s): all 15 in the two new files |
| 3 | `firebase emulators:exec --only firestore,storage --project demo-internly "node firebase/tests/demo/server.mjs --self-test"` | **19/19 demo scenarios passed, 0 failed** (1.8 s) — the same rules exercised through the browser harness, including the 50/51-field boundary and the Storage content-type/size checks |
| 4 | Demo smoke test under the same `emulators:exec` | `GET /` → **200**, 10,327 bytes, page renders the table; `GET /run` → **200**, plan 19 rows, 19 results, summary `19/19 passed, 0 failed, 1772 ms` |
| 5 | `flutter analyze` / `flutter test` | **Not re-run**: no Dart file changed; Run 42's 741 tests remain the latest full suite |

Coverage: `firestore.rules.test.mjs` (9 tests) — `users/{uid}` denies signed-out and other users, allows the owner on the document and its subcollections, and rejects a 51-field write while accepting 50; `internships/{key}` reads only when signed in and never accepts a client write (create, update, delete); `sync/**` is closed. `storage.rules.test.mjs` (6 tests) — `reports/{uid}` and `cvs/{uid}` allow the owner's PDF, reject another user, a signed-out client, non-PDF content, a PDF over 10 MB and every other path. `demo/server.mjs` exposes the same decisions as 19 rows on a local page (`http://localhost:5500`) so a screen recording can be used as evidence; the page and the node:test files both read the rules from `firebase/`.

Findings: the first run failed 4 Firestore cases because the tests addressed `users/alice/profile`; `users/{uid}` is the document itself and a three-segment path is invalid, so the cases now use `users/alice` and `users/alice/<collection>/<doc>`. No rule changed. Running the emulators requires a JDK on `PATH`; `JAVA_HOME` was set as well for the Storage rules runtime. The emulator prints a `sun.misc.Unsafe` warning from the Storage rules runtime on JDK 25; it did not affect results.

---

## Run 44: Student-reported application status (2026-11-11)

**Environment:** Windows 11 · branch `feat/application-status-tracking` (merged `origin/dev` `2a5e3b0`) · Flutter 3.47.3 stable · Dart 3.13.3. No device or emulator was attached, so no build or E2E run.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | **231 files, 3 changed** on the first pass, then 0 on the re-run |
| 2 | `flutter analyze` | **No issues found!** (ran in 6.8 s on the second pass) |
| 3 | `flutter test test/features/applications test/models/internship_application_test.dart` | **100 tests, all passed** |
| 4 | `flutter test` (full suite) | **751 tests, all passed** (after merging `dev`) |
| 5 | `python -m py_compile e2e_test/test_applications.py` | **Passed** (new TC-21 syntax only) |
| 6 | ARTEMIS TC-21 | **Not run**: no device attached; the case is written and marked `Ready` in `docs/test-plan.md` |
| 7 | `flutter build apk --debug` | **Not run**: Android toolchain incomplete on this machine |

Findings:

1. The tracker had no in-app writer for `under_review` … `rejected` (G-25 #6), so the stages could only be set from the console. `ApplicationService.updateStatus` + `UpdateStatusSheet` now write them and stamp `statusUpdatedAt` (BR-T8, DC-35).
2. `withdrawn` is deliberately excluded from the picker: Withdraw / Undo own `withdrawnAt` / `previousStatus`, and a plain status write would leave them stale. A service-level guard refuses it too.
3. No `application_update` event is logged when the picked stage equals the stored one, so a no-op tap cannot inflate the funnel.
4. The tracker shows `statusUpdatedAt` only for the active step of a document that has it; older documents keep showing no invented date (rule 7).
