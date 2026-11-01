# Design traceability

Maps every Lab 2 screen, flow and component to its Flutter route, widget and data source, with status, and records **every deviation from the design with its reason** (Lab 3 §3, §4 stage 1, §9). Written before feature work. Each feature PR updates its rows.

Sources: [`design/screen-spec.md`](design/screen-spec.md), [`design/user-flow.md`](design/user-flow.md), [`design/design-system.md`](design/design-system.md), Figma <https://www.figma.com/design/UQveNSgQNYbuZyaNMa57FQ/Internship-Finder---Design-System>.

**Status:** ✅ Done · 🟡 Placeholder / interim · ⬜ Planned · ⚠️ Deviation (see §4).

Routes marked *planned* are the agreed proposal. An owner who changes one updates this table in the same PR.

## 1. Screens

| # | Lab 2 screen | Route | Flutter widget | Data source | Owner | Status |
|---|---|---|---|---|---|---|
| — | Login *(Lab 3)* | `/login` | `LoginScreen` | Firebase Auth (Google) | Auth | 🟡 interim (DC-01) |
| 1 | Home | `/home` | `HomeScreen` | Shared Firestore pool `/internships` (synced from SerpAPI every 6h): `searchRank` + `postedAt`, role filter, Remote Config `home_recommended_limit` / `home_recent_limit` | Home | ✅ UI · 🟡 save implemented, bell pending |
| 2 | Search | `/search` | `SearchScreen` | — (query input, filter sheet) | Search | 🟡 placeholder |
| 3 | Search Results | `/search/results` *(planned)* | `SearchResultsScreen` | Shared Firestore pool `/internships` (synced from SerpAPI) | Search | ⬜ |
| 4 | Internship Detail | `/{tab}/internships/:jobKey` *(planned)* | `InternshipDetailScreen` | Firestore `/internships/{jobKey}` + `users/{uid}/savedInternships`, `…/applications` (saved / applied state) | Search | ⬜ ⚠️ DC-10 |
| 5 | Saved Internships | `/saved` | `SavedScreen` | Firestore `users/{uid}/savedInternships` (real-time listener) | Saved | ✅ UI (`MainTabAppBar`, work-mode filters, list, empty, error) · 🟡 open detail, unsave Undo and `ViewState` pending (DC-15) |
| 6 | Application Form | `/apply/:jobKey` *(planned, root navigator: no bottom nav)* | `ApplicationFormScreen` | Firestore `users/{uid}` (prefill), Cloud Storage `cvs/{uid}/…` (`FileStorageService`) | Apply | ⬜ |
| 7 | CV Match Check *(Lab 3)* | `/apply/:jobKey/match` *(planned)* | `CvMatchScreen` | Listing qualifications (`/internships/{jobKey}`) vs profile skills; Remote Config `cv_match_enabled` | Apply | ⬜ ⚠️ DC-09 |
| 8 | Application Review | `/apply/:jobKey/review` *(planned)* | `ApplicationReviewScreen` | In-memory form state | Apply | ⬜ |
| 9 | Application Success | `/apply/:jobKey/success` *(planned)* | `ApplicationSuccessScreen` | Firestore write result | Apply | ⬜ |
| 10 | My Applications | `/applications` | `MyApplicationsScreen` | Firestore `users/{uid}/applications` (real-time, sorted by date) | Track | 🟡 placeholder |
| 11 | Application Detail | `/applications/:jobKey` *(planned)* | `ApplicationDetailScreen` | Firestore application document | Track | ⬜ |
| 12 | Profile | `/profile` | `ProfileScreen` | Firestore `users/{uid}`, Cloud Storage `cvs/{uid}/…` | Profile | 🟡 placeholder (DC-03) |
| — | Firebase demo area *(Lab 3)* | `/profile/firebase` *(planned)* | `FirebaseDemoScreen` | Remote Config values, Crashlytics test actions, links to the two screens below | Profile | ⬜ (G-06) |
| — | Notification Center *(Lab 3)* | `/profile/notifications` *(planned)* | `NotificationCenterScreen` | FCM + Firestore `users/{uid}/notifications` | Notifications | ⬜ (G-04, G-13) |
| — | Report export *(Lab 3)* | `/profile/export` *(planned)* | `ReportExportScreen` | PDF from the user's applications → Cloud Storage `reports/{uid}/…` (`FileStorageService`) + Firestore metadata | Report | ⬜ (G-05) |

## 2. Flows

