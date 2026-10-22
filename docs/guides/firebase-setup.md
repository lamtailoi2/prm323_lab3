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
2. The **Spark** (free) plan is enough for Auth, Firestore, Analytics, Crashlytics, Remote Config and FCM. Cloud Storage needs **Blaze** (billing account required). Upgrade only as described in §10 (US bucket, $1 budget alert) so usage stays inside the no-cost quota.

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
2. **Android SHA fingerprints.** With the shared team keystore (§15) you register **one** SHA-1 / SHA-256 for everyone. Without it, every developer machine needs its own:
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
2. **Owner publishes the rules once.** `firebase/firestore.rules` is final (owner-only `users/{uid}/**`), and `firebase/storage.rules` is final (owner-only `reports/{uid}`, `cvs/{uid}`, PDF ≤ 10 MB). Either:
   - with the CLI (`firebase.json` points to `firebase/`):
     ```bash
     firebase use --add          # select the project; creates .firebaserc
     firebase deploy --only firestore:rules,firestore:indexes,storage   # storage after §10
     ```
   - or without the CLI: Firebase console → Firestore → **Rules** → paste `firebase/firestore.rules` → **Publish**; Storage → **Rules** → paste `firebase/storage.rules` → **Publish**.
3. **Keeping them in sync:** only the owner publishes rules. A teammate who needs a change edits `firebase/*.rules` in a PR and tags the owner; after merge the owner publishes again. Never edit rules only in the console. To check for drift, compare the console's Rules history with the files.
4. Local emulators (optional, needs the CLI): `firebase emulators:start --only auth,firestore,storage`.

Internship listings live in the shared `internships/{jobKey}` collection. The scheduled function (§13) is the only writer; signed-in users may read it, and the app never calls SerpAPI. Each user's own data still lives under `users/{uid}`.

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

Event names and parameters: [`analytics-plan.md`](../analytics-plan.md).

## 8. Remote Config

Console → **Remote Config** → create each parameter with **the same key and type** as in [`firebase/remote-config-defaults.json`](../../firebase/remote-config-defaults.json) (the app loads the same file as its in-app defaults), then **Publish**:

| Key | Type | Default | Changes |
|---|---|---|---|
| `home_recommended_limit` | Number | 5 | Number of cards in Home "Recommended for you" |
| `cv_match_enabled` | Boolean | true | Shows or skips the CV Match Check step (Flow 2d) |

The app listens for real-time updates, so a published change applies without restarting or rebuilding (Lab 3 §6). It also fetches at startup (minimum interval: 1 minute in debug, 1 hour in release) and works offline with the defaults.

## 9. Cloud Messaging (FCM)

Set this up together with the notifications feature (G-04, G-13):

- **Android 13+:** declare `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` and request it at runtime.
- **iOS:** requires a **paid Apple Developer account**. Create an APNs authentication key (`.p8`) and upload it in Console → Project settings → Cloud Messaging. In Xcode → Runner → Signing & Capabilities, add **Push Notifications** and **Background Modes → Remote notifications**. Never commit the `.p8` file.
- Test messages: Console → **Messaging → New campaign → Send test message** with a device's FCM token.

## 10. Cloud Storage (CV upload, PDF report) on Blaze at $0

Decision (G-12): Cloud Storage for Firebase on the **Blaze** plan, kept inside the no-cost quota. Budgets in Google Cloud **only alert; they cannot cap spending**, so follow every step.

1. Console → **Upgrade** to Blaze and link a billing account.
2. Google Cloud console → **Billing → Budgets & alerts → Create budget**: scope = this project, amount **$1**, alert thresholds **50 %, 90 %, 100 %**, email to the project owner.
3. Firebase console → **Storage → Get started**: choose location **`US-CENTRAL1`, `US-EAST1` or `US-WEST1`**. Only these regions get the Always Free tier; any other region is billed from the first byte. The location cannot be changed later.
4. Deploy the rules: `firebase deploy --only storage` (`firebase/storage.rules`: owner-only `reports/{uid}` and `cvs/{uid}`, PDF only, ≤ 10 MB).
5. Do not enable other paid products (Cloud Functions, extensions, …).
6. After grading: Google Cloud console → Billing → **Disable billing** for the project (returns it to Spark; Storage stops).

The app uploads through `FirebaseStorageService` (`lib/services/file_storage_service.dart`), which checks sign-in, own folder, PDF signature and size before sending, reports progress, and returns the download URL.

## 11. What may and may not be committed

