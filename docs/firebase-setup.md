# Firebase setup

The repository ships **without** Firebase configuration. Until you finish this guide, `lib/firebase_options.dart` is a placeholder and the app opens on a "Firebase is not configured" screen. That is expected: the app never pretends to be connected.

Identifiers used below (change them **before** step 3 if the team picks others; see handoff-gaps G-21):

| Platform | Identifier |
|---|---|
| Android `applicationId` | `com.group3.internly` |
| iOS bundle ID | `com.group3.internly` |

## 1. Prerequisites

- Flutter 3.47+ / Dart 3.13+ (`flutter doctor` without errors for the platforms you build)
- **Android:** Android Studio or the Android SDK with `cmdline-tools`, `platforms;android-36`, `build-tools`, and JDK 17 (or the JDK bundled with Android Studio)
- **iOS:** Xcode and CocoaPods (`pod --version`). This project uses CocoaPods, not SPM (handoff-gaps G-20).
- Node.js LTS (for the Firebase CLI)

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
```

## 2. Create the Firebase project

1. In the [Firebase console](https://console.firebase.google.com/), click **Add project**, name it (e.g. `internly-<group>`), and **enable Google Analytics** (needed for Analytics events and Crashlytics breadcrumbs).
2. The **Spark** (free) plan is enough for Auth, Firestore, Analytics, Crashlytics, Remote Config and FCM. Cloud Storage for new projects and Cloud Functions need **Blaze** (handoff-gaps G-10, G-12).

## 3. Register the apps and generate the config

From the repository root:

```bash
flutterfire configure \
  --project=<firebase-project-id> \
  --platforms=android,ios \
  --android-package-name=com.group3.internly \
  --ios-bundle-id=com.group3.internly \
  --out=lib/firebase_options.dart
```

This registers both apps and writes:

- `lib/firebase_options.dart` (replaces the placeholder; there must be exactly one copy)
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- the Android Gradle plugins `com.google.gms.google-services` and `com.google.firebase.crashlytics`, plus the iOS Crashlytics symbol upload build phase

Check with `git diff android/ ios/` that both Gradle plugins were added. Crashlytics on Android fails at runtime ("build ID is missing") without its Gradle plugin.

## 4. Authentication: Google Sign-In

1. Console → **Authentication → Sign-in method → Google → Enable**, and set the project support email.
2. **Android SHA fingerprints.** Every developer machine and every signing key needs its own:
   ```bash
   cd android && ./gradlew signingReport          # look for Variant: debug → SHA1 / SHA-256
   # or
   keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore \
     -storepass android -keypass android
   ```
   Console → **Project settings → Your apps → Android app → Add fingerprint**: add SHA-1 **and** SHA-256. Add the release key's fingerprints before building a release.
3. **Re-run `flutterfire configure`** (or re-download `google-services.json`) after enabling Google and adding fingerprints. The file must contain an `oauth_client` with `"client_type": 3` (the web client). `google_sign_in` 7 reads it on Android as `default_web_client_id`.
   - Symptom of a missing or wrong SHA-1 or web client: `GoogleSignInException(clientConfigurationError)`, or `canceled` right after picking an account. The app reports this as "Google Sign-In is not set up for this build".
4. **iOS URL scheme.** Open the new `ios/Runner/GoogleService-Info.plist`, copy `REVERSED_CLIENT_ID`, and add it to `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key>
       <string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.XXXXXXXX</string>
       </array>
     </dict>
   </array>
   ```
   The app passes `iosClientId` from `firebase_options.dart` to `GoogleSignIn.initialize`. If that field is missing, the plist was downloaded before Google sign-in was enabled: re-run step 3.

## 5. Cloud Firestore

1. Console → **Firestore Database → Create database** → **production mode**. Pick a nearby region (e.g. `asia-southeast1`); it cannot be changed later.
2. Deploy the rules and indexes from this repository (`firebase.json` points to `firebase/`):
   ```bash
   firebase use --add          # select the project; creates .firebaserc
   firebase deploy --only firestore:rules,firestore:indexes
   ```
3. Never edit rules only in the console. Change `firebase/firestore.rules` in a pull request, test with the emulator, and deploy.
4. Local emulators (optional): `firebase emulators:start --only auth,firestore`.

Seed data for `internships` is an open decision (handoff-gaps G-14). Never commit a service-account key to seed data.

## 6. Crashlytics

1. Console → **Crashlytics → Enable**.
2. Crash reporting is wired in `app/bootstrap.dart`. To verify, use the explicit test-crash control once it exists (G-06), then restart the app; reports are uploaded on the next launch. Never trigger a test crash at startup.
3. iOS needs dSYMs: the build phase added by `flutterfire configure` uploads them. Keep it.

## 7. Analytics

Enabled by step 2. To watch events live in **DebugView**:

```bash
# Android
adb shell setprop debug.firebase.analytics.app com.group3.internly
# iOS: Xcode → Scheme → Run → Arguments → add -FIRDebugEnabled
```

Event names and parameters: [`analytics-plan.md`](analytics-plan.md).

## 8. Remote Config

Console → **Remote Config** → create each parameter with **the same key and type** as in `RemoteConfigDefaults.values` (`lib/services/remote_config_service.dart`), then **Publish**. The app always ships with defaults, so it works before the first fetch and offline. Fetch interval: 1 minute in debug, 1 hour in release.

## 9. Cloud Messaging (FCM)

Set this up together with the notifications feature (G-04, G-13):

- **Android 13+:** declare `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` and request it at runtime.
- **iOS:** requires a **paid Apple Developer account**. Create an APNs authentication key (`.p8`) and upload it in Console → Project settings → Cloud Messaging. In Xcode → Runner → Signing & Capabilities, add **Push Notifications** and **Background Modes → Remote notifications**. Never commit the `.p8` file.
- Test messages: Console → **Messaging → New campaign → Send test message** with a device's FCM token.

## 10. File storage (CV upload, PDF report)

The provider is undecided (G-12). If Cloudinary is chosen:

- Use an **unsigned upload preset** dedicated to PDFs: allowed formats `pdf`, a fixed folder, and unique file names. Check in the Cloudinary console which size limits the preset can enforce server-side, and also enforce the size limit in the app before uploading.
- Only the **cloud name** and **preset name** may be in the app. The **API secret never** goes in the app or the repository.
- Unsigned uploads produce public URLs. Document this privacy trade-off before storing CVs or reports containing personal data.

## 11. What may and may not be committed

| Commit | Never commit |
|---|---|
| `lib/firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist` (app configuration, not secrets; protect them with Security Rules and API-key restrictions) | Service-account JSON (`*-firebase-adminsdk-*.json`) |
| `firebase.json`, `firebase/firestore.rules`, `firebase/firestore.indexes.json` | APNs keys (`.p8`), keystores (`.jks`, `.keystore`), `key.properties` |
| `.firebaserc` (project alias only) | Cloudinary API secret, AWS keys, `.env` files with secrets |

If the GitHub repository is public, restrict the Firebase API keys in Google Cloud console → **APIs & Services → Credentials**: Android key → package `com.group3.internly` + SHA-1; iOS key → bundle ID.

## 12. Verify

```bash
flutter pub get
flutter run            # pick an Android emulator / iOS simulator
```

Expected: Splash, then **Login** (not "Firebase is not configured"). Signing in with Google opens Home; Profile → **Sign out** returns to Login. The user appears in Console → Authentication → Users.
