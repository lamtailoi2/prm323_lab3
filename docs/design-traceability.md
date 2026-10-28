# Design traceability

Maps every Lab 2 screen, flow and component to its Flutter route, widget and data source, with status, and records **every deviation from the design with its reason** (Lab 3 §3, §4 stage 1, §9). Written before feature work. Each feature PR updates its rows.

Sources: [`design/screen-spec.md`](design/screen-spec.md), [`design/user-flow.md`](design/user-flow.md), [`design/design-system.md`](design/design-system.md), Figma <https://www.figma.com/design/UQveNSgQNYbuZyaNMa57FQ/Internship-Finder---Design-System>.

**Status:** ✅ Done · 🟡 Placeholder / interim · ⬜ Planned · ⚠️ Deviation (see §4).

Routes marked *planned* are the agreed proposal. An owner who changes one updates this table in the same PR.

## 1. Screens

| # | Lab 2 screen | Route | Flutter widget | Data source | Owner | Status |
|---|---|---|---|---|---|---|
| — | Login *(frame received 2026-10-28, G-03)* | `/login` | `LoginScreen` (+ `GoogleSignInButton`) | Firebase Auth (Google) | Auth | ✅ ⚠️ DC-18 |
| 1 | Home | `/home` | `HomeScreen` | Shared Firestore pool `/internships` (synced from SerpAPI every 6h): `searchRank` + `postedAt`, role filter, Recommended limited to the Profile preferred location (`users/{uid}`, G-23), Remote Config `home_recommended_limit` / `home_recent_limit`; allowance from `detected_extensions.salary` or the description (G-17) | Home | ✅ UI · 🟡 save/bell pending |
| 2 | Search | `/search` | `SearchScreen` | — (query input, filter sheet) | Search | 🟡 placeholder |
| 3 | Search Results | `/search/results` *(planned)* | `SearchResultsScreen` | Shared Firestore pool `/internships` (synced from SerpAPI) | Search | ⬜ |
| 4 | Internship Detail | `/{tab}/internships/:jobKey` *(planned)* | `InternshipDetailScreen` | Firestore `/internships/{jobKey}` + `users/{uid}/savedInternships`, `…/applications` (saved / applied state) | Search | ⬜ ⚠️ DC-10 |
| 5 | Saved Internships | `/saved` | `SavedScreen` | Firestore `users/{uid}/savedInternships` (real-time listener) | Saved | 🟡 placeholder |
| 6 | Application Form | `/apply/:jobKey` *(planned, root navigator: no bottom nav)* | `ApplicationFormScreen` | Firestore `users/{uid}` (prefill), Cloud Storage `cvs/{uid}/…` (`FileStorageService`) | Apply | ⬜ |
| 7 | CV Match Check *(Lab 3)* | `/apply/:jobKey/match` *(planned)* | `CvMatchScreen` | Listing qualifications (`/internships/{jobKey}`) vs profile skills; Remote Config `cv_match_enabled` | Apply | ⬜ ⚠️ DC-09 |
| 8 | Application Review | `/apply/:jobKey/review` *(planned)* | `ApplicationReviewScreen` | In-memory form state | Apply | ⬜ |
| 9 | Application Success | `/apply/:jobKey/success` *(planned)* | `ApplicationSuccessScreen` | Firestore write result | Apply | ⬜ |
| 10 | My Applications | `/applications` | `MyApplicationsScreen` | Firestore `users/{uid}/applications` (real-time, sorted by date) | Track | 🟡 placeholder |
| 11 | Application Detail | `/applications/:jobKey` *(planned)* | `ApplicationDetailScreen` | Firestore application document | Track | ⬜ |
| 12 | Profile | `/profile` | `ProfileScreen` (+ sheets `EditSkillsSheet`, `EditPreferencesSheet`, `UpdateCvSheet`) | Firestore `users/{uid}` (live listener: details, skills, preferences, CV metadata) + Google account (email, photo); Cloud Storage `cvs/{uid}/…` (`FileStorageService`); CV opened with `ExternalLinkService` | Profile | ✅ ⚠️ DC-14, DC-15, DC-16, DC-17 |
| — | Edit profile *(frame received 2026-10-28, G-27)* | `/profile/edit` (root navigator: no bottom nav) | `EditProfileScreen` (+ `AcademicStandingSheet`) | Firestore `users/{uid}` (merge write of the details: name, headline, university, major, year of study, graduation year, phone, city, bio); email and photo from the Google account | Profile | ✅ ⚠️ DC-14 |
| — | Firebase demo area *(Lab 3)* | `/profile/firebase` *(planned)* | `FirebaseDemoScreen` | Remote Config values, Crashlytics test actions, links to the two screens below | Profile | ⬜ (G-06) |
| — | Notification Center *(Lab 3)* | `/profile/notifications` *(planned)* | `NotificationCenterScreen` | FCM + Firestore `users/{uid}/notifications` | Notifications | ⬜ (G-04, G-13) |
| — | Report export *(Lab 3)* | `/profile/export` *(planned)* | `ReportExportScreen` | PDF from the user's applications → Cloud Storage `reports/{uid}/…` (`FileStorageService`) + Firestore metadata | Report | ⬜ (G-05) |

