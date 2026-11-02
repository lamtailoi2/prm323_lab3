# Implementation AI log

Every AI-assisted change is recorded here: the request, what the AI produced, **how it was verified**, and whether the team **accepted, modified or rejected** it. Only verification that actually ran is recorded; "not verified" is a valid entry. Long formal task prompts are stored verbatim in [`prompts/`](prompts/P-01-initialize-internly.md); short working requests are summarized.

| Field | Meaning |
|---|---|
| Request | The task given to the AI (summary, or a link to the verbatim prompt) |
| Output | What the AI changed or produced |
| Verification | Commands run with their real results, or manual checks |
| Decision | Accepted · Modified (how) · Rejected (why) |

---

## Session 2026-10-21: repository initialization and Lab 3 alignment

Tool: Claude Code (Opus 5.5, `claude-opus-5-5`), run in `prm323_lab3/` with read access to the Lab 2 repository. Operator: Lâm Tài Lợi.

### P-01: Initialize the repository
- **Request:** initialize the Internly Flutter repository from the Lab 2 handoff ([verbatim prompt](prompts/P-01-initialize-internly.md)); design sources in the Lab 2 repository.
- **Output:** inspected the empty working directory, the toolchain (Flutter 3.47.3, Dart 3.13.3, Xcode 26.5; Android SDK incomplete; no Firebase / FlutterFire CLI) and the Lab 2 repository (`03f4aa3`); found no `flutter-handoff.md` (G-01). Ran `git init` and `flutter create --org com.group3 --project-name internly --platforms android,ios --empty`, committed unchanged as the scaffold. Confirmed current package APIs from their sources before coding (google_sign_in 7.2, firebase_auth 7, Riverpod 3.4, go_router 18).
- **Verification:** scaffold commit in `git log`; package APIs read in `~/.pub-cache`.
- **Decision:** Accepted. App ID `com.group3.internly` recorded as an assumption (G-21).

### P-02: Target Android and iOS
- **Request:** generate the project for both Android and iOS.
- **Output:** platforms `android,ios`; iOS setup steps (URL scheme, APNs) in the setup guide; recorded as G-15 / DC-07.
- **Verification:** `flutter build ios --simulator --debug` (P-08).
- **Decision:** Accepted.

### P-03: Bring the Lab 2 design sources into the repository
- **Request:** copy the Lab 2 design documents where needed.
- **Output:** read-only snapshot in `docs/design/` (DESIGN.md, screen spec, design decisions, user flows, persona, Lab 2 README, 8 final screenshots) with a provenance note. Intermediate Stitch rounds and the Lab 2 AI design log were not copied.
- **Verification:** file list compared with the source; source commit recorded.
- **Decision:** Accepted.

### P-04: Document the design system and components
- **Request:** write the design system and component library (Figma pages 04 and 05) as a Markdown reference.
- **Output:** [`design-system.md`](../design/design-system.md): tokens with Dart and `ColorScheme` mapping, the 12 component sets with states, source precedence and usage rules. Added `material_symbols_icons` because Figma page 04 specifies Material Symbols Rounded.
- **Verification:** compared against the Figma screenshots; values that could not be read from them are marked **verify** (G-07).
- **Decision:** Accepted.

### P-05: Cross-check the design system against the theme
- **Request:** compare the Figma tokens and components with the implemented theme.
- **Output:** Figma ↔ code table. All 13 colors, 8 text styles, spacing, radius and elevation tokens match. Component differences fixed: Secondary button border, disabled fills, pressed state (reduced emphasis), loading state, App Bar without border (DC-06), Loading / Empty / Error views. Computed WCAG contrast: Rejected badge 4.41:1 and selected chip 4.24:1 fail AA (G-19); fixes proposed as DC-04 / DC-05.
- **Verification:** contrast computed with the WCAG 2.1 formula; `flutter analyze` clean; assertions in `test/theme/app_theme_test.dart`.
- **Decision:** Accepted; DC-04 and DC-05 pending team approval.

### P-06: Limit the scope to the shared foundation
- **Request:** build only shared code (theme, components, utilities, services); feature details belong to the feature owners.
- **Output:** feature models that had been started were removed; the shared `AppUser` stays. Shared components take primitive inputs only (`AppTextField`, `AppSearchField`, `InternshipCard`, `AppTag`, `StatusBadge`, `showAppDialog`, skeletons, `Validators`). Feature screens are placeholders (DC-02).
- **Verification:** see P-08.
- **Decision:** Modified: AI output reduced to the shared foundation; feature model files rejected.

### P-07: Project overview, contributor rules, review limits
- **Request:** project overview in README; `AGENTS.md` with coding conventions, rules and a short overview; limits for AI code review.
- **Output:** `README.md`; `AGENTS.md` (rules, folder placement, Dart / Riverpod conventions, testing, docs per PR, Git workflow, definition of done); `CLAUDE.md` importing `AGENTS.md`. AI review: at most 3 rounds per PR, a cap rather than a quota, and each round reviews only the diff since the previous one.
- **Verification:** documentation only.
- **Decision:** Accepted.

### P-08: Verification run (initialization)
Commands executed, with their real results (details in [`test-report.md`](test-report.md)):

| Command | Result |
|---|---|
| `dart format lib test` | Formatted; no further diffs |
| `flutter analyze` | `No issues found!` |
| `flutter test` | 65 tests, all passed |
| `flutter build ios --simulator --debug` (SPM) | **Failed**: SPM conflict, firebase-ios-sdk 13 vs GoogleSignIn-iOS 9 (`gtm-session-fetcher`) (G-20) |
| `flutter build ios --simulator --debug` (CocoaPods) | **Passed** (Firebase iOS 12.19.0, GoogleSignIn 9.2.0, GTMSessionFetcher 3.5.0) |
| Android build | **Not run**: Android SDK incomplete on this machine |

- **Decision:** SPM disabled for the project (CocoaPods) until `google_sign_in_ios` supports GoogleSignIn-iOS 10.

### P-09: Publish the repository
- **Request:** push the repository to `github.com/lamtailoi2/prm323_lab3`.
- **Output:** confirmed the remote repository was empty and private, added `origin`, pushed `main` with upstream tracking. No force push.
- **Verification:** `gh repo view` → default branch `main`; `git status -sb` → `main...origin/main`.
- **Decision:** Accepted.

### P-10: Restructure the user flows
- **Request:** make Save Internship a sub-flow inside Apply (after Search, before Track), with three main flows Search → Apply → Track, and add a step in Apply that shows which requirements the CV does not match and suggests improvements; update the Lab 3 docs and the Lab 2 copies.
- **Output:** rewrote `docs/design/user-flow.md` and updated `docs/design/screen-spec.md` (new numbering, **CV Match Check** screen); README, test scenarios, analytics events, gaps (G-24) and deviations (DC-08, DC-09) updated.
- **Verification:** searched for stale flow references; relative links checked with a script.
- **Decision:** Accepted. Matching rules, CV text extraction and the Figma frame remain open (G-24).

