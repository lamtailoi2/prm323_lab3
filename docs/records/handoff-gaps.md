# Handoff gaps, assumptions and open decisions

This file records what the Lab 2 handoff does not specify, specifies ambiguously, or contradicts, and how each item is handled. It is a living document: owners update **Status** and **Resolution** when a decision is made. Gap IDs are referenced from code comments and other docs, so never renumber them.

**Inspected on 2026-10-21:** Lab 2 repo at `03f4aa3` (DESIGN.md, screen-spec.md, design-decisions.md, user-flow.md, persona.md, README handoff tables, AI design log, final Stitch screenshots) and screenshots of Figma pages 04 Design System and 05 Components shared by the team.

Status legend: **Open** (decision needed) · **Assumed** (working assumption, confirm later) · **Resolved**.

## Summary

| ID | Gap | Owner | Status |
|---|---|---|---|
| G-01 | `handoff/flutter-handoff.md` does not exist | Team | Assumed |
| G-02 | Product name: "Internship Finder" (Lab 2) vs "Internly" (Lab 3) | Team | Assumed |
| G-03 | No Login screen in Lab 2 | Auth owner | Assumed (interim UI) |
| G-04 | No Notification Center screen in Lab 2 | Notifications owner | Assumed (Firebase demo area on Profile, per Lab 3 §3) |
| G-05 | No PDF report export in Lab 2 | Report owner | Assumed (Firebase demo area on Profile, per Lab 3 §3) |
| G-06 | No place in the UI for Remote Config values and Crashlytics test controls | Profile owner | Resolved (Firebase demo area on Profile, Lab 3 §3) |
| G-07 | Component values not documented (estimated from screenshots) | Design owner | Open (verify in Figma) |
| G-08 | Main entity for a CRUD requirement not defined | Team | Resolved (not required by the Lab 3 handout) |
| G-09 | Lab 3 specification document not in the repository | Team | Resolved (handout received 2026-10-21) |
| G-10 | Nobody can change an application's status (no employer side) | Applications owner | Open |
| G-11 | Remote Config parameters not chosen | Profile owner | Assumed (2 defaults in `firebase/remote-config-defaults.json`) |
| G-12 | CV / PDF storage provider and privacy of uploaded files | Team | Resolved (Firebase Storage on Blaze, $0 within no-cost quota) |
| G-13 | Notification data source (who sends FCM, where history is stored) | Notifications owner | Assumed (console sends; client stores history) |
| G-14 | No seed / demo data for internship listings | Search owner | Resolved (SerpAPI, no seeding) |
| G-15 | iOS added to scope; Lab 2 designed for Android only | Team | Resolved (Material on both) |
| G-16 | Figma pages available only as screenshots; 19 of 31 components not covered | Design owner | Open |
| G-17 | Allowance format: `$1,200/month` (Figma) vs VND per month (Stitch / AI log) | Home / Search owner | Resolved (VND format; allowance read from the description, 2026-10-28) |
| G-18 | No "Withdrawn" status badge specimen | Applications owner | Open |
| G-19 | Two Figma color pairs fail WCAG AA contrast | Design owner | Open (proposals DC-04, DC-05) |
| G-20 | iOS: SPM cannot resolve Firebase 13 + GoogleSignIn 9 | Tech lead | Resolved (CocoaPods; see note) |
| G-21 | App ID / bundle ID and repository naming not confirmed | Team | Resolved (keep `prm323_lab3`, user decision) |
| G-22 | Keyword search strategy (Firestore has no full-text search) | Search owner | Resolved (SerpAPI query) |
| G-23 | "Recommended for you" logic not specified | Home owner | Resolved (sync rank + recency) |
| G-24 | CV Match Check (new Apply step): matching rules, data source, Figma frame | Apply owner + design owner | Open |
| G-25 | Consequences of using SerpAPI (Google Jobs) as the data source | Search + Apply owners | Resolved (shared Firestore mirror) |
| G-26 | Zero-cost constraint: every service and tool must run at $0 | Team | Resolved (plan below) |
| G-27 | No Lab 2 frame for Edit profile (target of the Profile primary action) | Profile owner | Resolved (Edit Profile frame received 2026-10-28, DC-14) |
| G-28 | Profile "Settings & Support" rows (Notification preferences, Language, Help & Support) have no target screens | Profile owner | Assumed (honest coming-soon message, DC-17) |
| G-30 | Edit Profile and Update Preferences frames ask twice for a city and for a target role | Profile owner | Resolved (user decision 2026-10-28) |
| G-29 | Edit Profile `Change Photo` / `Remove` (JPG, PNG ≤ 5 MB) has no storage path: `storage.rules` allows only PDFs in `cvs/` and `reports/` | Profile owner | Resolved for now (Google photo only, user decision; DC-14) |