| Flow | Steps → routes | Alternative / error paths | E2E test | Status |
|---|---|---|---|---|
| **1 Search** | `/home` → `/search` (filter sheet) → `/search/results` → `/search/internships/:jobKey` | 1a no results → Clear filters · 1b results load error → Retry · 1c detail load error → Retry | TC-03, TC-04, TC-05 | ⬜ |
| **2 Apply** | detail → `/apply/:jobKey` → `/apply/:jobKey/match` → `/apply/:jobKey/review` → `/apply/:jobKey/success` | 2a CV upload error · 2b empty profile · 2c already applied · 2d CV gaps → improve or continue · **2e save for later**: save → `/saved` → `/saved/internships/:jobKey` → apply (2e.1 unsave + Undo, 2e.2 empty list, 2e.3 save error) | TC-06, TC-07, TC-08 | ⬜ ⚠️ DC-08, DC-09, DC-10 |
| **3 Track** | `/applications` → `/applications/:jobKey` | 3a no applications · 3b list error · 3c detail error · 3d withdraw + Undo | TC-09, TC-10 | ⬜ |
| Sign-in / sign-out | `/splash` → `/login` → `/home`; Profile → Sign out → `/login` | Cancelled picker shows a message; auth error message | TC-01, TC-14 | ✅ (interim UI) |

## 3. Components (Figma page 05 + Lab 2 README list)

| Lab 2 component | Flutter widget (file) | Variants / states as parameters | Status |
|---|---|---|---|
| Button | `AppButton` (`core/widgets/app_button.dart`) | `variant` primary / secondary / text · `onPressed: null` = disabled · `isLoading` · `icon` · `expand` | ✅ |
| Text Field / Text Area | `AppTextField` (`core/widgets/app_text_field.dart`) | `errorText`, `helperText`, `enabled`, `maxLines` / `maxLength` | ✅ |
| Search Field | `AppSearchField` | clear action, `onFilterPressed`, `readOnly` entry point | ✅ |
| Filter Chip | Flutter `FilterChip` + `ChipThemeData` | `selected` | ✅ ⚠️ DC-05 proposed |
| Internship Card + Save Toggle | `InternshipCard` | `isSaved`, `onSaveToggle`, `badge` (Applied), pressed state, Semantics summary | ✅ |
| Skill Tag | `AppTag` | — | ✅ |
| Application Status / Badge | `StatusBadge` | `label`, `icon`, `color` (status mapping in the Applications feature) | ✅ ⚠️ DC-04 proposed |
| App Bar | `AppTopBar` (`core/widgets/app_top_bar.dart`); tab destinations compose it as `MainTabAppBar` (bell, avatar) | `.main` / `.back`, `actions` | ✅ |
| Bottom Navigation | `AppShell` + `NavigationBarThemeData` | 5 fixed destinations | ✅ |
| Dialog | `showAppDialog` / `AppDialog` | confirm / cancel / error via labels | ✅ |
| Loading | `StateView.loading`, `InternshipCardSkeleton`, `SkeletonBox` | labeled spinner, card skeleton | ✅ |
| Empty State | `StateView.empty` | icon, title, message, action | ✅ |
| Error State | `StateView.error` | message, icon, `onRetry` | ✅ |
| Snackbar | Flutter `SnackBar` + `SnackBarThemeData` | action (Undo) | 🟡 theme only |
| Info Banner, Upload Dropzone, Bottom Sheet Option Row, Job Summary Card, CV File Card, Upload Progress Card, Match Card, Progress Stepper, Meta Tile, Section Header, Bullet Item, Benefit Item, Review Row | *to be built by the owning feature from Figma specs (G-16)* | — | ⬜ |
| Map Preview Card | *not buildable from SerpAPI data (no coordinates)* | — | ⚠️ DC-10 |

Design tokens → `lib/theme/` (ThemeData, ColorScheme, TextTheme, spacing / radius / elevation constants): ✅, cross-checked against Figma 04 in [`design-system.md`](design/design-system.md).

## 4. Deviations from the Lab 2 design

Every difference between Figma and the app is listed here with its reason. Lab 3 accepts these reasons: platform constraint, accessibility failure, API limit, or a recorded team decision. **Figma must be updated** so design and app stay in sync; an unrecorded difference counts as a defect.