### P-11: Review against the Lab 3 handout
- **Request:** compare the repository with the official Lab 3 handout and list what is missing.
- **Output:** gap list: E2E with Google ARTEMIS, Cloud Storage with `storage.rules`, `docs/design-traceability.md`, a message for cancelled sign-in, clearing local data on sign-out, pinned versions, required files and folders, and the risk of design changes without a Figma update.
- **Verification:** each requirement of the 18-page handout compared with the repository.
- **Decision:** Accepted.

### P-12: Align the foundation with the Lab 3 handout
- **Request:** apply the review with the team's decisions: report and slides submitted outside the repository; demo video link added to README later; repository name kept; internship data from SerpAPI (Google Jobs); free services only, no spending; flows as restructured in P-10; E2E with ARTEMIS; a documented `.env` setup; logging rules in AGENTS.md as the handout requires.
- **Output:**
  - Code: exact dependency versions; `ViewState` sealed class; `SerpApiClient` (key from `.env` via `--dart-define-from-file`, error mapping, no key leaks); info message for cancelled sign-in; `currentUserIdProvider` so sign-out drops user data; Crashlytics custom key `last_screen`; Remote Config defaults from `firebase/remote-config-defaults.json` with real-time updates; Semantics summary on `InternshipCard`.
  - Config: `.env.example`; `e2e_test/` (ARTEMIS commit `351ca84`, conftest, 3 runnable tests); `firebase/storage.rules`; `firebase.json`.
  - Docs: `design-traceability.md`, `test-plan.md` (15 cases, coverage, zero-cost model), `analytics-plan.md` (Appendix A), `code-review.md` (Appendix C + AI tool disclosure), `architecture.md` (Mermaid layer and sequence diagrams, ViewModel table), README, AGENTS.md ("Logs and evidence required by Lab 3"), `evidence/README.md`, gaps G-25 / G-26. Superseded documents removed.
- **Verification:** `flutter_tools` source checked (`--dart-define-from-file` accepts `.env`); ARTEMIS SDK source checked (`ArtemisClient.run`, `TaskResult.output` / `trace_id`, default Gemini models); `flutter analyze` clean; `flutter test` 79 passed; `e2e_test/*.py` compiled. ARTEMIS not run (no device, Firebase project or model key on this machine).
- **Decision:** Accepted.

### P-13: Reorganize the documentation folder
- **Request:** tidy up `docs/`.
- **Output:** the five handout-required files stay at `docs/` root; Lab 2 copies and `design-system.md` in `docs/design/`, the setup guide in `docs/guides/`, gaps, AI log, test report and prompts in `docs/records/`; `docs/README.md` index. A script rewrote all relative links and path mentions in code, rules and `pubspec.yaml`.
- **Verification:** dry run reviewed before applying; link and anchor check → 0 problems (except `ai/…` links inside the verbatim Lab 2 README); `flutter analyze` clean; `flutter test` 79 passed.
- **Decision:** Accepted.

### P-14: File storage provider
- **Request:** find a zero-cost storage option, then use Cloud Storage for Firebase as the handout requires.
- **Research (web):** since 2026-02-03 Cloud Storage for Firebase requires the Blaze plan (billing account), with no card-free plan except Google Cloud education credits; budgets only alert and cannot cap spending; the Always Free tier applies only to buckets in US-CENTRAL1, US-EAST1 and US-WEST1.
- **Output:** a Cloudinary implementation was built first and then replaced by `FirebaseStorageService` (`firebase_storage` 14.0.0) behind the same `FileStorageService` interface: pre-upload checks (signed in, own folder, PDF signature, ≤ 10 MB, random id), progress, download URL, error mapping. `storage.rules` deployed; setup guide §10 covers Blaze, a $1 budget alert, a US bucket and disabling billing after grading (G-12, G-26).
- **Verification:** `flutter analyze` clean; `flutter test` 85 passed; iOS simulator build passed with the FirebaseStorage pod (test report Run 4). Real uploads not run (no Firebase project configured here).
- **Decision:** Accepted; Cloudinary implementation rejected in favor of the handout's Cloud Storage requirement.

### P-15: Team setup with a single `.env`
- **Request:** let teammates set up the project without each registering their own SHA fingerprints.
- **Output:** `android/app/build.gradle.kts` signs debug builds with a shared team keystore read from `DEBUG_KEYSTORE_BASE64` in the untracked `.env` (falls back to the default debug keystore). The owner registers one SHA-1 / SHA-256; teammates only receive `.env`. Firebase config files stay committed; keystores are never committed. Setup guide §15 "Team setup".
- **Verification:** `keytool` generation, SHA listing and base64 round trip tested locally (temporary keystore deleted). Gradle change not built here (no Android SDK); to be confirmed with `flutter build apk --debug --dart-define-from-file=.env`.
- **Decision:** Accepted.

### P-16: Security rules set up once
- **Request:** rules that are configured once, and a way to keep them in sync for teammates who do not use the Firebase CLI.
- **Output:** final Firestore rules: a signed-in user reads and writes only `users/{uid}/**` (any subcollection, ≤ 50 fields per document); everything else denied, so features never need a rules change (G-10 resolved). Rules are changed only through a PR that tags the owner, who publishes them (CLI deploy or console). AGENTS.md, architecture §6 and setup guide §5 updated. Automated deployment through GitHub Actions deferred.
- **Verification:** rules reviewed by reading (no emulator or Firebase project on this machine); `flutter analyze` clean.
- **Decision:** Accepted.

### P-17: Integrate branches into `main`
- **Request:** merge the working branches into `main` and remove them.
- **Output:** `main` fast-forwarded to include both branches (no merge commit) and pushed; both branches deleted locally and on GitHub after confirming they were fully merged.
- **Verification:** `flutter analyze` clean and `flutter test` 85 passed on `main` before pushing; `main` equals `origin/main`.
- **Decision:** Accepted.

### P-18: Home UI + SerpAPI → Firestore sync
- **Request:** implement the Figma Home design and change listings to a scheduled SerpAPI → Firestore sync so the app never holds the key.
- **Output:** `HomeScreen` (brand mark, bell placeholder, profile avatar, read-only search entry, `Browse by Skill` / `All skills`, skill filter, `Recently Posted`), rewritten `InternshipCard` (logo fallback, allowance, posted age, tags), Firestore-backed `InternshipService` and `HomeViewModel` (Remote Config limits), `Internship.fromFirestore`, `formatAllowance`, `formatPostedAge`, Node 22 `functions/` sync (`syncInternshipsJob`, Secret Manager `SERPAPI_KEY`, 6-hour rotation, 7-day expiry), read-only `/internships` rules, and docs (architecture, setup, G-23/G-25, traceability, analytics, test report).
- **Verification:** `dart format lib test` → formatted; `flutter analyze` → No issues found; `flutter test` → 119 passed; `cd functions && npm test` → 5 passed; `npm run build` → passed. Deployment, real SerpAPI sync and APK build: not run (no Firebase credentials / Android SDK here).
- **Decision:** Accepted for the Home slice. Save and bell intentionally show an honest coming-soon message (DC-11) until their features land.