## 2. Flows

| Flow | Steps → routes | Alternative / error paths | E2E test | Status |
|---|---|---|---|---|
| **1 Search** | `/home` → `/search` (filter sheet) → `/search/results` → `/search/internships/:jobKey` | 1a no results → Clear filters · 1b results load error → Retry · 1c detail load error → Retry | TC-03, TC-04, TC-05 | ⬜ |
| **2 Apply** | detail → `/apply/:jobKey` → `/apply/:jobKey/match` → `/apply/:jobKey/review` → `/apply/:jobKey/success` | 2a CV upload error · 2b empty profile · 2c already applied · 2d CV gaps → improve or continue · **2e save for later**: save → `/saved` → `/saved/internships/:jobKey` → apply (2e.1 unsave + Undo, 2e.2 empty list, 2e.3 save error) | TC-06, TC-07, TC-08 | ⬜ ⚠️ DC-08, DC-09, DC-10 |
| **3 Track** | `/applications` → `/applications/:jobKey` | 3a no applications · 3b list error · 3c detail error · 3d withdraw + Undo | TC-09, TC-10 | ⬜ |
| Sign-in / sign-out | `/splash` → `/login` → `/home`; Profile → Settings & support → Sign out → `/login` | Cancelled picker shows a message; auth error message; Sign out stays reachable while the profile loads or fails | TC-01, TC-14 | ✅ |
| Profile upkeep (Flow 2 alternative: `Edit profile`, 2d `Edit skills`) | `/profile` → `/profile/edit` · Add skill / Update / Replace CV sheets | Validation errors under the fields; save / upload error + retry in place; file > 10 MB rejected before upload; discard dialog on Back with unsaved changes | TC-17 | ✅ (E2E not run) |

## 3. Components (Figma page 05 + Lab 2 README list)

| Lab 2 component | Flutter widget (file) | Variants / states as parameters | Status |
|---|---|---|---|
| Button | `AppButton` (`core/widgets/app_button.dart`) | `variant` primary / secondary / text · `onPressed: null` = disabled · `isLoading` · `icon` · `expand` | ✅ |
| Text Field / Text Area | `AppTextField` (`core/widgets/app_text_field.dart`) | `errorText`, `helperText`, `enabled`, `maxLines` / `maxLength` | ✅ |
| Search Field | `AppSearchField` | clear action, `onFilterPressed`, `readOnly` entry point | ✅ |
| Filter Chip | Flutter `FilterChip` + `ChipThemeData` | `selected` | ✅ ⚠️ DC-05 proposed |
| Internship Card + Save Toggle | `InternshipCard` | `isSaved`, `onSaveToggle`, `badge` (Applied), pressed state, Semantics summary | ✅ |
| Skill Tag | `AppTag` | `size`: `compact` (Internship Card) / `large` (Profile, 44 dp) | ✅ |
| Application Status / Badge | `StatusBadge` | `label`, `icon`, `color` (status mapping in the Applications feature) | ✅ ⚠️ DC-04 proposed |
| App Bar | `AppTopBar` | `.main` / `.back`, `actions` | ✅ |
| Bottom Navigation | `AppShell` + `NavigationBarThemeData` | 5 fixed destinations | ✅ |
| Dialog | `showAppDialog` / `AppDialog` | confirm / cancel / error via labels | ✅ |
| Loading | `StateView.loading`, `InternshipCardSkeleton`, `SkeletonBox` | labeled spinner, card skeleton | ✅ |
| Empty State | `StateView.empty` | icon, title, message, action | ✅ |
| Error State | `StateView.error` | message, icon, `onRetry` | ✅ |
| Snackbar | Flutter `SnackBar` + `SnackBarThemeData` | action (Undo) | 🟡 theme only |
| CV File Card, Upload Dropzone, Upload Progress Card, Section Header | Profile-only versions: `CvFileTile`, `UpdateCvSheet` picker area and progress, `ProfileSection` (`features/profile/widgets/`) | built from the Profile screenshots, not the Figma specs (G-16); move to `core/widgets` when Apply reuses them | 🟡 feature-local |
| Info Banner, Bottom Sheet Option Row, Job Summary Card, Match Card, Progress Stepper, Meta Tile, Bullet Item, Benefit Item, Review Row | *to be built by the owning feature from Figma specs (G-16)* | — | ⬜ |
| Map Preview Card | *not buildable from SerpAPI data (no coordinates)* | — | ⚠️ DC-10 |