---

## Details

### G-01: Flutter handoff file missing
- **Found:** the Lab 2 README says per-screen handoff "will be added in `handoff/flutter-handoff.md`"; `handoff/` only contains `.gitkeep`.
- **Handling:** tokens and components are consolidated in [`design-system.md`](../design/design-system.md). Screen content, states and flows come from `screen-spec.md` and `user-flow.md`. Per-screen layout must be read from Figma page 03 by each screen owner.

### G-02: Product name
- **Found:** Lab 2 calls the product "Internship Finder"; the Lab 3 brief calls it "Internly".
- **Assumption:** app and package name are **Internly** (`internly`, title "Internly"). Lab 2 docs keep the old name (read-only snapshot).

### G-03: Login screen
- **Found:** Lab 3 requires Google Sign-In and "signed-out users can access only Login", but Lab 2's 11 screens include no Login or onboarding.
- **Handling:** an interim Login screen built only from existing tokens and components (`features/auth/screens/login_screen.dart`, logged as DC-01). It supports loading and error states. The auth owner designs the final version and records it in the change log.

### G-04: Notification Center
- **Found:** not in the Lab 2 screen inventory. The only hint is a bell action in the Home app bar (Stitch final) and the App Bar "Main" specimen with a notification action (Figma 05).
- **Needed:** list layout, empty/error states, read/unread treatment, and navigation target per notification type. Build it from existing components and log it in the change log.

### G-05: PDF report export
- **Found:** not in Lab 2 (no screen, entry point or report content).
- **Needed:** entry point (e.g. My Applications app bar action or Profile → Settings), report content (built from real user data, e.g. the applications list with statuses), branding, and a "View report" action. Upload and metadata must follow G-12. Never save a placeholder URL as a real result.

### G-06: Remote Config display and Crashlytics controls
- **Found:** Lab 3 requires displaying current Remote Config values, a handled-exception demo and an explicit test-crash control. Lab 2 has no place for them.
- **Proposal:** a "Diagnostics" group in Profile → "Settings & Support" (the Stitch Profile final already has this section). Never trigger a crash at startup.

### G-07: Values not documented in the handoff
Values below are **estimated from the Figma screenshots** or left at Material defaults. Verify each in Figma inspect mode and update the code and [`design-system.md`](../design/design-system.md).

| Value | Current | Where |
|---|---|---|
| Pressed state opacity ("reduced emphasis") | 0.7 | `AppTheme.pressedOpacity` |
| App Bar "Main" title style | `type/heading/large` | `AppTopBar.main` |
| Error State icon size | 32 dp | `StateView._errorIconSize` |
| Internship Card inner gaps, tag text style | 4/8 dp, `type/caption` | `InternshipCard`, `AppTag` |
| Status badge padding | 8 × 4 dp | `StatusBadge` |
| Dialog inner padding | 24 dp | `AppDialog` |
| Helper colors: inverse surface (SnackBar) | Material default (`onSurface`) | `AppTheme` |
| Shadow of plain `AlertDialog` / bottom sheet | Material elevation | use `AppDialog` for exact `elevation/2` |
| Profile header avatar | 56 dp | `AppSizes.profileHeaderAvatar` (Profile screenshot) |
| CV file / sheet header icon tile | 40 dp, `primaryContainer`, radius 12 | `AppSizes.fileTile`, `FileTileIcon` (Profile screenshots) |
| Edit profile photo | 80 dp | `AppSizes.editProfileAvatar` (Edit Profile frame) |