| ID | Date | Screen / component | Change | Reason | Status | Figma updated? |
|---|---|---|---|---|---|---|
| DC-01 | 2026-10-21 | Login (new) | Interim Login screen: "Internly" title, tagline, info/error message row, full-width Primary `Continue with Google` with loading state; tokens and components only | Lab 3 requires sign-in; Lab 2 has no Login screen (G-03) | Temporary: auth owner finalises | ⬜ add frame |
| DC-02 | 2026-10-21 | Home, Search, Saved, Applications, Profile | Placeholder screens so shell, routing and auth run before features exist | Initialization scaffolding | Temporary: replaced by each feature | n/a |
| DC-03 | 2026-10-21 | Profile (placeholder) | Sign out as a full-width Secondary button (final design: "Settings & Support" list) | Test sign-in / sign-out before Profile is built | Temporary | n/a |
| DC-04 | 2026-10-21 | Application Status "Rejected" | Proposal: label in `textPrimary` with the `error` icon, or `surface` background | **Accessibility failure**: `error` on `surfaceVariant` = 4.41:1 < 4.5:1 (G-19) | Proposed | ⬜ |
| DC-05 | 2026-10-21 | Filter Chip, selected | Proposal: selected label in `textPrimary`, keep `primaryContainer` fill and check icon | **Accessibility failure**: `primary` on `primaryContainer` = 4.24:1 (G-19) | Proposed | ⬜ |
| DC-06 | 2026-10-21 | App Bar, Bottom Navigation | Follow Figma 05 over the Stitch prompt: no App Bar bottom border, no nav indicator pill | Source precedence: Figma final UI over Stitch output | Applied | ✅ matches Figma |
| DC-07 | 2026-10-21 | Whole app (iOS) | iOS uses the same Material design as Android | Team asked for Android + iOS (G-15); Lab 3 grades Android | Applied | n/a |
| DC-08 | 2026-10-21 | Flows | Flows restructured to **1 Search → 2 Apply → 3 Track**; Save becomes sub-flow 2e of Apply; branches renumbered | Team decision: saving is a step towards applying | Applied in docs | ⬜ update Figma pages 01 and 06 (prototype) |
| DC-09 | 2026-10-21 | CV Match Check (new screen in Apply) | Step between Application Form and Review: matched vs unmatched requirements, one suggestion per gap, never blocking | Team decision (G-24) | Approved | ⬜ add frames + prototype link |
| DC-10 | 2026-10-21 | Internship Detail, Apply, cards | Listings come from SerpAPI Google Jobs: fields such as allowance, company size or office location can be missing; there is no map location; applying to the employer happens on an external site | **API limit** (G-25) | Expected: each screen owner records the exact UI change here | ⬜ per screen |
| DC-11 | 2026-10-22 | Home (card Save, app-bar bell) | The app-bar bell still shows an honest "coming soon" SnackBar instead of opening an empty Notification Center. The card Save Toggle now writes the listing to `users/{uid}/savedInternships`; a failed write keeps the bookmark empty and shows the service message in a SnackBar | Notification Center is owned by a later feature and Lab 3 forbids fake success; the Save Toggle targets sub-flow 2e and had no data source until the Saved service landed | Save implemented 2026-10-28; bell temporary until the Notification Center lands | n/a (no visual change) |
| DC-14 | 2026-10-28 | Home card (failed save) | The failure message from a save / unsave appears in a SnackBar at the bottom of the screen | **Lab 3 requirement**: every failed action needs a visible, plain-language message; the Home frames show no error component and Figma has no Snackbar spec (G-07) | Applied | ⬜ add Snackbar spec
| DC-12 | 2026-10-22 | Home (search entry) | Hint shortened to `Search internships`; the shared field still uses the full placeholder elsewhere | Team decision: the full placeholder wrapped to two lines at 360 dp and made the Home search entry taller than the design (screen-spec allows a placeholder "such as") | Applied | ⬜ update Home frame hint |
| DC-13 | 2026-10-22 | Home (Browse by Skill → Browse by Role) | The five fixed skill chips become role chips: Frontend, Backend, Full-stack, Mobile, Data/AI, Tester/QA, DevOps/Cloud, Other IT. Only roles present in the current pool are shown; non-IT listings are hidden. Skills remain as card tags. | **API/data limit**: Google Jobs has no category field, and the Lab 2 skill chips were sparse against real data (Flutter 1, NestJS 1, MongoDB 2, React 8, Python 8). The team chose an IT-only role taxonomy for discovery. | Applied | ⬜ add Home role chips frame |
| DC-15 | 2026-11-01 | Saved Internships (app bar) | The header is the same bar as Home: title, notification bell, profile avatar, and **no brand mark** in the leading slot. The title is the bottom-navigation label (`Saved`). The screen keeps the name "Saved Internships" in docs and spec; `MainTabAppBar` is shared by both tabs | **Team decision**: tab headers must not differ, so a tab switch only changes the title, and the logo is removed from the bar so the title keeps the normal 16 dp text margin. The title uses the tab label because `Saved Internships` measures 211 dp at `type/heading/large` (Inter, 24 sp) and leaves only ~33 dp of slack at 360 dp, so it clips under larger system font scales | Applied | ⬜ update the Saved frame header |

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