| Commit | Never commit |
|---|---|
| `lib/firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist` (app configuration, not secrets; protect them with Security Rules and API-key restrictions) | Service-account JSON (`*-firebase-adminsdk-*.json`) |
| `firebase.json`, `firebase/firestore.rules`, `firebase/firestore.indexes.json` | APNs keys (`.p8`), keystores (`.jks`, `.keystore`), `key.properties` |
| `.firebaserc` (project alias only), `.env.example` | `.env` (SerpAPI key), `e2e_test/.env`, Cloudinary API secret, AWS keys, model API keys |

If the GitHub repository is public, restrict the Firebase API keys in Google Cloud console → **APIs & Services → Credentials**: Android key → package `com.group3.internly` + SHA-1; iOS key → bundle ID.

## 12. Verify

```bash
flutter pub get
cp .env.example .env                        # debug signing key only
flutter run --dart-define-from-file=.env    # pick an Android device / emulator
```

Expected: Splash, then **Login** (not "Firebase is not configured"). Signing in with Google opens Home; Profile → **Sign out** returns to Login. The user appears in Console → Authentication → Users.

## 13. SerpAPI sync Cloud Function (internship data)

The app never holds a SerpAPI key. A scheduled Cloud Function mirrors Google Jobs into Firestore so the free quota is spent once for every user, not once per device.

1. Create a free SerpAPI account (no card) and copy the key from <https://serpapi.com/manage-api-key>.
2. Enable the required Google Cloud APIs (the first deploy asks): **Cloud Functions**, **Cloud Scheduler**, **Secret Manager**, **Artifact Registry** and **Cloud Build**.
3. Store the key in Secret Manager (Blaze is already required for Storage):
   ```bash
   firebase functions:secrets:set SERPAPI_KEY
   # paste the key when prompted; never put it in .env or Git
   ```
4. Install and deploy:
   ```bash
   cd functions && npm install && cd ..
   firebase deploy --only functions,firestore:rules
   ```
   `syncInternshipsJob` runs every 6 hours in `Asia/Ho_Chi_Minh`; the first run backfills five keywords with `location=Vietnam`, then each run refreshes one keyword.
5. Verify: Console → Functions → `syncInternshipsJob` logs `internship sync complete`; Firestore → `internships` has documents and `sync/state` shows the last run. The app reads that pool without a key.
6. Quota: five backfill searches, then about four per day (~120 per month) on the 250-search free plan. If the quota runs out, `sync/state.lastError` says so; the app keeps the last good listings until they expire after seven days.
7. Rotating the key: `firebase functions:secrets:set SERPAPI_KEY` again and redeploy the function. Nothing in the app changes.

## 14. End-to-end tests (ARTEMIS)

Setup, the zero-cost model choice (Gemini API free tier) and run commands are in [`test-plan.md`](../test-plan.md).

## 15. Team setup: one `.env` for everyone

Goal: the owner sets everything up once; teammates only receive one `.env` file and run the app. Firebase config files are committed, so nobody sends those.

**Owner (once)**

1. Create a team debug keystore and print its fingerprints and base64:
   ```bash
   keytool -genkeypair -keystore debug.keystore -alias androiddebugkey \
     -storepass android -keypass android -keyalg RSA -keysize 2048 \
     -validity 10000 -dname "CN=Internly Debug"
   keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android | grep -E "SHA1|SHA256"
   base64 < debug.keystore | tr -d '\n'      # Windows: [Convert]::ToBase64String([IO.File]::ReadAllBytes("debug.keystore"))
   ```
2. Firebase console → Project settings → Android app → **Add fingerprint**: add the SHA-1 and SHA-256 above, once.
3. Fill the root `.env`: `DEBUG_KEYSTORE_BASE64=<the one-line base64>`. `android/app/build.gradle.kts` decodes it into the build folder and signs every debug build with it. The SerpAPI key is **not** in this file; the owner sets it as the `SERPAPI_KEY` function secret (§13).
4. Firebase console → **Users and permissions**: add teammates (Editor to deploy rules or change Remote Config, Viewer for evidence screenshots).
5. Send `.env` privately (Zalo / Drive), **never through Git**. Delete the local `debug.keystore` file or keep it outside the repository; keystores must not be committed (Lab 3 §9).

**Teammate**

```bash
git pull
# put the received .env in the repository root
flutter pub get
flutter run --dart-define-from-file=.env
```

Google Sign-In works immediately because the debug build carries the team key. Internship data comes from the shared Firestore pool, so teammates do not need a SerpAPI key. Only teammates who deploy rules or functions need `firebase-tools` and `firebase login` with their own Google account; nobody needs a service account.

The debug keystore is for **debug builds only**. A real release would need its own private keystore.
