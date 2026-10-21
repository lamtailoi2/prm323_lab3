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
| G-04 | No Notification Center screen in Lab 2 | Notifications owner | Open |
| G-05 | No PDF report export in Lab 2 | Report owner | Open |
| G-06 | No place in the UI for Remote Config values and Crashlytics test controls | Profile owner | Open |
| G-07 | Component values not documented (estimated from screenshots) | Design owner | Open (verify in Figma) |
| G-08 | Main entity for the Lab 3 CRUD requirement not defined | Team + lecturer | Open (blocks MobAI scenario 6) |
| G-09 | Lab 3 specification document not in the repository | Team | Open |
| G-10 | Nobody can change an application's status (no employer side) | Applications owner | Open |
| G-11 | Remote Config parameters not chosen | Profile owner | Open |
| G-12 | CV / PDF storage provider and privacy of uploaded files | Team | Open |
| G-13 | Notification data source (who sends FCM, where history is stored) | Notifications owner | Open |
| G-14 | No seed / demo data for internship listings | Search owner | Open |
| G-15 | iOS added to scope; Lab 2 designed for Android only | Team | Resolved (Material on both) |
| G-16 | Figma pages available only as screenshots; 19 of 31 components not covered | Design owner | Open |
| G-17 | Allowance format: `$1,200/month` (Figma) vs VND per month (Stitch / AI log) | Home / Search owner | Open |
| G-18 | No "Withdrawn" status badge specimen | Applications owner | Open |
| G-19 | Two Figma color pairs fail WCAG AA contrast | Design owner | Open (proposals DC-04, DC-05) |
| G-20 | iOS: SPM cannot resolve Firebase 13 + GoogleSignIn 9 | Tech lead | Resolved (CocoaPods; see note) |
| G-21 | App ID / bundle ID and repository naming not confirmed | Team + lecturer | Assumed |
| G-22 | Keyword search strategy (Firestore has no full-text search) | Search owner | Open |
| G-23 | "Recommended for you" logic not specified | Home owner | Open |

---

## Details

### G-01: Flutter handoff file missing
- **Found:** the Lab 2 README says per-screen handoff "will be added in `handoff/flutter-handoff.md`"; `handoff/` only contains `.gitkeep`.
- **Handling:** tokens and components are consolidated in [`design-system.md`](lab2-handoff/design/design-system.md). Screen content, states and flows come from `screen-spec.md` and `user-flow.md`. Per-screen layout must be read from Figma page 03 by each screen owner.

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
Values below are **estimated from the Figma screenshots** or left at Material defaults. Verify each in Figma inspect mode and update the code and [`design-system.md`](lab2-handoff/design/design-system.md).

| Value | Current | Where |
|---|---|---|
| Pressed state opacity ("reduced emphasis") | 0.7 | `AppTheme.pressedOpacity` |
| Text button default fill | `surface` | `AppTheme` text button style |
| App Bar "Main" title style | `type/heading/large` | `AppTopBar.main` |
| Error State icon size | 32 dp | `StateView._errorIconSize` |
| Internship Card inner gaps, tag text style | 4/8 dp, `type/caption` | `InternshipCard`, `AppTag` |
| Status badge padding | 8 × 4 dp | `StatusBadge` |
| Dialog inner padding | 24 dp | `AppDialog` |
| Helper colors: inverse surface (SnackBar) | Material default (`onSurface`) | `AppTheme` |
| Shadow of plain `AlertDialog` / bottom sheet | Material elevation | use `AppDialog` for exact `elevation/2` |

### G-08: Main entity for CRUD
- **Found:** Lab 3 requires create / read / update / delete for "the main entity" and MobAI scenario 6 ("create, edit and delete the main entity"). Lab 2 flows only **create** an application (submit) and **withdraw** it (with Undo). There is no edit or delete.
- **Options:**
  1. *Application*: create = submit; update = withdraw/undo, or edit the short introduction while status is Submitted (needs design); delete = remove a withdrawn application (needs design).
  2. *Profile*: create on first sign-in, edit in Profile, delete = remove CV or reset profile.
  3. *Saved internship*: create = save, delete = unsave; no meaningful update.
- **Needs:** team decision checked against the Lab 3 specification (G-09). Any new UI goes to the change log.

### G-09: Lab 3 specification
- **Found:** only the task brief is available; the official Lab 3 assignment (grading rubric, naming rules, the "main entity" definition) is not in the repository.
- **Action:** add it (or a link) to `docs/` and re-check G-08, G-11 and G-21 against it.

### G-10: Application status changes
- **Found:** statuses Under review, Interview, Accepted and Rejected exist, but Lab 2 has no employer or admin side to set them.
- **Constraint:** security rules must not let a student set these statuses. Students may only create with `submitted` and toggle withdraw/undo.
- **Options:** update statuses from the Firebase console or an Admin SDK script for demos, or add a Cloud Function (requires the Blaze plan).

### G-11: Remote Config parameters
- **Required:** at least two parameters, with in-app defaults, that change real behavior, and their current values displayed (G-06).
- **Proposal (not implemented):** `home_recommended_limit` (int, number of cards in "Recommended for you") and `application_withdraw_enabled` (bool; screen-spec says "Withdraw application if allowed"). Defaults belong in `RemoteConfigDefaults.values`.