### P-19: Home role taxonomy + SerpAPI keyword/location tuning
- **Request:** check and optimize the SerpAPI config; use three to five keywords with `location=Vietnam` because the app filters by role and location; replace Home skill shortcuts with IT-only roles; verify the sync.
- **Output:** added `JobRole`/`jobRoleFor` (`lib/core/utils/job_role.dart`) and `Internship.role`; Home now shows `Browse by Role`, filters the IT-only pool by role and hides non-IT listings; skills stay as card tags. Replaced the skill-shortcut widget with `RoleShortcuts`, updated ViewModel, screen and tests, and recorded DC-13. Sync config now uses five proven queries with `location=Vietnam`; `fetchJobs` accepts an optional location for a future filter-driven query. Deployed `syncInternshipsJob` and reran the scheduler.
- **Verification:** `flutter analyze` → No issues found; `flutter test` → 124 passed; `cd functions && npm test` → 7 passed; `npm run build` → passed; `firebase deploy --only functions` → successful; sync state → `fetched=40`, `written=40`, `backfill=true`, no `lastError`. After a hot restart, the rebuilt iOS simulator shows `Browse by Role`, the role chips and a `Frontend Developer Intern` card; screenshot saved as `evidence/screens/home-roles-actions-20261022.png`; widget tests also cover the chips at 360/412 dp.
- **Decision:** Accepted for the Home slice and sync config. Location-specific filtering remains the Search feature's job and is not baked into the sync.

### P-20: Transparent Home section actions + E2E evidence
- **Request:** make the Home section-header text actions (`All roles`, `View all`) transparent with no white block behind them, then record the professional prompt and save E2E evidence ([normalized prompt](prompts/P-20-home-role-actions.md)).
- **Output:** `AppTheme.textButtonTheme` now uses a transparent background in every state, so `AppButtonVariant.text` no longer paints a surface block while keeping its 48 dp target. Added the theme assertion, a Home-role ARTEMIS case (`TC-16`) and its test-plan row. Saved the simulator screenshot and the real ARTEMIS environment check.
- **Verification:** `dart format lib test` → 0 changed; `flutter analyze` → `No issues found!`; `flutter test` → **125 passed**; hot reload + screenshot at RGB `248,250,252` behind `All roles`/`View all` (no white pill). ARTEMIS suite **not run**: `adb devices` is empty and no ARTEMIS daemon listens on `127.0.0.1:8000`; see `evidence/artemis/e2e-environment-20261022.md`.
- **Decision:** Accepted for the text-action style and test coverage. E2E execution remains pending an Android device/emulator and the ARTEMIS host.

### P-21: Profile screen
- **Request:** "làm màn profile đi" (build the Profile screen). Working request by the Profile owner; no verbatim prompt file.
- **Output:** branch `feat/profile-ui`. `UserProfile` model (`users/{uid}`: details, skills, preferences, CV metadata) with `FirestoreReader` parsing; `UserProfileService` (live listener, merge write per section, Firestore errors → `AppException`, malformed `cv` logged to Crashlytics); `DocumentPickerService` (`file_selector`) and `ExternalLinkService` (`url_launcher`), both pinned. ViewModels: `ProfileViewModel` (`ViewState`, user-scoped), `EditProfileViewModel` (validation), `EditSkillsViewModel`, `EditPreferencesViewModel`, `UpdateCvViewModel` (10 MB pre-check, progress, upload to `cvs/{uid}` then save), `OpenCvViewModel`. Views: `ProfileScreen` (header, CV / Resume, Technical skills, Internship preferences, Settings & support with Sign out reachable in every state), `EditProfileScreen` at `/profile/edit` (no Lab 2 frame: G-27), three sheets from the Lab 2 Stitch frames. Events `profile_update` and `cv_upload`. Helpers `formatShortDate`, `formatFileSize`, `Validators.phone`; tokens `AppSizes.profileHeaderAvatar`, `AppSizes.fileTile`. Docs: traceability (rows, DC-14…DC-17, DC-03 removed), gaps G-27/G-28 and G-07 rows, analytics rows 16–17, architecture (ViewModels, services, profile schema), design-system sizes, test plan TC-14 wording + TC-17 (`e2e_test/test_profile_skills.py`).
- **Verification:** `dart format lib test` → 0 changed; `flutter analyze` → No issues found!; `flutter test` → **186 passed** (125 on `main`, +61), 3 consecutive runs all green; `flutter build ios --simulator --debug` → built (new pods resolved); widget renders of Profile, the three sheets and Edit profile at 360 dp compared by eye with the Lab 2 frames (renders not stored as evidence). Real Firestore write, real Storage upload, DebugView events, Android build and ARTEMIS TC-17: **not run** (no Android toolchain / device / ARTEMIS host on this machine).
- **Decision:** Accepted for review. Deviations recorded as DC-14…DC-17; settings rows without screens show honest coming-soon messages.

### P-22: Run the Profile screen and investigate a stuck save
- **Request:** "chạy thử tui xem" (run the app to try the Profile screen), then "save thành công nhma bị treo" (the save worked but the sheet hung) and "viết các log cần thiết đi" (write the logs needed).
- **Output:** booted the iPhone 17 Pro simulator and ran the app with `flutter run` in tmux; opened Profile, the three sheets and Edit profile through the Dart VM service. For the hang: checked the server copy and the cache of `users/{uid}` (data saved, no pending writes) and that the Analytics plugin answered; added timing logs to `FirestoreUserProfileService._merge` (Crashlytics breadcrumb with the section name and duration only; a `debugPrint` used during the investigation was removed in P-26). Recorded Run 9 in the test report.
- **Verification:** after hot reload, two repeated `Save preferences` taps logged `saved preferences in 890 ms` / `742 ms` and closed the sheet; the original hang did not reproduce. `flutter analyze` → No issues found!
- **Decision:** Accepted (logs). Root cause of the single hang not confirmed; the most likely cause is a slow server acknowledgement. A timeout + "saved on this phone" message is proposed but not built, because it needs new copy (team decision).

