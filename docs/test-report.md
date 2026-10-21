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
| 9 | MobAI end-to-end | **Not run**: feature screens not built yet; specs in `mobai_tests/README.md` |

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
- Configure Firebase (`docs/firebase-setup.md`), then do a manual sign-in and sign-out check on Android and iOS (row 7).
- Add the Firestore emulator rules tests with the first feature collection (row 8).

---

## Run template

```markdown
## Run N: <PR / milestone> (<date>)

Environment: <OS, Flutter, device / emulator, commit>

| # | Command / scenario | Result |
|---|---|---|
| 1 | flutter analyze | |
| 2 | flutter test | <passed>/<total> |
| 3 | <build / MobAI scenario> | |

Failures and follow-ups: <links to issues / commits>
```
