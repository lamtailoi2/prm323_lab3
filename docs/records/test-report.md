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

---

## Run 8: Save Toggle on Home (2026-10-28)

Branch `feat/saved-internships`, commit `569be13` plus the Save Toggle working tree. Environment: Windows 11 (10.0.26200.9711), Flutter 3.47.8 / Dart 3.13.3, Android emulator `sdk gphone64 x86_64` (Android 17 / API 37, `-gpu swiftshader_indirect`), Firebase project `prm-lab3`.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | Completed; 78 files checked, 0 changed |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **131 tests, all passed** (125 before this change: +4 in `test/features/saved/saved_viewmodel_test.dart`, +2 net in `home_screen_test.dart`, where the "coming soon" case became save / unsave / failed-save) |
| 4 | Save Toggle on the emulator (signed in, Home) | **Not run yet**: the app session (`flutter run`) is owned by the developer's terminal; the widget tests above cover the tap, the filled bookmark, `internship_save` and the failure message. Verify by hot restarting (`R`) and tapping a card bookmark, then checking `users/{uid}/savedInternships` and the Saved tab |
| 5 | `firestore.rules` change | **None needed**: saved items live under `users/{uid}/savedInternships` (AGENTS.md rule 9) |
| 6 | DebugView screenshot for `internship_save` | **Not run**: needs the on-device check in row 4 and the DebugView session; `evidence/analytics/` has no entry yet |
| 7 | ARTEMIS case for saving | **Not run**: no ARTEMIS daemon on this machine (Run 7 row 5) |

---

## Run 9: Shared tab header for Saved Internships (2026-11-01)

Branch `feat/saved-internships` (1 commit ahead of `origin`), uncommitted working tree. Environment: Windows 11 (10.0.26200.9711), Flutter / Dart from `C:\Users\ADMIN\flutter`, emulator `Pixel_9` (Android 17 / API 37, 1080x2424 @ 420 dpi = 411 dp, windowed), Firebase project `prm-lab3`.

| # | Command / scenario | Result |
|---|---|---|
| 1 | `dart format lib test` | Completed; 80 files checked, 1 changed (`test/core/widgets/components_test.dart`) |
| 2 | `flutter analyze` | **No issues found!** |
| 3 | `flutter test` | **140 tests, all passed** (+9: `test/features/saved/saved_screen_test.dart` at 360 / 412 dp, bell, avatar → Profile, empty state, 48 dp targets; +3 `MainTabAppBar` cases in `components_test.dart`) |
| 4 | `flutter build apk --debug --dart-define-from-file=.env` | **Passed**: `✓ Built build\app\outputs\flutter-apk\app-debug.apk` (81.5 s) |
| 5 | On device: `adb install -r` + Saved tab, 412 dp | **Passed**: `Saved` title at the 16 dp text margin, bell and avatar as on Home; screenshot `evidence/screens/saved-header-412-20261101.png` |
| 6 | On device: `adb shell wm size 945x2120` (360 dp), Saved tab | **Passed**: same header, title not clipped; screenshot `evidence/screens/saved-header-360-20261101.png`. `wm size reset` restored 1080x2424 |
| 7 | Follow-up: brand mark removed from the tab header (`MainTabAppBar`) | **Passed after re-run**: `dart format` 0 changed; `flutter analyze` `No issues found!`; `flutter test` **140 passed**; APK rebuilt, reinstalled, both widths re-captured (rows 5–6 hold the screenshots of this state). Title width measured with the bundled Inter font: `Saved Internships` = 211.2 dp vs 244 dp available at 360 dp |
| 8 | Bottom navigation at 360 dp | **Finding, not fixed here**: the `Applications` label wraps onto two lines at 360 dp (it fits at 412 dp). Out of scope for this change; needs its own fix against `design-system.md` §2.7 (`Labels type/caption`) |
| 9 | ARTEMIS case for the tab header | **Not run**: no ARTEMIS daemon on this machine (Run 7 row 5) |

---

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