### G-08: Main entity for CRUD
- **Resolved (2026-10-21):** this requirement came from the initialization brief, not from the Lab 3 handout, which does not require CRUD of a main entity. The application record still gets create / update / delete naturally if students track their own statuses (G-25 point 6). The notes below are kept for history.
- **Found:** the initialization brief required create / read / update / delete for "the main entity". Lab 2 flows only **create** an application (submit) and **withdraw** it (with Undo).
- **Options:**
  1. *Application*: create = submit; update = withdraw/undo, or edit the short introduction while status is Submitted (needs design); delete = remove a withdrawn application (needs design).
  2. *Profile*: create on first sign-in, edit in Profile, delete = remove CV or reset profile.
  3. *Saved internship*: create = save, delete = unsave; no meaningful update.
- **Needs:** team decision checked against the Lab 3 specification (G-09). Any new UI goes to the change log.

### G-09: Lab 3 specification
- **Resolved (2026-10-21):** the handout "PRM393 — Lab 3: Cloud-Enabled Mobile App (Firebase, Google ARTEMIS, AI Code Review)" was received. Its required files are `docs/design-traceability.md`, `architecture.md`, `analytics-plan.md`, `test-plan.md`, `code-review.md`, `e2e_test/`, `firebase/storage.rules`, `firebase/remote-config-defaults.json` and `evidence/`. User decisions on it: keep the repository name, submit the report and slides separately, video link in README later, SerpAPI data (G-25), zero cost (G-26), keep the new flows (DC-08/09), ARTEMIS. It names E2E testing with **Google ARTEMIS** (the PDF footer says "Patrol"; the body and rubric say ARTEMIS, which we use).

### G-10: Application status changes
- **Found:** statuses Under review, Interview, Accepted and Rejected exist, but Lab 2 has no employer or admin side to set them.
- **Resolved (2026-10-21):** with SerpAPI listings there is no employer side, so students track their own statuses (G-25 point 6). The final Firestore rules allow owners to write anything under `users/{uid}`.
- **Options:** update statuses from the Firebase console or an Admin SDK script for demos, or add a Cloud Function (requires the Blaze plan).

### G-11: Remote Config parameters
- **Required:** at least two parameters, with in-app defaults, that change real behavior, and their current values displayed (G-06).
- **Assumed:** `home_recommended_limit` (number, default 5: cards in "Recommended for you") and `cv_match_enabled` (boolean, default true: feature flag for the CV Match Check step), matching the handout's examples ("max items", "a feature flag for a screen"). Defaults live in `firebase/remote-config-defaults.json`; key constants in `RemoteConfigKeys`. The owning features must use them so the change is visible.

### G-12: File storage and privacy
- **Lab 3 requires Cloud Storage:** files under a per-user path (`reports/{uid}/…`), progress and URL shown, and `storage.rules` that restrict each user to their own folder (`firebase/storage.rules` is ready). Cloudinary would only be an equivalent if the lecturer approves it.
- **Cost:** by Firebase's announcement, new Storage buckets need the **Blaze** plan, which requires a billing account (card) even at $0.
- **Decision (user, 2026-10-21, final):** use **Cloud Storage for Firebase on the Blaze plan** and keep usage inside the no-cost quota. (Cloudinary was implemented first and then dropped, because the handout grades Cloud Storage with `storage.rules`.)
- **Checked facts:** since 2026-02-03 Cloud Storage for Firebase needs Blaze; there is no card-free Storage plan (the only card-free path is Google Cloud education credits from the lecturer). Google Cloud **budgets only send alerts; they do not cap spending**. A hard cap needs a self-built Pub/Sub function that unlinks billing, which lags behind real spend and shuts down every service in the project, so it is not used.
- **How it stays at $0:**
  1. Create the bucket in `US-CENTRAL1`, `US-EAST1` or `US-WEST1` (only these get the Always Free tier; other regions are billed from the first byte).
  2. Deploy `firebase/storage.rules`: owner-only folders `reports/{uid}` and `cvs/{uid}`, PDF only, ≤ 10 MB. `FirebaseStorageService` runs the same checks before uploading.
  3. Budget of $1 with alerts at 50 / 90 / 100 %.
  4. Enable no other paid service; unlink billing after grading.