### G-12: File storage and privacy
- **Found:** Lab 2 Flow 1a uploads a CV (PDF). Lab 3 requires uploading a PDF report and storing its URL, file name, owner UID and timestamp. New Firebase Storage buckets need the Blaze plan; the brief suggests Cloudinary.
- **Risk:** Cloudinary *unsigned* uploads produce publicly reachable URLs. CVs and reports contain personal data (name, phone, email).
- **Needed:** choose the provider. If Cloudinary: a dedicated unsigned preset restricted to PDF, a folder per purpose, client-side size limit (verify which server-side limits the preset can enforce), no API secret in the app, and a documented privacy trade-off. Alternatively, signed uploads via a backend.

### G-13: Notification data source
- **Found:** FCM needs a sender (Firebase console for demos, or a backend). The Notification Center needs history, but no backend is planned.
- **Options:** the client stores received messages in `users/{uid}/notifications` (foreground, opened-app and background handlers), or a server writes them. Also decide where FCM tokens are stored.

### G-14: Seed data
- **Found:** listings are read-only for clients, so the app cannot create them.
- **Needed:** a seeding path (Firebase console import, or a local Admin SDK script run with `gcloud auth application-default login`, never a committed service-account key) and a demo data set. Per the Lab 2 AI log, demo listings must not be presented as real, verified vacancies.

### G-15: iOS in scope
- **Found:** Lab 2 targets Android (360–412 dp, Material). The team asked for an Android + iOS repository.
- **Resolution:** iOS uses the same Material design, with no Cupertino adaptation (DC-07). iOS-specific setup (Google Sign-In URL scheme, APNs for FCM, which needs a paid Apple Developer account) is in [`firebase-setup.md`](firebase-setup.md).

### G-16: Figma access
- **Found:** Figma pages 04 and 05 were provided as screenshots; inspect values (paddings, exact sizes) are not available offline. The README lists 31 components, but page 05 shows 12 sets. Missing specs: Save Toggle, Skill Tag, Badge, Snackbar, Info Banner, Text Area, Upload Dropzone, Bottom Sheet Option Row, Job Summary Card, CV File Card, Upload Progress Card, Match Card, Map Preview Card, Progress Stepper, Meta Tile, Section Header, Bullet Item, Benefit Item, Review Row.
- **Action:** export pages 03–05 (PNG) into `docs/lab2-handoff/figma/`, and read component specs in Figma before building each one.

### G-17: Allowance format
- **Found:** the Figma card specimen shows `$1,200/month`. The Stitch Home final shows `12,000,000 VND / mo`, the Internship Detail prompt says `8–12M VND/month`, and the AI log standardised allowances to VND. Unpaid and undisclosed allowances must be distinguishable.
- **Handling:** `InternshipCard` takes a preformatted `allowanceText`. The feature owner picks one VND format and uses it everywhere.

### G-18: Withdrawn badge
- **Found:** Flow 3d sets the status to Withdrawn, but Figma 05 "Application Status" has only five specimens (Submitted, Under review, Interview, Accepted, Rejected).
- **Needed:** icon and color for Withdrawn (likely the neutral treatment). Check the Application Detail "withdrawn" frame on Figma page 03.

### G-19: Contrast failures
- **Found (computed):** Rejected badge `#DC2626` on `#F1F5F9` = 4.41:1; selected filter chip `#2563EB` on `#DBEAFE` = 4.24:1. Both are below the 4.5:1 that DESIGN.md §13 requires for 14 sp text. Details in [`design-system.md` §3](lab2-handoff/design/design-system.md#3-contrast-check-computed).
- **Proposals:** DC-04 and DC-05 in the change log (status: proposed, not applied).

### G-20: iOS dependency resolution
- **Found (2026-10-21, `flutter build ios --simulator`):** with Swift Package Manager, `firebase-ios-sdk` 13.0.0 (FlutterFire 7.x) requires `gtm-session-fetcher` 4.x–5.x, while `GoogleSignIn-iOS` 9.x (`google_sign_in_ios` 6.3.8, the latest) requires 3.x. Resolution fails.
- **Resolution:** SPM is disabled for this project (`flutter: config: enable-swift-package-manager: false` in `pubspec.yaml`), so iOS uses CocoaPods. On the CocoaPods path, FlutterFire pins **Firebase iOS SDK 12.19.0** (`firebase_core/ios/firebase_sdk_version.rb`), which resolves with **GoogleSignIn 9.2.0** and **GTMSessionFetcher 3.5.0** (`ios/Podfile.lock`). `flutter build ios --simulator --debug` then succeeds ([`test-report.md`](test-report.md)). Revisit when `google_sign_in_ios` moves to GoogleSignIn-iOS 10+, or if CocoaPods support is dropped upstream.

### G-21: Identifiers and repository naming
- **Assumption:** Android `applicationId` and iOS bundle ID are `com.group3.internly`. Change them **before** registering the apps in Firebase if the team prefers another ID.
- **Open:** the brief says "PRM393 Lab 3", while the Lab 2 repository and folders use "prm323". Check the lecturer's required repository name before creating the GitHub repository.

### G-22: Keyword search
- **Found:** Search matches "internships, companies, or skills"; Firestore has no full-text search.
- **Options:** query by filters (skills `array-contains-any`, work mode, city) and filter keywords client-side; store normalized `searchKeywords` arrays; or use an external search service (out of scope).

### G-23: Recommendation logic
- **Found:** Home shows "Recommended for you" (and Internship Detail shows a "% profile match" in the AI log), but no rule is specified.
- **Proposal:** match listing skills against profile skills and preferred work modes, computed client-side, with no invented percentages shown until the rule is agreed.