Design tokens → `lib/theme/` (ThemeData, ColorScheme, TextTheme, spacing / radius / elevation constants): ✅, cross-checked against Figma 04 in [`design-system.md`](design/design-system.md).

## 4. Deviations from the Lab 2 design

Every difference between Figma and the app is listed here with its reason. Lab 3 accepts these reasons: platform constraint, accessibility failure, API limit, or a recorded team decision. **Figma must be updated** so design and app stay in sync; an unrecorded difference counts as a defect.

| ID | Date | Screen / component | Change | Reason | Status | Figma updated? |
|---|---|---|---|---|---|---|
| DC-01 | 2026-10-21 | Login (new) | Interim Login screen: "Internly" title, tagline, info/error message row, full-width Primary `Continue with Google` with loading state; tokens and components only | Lab 3 requires sign-in; Lab 2 has no Login screen (G-03) | **Replaced 2026-10-28** by the Login frame (DC-18) | n/a |
| DC-02 | 2026-10-21 | Home, Search, Saved, Applications, Profile | Placeholder screens so shell, routing and auth run before features exist | Initialization scaffolding | Temporary: replaced by each feature | n/a |
| DC-03 | 2026-10-21 | Profile (placeholder) | Sign out as a full-width Secondary button (final design: "Settings & Support" list) | Test sign-in / sign-out before Profile is built | **Removed 2026-10-28**: Sign out is the last row of Settings & support, as designed | n/a |
| DC-04 | 2026-10-21 | Application Status "Rejected" | Proposal: label in `textPrimary` with the `error` icon, or `surface` background | **Accessibility failure**: `error` on `surfaceVariant` = 4.41:1 < 4.5:1 (G-19) | Proposed | ⬜ |
| DC-05 | 2026-10-21 | Filter Chip, selected | Proposal: selected label in `textPrimary`, keep `primaryContainer` fill and check icon | **Accessibility failure**: `primary` on `primaryContainer` = 4.24:1 (G-19) | Proposed | ⬜ |
| DC-06 | 2026-10-21 | App Bar, Bottom Navigation | Follow Figma 05 over the Stitch prompt: no App Bar bottom border, no nav indicator pill | Source precedence: Figma final UI over Stitch output | Applied | ✅ matches Figma |
| DC-07 | 2026-10-21 | Whole app (iOS) | iOS uses the same Material design as Android | Team asked for Android + iOS (G-15); Lab 3 grades Android | Applied | n/a |
| DC-08 | 2026-10-21 | Flows | Flows restructured to **1 Search → 2 Apply → 3 Track**; Save becomes sub-flow 2e of Apply; branches renumbered | Team decision: saving is a step towards applying | Applied in docs | ⬜ update Figma pages 01 and 06 (prototype) |
| DC-09 | 2026-10-21 | CV Match Check (new screen in Apply) | Step between Application Form and Review: matched vs unmatched requirements, one suggestion per gap, never blocking | Team decision (G-24) | Approved | ⬜ add frames + prototype link |
| DC-10 | 2026-10-21 | Internship Detail, Apply, cards | Listings come from SerpAPI Google Jobs: fields such as allowance, company size or office location can be missing; there is no map location; applying to the employer happens on an external site | **API limit** (G-25) | Expected: each screen owner records the exact UI change here | ⬜ per screen |
| DC-11 | 2026-10-22 | Home (card Save, app-bar bell) | Both controls show an honest "coming soon" SnackBar instead of faking a saved state or opening an empty Notification Center | The Saved service and Notification Center are owned by later features; Lab 3 forbids fake success | Temporary until those features land | n/a (no visual change) |
| DC-12 | 2026-10-22 | Home (search entry) | Hint shortened to `Search internships`; the shared field still uses the full placeholder elsewhere | Team decision: the full placeholder wrapped to two lines at 360 dp and made the Home search entry taller than the design (screen-spec allows a placeholder "such as") | Applied | ⬜ update Home frame hint |
| DC-13 | 2026-10-22 | Home (Browse by Skill → Browse by Role) | The five fixed skill chips become role chips: Frontend, Backend, Full-stack, Mobile, Data/AI, Tester/QA, DevOps/Cloud, Other IT. Only roles present in the current pool are shown; non-IT listings are hidden. Skills remain as card tags. | **API/data limit**: Google Jobs has no category field, and the Lab 2 skill chips were sparse against real data (Flutter 1, NestJS 1, MongoDB 2, React 8, Python 8). The team chose an IT-only role taxonomy for discovery. | Applied | ⬜ add Home role chips frame |
| DC-14 | 2026-10-28 | Edit profile | Follows the Edit Profile frame, except: Google photo without `Change Photo` / `Remove`; no "VNU V-Career Sync" banner; no avatar in the app bar; `Email` (locked, from Google) instead of `University Email`; `Headline` instead of `Headline / Target Role`, shown under the name on Profile; Academic standing opens a picker sheet (year of study chips; graduation years this year to +8 in one scrolling row) and the field wraps; bio counter under the field | Rules allow PDFs only, user chose the Google photo (G-29); no VNU integration exists (no fake feature); an avatar on a secondary screen leads nowhere; the email is a Google address; target roles are chosen in Update preferences (G-30); the frame has no picker | Applied | ⬜ update frame |
| DC-15 | 2026-10-28 | Profile (header, CV card, sections) | No verified tick, online dot or app-bar avatar (bell only, as Home DC-11); headline under the name (G-30); skills, roles and work modes as 44 dp Skill Tags instead of icon / blue chips; `Replace CV` as a Secondary button; default badge under the file row; sentence-case titles | No data behind "verified" or "online"; display-only values use Skill Tag (DESIGN.md §10); Button has three variants; the badge wrapped at 360 dp; AGENTS.md copy rule | Applied | ⬜ update frame |
| DC-16 | 2026-10-28 | Profile sheets | Skills come from the shared `knownSkills` list (no "Tailwind CSS"), opening selection first; search placeholder wraps at 360 dp; nearest color tokens for the Selected skills box and count pill; `Clear all` as an `error` text button; empty Location prefilled from the current city (G-30); solid picker outline; `Upload CV` copy when there is no CV; "PDF, up to 10 MB" | Profile skills must match listing skills (G-23, G-24); 16 sp Search Field text; tokens only; Button has no destructive variant; Flutter has no dashed border; the 10 MB limit is enforced by `storage.rules` (G-12) | Applied | ⬜ update frames |
| DC-17 | 2026-10-28 | Profile › Settings & support | Notification preferences, Language and Help & support rows show an honest SnackBar; Language shows `English` instead of `Tiếng Việt · EN` | No target screens are designed and the app is English only (G-28); Lab 3 forbids faking a working feature | Temporary until those screens exist | n/a (copy only) |
| DC-18 | 2026-10-28 | Login | Follows the Login frame (photo, scrim, `Internly.` wordmark, white Google button, legal line), except: English copy (`Start your IT career`, `Connecting tech students with hundreds of top internships.`, `Continue with Google`, `By continuing, you agree to our Terms & Privacy.`); `Terms` and `Privacy` show a coming-soon SnackBar and each has a 48 dp touch target; the sign-in error and the cancelled-picker message sit in a white rounded box above the button; a spinner replaces the "G" while signing in; Google's current gradient "G"; the legal line uses the standard 16 dp side padding so the longer English sentence stays on one line at 360 dp; the content scrolls when the screen is short. Values not measurable from the frame (verify in Figma: G-07): 32 dp side padding, 48 dp button, scrim 80 % → 65 % → 95 % `textPrimary` | The app is English only (G-28, user decision); no Terms / Privacy content exists and Lab 3 forbids faking a feature (G-31); **accessibility**: `error` text straight on the scrim is below 4.5:1, links need 48 dp targets, text must not be clipped at large font sizes; Lab 3 §6 requires a visible sign-in message and the frame has none; Google's branding guidelines require its own asset | Applied | ⬜ update frame (English copy, message box) |

## 5. Screen verification checklist

Copy into the screen's PR description; the reviewer checks it before approving.

| Check | 360 dp | 412 dp |
|---|---|---|
| Layout and visual order match the Figma frame | | |
| Tokens only (no raw colors, sizes, paddings) | | |
| Lab 2 components reused (no one-off copies) | | |
| One primary action | | |
| Loading / empty / error (+ Retry) states from `ViewState` | | |
| Touch targets ≥ 48 dp, body text ≥ 14 sp, no overflow | | |
| Status / selection not by color alone; Semantics labels on key widgets | | |
| Copy matches the design | | |
| App screenshot next to the Figma frame in `evidence/` | | |