- **Found:** Flow 2a (Lab 2 Flow 1a) uploads a CV (PDF). Lab 3 requires uploading a PDF report and storing its URL, file name, owner UID and timestamp. New Firebase Storage buckets need the Blaze plan; the brief suggests Cloudinary.
- **Risk (historical):** Cloudinary unsigned uploads would have produced public URLs for files with personal data; Firebase download URLs are unguessable tokens and uploads are rules-protected.
- **Needed (historical):** choose the provider. If Cloudinary: a dedicated unsigned preset restricted to PDF, a folder per purpose, client-side size limit (verify which server-side limits the preset can enforce), no API secret in the app, and a documented privacy trade-off. Alternatively, signed uploads via a backend.

### G-13: Notification data source
- **Found:** FCM needs a sender (Firebase console for demos, or a backend). The Notification Center needs history, but no backend is planned.
- **Options:** the client stores received messages in `users/{uid}/notifications` (foreground, opened-app and background handlers), or a server writes them. Also decide where FCM tokens are stored.

### G-14: Seed data
- **Resolved:** listings come from SerpAPI Google Jobs at request time (user decision, 2026-10-21); nothing is seeded. The notes below are kept for history.
- **Found:** listings are read-only for clients, so the app cannot create them.
- **Needed:** a seeding path (Firebase console import, or a local Admin SDK script run with `gcloud auth application-default login`, never a committed service-account key) and a demo data set. Per the Lab 2 AI log, demo listings must not be presented as real, verified vacancies.

### G-15: iOS in scope
- **Found:** Lab 2 targets Android (360–412 dp, Material). The team asked for an Android + iOS repository.
- **Resolution:** iOS uses the same Material design, with no Cupertino adaptation (DC-07). iOS-specific setup (Google Sign-In URL scheme, APNs for FCM, which needs a paid Apple Developer account) is in [`firebase-setup.md`](../guides/firebase-setup.md).

### G-16: Figma access
- **Found:** Figma pages 04 and 05 were provided as screenshots; inspect values (paddings, exact sizes) are not available offline. The README lists 31 components, but page 05 shows 12 sets. Missing specs: Save Toggle, Skill Tag, Badge, Snackbar, Info Banner, Text Area, Upload Dropzone, Bottom Sheet Option Row, Job Summary Card, CV File Card, Upload Progress Card, Match Card, Map Preview Card, Progress Stepper, Meta Tile, Section Header, Bullet Item, Benefit Item, Review Row.
- **Action:** export pages 03–05 (PNG) into `docs/design/figma/`, and read component specs in Figma before building each one.

### G-17: Allowance format
- **Found:** the Figma card specimen shows `$1,200/month`. The Stitch Home final shows `12,000,000 VND / mo`, the Internship Detail prompt says `8–12M VND/month`, and the AI log standardised allowances to VND. Unpaid and undisclosed allowances must be distinguishable.
- **Handling:** `InternshipCard` takes a preformatted `allowanceText`. The feature owner picks one VND format and uses it everywhere.
- **Found (2026-10-28):** none of the 322 synced listings has `detected_extensions.salary`: Google Jobs does not structure pay for Vietnamese listings, so every card showed "Not disclosed". The pay is only written in the description: 74 listings give an amount, 70 say "Thỏa thuận", 50 are vague ("Attractive allowance"), 128 say nothing.
- **Resolved (2026-10-28):** `allowanceFromText` (`lib/core/utils/allowance.dart`) reads the description when Google gives no salary. Format, used everywhere: `12,000,000 VND / mo`; ranges `2,000,000–3,000,000 VND / mo`; qualifiers `Up to` / `From` / `About` when the text says so; ` / mo` only when the text says monthly; `$500 / mo` for USD; `Negotiable` for "Thỏa thuận" / "negotiable". Vague text and other allowances (meal, lunch, parking, home office…) are ignored, and amounts outside 100,000–200,000,000 VND (or 50–10,000 USD) are rejected, so "Lương tháng 13" or "100% salary" never become pay. Result on the 2026-10-28 pool: 73 amounts, 70 negotiable, 179 not disclosed.