### P-23: Edit profile frame and sheets matched to the design
- **Request:** "update edit profile" with a new Edit Profile frame, then "đảm bảo 2 cái này match với design nữa" (make the Update Preferences and Edit Skills sheets match their frames). Photo upload: the user chose the Google photo (no `storage.rules` change).
- **Output:** `ProfileDetails` gains `headline`, `graduationYear`, `city`, `bio`; `EditProfileScreen` rebuilt from the frame (photo, two cards, required markers, clear button, icons, locked email, 300-character bio, `Save changes` + `Cancel`, app-bar `Cancel`) with an `AcademicStandingSheet` picker; `AppTextField` gains `prefixIcon`, `suffix`, `isRequired`, `readOnly` + `onTap`; `TargetRole` (the frame's five roles) replaces Home's `JobRole` in preferences; `SheetChip` / `SheetGroupHeader` give the sheets the frame's chip outline, "+" icons and uppercase headings; Edit skills restyled (selected box, count pill, red `Clear all`, outlined removable chips, opening selection first). Docs: G-27 resolved, G-29 added, DC-14 and DC-16 rewritten, schema, design-system Text Field options and sizes.
- **Verification:** `flutter analyze` → No issues found!; `flutter test` → **193 passed**; hot restart on the simulator and screenshots compared with the frames; a 360 dp render found the academic value cut off, fixed by wrapping.
- **Decision:** Accepted. Banner "VNU V-Career Sync" and photo change are left out on purpose (no such integration; rules allow PDFs only), recorded in DC-14 / G-29.

### P-24: Profile tag height
- **Request:** "height của badge sai, 44 px mới đúng"; clarified as the skill / preference tags on Profile.
- **Output:** `AppTag` gains `size` (`compact` default for the Internship Card, `large` = `AppSizes.tagLarge` 44 dp); Profile Technical skills, Target roles and Work mode use `large`. Label style and horizontal padding unchanged. Follow-up "chưa update trong edit skills kìa": the selected and suggested chips of Edit skills are also 44 dp (`SheetChip(large: true)`, `SheetChip.largePadding` = 12 dp minus the 1 dp outline, a transparent outline on unselected large chips so selecting does not change the height, 20 dp delete icon); rows 4 dp apart; tap targets stay 48 dp.
- **Follow-up:** "44 lun" (Update preferences too): 44 dp became the only `SheetChip` size, also used by the Academic standing picker; rows 4 dp apart in every sheet. "xong update evidence": sheet screenshots replaced / added in `evidence/screens/` (test report Run 9).
- **Follow-up:** "này 36 và k có dấu tick" (Quick select): `SheetChip(compact: true, showCheckmark: false)` = 36 dp (8 dp padding minus the outline), outline only; the Location field still shows the chosen city. Test asserts both; preferences evidence re-taken.
- **Verification:** `flutter analyze` → No issues found!; `flutter test` → 195 passed (Edit skills test asserts 44 dp for a removable chip and for selected and unselected suggestions; a first run measured 46 dp because of the outline, fixed as above); simulator screenshots after hot reload.
- **Decision:** Accepted.

### P-25: Review the Profile screen for duplicate fields
- **Request:** "xem lại profile screen có field nào bị trùng k" (check whether any Profile field is duplicated).
- **Output:** found two overlaps between the Edit Profile and Update Preferences frames (current city vs internship location; headline / target role vs target role chips) and four Edit profile fields not shown on Profile (headline, graduation year, city, bio). User decisions: keep both cities and prefill an empty preferences Location from the current city (`EditPreferencesViewModel.build`); rename the field to `Headline` and show it under the name in `ProfileHeaderCard`. Recorded as G-30 and in DC-14 / DC-15 / DC-16.
- **Verification:** `flutter analyze` → No issues found!; `flutter test` → 197 passed.
- **Decision:** Accepted.

### P-26: Trim before the pull request
- **Request:** "bạn đánh giá xem có nên lược bớt j k", then "làm đi, check lại profile screen xem có cái nào thừa k" (assess what to trim, do it, and check the Profile screen for anything redundant).
- **Output:** merged test report Runs 8–13 into Run 8 (final checks) and Run 9 (simulator); moved the two pre-design-match sheet screenshots out of `evidence/` (superseded by the `-matched-` ones); left `lib/app/bootstrap.dart` as on `main` (formatter-only change); removed the investigation `debugPrint` from `FirestoreUserProfileService` (Crashlytics breadcrumb kept); shortened DC-14 / DC-15 / DC-16. Profile review: no unused code; simplified the two error listeners of `ProfileScreen` (their non-`AppException` fallbacks could never run) and reused `ProfileHint` for "Not set". Kept the design-sourced overlaps (app-bar bell and "Notification preferences"; "1 active file" and the default badge; app-bar and bottom `Cancel` in Edit profile).
- **Verification:** `flutter analyze` → No issues found!; `flutter test` → 197 passed.
- **Decision:** Accepted.

### P-27: Graduation years as a scrolling row
- **Request:** "nên design là scroll", then "ý là scroll năm từ 2026-2099 hay bao nhiêu range hợp lý á" (make Expected graduation a scroll; which year range is reasonable).
- **Output:** recommended this year to this year + 8 (2026–2034): Year of study allows up to 6 years, plus 2 for delays; 2099 would mean 70+ items no student needs. `EditProfileViewModel.graduationYearsAhead`; `AcademicStandingSheet` shows the years in one horizontal `SingleChildScrollView` row and scrolls the stored year into view on open (a stored earlier year is still listed). Docs: DC-14, G-27, Run 8; evidence screenshot re-taken.
- **Verification:** `flutter analyze` → No issues found!; `flutter test` → 198 passed (+1: a stored year 7 years ahead is selected and on screen when the picker opens); hot restart on the simulator.
- **Decision:** Accepted.

### P-28: Home allowance from the listing description
- **Request:** "trang home các jobs k lấy đc lương hả" (Home jobs show no salary?), then "PR profile sau đó làm lương" (do the salary after the Profile PR).
- **Output:** found that SerpAPI never fills `detected_extensions.salary` for the Vietnamese pool (0 of 322) while 144 descriptions state an amount or "Thỏa thuận". Added `allowanceFromText` to `lib/core/utils/allowance.dart` and used it in `Internship.fromSerpApi` when Google gives no salary. G-17 resolved (format and rules), G-25 note, Home traceability row, test report Run 10, two Home screenshots in `evidence/screens/`.
- **Verification:** `flutter analyze` → No issues found!; `flutter test` → 159 passed; the parser was run over the real pool on the simulator and every extracted amount compared with its source sentence (four misreadings fixed, see Run 10).
- **Decision:** Accepted. Free-text parsing can still miss unusual wording; it never invents a value (vague text stays "Not disclosed").

### P-29: Recommended for you by preferred location
- **Request:** "phần recommend for you nếu có chọn location hcm thì chỉ nên gợi ý jobs hcm" (if the preferred location is HCM, Recommended should only suggest HCM jobs).
- **Output:** `foldText` / `containsWords` (`lib/core/utils/text_fold.dart`, extracted from `job_role.dart`), `matchesPreferredLocation` (`lib/core/utils/location_match.dart`) with Vietnamese and English city spellings; `HomeViewModel` listens to the profile (user-scoped) and filters only "Recommended for you". Listings that only say "Việt Nam" are left out for a specific city; Recently Posted is unchanged. G-23 updated, Home traceability row, architecture table, Run 11, one Home screenshot.
- **Verification:** `flutter analyze` → No issues found!; `flutter test` → 208 passed (one test expectation of mine was wrong, "Ninh" is a whole word in "Ninh Bình", and was replaced); simulator with location Ho Chi Minh City: 5 of 5 Recommended cards in HCM.
- **Decision:** Accepted. Built on PR #2 (profile model and service).
- **Follow-up:** "push lên cái này đi rồi solve conflict với dev" (put it on PR #3 and resolve conflicts with `dev`): merged `origin/dev` (PR #2 merged) into `feat/home-allowance` without rewriting its pushed history, then cherry-picked the four location commits. Conflicts were append-only in the test report and AI log (both sides kept, in merge order) and one Home row in traceability (both changes combined). `flutter analyze` → No issues found!; `flutter test` → 242 passed.

### P-30: Recommended ordered by the profile
- **Request:** "tôi nghĩ là phần recommend sẽ bám vào các phần này bạn thấy sao" (Recommended should follow Technical skills, Target roles, Work mode and Location), then "làm đi".
- **Output:** checked the pool first and proposed ranking instead of filtering (work mode is missing on 288 of 289 IT listings, so it is not used). Added `recommendationScore` (`lib/core/utils/recommendation.dart`) and `TargetRole.jobRoles`; `HomeViewModel` keeps the location filter and sorts Recommended by score, then sync rank and recency. The simulator run exposed two existing problems, both fixed: duplicate jobs from several sync keywords (171 of 322; now shown once) and two non-IT titles classified as Frontend (non-IT words added to `jobRoleFor`). G-23, the Home traceability row, Run 12 and one Home screenshot.
- **Verification:** `flutter analyze` → No issues found!; `flutter test` → 252 passed; simulator with the student's profile: five distinct Hanoi Frontend listings, best skill matches first.
- **Decision:** Accepted. An optional "Matches your skills: …" line on the card was proposed but not built (new UI, needs a design decision).

### P-31: Login from the Login frame
- **Request:** "làm trang đăng nhập" (build the Login page), with a screenshot of the new Login frame and the campus photo.
- **Questions asked first (answers from the user):** the frame is in Vietnamese but the app is English only (G-28) → translate to English; the underlined "Điều khoản" / "Bảo mật" have no content → honest coming-soon SnackBar (G-31); the Home work in progress → open its PR first (PR #4), then branch `feat/auth-login-ui` from `dev`.
- **Output:** `LoginScreen` rebuilt from the frame (photo under a `textPrimary` scrim, `Internly.` wordmark, headline, pitch, legal line) and a feature-local `GoogleSignInButton` (white, Google's "G", spinner while loading). Assets: `assets/images/login_background.jpg` (the supplied photo, 960 × 600) and Google's "G" cut from the official `signin-assets.zip` (rendered to 1x–4x PNG with headless Chrome). G-03 resolved, G-31 added, DC-01 replaced by DC-18, Login and sign-in rows in traceability, README AI tools row, Run 13, two screenshots.
- **Verification:** `flutter analyze` → No issues found!; `flutter test` → 250 passed (+8); simulator screenshot next to the frame. A temporary render showed the legal line wrapping at 360 dp; fixed before committing.
- **Decision:** Accepted. Values that cannot be measured from a screenshot (32 dp side padding, 48 dp button, scrim and text opacities) are marked "verify in Figma: G-07". The photo's source and license are still to be confirmed by the design owner.
- **Follow-up:** "PR lên dev" → PR #5; then "solve conflict" after PR #4 merged: merged `origin/dev` into `feat/auth-login-ui` without rewriting its pushed history. Conflicts were only in the shared docs (the Login and Home rows in traceability, P-30 / P-31 here) and both sides were kept. `flutter analyze` → No issues found!; `flutter test` → 260 passed.

### P-32: CV validation via LLM (generic pre-submit gate)
- **Request:** the full task prompt in [P-32-cv-validation-llm.md](prompts/P-32-cv-validation-llm.md): a generic "is this file a usable CV?" gate before Confirm Application, distinct from CV Match Check, running behind a callable function with Gemini (free tier) and no key in the app.
- **Output:** backend `functions/src/validate-cv.ts` with `handleValidateCv` (injectable download / text extraction / Gemini deps), `assertOwnedCvPath` (UID from the callable auth context; only `cvs/${uid}/…`, traversal and empty paths rejected), `parseValidationResponse` (markdown-fence tolerant, strict boolean), a `< 50` character short-circuit before Gemini, fail-open on unparseable model output, and safe `HttpsError`s. `index.ts` adds `geminiApiKey = defineSecret('GEMINI_API_KEY')` bound only to `validateCv`; `functions/package.json` adds `@google/generative-ai` and `pdf-parse` (v2 class API; the v1 `@types/pdf-parse` package was not kept because v2 ships its own types). App: `lib/models/cv_validation_result.dart`, `lib/services/cv_validation_service.dart` (callable + defensive result parsing + `FirebaseFunctionsException` mapping), `lib/features/applications/viewmodels/cv_validation_viewmodel.dart` (`ViewState`, user-scoped, repeated-tap guard, `cv_validation_result` event), and `lib/features/applications/widgets/cv_validation_step.dart` (loading / valid / invalid / failed, `Update CV` + `Retry`, shared components only). `cloud_functions` added to `pubspec.yaml`; `FakeCvValidationService` added to `test/helpers/fakes.dart`. Docs: architecture, analytics row 18 + funnel, G-24 update, DC-19, Run 14, README and review disclosure.
- **Verification:** `npm run build` → passed; `npm test` (functions) → **18 tests, 18 passed** (11 new, all external effects stubbed); `dart format lib test` → new/changed files formatted (`lib/app/bootstrap.dart` restored to its `dev` state); `flutter analyze` → **No issues found!**; `flutter test` → **275 tests, all passed** (+15: service parsing/error mapping, ViewModel loading/valid/invalid/repeated-tap/signed-out, step widget at 360 and 412 dp). Deploy, real PDF/Gemini calls, DebugView screenshot and device verification: **not run** (no dev Firebase project/credentials or model key on this machine), recorded as Run 14 rows 6–8.
- **Decision:** Accepted with one scope adjustment: the Apply flow screens do not exist yet, so the step is an embeddable `CvValidationStep` with `onValid` / `onUpdateCv` callbacks rather than a new route. No invented route or full Apply UI; the placement and the still-missing Figma frame are recorded as DC-19 and in G-24. The model choice (`gemini-2.5-flash-lite`) reuses the G-26 free-tier decision instead of re-deciding it.

---

## Session 2026-10-28: Saved internships (OpenCode)

Tool: OpenCode (`deepseek-v4.1-flash-free`), run in `prm323_lab3/` on Windows 11 with an Android emulator. Operator: Kim Hao.

### P-21: Recover the conflicted index and commit the Saved list
- **Request:** "resolve my current index first rồi chuyển qua nhánh feat/saved-internships", then "commit luôn".
- **Output:** diagnosed a half-applied `git stash pop` on `dev` (unmerged `lib/services/saved_internship_service.dart`, `saved_screen.dart` staged) whose stash base was `feat/saved-internships`; checked that the staged `saved_screen.dart` blob (`76a7ccf`) was identical to the stash copy before touching anything; `git reset --hard HEAD` on `dev`, `git checkout feat/saved-internships`, `git stash pop` (clean, stash dropped), `dart format` on the two feature files, then commit `569be13` with the known gaps written into the commit message.
- **Verification:** `flutter analyze` → `No issues found!`; `flutter test` → 125 passed; `dart format --set-exit-if-changed lib test` → `lib/app/bootstrap.dart` (pre-existing on the branch, not touched) still differs.
- **Decision:** Accepted as the starting point for the feature. The screen's direct service call, `AsyncValue` instead of `ViewState` and the missing tests were recorded as follow-ups; P-22 closes the MVVM gap for the toggle.

### P-22: Save Toggle on the Home cards
- **Request:** "xử lý tiếp hành động khi bấm bookmark save trên màn home, lưu ý tạo file gì hay code ở đâu phải thông báo và tổng hợp lại".
- **Output:** `SavedInternshipService` became an interface + `FirestoreSavedInternshipService` + provider, throwing `AppException` (permission-denied / network / not-found); the stream providers moved from `features/saved/screens/` to `lib/features/saved/viewmodels/saved_providers.dart`, plus `savedInternshipIdsProvider` for the bookmark state; new `SavedViewModel.toggle(internship, source:)` with the loading guard, `ref.mounted` checks and the `internship_save` event; `HomeScreen` wires `InternshipCard.isSaved` / `onSaveToggle` and shows a failure SnackBar through `ref.listen`; `FakeSavedInternshipService` and `saved_viewmodel_test.dart` added, `home_screen_test.dart` covers save, unsave and failure; docs updated in `analytics-plan.md` (row 7), `design-traceability.md` (Home row, DC-11, DC-14) and `test-report.md` (Run 8).
- **Verification:** `dart format lib test` → 78 files, 0 changed; `flutter analyze` → `No issues found!`; `flutter test` → **131 passed**. On-device save, DebugView screenshot and ARTEMIS case **not run** (the app session belongs to the developer's terminal); the exact manual step is recorded in `test-report.md` Run 8 rows 4 and 6.
- **Decision:** Accepted for MVVM, analytics and tests. Open: `SavedScreen` still calls the service directly and uses `AsyncValue` (its own PR), no unsave undo, and the on-device / DebugView evidence is pending.

### P-23: Emulator launched with `-qt-hide-window`
- **Request:** "mở android sao nãy h không mở được" (the Android emulator does not open).
- **Output:** no code change. `flutter devices` and `adb` both showed a healthy `emulator-5554`, and a screenshot pulled with `adb shell screencap` showed the app running on the Home screen; enumerating the top-level windows of `emulator.exe` / `qemu-system-x86_64` returned **no window at all**. The command line was `emulator.exe ... -avd Pixel_9 -qt-hide-window -grpc-use-token ...`, so the emulator ran headless. Killed it (`adb -s emulator-5554 emu kill`, then `Stop-Process` for the leftovers) and restarted it with `emulator.exe -avd Pixel_9` (no `-qt-hide-window`); the window then reported the title `Android Emulator - Pixel_9:5554`, booted (`sys.boot_completed=1`) and `flutter run -d emulator-5554 --dart-define-from-file=.env` built and installed the app.
- **Verification:** window enumeration before / after, `adb devices`, `getprop sys.boot_completed`, `dumpsys window` (`mCurrentFocus=com.group3.internly/.MainActivity`) and a device screenshot showing the Home screen. `flutter doctor` still reports `Android license status unknown`; builds still succeed.
- **Decision:** Accepted as an environment fix. No repository change; the correct launch command (`flutter emulators --launch Pixel_9`) is worth adding to the setup guide if it keeps coming up.

### P-24: Shared tab header for Saved Internships
- **Request:** "header của màn saved internship làm cho giống header của home, thiếu avatar, icon bell" (the Saved header should match Home; it is missing the avatar and the bell).
- **Output:** new shared `MainTabAppBar` (`lib/core/widgets/main_tab_app_bar.dart`) = `AppTopBar.main` + brand mark + bell (interim "Notifications are coming soon." SnackBar, G-04/G-13) + avatar → Profile. `HomeScreen` now uses it (its private `_BrandMark`, `_ProfileAction`, `_AvatarFallback` and `_showMessage` were removed instead of copied), and `SavedScreen` swapped `AppTopBar.main(title: 'Saved Internships')` for it with the tab title `Saved`. New `test/features/saved/saved_screen_test.dart` (both widths, bell, avatar → Profile, empty state, 48 dp targets) and a `MainTabAppBar` group in `test/core/widgets/components_test.dart`. Docs: traceability row 5, §3 App Bar, DC-20, `design-system.md` §2.6, `test-report.md` Run 9.
- **Verification:** `dart format lib test` → 80 files, 1 changed; `flutter analyze` → `No issues found!`; `flutter test` → **140 passed**; `flutter build apk --debug` → `✓ Built build\app\outputs\flutter-apk\app-debug.apk`; installed on the emulator and screenshotted at 412 dp (`wm size` 1080x2424) and 360 dp (`wm size 945x2120`) — the header matches Home and the title does not clip.
- **Decision:** **Modified**: the AI first proposed keeping the title `Saved Internships`; measured against the 360 dp bar it clips, so the title follows the bottom-navigation label (`Saved`) and the change is recorded as DC-20 for the design owner.

### P-25: Drop the brand mark from the tab header
- **Request:** "bỏ cái icon kế bên đi, chỉ giữ chuông và avatar" (remove the icon on the left; keep only the bell and the avatar).
- **Output:** `MainTabAppBar` no longer passes `leading` / `leadingWidth`, and the private `_BrandMark` class plus the `app_radii` / `app_spacing` imports were deleted; the title now starts at the `AppTopBar` default `kMiddleSpacing` (16 dp), which equals `AppSpacing.screenHorizontal`, so it lines up with the content below. `app_top_bar.dart` only had its `leading` doc comment corrected. Tests now assert the absence (`find.byIcon(Symbols.school_rounded)`, `findsNothing`) instead of the `Internly` semantics label. Docs: DC-20 rewritten, `design-system.md` §2.6, traceability §3, `test-report.md` Run 9 row 7, and both evidence screenshots re-captured.
- **Verification:** `dart format lib test` → 80 files, 0 changed; `flutter analyze` → `No issues found!`; `flutter test` → **140 passed**; `flutter build apk --debug` → `✓ Built`; reinstalled on the emulator and screenshotted the Saved tab at 412 dp and 360 dp (`wm size 945x2120`, then reset) — bell and avatar only, title flush with the 16 dp margin. Title width measured with the bundled Inter font through a temporary `TextPainter` test (deleted afterwards): `Saved` = 72.6 dp, `Saved Internships` = 211.2 dp against 244 dp available.
- **Decision:** Accepted. `Saved` stays the title: with the brand mark gone the long name would fit today, but only with ~33 dp of slack, which clips as soon as the system font scale grows. Offered restoring `Saved Internships` to the team instead of deciding unilaterally.

### P-26: Unsave with Undo on the Saved screen
- **Request:** implement the Flow 2e.1 interaction — tapping the bookmark on a Saved card removes it immediately and shows a dark Snackbar with a check-circle icon, `Removed from Saved` and `Undo`; Undo restores the item, letting the Snackbar time out keeps it removed; no duplicate Snackbars, errors handled, only the Saved feature touched.
- **Output:** `SavedViewModel` gained `remove(internship)` and `restore(internship)` (returns `SavedWriteResult = ({bool done, AppException? error})`, with a shared `_writing` guard). They reuse `SavedInternshipService.remove/save`, so Undo writes the same `users/{uid}/savedInternships/{key}` document and logs `internship_save(source: saved)`; failures are returned instead of stored in `AsyncValue` because `HomeScreen` already listens to that state and would show the message twice. `SavedScreen` now calls the ViewModel instead of the service directly, shows the dark Snackbar (`check_circle` + `Removed from Saved` + `Undo`, `persist: false`, 16 × 12 dp padding), replaces the current Snackbar on a second unsave, and shows the service message + `Retry` on failure. `AppTheme` resolves the inverse-surface helper (`colorScheme.inverseSurface` / `onInverseSurface` / `inversePrimary`) and gives `SnackBarThemeData` the dark surface, the `primary-container` action label and radius 12. Tests: 5 ViewModel cases, 6 screen cases at 360 / 412 dp and 1 theme case. Docs: `design-system.md` §1.1 / §2.13–2.14, traceability row 5, §3, DC-21, `analytics-plan.md` row 7, G-07, `test-report.md` Run 10.
- **Verification:** `dart format lib test` → 80 files, 2 changed; `flutter analyze` → `No issues found!`; `flutter test` → **152 passed**; focused `flutter test test/features/saved test/theme` → 34 passed. On-device unsave / Undo, the DebugView screenshot for `internship_save(source=saved)` and an ARTEMIS case are **not run** (no signed-in session owned by this agent, no ARTEMIS daemon); recorded in `test-report.md` Run 10 rows 6–8. Found while testing: Flutter 3.47 makes a SnackBar with an action persist by default, so the undo Snackbar sets `persist: false`.
- **Decision:** Accepted for the Saved slice; the documented 4 s Undo window follows the reference and Lab 2 ("Snackbars hide after a few seconds"). The Snackbar has no Figma spec (G-16), so its tokens are recorded as DC-21 for the design owner.

### P-27: Saved loading state with card skeletons
- **Request:** do the loading state of the Saved screen next. Lab 2 asks for loading / empty / error; the screen still showed a centered spinner with `Loading saved internships...`.
- **Output:** `SavedScreen` now renders the loading state as a `Column`: the static work-mode shortcut row (extracted into `_filterChips()`, shared with the loaded state, still tappable while the first snapshot arrives) plus a `ListView.builder` of 3 `InternshipCardSkeleton`s, wrapped in one `Semantics(container, liveRegion, label: 'Loading saved internships')` + `ExcludeSemantics` so a screen reader announces the state once instead of reading placeholder boxes. `StateView.loading` is no longer used by Saved. The saved count is deliberately not rendered while loading, so the screen never shows a fake `0 saved`.
- **Verification:** `dart format lib\features\saved test\features\saved` → 5 files, 0 changed; `flutter analyze` → `No issues found!`; `flutter test test\features\saved` → **23 passed**; `flutter test` → **154 passed**. The 2 new cases hold the first snapshot open with a `StreamController` (new optional `savedStream` in the test helper, overriding `savedInternshipsProvider`) and assert the 3 skeletons, the semantics label, no spinner and no empty state at 360 / 412 dp, then that the real cards replace them. On-device cold load and an ARTEMIS case are **not run**; recorded in `test-report.md` Run 11 rows 6–7.
- **Decision:** Accepted; the skeleton pattern and count are the same shape as Home (2 cards there), so the two lists load identically. No design deviation: the Loading specimen already documents card-shaped skeletons, so no DC entry was added; `design-system.md` §2.9 now names both screens that use it.

### P-34: Internship Detail screen (Flow 1 end)
- **Request:** "Bắt đầu Detail" — build Internship Detail (Hoàng Anh's screen, Flow 1: Job Detail → Check CV → Upload / Select CV → Pre-submit) from the Lab 2 frames on Figma page 03, on a branch from `dev`.
- **Output:** `Internship` parses `description`, `job_highlights` (`JobHighlight`), `schedule_type` and `via` from the stored raw job; `InternshipService.watchByKey(key)` (null when the listing left the pool; a malformed document is reported to Crashlytics and treated as unavailable); `skillMatchFor` / `SkillMatch` in `core/utils/skill_match.dart`; `InternshipDetailViewModel` (family on `(internshipKey, source)`, `ViewState<InternshipDetail>`, saved-copy fallback, Profile skills and `cv_match_enabled` recomputed live, `view_internship` once); `InternshipDetailScreen` with Detail-only widgets (`SkillMatchCard`, `DetailMetaTile`, `DetailSectionCard`, `DetailBulletItem`, `DetailBenefitItem`, `DetailBottomBar`, `DetailSkeleton`); routes `/home|search|saved/internships/:jobKey` on the root navigator; Home and Saved cards open it; `SavedViewModel.toggleAndReport` so the Detail SnackBar is not duplicated by Home's listener; token `AppSizes.companyLogoLarge` (48). Docs: traceability row 4, Flow 1, §3, DC-24; analytics rows 6–7; G-24 update; `design-system.md`; `test-report.md` Run 15. Figma specs read with the Figma MCP (layout, text styles, copy of the Saved / Save failed / Error / Expanded frames).
- **Verification:** see `test-report.md` Run 15 (format, analyze, full test suite, debug APK with the team key, emulator check).
- **Decision:** Accepted, with deviations recorded as DC-24 (Google Jobs fields; Skill match from Profile skills only; `Apply now` shows a coming-soon SnackBar until the pre-submit slice). Found while testing: the per-chip semantics labels of the Skill match were merged into the parent node, so each chip is now its own semantics container.

### P-35: Skill match card for a profile without skills
- **Request:** the developer's screen recording showed `0% skill match` + `Low match` on Internship Detail for an account with no Profile skills; "Sửa luôn" (fix it).
- **Output:** `SkillMatch.profileHasSkills`; `SkillMatchCard` shows `See how you match`, `This internship asks for N skills`, neutral Skill Tags (semantics label = skill name, not "missing") and a text `Add skills` button that opens Profile; a profile with skills but no overlap still gets the honest `0% skill match` / `Low match`. Tests: 1 unit, 2 widget. DC-24 point 3 updated.
- **Verification:** `flutter analyze` → `No issues found!`; `flutter test` → **342 passed**; on-device check in `test-report.md` Run 15.
- **Decision:** Accepted. Also answered from the same recording: the stretched frames are Android 12+ stretch overscroll; left as is (platform default on every scrollable screen; changing it is an app-wide team decision).

---

### P-21: Search Results UI and Real Firebase Data Integration
- **Request:** implement Search Results screen matching the Figma/Lab 2 design without hardcoding, reading real listings from Firebase Firestore, supporting query, work mode filter chips, result count, sorting (most recent / best match), bookmarking/saving, and state handling.
- **Output:**
  - Built `SearchResultsScreen` (`lib/features/internships/screens/search_results_screen.dart`) with top bar actions, `AppSearchField` with filter badge, active filter chips (`✓ Remote ✕`, `✓ Flutter ✕`, `Clear filters`), dynamic result count header with green indicator, sort options popup, `InternshipCard` list, footer matching Figma, and ViewState handling (loading skeletons, empty state with clear filters, error with retry).
  - Built `SearchResultsViewModel` (`lib/features/internships/viewmodels/search_results_viewmodel.dart`) using Riverpod `Notifier` to query Firestore `InternshipService.watchActive()`, filter dynamically by search query (title, company, skills, keywords) and work arrangement, sort results, manage saved state, and record to `SearchHistoryService`.
  - Added `SearchResultsFilterSheet` (`lib/features/internships/widgets/search_results_filter_sheet.dart`) for interactive work arrangement selection.
  - Implemented `SavedService` (`lib/services/saved_service.dart`) under `users/{uid}/savedInternships` following rule 9.
  - Updated `AppSearchField` to display `filterCount` badge.
  - Wired `/search/results` in `router.dart` and connected search submit/trending skill/recent search navigation in `SearchScreen`.
  - Added `SearchFilterCriteria` (`lib/features/internships/models/search_filter_criteria.dart`) and full `SearchResultsFilterSheet` with work mode multi-select, location dropdown, skill chips, job type dropdown, allowance range dropdown, live matching count (`Show X results →`), and clear filters.
  - Added unit tests in `search_results_viewmodel_test.dart` and widget tests in `search_results_screen_test.dart` (360 and 412 dp).
- **Verification:** `dart format lib test` formatted cleanly; `flutter analyze` passed with 0 issues; `flutter test` passed all 170 tests (+19 tests).
- **Decision:** Accepted.

---

### P-33: Saved empty state opens Search
- **Request:** "trang saved nếu k saved bấm vào nút search phải navigate sang search screen" (on the Saved tab with nothing saved, the search button must open the Search screen).
- **Output:** the `Search internships` action of the Saved empty state called `_openSearch`, which only showed a "Search internships is coming soon." SnackBar; it now calls `context.go(AppRoutes.search)`, as the Home empty state does, and `_openSearch` was deleted. New widget test: tap `Search internships` on the empty list, expect the Search route and no empty state. While verifying, `dev` did not compile its tests: the merge `b025509` (dev → feat/search-ui) kept the `saved_service.dart` import in `test/helpers/fakes.dart` but dropped the `saved_internship_service.dart` import and the `FakeSavedService` class that the Search tests use; both were restored exactly as on `b025509^1`. Docs: traceability row 5, `test-report.md` Run 14.
- **Verification:** `flutter analyze` → `No issues found!`; `flutter test` → **351 passed**. On-device check **not run**.
- **Decision:** Accepted. The two parallel saved services (`SavedService` used by Search Results, `SavedInternshipService` used by Home and Saved) write the same `users/{uid}/savedInternships` collection; merging them is left to the Search owner and not done here.

### P-36: Detail on the new dev: Search Results link and Applied state
- **Request:** "tiếp tục công việc" (continue) after `dev` gained Search / Search Results (Lập) and My Applications with `ApplicationService` (another teammate).
- **Output:** working tree stashed, branch fast-forwarded to `origin/dev` `3c2c313`, stash re-applied; conflicts resolved in `router.dart` (search branch keeps `results` and gains the detail route), `router_test.dart`, `design-traceability.md` (dev already used DC-22 / DC-23, so the Detail deviation is **DC-24**) and `test-report.md` (Detail run is **Run 15**; the AI log entries are P-34 / P-35 because dev already used P-28–P-33). Search Results cards now `push` `/search/internships/:jobKey` instead of the placeholder `Selected …` SnackBar. `InternshipDetailViewModel` listens to `ApplicationService.watchApplications()`; an application for the listing shows the Figma "Internship Detail – Applied" Info Banner (`DetailAppliedBanner`) and `View application` (opens My Applications; Application Detail is not built). DC-24 point 11.
- **Verification:** `flutter analyze` → `No issues found!`; `flutter test` → **426 passed**. On-device check not run (emulator off, no application documents yet).
- **Decision:** Accepted. Noted for the team, not changed here: `dev`'s `test-report.md` no longer contains the Saved runs 9–11 that existed at `7f7a1dd` (lost in a merge), and the AI log has duplicate IDs P-21–P-27.

---

### P-38: Plain-text listing descriptions
- **Request:** "fix luôn phần này": some descriptions showed raw Markdown such as `## Job Purpose` on Internship Detail.
- **Output:** `core/utils/listing_text.dart`: `plainListingText` (drops heading `#`s and bold markers, turns `-` / `*` / `+` list markers into `• `, removes horizontal rules, collapses blank-line runs) and `plainListingItem` for `job_highlights` items. `Internship.fromSerpApi` stores the cleaned description and items; skills and allowance are still read from the raw text, and the Firestore document is unchanged. Tests: 6 helper cases (incl. `C++`, `C#` and `#hashtag` left alone), 1 model case.
- **Verification:** `flutter analyze` → `No issues found!`; `flutter test` → **433 passed**; checked on the emulator (`test-report.md` Run 15 row 11).
- **Decision:** Accepted; plain text instead of a Markdown renderer, so no new dependency (AGENTS.md rule 10).

---

## Entry template

```markdown
### P-nn: <short title>
- **Request:** <summary of the task, or a link to docs/records/prompts/P-nn-….md>
- **Output:** <files / behavior changed>
- **Verification:** <commands + real results, manual checks, or "not verified">
- **Decision:** Accepted / Modified (<how>) / Rejected (<why>)
```