### G-18: Withdrawn badge
- **Found:** Flow 3d sets the status to Withdrawn, but Figma 05 "Application Status" has only five specimens (Submitted, Under review, Interview, Accepted, Rejected).
- **Needed:** icon and color for Withdrawn (likely the neutral treatment). Check the Application Detail "withdrawn" frame on Figma page 03.

### G-19: Contrast failures
- **Found (computed):** Rejected badge `#DC2626` on `#F1F5F9` = 4.41:1; selected filter chip `#2563EB` on `#DBEAFE` = 4.24:1. Both are below the 4.5:1 that DESIGN.md §13 requires for 14 sp text. Details in [`design-system.md` §3](../design/design-system.md#3-contrast-check-computed).
- **Proposals:** DC-04 and DC-05 in the change log (status: proposed, not applied).

### G-20: iOS dependency resolution
- **Found (2026-10-21, `flutter build ios --simulator`):** with Swift Package Manager, `firebase-ios-sdk` 13.0.0 (FlutterFire 7.x) requires `gtm-session-fetcher` 4.x–5.x, while `GoogleSignIn-iOS` 9.x (`google_sign_in_ios` 6.3.8, the latest) requires 3.x. Resolution fails.
- **Resolution:** SPM is disabled for this project (`flutter: config: enable-swift-package-manager: false` in `pubspec.yaml`), so iOS uses CocoaPods. On the CocoaPods path, FlutterFire pins **Firebase iOS SDK 12.19.0** (`firebase_core/ios/firebase_sdk_version.rb`), which resolves with **GoogleSignIn 9.2.0** and **GTMSessionFetcher 3.5.0** (`ios/Podfile.lock`). `flutter build ios --simulator --debug` then succeeds ([`test-report.md`](test-report.md)). Revisit when `google_sign_in_ios` moves to GoogleSignIn-iOS 10+, or if CocoaPods support is dropped upstream.

### G-21: Identifiers and repository naming
- **Assumption:** Android `applicationId` and iOS bundle ID are `com.group3.internly`. Change them **before** registering the apps in Firebase if the team prefers another ID.
- **Resolved (user decision):** the repository stays `lamtailoi2/prm323_lab3`, although the handout asks for `PRM393_Lab03_<StudentID>`. The report and slides are submitted separately (not in the repository).

### G-22: Keyword search
- **Resolved:** SerpAPI performs the search (`q` with the keyword plus "internship", `location`, work-from-home filter). Check the current SerpAPI Google Jobs parameters when implementing.
- **Found:** Search matches "internships, companies, or skills"; Firestore has no full-text search.
- **Options:** query by filters (skills `array-contains-any`, work mode, city) and filter keywords client-side; store normalized `searchKeywords` arrays; or use an external search service (out of scope).

### G-23: Recommendation logic
- **Found:** Home shows "Recommended for you" (and Internship Detail shows a "% profile match" in the AI log), but no rule is specified.
- **Resolved (2026-10-22):** Home ranks the synced pool by the SerpAPI result position (`searchRank`, lower is more relevant) and then by posting date, capped by Remote Config `home_recommended_limit`. No profile matching and no invented percentage are shown in this slice. Profile-aware ranking remains a future decision that must share its code with CV Match Check (G-24).

### G-24: CV Match Check
- **Found (2026-10-21):** the team restructured the flows to Search → Apply → Track (DC-08) and added a CV Match Check step to Apply (DC-09): show which requirements the CV / profile does not match and suggest improvements. Lab 2 has no screen for it; the closest existing parts are the "Your match" card in Internship Detail (AI log) and the "Match Card" component in Figma.
- **Decided so far:** the step sits between Application Form and Application Review; it never blocks applying (`Continue to review` always available); suggestions are honest (never ask the student to claim skills they lack); status per requirement uses label + icon (see `user-flow.md` Flow 2d and `screen-spec.md` › CV Match Check).
- **Open:**
  1. **Matching rules.** Baseline proposal: compare the internship's `skills` and "Must have" items with the profile / form skills, case-insensitively, with a small synonym list (e.g. "REST" ↔ "REST API"). "Nice to have" items are informational only.
  2. **CV content.** Whether to read text from the CV PDF (on-device extraction) or rely on declared skills only. Reading the PDF adds a dependency and accuracy limits.
  3. **AI-generated suggestions.** If an LLM is used, it must run behind a backend you control: no API keys in the app (AGENTS.md rule 8), and the user must be told that CV text leaves the device.
  4. **Design.** Figma frame for the screen (states: checking, all matched, gaps, failed), built from existing components (Match Card, Skill Tag, Bullet Item, Info Banner).

### G-25: SerpAPI (Google Jobs) as the data source
- **Decision (user, 2026-10-21):** internship listings come from SerpAPI's `google_jobs` engine. Lab 3 requires real data and no mocks.
- **Updated (2026-10-22):** a scheduled Cloud Function (`functions/src/sync.ts`) mirrors SerpAPI into the shared `/internships/{jobKey}` Firestore collection every 6 hours. The app reads only Firestore, so the key never ships in the APK and the quota is shared by all users.
- **Consequences to handle in the features:**
  1. **API key location.** `SERPAPI_KEY` lives in Secret Manager and is attached only to the scheduled function. Rotate it in the console/CLI and redeploy; the app needs no update. Never put it in `.env`, the repository or a client build.
  2. **Quota.** The free plan allows 250 searches/month (checked 2026-10-22). The first sync backfills five keywords (5 searches), then each 6-hour run refreshes one keyword (about 120/month), so the first month is about 125 searches. If the quota runs out, `sync/state.lastError` records it and the app keeps the last good pool until documents expire after 7 days.
  3. **Coverage in Vietnam.** Google Jobs needs a location; the same query with no `location` returned zero in testing. The sync uses `location=Vietnam` and five proven queries: `IT internship Vietnam`, `thực tập IT`, `thực tập backend`, `thực tập data`, `thực tập tester` (40 distinct jobs in the 2026-10-22 run). `thực tập mobile` and `thực tập devops` returned nothing and are not queried. The app filters the nationwide pool by the listing's stored `location` (Ho Chi Minh City, Hanoi, …); this is the future Search location filter, not a sync parameter. “Hasn't returned any results” is treated as an empty page, not a failed run.
  4. **IDs.** `job_id` is long and may contain `/`. Both the function and the app derive the same 16-hex FNV-1a key (`jobKeyFor`) for Firestore document IDs, routes and analytics (≤ 100 characters).
  5. **Listings expire.** The function sets `expiresAt` to 7 days after a listing is last seen and deletes expired documents; the app query excludes them. Saved items and applications still store a snapshot of the fields they display.
  6. **Applying is external.** Google Jobs gives `apply_options` links to employer sites; the app cannot submit to the employer. Proposal: Flow 2 ends by recording the application in Firestore (the student's own tracking record) and offering the employer's apply link. Statuses (Under review, Interview, …) are then **updated by the student**, which also gives the main entity its update and delete (G-08, G-10). Record the UI change as DC-10.
  7. **Missing fields.** Salary, company size, logo and office location are often absent: show "Not disclosed" or hide the row; the Map Preview Card cannot be built (DC-10). Salary is read from the description when the text states it (G-17).
  8. **CV Match Check input:** `job_highlights` (Qualifications) and the description text vs the profile skills (G-24).

### G-26: Zero-cost plan
The user wants **no spending at all**, including AI models. Every requirement can be met at $0:

| Need | $0 option | Limits / notes |
|---|---|---|
| Firebase Auth, Firestore, FCM, Analytics, Crashlytics, Remote Config | Spark (free) plan | Free quotas are far above lab usage |
| File storage | **Cloud Storage for Firebase on Blaze**, bucket in `US-CENTRAL1` / `US-EAST1` / `US-WEST1` (Always Free tier), $1 budget alert (G-12) | Card required; budget alerts do not cap spending |
| Scheduled internship sync | **Cloud Functions (2nd gen) + Cloud Scheduler on the same Blaze plan**, 1 job every 6 hours, 5 searches on the first run (G-25) | Card required (already for Storage); free monthly invocations far exceed this job; `retryCount: 0` avoids quota doubles |
| Internship data | SerpAPI free plan (no card) | Small monthly quota (G-25) |
| ARTEMIS | Open source (Apache 2.0) | — |
| ARTEMIS model | Gemini API key from Google AI Studio **without enabling billing** (free tier). ARTEMIS's default config already uses Gemini models | Rate limits (slower runs); free-tier prompts may be used by Google to improve its products, so use only test data. If a configured model is not available on the free tier, switch that node to a free Flash / Flash-Lite model in `config/artemis.jsonc`. A local Ollama preset exists but is weaker (the Pro explorer expects Gemini models) |
| Android device | Own phone or the Android Emulator | — |
| AI code review | A free tool such as Gemini Code Assist on GitHub (free for individuals), or CodeRabbit / SonarCloud if the repository is made public | Check each tool's current free terms before use |
| iOS push (APNs) | Not needed: Lab 3 grades Android only | Apple Developer Program would cost money; skip iOS push |

### G-27: Edit profile has no frame
- **Found (2026-10-28):** `Edit Profile` is the primary action of the Lab 2 Profile frame, and Flow 2b/2d send students to Profile to fill in missing data, but Lab 2 had no Edit profile frame (only the Edit Skills, Update Preferences and Update CV sheets).
- **Resolved (2026-10-28):** the design owner provided an Edit Profile frame (photo; "Academic & Personal Details": Full Name *, Headline / Target Role *, University / Institution, Major / Degree Program, Academic Standing & Graduation; "Contact & Location": University Email (locked), Phone Number, Location / Current City, Short Bio / Introduction 0/300; a "VNU V-Career Sync" banner; `Save Changes` / `Cancel`). The app follows it with the differences listed in DC-14. `/profile/edit` keeps the root navigator (no bottom navigation), like the Apply forms.
- **Still open:** the picker behind "Academic Standing & Graduation" is not drawn. The app uses a sheet with Filter Chips: year of study 1–6, and graduation years in one horizontally scrolling row from this year to this year + 8 (six years of study plus two for delays; a stored earlier year is kept), scrolled to the stored year on open.

### G-28: Settings rows without a destination
- **Found (2026-10-28):** the Lab 2 Profile frame lists Notification Preferences, Language (`Tiếng Việt · EN`) and Help & Support, but no screen, content or behaviour is designed for them; the app is English only.
- **Assumed:** the rows stay, as designed, and each shows an honest SnackBar (`… are coming soon.`, `Internly is available in English only for now.`); Language shows `English`. Recorded as DC-17. Notification preferences is the natural entry point for the Notification Center (G-04); the Firebase demo area (G-06) can be added to the same list.

### G-29: Profile photo upload
- **Found (2026-10-28):** the Edit Profile frame has `Change Photo` / `Remove` ("JPG, PNG up to 5MB"). `firebase/storage.rules` only allows PDFs under `cvs/{uid}` and `reports/{uid}` (AGENTS.md rule 9), and `FileStorageService` only uploads PDFs.
- **Decision (user, 2026-10-28):** show the Google account photo only, without `Change Photo` / `Remove`, so no rules change is needed (DC-14).
- **If revisited:** add an owner-only `avatars/{uid}/…` path (image/jpeg or image/png, ≤ 5 MB) in a PR that tags the rules owner, an image upload in `FileStorageService`, and a `photoUrl` field in `users/{uid}` that Home and Profile read before the Google photo.

### G-30: Duplicate profile fields
- **Found (2026-10-28, review of the Profile screen):** the Edit Profile frame has "Location / Current City" and "Headline / Target Role"; the Update Preferences frame has "Location" and "Target roles". Students would type a city twice and state a target role twice; `city` and `headline` were also saved without being shown on Profile.
- **Decision (user, 2026-10-28):** keep both city fields (where the student lives vs where they want an internship) and prefill an empty preferences Location from the current city; rename "Headline / Target Role" to "Headline", keep target roles only in Update preferences, and show the headline under the name on Profile (DC-14, DC-15, DC-16).
- **Still not shown on Profile:** graduation year, current city and bio (stored for Apply prefill; the Lab 2 Profile frame has no place for them).

