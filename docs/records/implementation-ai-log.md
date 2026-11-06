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

### P-37: Search Field on one line
- **Request:** screenshot of the Search field with its placeholder on two lines; "fix lại nào cho thành 1 dòng thôi" (make it one line).
- **Output:** `AppSearchField` defaults to one line (`maxLines: 1`, `hintMaxLines: 1`) with the placeholder `Search role, company, skill`; new `wrapHint` keeps the previous two-line behavior, used by Profile › Edit skills (DC-16). Tests and docs: `components_test.dart`, DC-25, `design-system.md` §2.3, `test-report.md` Run 16.
- **Verification:** placeholder widths measured in the real field (Run 16 row 1); `flutter analyze` → `No issues found!`; `flutter test` → **385 passed**.
- **Decision:** Modified: the first candidate (`Search roles, companies, skills`) was measured against a 360 dp field instead of a 360 dp screen and still wrapped; the widget test caught it and the shorter copy was chosen. Figma still shows the wrapping specimen (DC-25 to update).

---

### P-39: Filters from the Search tab, location matching, one drag handle
- **Request:** "tui handle phần search và filter á" (Flow 1 includes Search Jobs → Filter & Sort): the Search tab filter icon said "More filters are coming soon."; then "kiểm tra lại phần filter location" and "UI bị thừa" (two drag handles on the Filter sheet).
- **Output:** the filter predicate moved from `SearchResultsViewModel._applyFilters` to `SearchFilterCriteria.matches` (shared); `SearchViewModel.countMatching` previews the sheet from the pool it already streams; the Search filter icon opens `SearchResultsFilterSheet` seeded with the selected work mode, and `Show N results` goes to `/search/results` with the criteria as `extra` (`SearchResultsScreen.initialCriteria`). Location used a plain `contains` of the English option in Google's Vietnamese text, so `Ha Noi` / `Da Nang` matched almost nothing; it now uses `matchesPreferredLocation` (accent folding + aliases, as Home). The sheet's own drag handle was removed because `BottomSheetThemeData.showDragHandle` already draws one.
- **Verification:** `flutter analyze` → `No issues found!`; `flutter test` → **391 passed**; on device: `test-report.md` Run 16 rows 5–6.
- **Decision:** Accepted. Left for a follow-up: duplicate listings in Search Results and the `search_filter_apply` event.

---

### P-40: Search analytics and distinct Search Results
- **Request:** "Sửa nhanh trước" after the Flow 1 audit: log `search` from the Search tab / Search Results and `search_filter_apply`, show each job once in Search Results, and update the Flow 1 status in the docs.
- **Output:** `distinctListings` / `compareBySyncRank` / `compareByNewest` moved from `HomeViewModel` to `lib/core/utils/distinct_listings.dart`; `SearchResultsViewModel` and `SearchViewModel` (trending counts, filter preview) use it. `SearchResultsViewModel` keeps the searched term and the filter-sheet source pending until results are computed, then logs `search` (`search_term`, `result_count`, `source = search`) and `search_filter_apply` (`work_mode`, `location`, `skill_count`, `result_count`, `source = search` / `search_results`); Home adds `source = home`. Docs: analytics-plan rows 4–5, design-traceability rows 2–3 and Flow 1, test-plan TC-04 copy (`No internships found`), `test-report.md` Run 17.
- **Verification:** `flutter analyze` → `No issues found!`; `flutter test` → **451 passed**; on device and DebugView: Run 17 rows 3–5.
- **Decision:** Accepted. Kept `elapsed_sec` Home-only (the Search tab has no start time to measure from); a work-mode-only search from the Search tab logs no `search` because there is no term.

---

### P-41: Apply Form (Flow 1 pre-submit)
- **Request:** "làm UI nào trong flow 1 chưa làm" — the Flow 1 part after `Apply now`: Check CV → Upload / Select CV → Pre-submit Complete, with CV upload failed → Retry. Answers to the design questions: only the CV part of the Lab 2 Application Form; a CV uploaded here is for this internship only (Profile unchanged); `Continue to review` says the review step is coming soon until Flow 4 exists.
- **Output:** `ApplyFormViewModel` (listing via `watchByKey` + saved copy, Profile CV, upload through `DocumentPickerService` / `FileStorageService` with progress, Retry, `Use CV from Profile`, Preview, `continueToReview()`; `apply_start` and `cv_upload` `source=apply_form`), `ApplyFormScreen` and `apply_form_parts.dart` (step header, summary card, banner, CV section states, bottom bar, skeleton); routes `/{tab}/internships/:jobKey/apply` (`{tab}_apply_form`); Detail `Apply now` pushes it; `CvFileTile` moved to `core/widgets` (Profile imports updated); `DetailSectionCard.isRequired`. `FileStorageService` caps upload retries at 30 s (`maxUploadRetryTime`, found on device). Docs: design-traceability row 6, Detail and Flow 1 rows, components, DC-24 (6), DC-26; analytics-plan rows 8 and 17; `test-report.md` Run 18.
- **Verification:** `flutter analyze` → `No issues found!`; `flutter test` → **475 passed**; Figma frames read with the Figma MCP (`Application Form`, `Form · Empty`, `Form · CV uploading`, `Form · CV upload failed`, `Form · Validation error`, `Replace CV sheet`); on device: `test-report.md` Run 18 rows 3–4. The device check found that an offline upload never failed (Firebase Storage retries for 10 minutes), so `FileStorageService` now caps upload retries at 30 s (`maxUploadRetryTime`); the failure + `Retry` then appeared after 36 s.
- **Decision:** Modified from the Lab 2 frames as recorded in DC-26 (team decision for the CV-only step, platform limits for PDF ≤ 10 MB / no Cancel / system picker). Hand-off to Flow 4 (`jobKey`, CV `storagePath`, `cv_source`) waits for Hảo's route.

---

### P-42: Apply Form summary facts, skill match line, Profile CV sheet
- **Request:** "phần upload CV chỉ có tên công ty thôi thì UI hơi trống" → accepted suggestions: location fallback + allowance / job type on the summary card and a skill match line with `Edit skills`; then "phần upload CV hay replace CV ở phần profile và Apply đồng bộ UI với nhau, sửa phần ở Apply giống profile" (screenshot of Profile › Update CV).
- **Output:** `ApplySummaryCard` (location fallback, `_SummaryFact` allowance / job type), `ApplySkillMatchLine` + `ApplyFormState.skillMatch` (`skillMatchFor`, Remote Config `cv_match_enabled`); `ProfileSheet` / `showProfileSheet` moved to `core/widgets/app_sheet.dart` as `AppSheet` / `showAppSheet` (Profile sheets updated); the Update CV layout extracted to `core/widgets/cv_upload_sheet.dart` (`CvUploadSheet`), used by Profile `UpdateCvSheet` and the new `ApplyCvSheet`; `ApplyFormViewModel` now selects a file (`chooseCv`, `removeSelected`) and uploads on the primary action (`uploadSelected`), and `closeCvSheet` drops an unsent file or error. Docs: DC-26 items (1), (4)–(6), components row, Run 18 rows 6–8.
- **Verification:** `flutter analyze` → `No issues found!`; `flutter test` → **483 passed** (Profile tests unchanged); on device: Run 18 row 7.
- **Follow-up request:** "Info Banner đẩy lên trên phần skill và phần skill bấm vào view more thì có thể xem được" → the banner now sits under the summary card (`ApplyFormScreen._banner`, which also removes an empty gap when no banner applies), and `ApplySkillMatchLine` is stateful with `Show all skills` / `Show fewer` (named like Detail's `Show all N benefits` / `Show fewer`) listing every missing and matched skill (`Skills: …` when Profile has none). Verified: 483 tests passed; device Run 18 row 9.
- **Decision:** Accepted. The Profile sheet's look and copy did not change; only its code moved. Tip copy kept as in Figma (not changed without a decision).

---

### P-43: Job type filter and Applied badge
- **Request:** Flow 1 audit → "Sửa cả hai": the Job type option of the Filter sheet was counted as a criterion but never applied, and the Flow 2c `Applied` badge was not shown on cards.
- **Output:** `SearchFilterCriteria.matches` checks `Internship.scheduleType` against folded English and Vietnamese words per option (listings without a type are left out); `appliedInternshipKeysProvider` (`features/applications/viewmodels/applied_providers.dart`) maps `ApplicationService.watchApplications()` to job keys; `InternshipCard.isApplied` draws the `Applied` `StatusBadge` and adds "Applied" to the card's Semantics summary (the visible details are excluded from semantics, so a plain `badge` was not read aloud); Home, Search Results and Saved pass it. Tests: criteria job type group, badge tests on the three screens (provider overridden). Docs: design-traceability rows 1, 3, 5 and Internship Card; Run 19.
- **Follow-up (same day):** on device every Job type gave 0 results. Reading 28 documents in the Firestore console showed the `hl=vi` sync gets no `detected_extensions`; the schedule type and posted age are only in `raw.extensions` (Vietnamese). Added `lib/core/utils/listing_extensions.dart` (`scheduleTypeFromExtensions` → English labels, `postedTextFromExtensions`), Vietnamese ages in `parsePostedAge`, the fallback in `Internship.fromSerpApi`, and `formatPostedAgeLong` for the Detail meta row (`Posted 3 days ago`, user: "thiếu 2 thông tin này ở intern detail"). `Apply by` stays out: the data has no deadline. Docs: G-25 #8, DC-24 (1), Run 19 rows 3–6.
- **Verification:** `flutter analyze` → `No issues found!`; `flutter test` → **500 passed**; on device `Internship` → 38 of 83 (Run 19 row 6).
- **Follow-up:** "cái badge saved này nó đang không tự tắt do tui lag hay code lỗi" → code: the Detail `Saved to your list` SnackBar had an action and no `persist: false`, so it never timed out. Fixed and covered by a test that fails without the fix; `flutter test` → **501 passed** (Run 19 row 7).
- **Decision:** Accepted. The first badge version used the card's `badge` slot; the test showed it was not in the semantics tree, so `isApplied` was added instead.

---

### P-44: AI code review R1 of PRs #11–#15 and fixes
- **Request:** "ok làm mục 1" — run the Lab 3 §8 AI code review on Hoàng Anh's PRs and record it.
- **Output:** three Claude Code review subagents (fresh context, only the PR diff and AGENTS.md) reviewed PR #11, PR #14, and PRs #12/#13/#15; raw outputs saved in `evidence/code-review/`. 20 findings (CR-01 – CR-20): 13 accepted, 5 modified, 2 rejected, each with a reason in `docs/code-review.md`. 18 fix commits `fix(CR-xx)` / `test(CR-xx)` on `fix/code-review-r1` (Detail SnackBar actions and Save semantics, expired listing after unsave, C# headings, Saved write path, Applied by job identity, merge after filter, unaccented query, background history write, allowance options, filter analytics, Apply Form Continue after a failed upload, Edit skills over the form, Profile load error, Profile tip). Docs: G-32, analytics row 5, DC-26 (8), Run 20.
- **Verification:** every accepted bug was first reproduced by a failing test (Run 20 row 1); `flutter analyze` → `No issues found!`; `flutter test` → **525 passed**.
- **Decision:** Modified where the suggestion broke something else (CR-09 `foldText` would make `C#` match every `C`) or touched another owner's data (CR-07 Saved part); CR-11 and CR-17 rejected with reasons and recorded in G-32. R2 not needed: no blocker or major left open.

---

### P-45: Work mode from the listing text (the Work mode filter returned none)
- **Request:** "kiểm tra giúp tôi phần work mode, chỗ đó hiện tôi filter luôn không có kết quả nào cả" — selecting On-site / Remote / Hybrid in the Filter sheet always ended in an empty list.
- **Output:** **Cause:** `Internship.fromSerpApi` read the work mode only from `title` and `extensions`; the `hl=vi` sync has no `detected_extensions` and the Vietnamese chips carry only the schedule and posted age, so `workMode` stayed `null` for 288 of 289 IT listings (recorded in `recommendation.dart` and Run 12) and the filter excluded every one of them. Detection now also reads the location, description and highlight items, but only for explicit wording (`remote work`, `work from home`, `làm việc từ xa`, `làm việc tại nhà`, `hybrid working`, `on-site`, `làm việc tại văn phòng`); a listing that states both office and home counts as hybrid, and a bare "hybrid" in a description is not used because it usually means a hybrid mobile app. Files: `lib/models/internship.dart`, `test/models/internship_test.dart`, `test/features/internships/search_filter_criteria_test.dart`; docs: G-25 #9, Run 21.
- **Verification:** `dart format lib test` → 1 file changed; `flutter analyze` → `No issues found!`; `flutter test` → **533 passed** (+8: 5 model tests for title/chips/location, explicit Vietnamese and English wording, both arrangements → hybrid, the "hybrid app" / "remote server" false positives, no wording → `null`; 3 filter tests for selected modes, unknown left out, no mode keeps all). On device not run.
- **Decision:** Accepted. Reading the description follows the accepted allowance fallback (P-28/G-17); a listing that does not state its arrangement stays `null` and is left out instead of being guessed (rule 7).

---

### P-46: Filter skills from the pool, not a fixed list
- **Request:** "à chỗ skill ở filter, chỗ đó đang fix cứng là vậy hay dựa vào phân tích CV mà có" → "thay thế giúp tôi".
- **Output:** the Filter sheet had a fixed `_suggestedSkills` list (Flutter, React, NestJS, Java, UI/UX, Data) that was not tied to the CV, the profile or the pool. Added `suggestedFilterSkills` (`lib/core/utils/skill_suggestions.dart`): it counts the skills the current listings actually mention, most common first, ties in `knownSkills` order (the vocabulary `findSkills` tags listings with) and then alphabetically, capped at the sheet's 6-chip row. `SearchViewModel` and `SearchResultsViewModel` expose it from the raw pool (duplicates merged first, CR-08), both screens pass it to `SearchResultsFilterSheet`, and the Skills section hides until the first snapshot instead of showing chips that cannot match. A skill already selected stays visible even if the pool no longer mentions it, so it can still be removed. CV validation was not used: `validateCv` returns validation results, not a skill list.
- **Verification:** `dart format lib test` → 0 changed (1 earlier); `flutter analyze` → `No issues found!`; `flutter test` → **538 passed** (+5: `skill_suggestions_test.dart` order, vocabulary tie, alphabetical tie, empty pool, 6-chip cap; the sheet test now asserts the pool's Flutter / Dart / Node.js chips, that fixed `React` is gone, and that tapping Flutter narrows the count). On device not run.
- **Decision:** Accepted. The pool is the honest source for a filter over listings; Profile skills are not used yet because a skill absent from the pool would be a chip that always yields zero results.

---

### P-47: Flow 2 completion (Validate CV → Review → Success)
- **Request:** the pasted implementation plan "Complete Flow 4 (Application)": wire CV Validation into the Apply flow, add Application Review and Success screens, `ApplicationService.createApplication()`, the router steps and the `application_create` event, then tests and docs.
- **Output:** `CvValidationScreen` (`features/applications/screens/`, wraps `CvValidationStep`, `Update CV` pops back to the form); `ApplicationReviewViewModel` (`ViewState<Internship>` + `ViewState<UserProfile>` + `AsyncValue<void> submit`, `ApplySession` = CV + `apply_start` time, guarded double tap, `application_create`); `ApplicationReviewScreen` (step 2 header, `ApplySummaryCard`, CV card, five profile rows, submit bar with `FormMessage` + loading); `ApplicationSuccessScreen` (confirmation, recap, `View my applications` / `Back to home`); `ApplicationService.createApplication()` writing `users/{uid}/applications/{jobKey}` (`title`, `companyName`, `appliedAt` server timestamp, `status`, `cvStoragePath`) with write-specific `AppException` messages; `ApplyStepHeader.review` variant; `ApplyFormState.startedAt`; routes `.../apply/validation`, `.../apply/review`, `.../apply/review/success` with `{tab}_cv_validation` / `{tab}_application_review` / `{tab}_application_success` screen names; the Apply Form's `Continue to review` placeholder replaced by navigation with `ApplySession`. Tests: `application_review_viewmodel_test.dart` (8), `application_review_screen_test.dart` (7, both widths and the 48 dp guideline), `application_success_screen_test.dart` (5), `FakeApplicationService.createApplication`, Apply Form hands the CV over, `AppRoutes` Flow 2 paths. Docs: design-traceability rows 6–9, Flow 2 and DC-27; analytics row 10; G-24 update; Run 23.
- **Verification:** `flutter analyze` → `No issues found!`; the three new test files → **20 passed** (review ViewModel 8, review screen 7, success screen 5); the new `AppRoutes` path test passes; `flutter test` full suite → **547 tests, all passed**. On the Android 17 (API 37) emulator `flutter run -d emulator-5554 --dart-define-from-file=.env` builds, installs and launches (`com.group3.internly/.MainActivity` focused). Device logcat showed a real bug in the flow this task made reachable: entering Validate CV logged Riverpod's *"Tried to modify a provider while the widget tree was building"*, because `CvValidationStep.initState` starts `CvValidationViewModel.validate()` (which sets `state`) through `listenManual(..., fireImmediately: true)` and the uid is already known in the Apply flow. Fixed by starting the check in a post-frame callback; the regression test fails without the fix. The full suite was green only after Smart App Control (which blocks the unsigned `impellerc.exe`) was turned off on the development machine — before that, 9 unrelated tap-driven tests failed with a missing `ink_sparkle.frag` asset. Not verified: DebugView, the complete flow walked end to end, ARTEMIS.
- **Decision:** Accepted for the code; the design has no Figma frame for Review / Success, so they are built from existing components and recorded as DC-27. Deviations from the plan: no `cvStoragePath` field on `InternshipApplication` (it is written but never read, so the model stays as it is), `ApplySession` travels in the route `extra` instead of the ViewModel family key, and the success screen takes the recap from the route too. E2E TC-06–TC-08 and the DebugView screenshot remain open.

---

### P-48: Flow 3 Application Detail audit and gap closure
- **Request:** read the current source, check the Flow 3 plan (`plan-flow3-implement.md`) for mistakes or missing items, supplement it, and implement what remains.
- **Output:** the audit found the feature already implemented on `feat/application-detail` — `ApplicationDetailScreen` (`ApplicationIdentityCard`, `ApplicationStatusTracker`, `ApplicantCard`), `ApplicationDetailViewModel` (`ViewState`, retry, withdraw + Undo within 24 h, `view_application` once), route `application_detail`, card / `Review offer` / `View application` navigation, model snapshot fields (`cvFileName` / `cvUrl` / `cvStoragePath`, `applicant`, `withdrawnAt` / `previousStatus`) and `ApplicationService.watchApplications()` + `withdraw` / `undoWithdrawal`. The plan was stale in several places (it deferred withdraw, assumed a `watchApplication(jobKey)` method and `CvFile` / `ApplicantSnapshot` models that do not exist, and reused deviation ID DC-27, which belongs to Review / Success). Closed the real gaps: added `e2e_test/test_applications.py` (TC-09 happy path, TC-10 airplane-mode recovery); corrected `analytics-plan` row 11 to Implemented; marked TC-09/TC-10 Ready (not run) and added their result rows in `test-plan.md`; defined the missing DC-29 in `design-traceability.md`, superseded DC-22 (d)–(f) and updated DC-24 item 11; updated the application schema and status rules in `architecture.md`; added Withdrawn to the badge table in `design-system.md` and resolved G-18 in `handoff-gaps.md`; recorded Run 24. `plan-flow3-implement.md` §2, §4–§7, §10.1 and §15 were corrected to the as-built contract.
- **Verification:** `dart format --output=none --set-exit-if-changed lib test` → **186 files, 0 changed**; `flutter analyze` → **No issues found!**; Flow 3 targeted tests → **33 passed**; `flutter test` → **583 passed**. Five full-screen device screenshots were captured on the Android emulator (1080 × 2400) with the real signed-in test account — `application-list`, `application-detail-submitted`, `application-detail-applicant`, `application-detail-withdraw-dialog`, `application-detail-withdrawn` — saved in `evidence/screens/application-*.png` (full screen, not redacted; the owner asked for the real test-account screenshots). `empty`, `rejected`, `error` and `loading` were not captured: the account has one application, there is no UI to set another status, and a network error cannot be produced deterministically. E2E TC-09/TC-10 written but **not run** (no ARTEMIS daemon/toolchain); DebugView not run.
- **Decision:** Accepted the existing implementation (it is ahead of the plan and covered by tests); the plan and docs were corrected rather than the code. Withdraw / Undo stays, because Flow 3d is part of the Lab 2 flow and the Application Detail withdrawn frame supplies the badge (G-18 resolved). E2E results and the DebugView screenshot remain open.

---

### P-49: Flow 3 Application Detail — full Figma alignment (option 1)
- **Request:** after the P-48 audit, the owner chose "Phương án 1 – Đồng bộ hoàn toàn với Figma": align the UI with the Figma frame, fix the navigation bug and the error copy, add the missing tests, update the docs and recapture evidence. Rules given: do not guess, ask when unsure, avoid re-reading files unnecessarily. `plan-flow3-implement.md` must be corrected wherever it no longer matches.
- **Output:** verified the audit against `docs/design/screenshots/application-detail-final.png` before changing anything; it found DC-29 itself wrong about the tracker (it described 5 steps including "Onboarding"; the frame has 4 and no Onboarding), so the docs were corrected to the frame rather than the code. Product changes: `application_status_tracker.dart` — 4 steps with the frame's names (`Technical interview`, `Offer decision`), a `Step X of 4 (Y% completed)` progress line, right-aligned step dates, and the duplicate badge removed from the identity card (it now lives only on the tracker); `application_identity_card.dart` — facts render as `surface-variant` chips and the raw `Divider(height: 1)` is gone; `applicant_card.dart` — the CV tile reads `{size} • Uploaded {date}` from a new `cvSizeBytes` recorded at submission, with the previous `PDF · Submitted {date}` kept for older documents; `internship_application.dart` / `application_service.dart` / `application_review_viewmodel.dart` — `cvSizeBytes` added to the model, the `createApplication` contract and the Firestore write; `application_detail_screen.dart` — heading `About {companyName}`, app-bar back and the empty state's `Back to Applications` use `context.go('/applications')` instead of `Navigator.maybePop` (which returned to Internship Detail), and `Withdraw application` is styled destructive with `AppColors.error` through a local `_DestructiveWithdrawButton` theme override (no new `AppButtonVariant`, per the design-system rule and the owner's choice); `application_service.dart` — `_toWriteAppException` takes the action name, so a failed withdraw / undo reads "We could not withdraw this application …" / "We could not undo this withdrawal …" instead of the generic apply-submission message. Tests: `application_detail_screen_test.dart` (4 steps + progress, `{size} • Uploaded`, generic CV fallback, single status badge, app-bar back to `/applications`, empty-state action to `/applications`, destructive button colour), `application_detail_viewmodel_test.dart` (withdraw- and undo-specific failure messages), `internship_application_test.dart` (`cvSizeBytes` present / absent), `test/helpers/fakes.dart` (`CreatedApplication.cvSizeBytes`). Docs: DC-29 rewritten to the frame (4 steps, progress, static step descriptions, `About {companyName}`, destructive withdraw, back behaviour, no verified tick, no Version 2.4, CV tile); `architecture.md` — `ApplicationDetailViewModel` Done with its real services (`ApplicationService`, `InternshipService`, `ExternalLinkService`, `AnalyticsService`) and `cvSizeBytes` in the application schema; `handoff-gaps.md` — G-18 table row Resolved with the page-05 specimen note; `design-system.md` — §2.12 "6 specimens".
- **Verification:** `dart format --output=none --set-exit-if-changed lib test` → **0 changed after formatting**; `flutter analyze` → **No issues found!**; Flow 3 targeted (`internship_application_test`, `test/features/applications/`, `test/app/router_test.dart`) → **88 passed**; `flutter test` (full suite) → **593 passed**. No screenshots or E2E were captured in this entry: the emulator was not run and ARTEMIS is not available on this machine — recapturing `evidence/screens/application-*.png` from the new build is still open (the existing five were taken before these changes and no longer match).
- **Decision:** Applied. Accepted the design system rule that `AppButton` gains no destructive variant; the withdraw styling stays local to the screen and is recorded in DC-29. Rejected the audit's suggestion to render the frame's per-step process captions and the "Expected review outcome by" banner as static text: they describe one employer's process and the app has no such data (rule 7), so the tracker keeps its generic descriptions and real dates only, and DC-29 records that deviation. Kept `Year of study` out of the applicant rows (the frame does not show it). Kept the company card to logo / name / location (API limit, DC-24).

---

### P-50: FCM in all three app states + Notification Center
- **Request:** "FCM: nhận thông báo ở cả 3 trạng thái app — cài firebase_messaging, xin quyền (Android 13+), gửi test message từ Firebase console, chụp evidence/fcm/. Notification Center: lưu `users/{uid}/notifications`, bấm mở đúng màn, chuông thay câu coming soon, log `notification_center_open`."
- **Output:** added `firebase_messaging` 17.0.0 (pinned) and `POST_NOTIFICATIONS`; `models/app_notification.dart`; `services/notification_service.dart` (permission, token + `users/{uid}.fcmToken`, `users/{uid}/notifications` listener with malformed-document logging, deep link payload, top-level background handler); `app/notification_coordinator.dart` (foreground SnackBar + history, background / terminated open → history + read + navigate, safe route validation in `core/utils/notification_target.dart`); `features/notifications/` (ViewModel with `ViewState`, read mark, `notification_center_open` once, screen with skeleton / empty / error + Retry, tile with unread dot + Semantics); route `/profile/notifications`; every app-bar bell now opens the Notification Center; Profile → Diagnostics gained `Copy FCM token`; `formatRelativeTime`; fakes and 30 new tests. Docs: `analytics-plan` row 15, `architecture` table/services, `design-traceability`, `handoff-gaps` G-04/G-13, `firebase-setup` §9, Run 26.
- **Verification:** `dart format lib test` 202 files; `flutter analyze` → **No issues found!**; targeted notification/profile tests → **44 passed**; `flutter test` → **624 passed**; `flutter build apk --debug --dart-define-from-file=.env` → **✓ Built** (73.7 s); on `Medium_Phone_API_37.0` (API 37, Play Store image) the app opened signed in, the permission dialog appeared, `POST_NOTIFICATIONS: granted=true`, `Copy FCM token` showed `FCM token copied.`, and the bell opened `No notifications yet`. FCM delivery in the three states and the DebugView check are **not run** (need console test messages).
- **Decision:** Accepted. A console test message gets a notification payload; on Android the background isolate only runs for data messages, so background/terminated history is written when the notification is tapped (`onMessageOpenedApp` / `getInitialMessage`), which keeps the entry honest without a backend. Foreground messages show an in-app SnackBar (no `flutter_local_notifications` dependency and no extra Android desugaring). `getToken()` is kept (with a reasoned `ignore`) because the console's test-message field takes the FCM registration token although FlutterFire 17 deprecates it in favour of the FID API.

---

### P-51: Search bell, token refresh and the FCM evidence follow-up
- **Request:** "kiểm tra xem còn thiếu gì không" then "làm lần lượt giúp tôi": close the gaps found in the FCM / Notification Center audit (Search tab had no bell, no `onTokenRefresh` handler, evidence and docs incomplete).
- **Output:** `SearchScreen` now uses `MainTabAppBar` (title → bell → avatar, as design-system §2.6 requires for every bottom-navigation destination); `NotificationService.tokenRefreshes()` added plus `NotificationCoordinator._storeToken`, so a rotated FCM token updates `users/{uid}.fcmToken` (the deprecated `onTokenRefresh` carries a reasoned `ignore`, like `getToken()`); `FakeNotificationService.refreshToken()`; `test/app/notification_coordinator_test.dart` (2 cases); `search_screen_test.dart` now provides a `FakeAuthService`, asserts both app-bar actions at 360 / 412 dp and that the bell opens the Notification Center; docs: Run 27, this entry, `firebase-setup` §9 token bullet.
- **Verification:** `dart format` 0 changed; `flutter analyze` → **No issues found!**; targeted tests → **58 passed**; `flutter test` → **627 passed**; on `emulator-5554`, console test messages arrived in the foreground, background and terminated states (screenshots in `evidence/fcm/`), and after `setprop debug.firebase.analytics.app` + restart the bell produced `FA-SVC ... name=notification_center_open ... unread_count=7` in logcat. Tap-to-destination screenshot and the DebugView browser capture are **not run**.
- **Decision:** Accepted. The Search tab gains the same two actions as the other tabs instead of a bell-only variant, because the design system says the bar is identical on every destination. Token refresh follows the existing deprecated-token workflow (console test messages take the FCM registration token, not the FID from `onRegistered`).

---

### P-52: Local admin dashboard (FCM, users, notification history)
- **Request:** "một số tác vụ đang phải chạy lên Firebase… notification, nút crash… tạo một web dashboard cho admin để quản lý, không cần chạy lên Firebase nữa." Answers: local on this machine; send notification, users + FCM token, view/delete notification history; the test crash stays in the app.
- **Output:** new `tools/admin-dashboard/` (Node 20+, Express 4, firebase-admin 13): `server.js` exposes `GET /api/status`, `GET /api/users` (Firestore `users` joined with Firebase Auth for email/display name), `GET /api/notifications?uid=`, `DELETE /api/notifications/:uid/:id`, `DELETE /api/notifications?uid=`, `POST /api/send` (one user or all users with a token, `sendEachForMulticast` in chunks of 500, per-recipient result, optional history write); `lib/admin.js` holds the route/validation helpers; `public/` is a dependency-free dark UI with user filter, token copy, compose form, history list and delete; `npm test` covers the helpers. The service-account key is read from `INTERNLY_ADMIN_SA`, `GOOGLE_APPLICATION_CREDENTIALS` or `%USERPROFILE%\.internly-admin\service-account.json` (never in the repo); the server binds to `127.0.0.1` only. History documents use the FCM message ID as the document ID, the same ID the app writes, so server and client writes merge. Root `.gitignore` ignores `tools/admin-dashboard/node_modules/`; README docs table links the tool.
- **Verification:** `npm install` 237 packages; `npm test` → **6 passed**; `node --check` on `server.js`, `lib/admin.js` and `public/app.js` → clean; `node server.js` → UI, CSS and `/app.js` return **200**; `/api/status` reports the missing credential with the exact path and next step; `/api/users` returns **503** with the same hint. Real send/list/delete and the rendered UI were **not run**: the machine has no service-account key or `gcloud` ADC, and `agent-browser` is not installed. No dependency was added to the Flutter app.
- **Decision:** Accepted. Local-only instead of hosting: no deploy, no cost and no privileged credential on a server. The dashboard does **not** trigger crashes remotely (the app's debug crash control stays the only trigger), and does not replace Crashlytics/Remote Config, which still need the Firebase Console. Sending still requires a one-time service-account key from the Console; after that, day-to-day notification work happens in the dashboard.

---

### P-53: Admin dashboard — real send, message-ID fix, history and deep link
- **Request:** "đã add file json key vào rồi mà sao vẫn không nhận credentials", then continue verifying the dashboard with the real project.
- **Output:** the key the developer downloaded to the repository root was moved to `%USERPROFILE%\.internly-admin\service-account.json` (outside the repo, at the path the server reads). Found and fixed a real bug in `POST /api/send`: Firebase Admin returns `messageId` as `projects/<project>/messages/<id>`, which Firestore rejects as a document path; `lib/admin.js` gained `normaliseMessageId()` (trailing ID, the value `RemoteMessage.messageId` carries, so the server and app writes merge), server.js uses it for results and history writes, and a batch failure now returns `historyError` instead of failing an already-delivered send. `public/app.js` shows `historyError`. Added the message-ID unit test (7 dashboard tests). Docs: Run 28, this entry.
- **Verification:** `npm test` → **7 passed**; `node --check` clean; real key: `/api/status` → `prm-lab3 ready=True`, `/api/users` → 8 users; `POST /api/send` to the one token → `success=1 historyWritten=1`; the app showed the SnackBar, tapping **View** opened the **Saved** tab (screenshot `evidence/fcm/fcm-notification-tap-saved-20261106.png`); the history entry exists with the normalised message ID and `route=/saved`; deleting both test entries through `DELETE /api/notifications` worked. Background/terminated notification taps were not re-captured in this run.
- **Decision:** Accepted. Normalising the ID keeps a single history document per delivered message; the client and server both write the same document with `merge: true`. The server's 4317 instance must be restarted after adding the key because credentials are read once at startup.

---

### P-54: CV Match Check (G-24 / DC-09)
- **Request:** "giờ làm thêm phần CV match giúp tôi, có thể tham khảo web này, nó có chức năng CV match https://techjobs.vn/cv-match." Answers: per-internship step inside Apply; rule-based score + AI commentary (like techjobs); Form → CV Match → Validate CV → Review.
- **Output:** backend refactored to share CV helpers (`functions/src/cv-shared.ts`, with `validate-cv.ts` re-exporting and behaving identically) and added `skills.ts` (TypeScript port of `knownSkills` + word-boundary matcher), `match-cv-score.ts` (requirement split incl. nice-to-have sections, case-insensitive scoring from Profile + CV skills, fallback suggestions, tolerant commentary parsing) and `match-cv.ts` (callable handler: reads `internships/{key}` and `users/{uid}.skills`, downloads and extracts the PDF, computes the score, calls Gemini only when there are gaps, falls back deterministically on any model failure or unreadable CV). `index.ts` exports `matchCv` with the same `GEMINI_API_KEY` secret. Client: `models/cv_match_result.dart`, `services/cv_match_service.dart` (callable + parse + error mapping), `features/applications/viewmodels/cv_match_viewmodel.dart` (`ViewState`, `cv_match_check`), `widgets/cv_match_step.dart` (score, matched, gaps + one suggestion, nice-to-have, `Continue` always enabled, Retry), `screens/cv_match_screen.dart` (session guard, route `…/apply/match`), router helper/route, and the Apply Form now branches on `cv_match_enabled` (on → CV Match, off → Validate CV). Tests: 22 Flutter + 23 functions, plus `e2e_test/test_apply.py` TC-06 (written). Docs: `design-traceability` row 7, flow row 2, DC-30; `handoff-gaps` G-24 resolved; `architecture` ViewModel/service/data/failure/secrets; `analytics-plan` row 9; `test-plan` TC-06; `firebase-setup` deploy note; Run 29.
- **Verification:** `dart format lib test` → 0 changed; `flutter analyze` → **No issues found!**; targeted CV match + Apply Form tests → **38 passed**; `flutter test` → **649 passed**; `cd functions && npm test` → **41 passed**; `npm run build` → `tsc` clean. Deploy, device walk, screenshots and DebugView are **not run** (no owner deploy/secret in this session); TC-06 written but not run.
- **Decision:** Accepted. Deterministic scoring keeps the percentage reproducible and lets the step work without Gemini (blank key, quota, malformed output, unreadable PDF → Profile-only fallback with the same honest suggestions); Gemini only writes the summary and one suggestion per gap (techjobs-style). The step is advisory only: `Continue` is enabled while loading and after errors, and the blocking Validate CV gate stays after it. `Edit skills` / `Replace CV` return to the Apply Form instead of mutating `ApplySession`, keeping the submitted skills consistent (DC-30). The TS skill list is a deliberate duplicate guarded by a parity test. *(Provider note: the match commentary moved from Gemini to Groq in P-55; `validateCv` stays on Gemini.)*

---

### P-55: CV Match commentary on Groq
- **Request:** "nếu được tôi có thể đổi 1 cái sang grod được không" — confirmed as Groq, and the CV Match commentary is the call to move.
- **Output:** new `functions/src/groq.ts` (OpenAI-compatible `/openai/v1/chat/completions`, `openai/gpt-oss-20b`, temperature 0, `response_format: json_object`, 25 s `AbortSignal.timeout`, error body capped at 200 chars and never containing the key, system + user messages) and `groq.test.ts` (request shape, HTTP error, empty content, blank key). `index.ts` binds a new `GROQ_API_KEY` secret to `matchCv` only and passes `askGroq`; `match-cv.ts` uses a provider-neutral `askModel` dependency and neutral log messages. `validateCv` is unchanged and keeps `GEMINI_API_KEY`. Docs: architecture (services, data, failure, secrets), DC-30, G-24, `firebase-setup` §13, a provider note on P-54, Run 30.
- **Verification:** `cd functions && npm test` → **45 passed** (+4: real Firestore shape, Groq client); `npm run build` → `tsc` clean; deployed `matchCv`/`validateCv`/`syncInternshipsJob` with `firebase deploy --only functions`; a direct Groq probe showed `llama-3.3-70b-versatile` → 404 and `openai/gpt-oss-20b` → 200 JSON mode, so the model was switched; on `emulator-5554` the CV Match screen returned `50% match`, PostgreSQL matched from the CV text, SQL as a gap, with a Groq-written summary and suggestion (`evidence/screens/cv-match-groq-20261106.png`), then `Continue` ran Validate CV (Gemini) and reached Review. No Flutter file changed (Run 29's 649 tests still stand). DebugView not checked.
- **Decision:** Accepted. Groq serves only the advisory match commentary because it already has a deterministic fallback: a Groq outage, quota or malformed JSON still returns the score plus canned suggestions and never blocks applying. The blocking Validate CV gate stays on Gemini, so a Groq outage cannot stop a submission. Separate secrets per function keep least privilege; the key never reaches the app.

---

### P-56: CV Match — model skill extraction from CV + JD, real-device verification
- **Request:** "chạy giúp tôi", then "CV match … dựa vào skill hay những công nghệ được nêu trong CV, sau đó so sánh với job description" → chose Groq extraction from CV + JD with deterministic scoring.
- **Output:** new `functions/src/skill-extraction.ts` (`SKILL_EXTRACTION_RUBRIC`, `parseSkillExtraction`, `canonicalSkill` aliases such as JS → JavaScript, Postgres → PostgreSQL, Node → Node.js, Go → Golang, `buildSkillExtractionPrompt`, `unionSkills`, vocabulary fallback). `matchCv` now: parses the real Firestore document (`raw`), downloads the CV, calls Groq extraction with both texts, unions the result with the local `knownSkills` vocabulary, removes nice-to-have overlaps, then scores deterministically (a skill matches when in the extracted CV list or in `users/{uid}.skills`). The commentary stays a second Groq call. `groq.ts` adds `reasoning_effort: low` and `max_completion_tokens: 4096` (gpt-oss otherwise spends the budget on hidden reasoning and JSON mode returns empty content), and extraction now has its own system rubric (`askExtraction`) instead of the commentary prompt. Long suggestions are clipped at word boundaries. Docs: Run 30, architecture, DC-30, G-24.
- **Verification:** `npm --prefix functions test` → **46 passed**; build clean; deployed `matchCv`/`validateCv`/`syncInternshipsJob`; direct Groq probe of the real CV + JD prompt → 200 with `cvSkills`/`jobSkills`/`jobNiceToHave`; on `emulator-5554` the CV Match screen changed from the vocabulary result (`50%`, 1/2) to the extraction result: **`17% match`, `Low match`, `1 of 6 requirements matched`** — PostgreSQL matched, gaps SQL, Data Studio, Metabase, Power BI, Looker Studio, with a Groq summary (`evidence/screens/cv-match-extraction-20261106.png`). `Continue` still reached Validate CV (Gemini) → Review. Flutter untouched (Run 29's 649 tests stand). DebugView not checked.
- **Decision:** Accepted. The score stays deterministic; Groq is only an extractor, and the local vocabulary is unioned in so a model omission cannot erase a skill the listing plainly names. Two Groq calls happen only when the match has gaps (extraction + commentary); any failure falls back to vocabulary + canned suggestions and never blocks applying. Known limitation: alternatives in a JD (e.g. “Data Studio/Looker Studio, Metabase, Power BI”) are counted as separate required skills, which lowers the percentage; grouping them is a future refinement.

---

### P-57: ARTEMIS host setup, first TC-05 runs and E2E harness fixes
- **Request:** (Claude Code, Opus 5.5, session 2026-11-05; operator Phạm Nguyễn Hoàng Anh) "guide me to install and run ARTEMIS for Lab 3". Then, step by step at the operator's choice: wait for the overloaded model, switch to Flash-Lite, find why TC-05 fails, fix `conftest.py` (approved by Lâm Tài Lợi, its author), patch ARTEMIS's text input, run TC-05 three times, write the run guide, record and commit.
- **Output:**
  - Host setup: ARTEMIS host on macOS (`~/artemis` at `351ca84`, `uv` via Homebrew, `scrcpy`, daemon without `start.sh`). The operator created the Gemini key (free tier) and entered it themself.
  - Diagnosis, each step checked against the daemon log, the session API or the device:
    - the default model is capped at 20 requests per day and was overloaded, and the fallback never triggers before the 180 s timeout;
    - nothing calls the Outputter, so runs return no `output`;
    - `KEYCODE_PASTE` is ignored by Flutter text fields;
    - leftover text and the cold-start ANR affected runs.
  - `e2e_test/conftest.py` (`6fe33a9`): `REPORT_AS_JSON` + `final_report()` (reads `report_task_status` from `/api/sessions/{id}/steps`), and the `cold_start_app` fixture (force-stop, `am start -W`, 10 s).
  - `e2e_test/artemis-local.patch`: Flash-Lite models and `adb input text` for ASCII.
  - `docs/guides/artemis-e2e.md`.
  - `docs/test-plan.md`: model row, §1, TC-05 Done, §4 row and the flaky / failed table.
  - `evidence/artemis/e2e-environment-20261105.md` with `runs-20261105.jsonl` and three screenshots.
  - README and disclosure rows.
- **Verification:**
  - `artemis doctor` all ✔.
  - Direct API calls per model (HTTP codes in the evidence file).
  - Manual input check on the emulator (`keyevent 279` leaves the field empty, `adb shell input text` types).
  - `git apply --check` of the patch on a clean `351ca84` → applies.
  - `python -m py_compile conftest.py` → OK.
  - 11 real TC-05 runs, all recorded with their causes. The final `uv run pytest test_detail.py --count 3 -v` → **3 passed** (traces `505846be`, `045c4d16`, `ebe3d568`, average 65.7 s).
  - No Flutter code changed, so `flutter analyze` / `flutter test` were not run for this entry.
- **Decision:**
  - Modified. The default `gemini-3.8-flash` was replaced, because its free tier (20 requests per day) cannot carry the suite.
  - ARTEMIS is patched locally instead of changing the app: the paste behaviour is the tool's, and the app's Search code was checked and is correct.
  - The report is read through the daemon's step API with the client's private `_request` (the pinned client has no public call). Revisit if ARTEMIS is upgraded.
  - Run 3 passed but is not counted, because it did not type.
  - Replays stay on the host, because they show the signed-in account.

---

### P-58: Search bookmark uses the Saved feature's write path
- **Request:** "bấm bookmark saved bên search lại kh lưu đc qua bên saved internship, fix" — tapping the bookmark on a Search Results card showed no item on the Saved screen.
- **Output:** **Cause:** Search wrote through the legacy `SavedService` (`lib/services/saved_service.dart`), which stored only `{savedAt}` in `users/{uid}/savedInternships/{key}`; `SavedInternshipService.watchSaved` reads the copied listing from the `internship` field and skipped those documents, so the bookmark looked saved on Search but the Saved list stayed empty. Removed the second write path: `SearchResultsViewModel` no longer owns saved state or subscriptions; `SearchResultsScreen` watches `savedInternshipIdsProvider` for the bookmark and calls `SavedViewModel.toggleAndReport(..., source: 'search')`, like Home and Internship Detail, showing a failure in its own SnackBar. Deleted `SavedService`, `savedServiceProvider` and `FakeSavedService`; updated the Search ViewModel/screen/router tests to `FakeSavedInternshipService`, and the bookmark widget test now asserts the shared saved collection receives the key and the card flips to `Remove from saved`.
- **Verification:** `dart format lib test` → **188 files, 0 changed**; `flutter analyze` → **No issues found!** (74.1 s); `flutter test` → **592 tests, all passed**. On the Android 17 (API 37) emulator (`flutter run -d emulator-5554 --dart-define-from-file=.env`, signed in with the test account): bookmarking `Recruitment Intern` on Search Results filled the icon and the Saved tab changed from 3 to 4 saved items with that listing on top; unbookmarking it on Search returned Saved to 3 and removed the card. Screenshots: `evidence/screens/search-bookmark-saved-20261105.png`, `saved-after-search-bookmark-20261105.png`, `saved-after-search-unsave-20261105.png`.
- **Decision:** Accepted. This performs the merge that P-44 left to the Search owner: one saved service and one document shape for Home, Search, Detail and Saved, so the same bookmark is readable everywhere.

---

### P-59: runs.jsonl records the pytest result
- **Request:** (Claude Code, Opus 5.5, 2026-11-06; operator Phạm Nguyễn Hoàng Anh) after P-57, write the pytest outcome of each ARTEMIS run into `runs.jsonl`. The pass/fail of TC-05 runs had to be looked up in the daemon log, because `succeeded` is ARTEMIS's own status and stayed `true` when the report check failed.
- **Output:** `e2e_test/conftest.py`: `_record()` keeps the run in `_pending_run`; a `pytest_runtest_makereport` hook writes it when the test's call phase ends, adding `pytest` (`passed` / `failed`) and `failure` (the assertion or exception message). A test that fails before ARTEMIS runs still gets a line, keyed by the test name. `docs/guides/artemis-e2e.md` §5 and `docs/test-plan.md` §1 describe the new fields.
- **Verification:** `python -m py_compile conftest.py` → OK. A throwaway test file (fixture overridden, no ARTEMIS call, no device) produced three lines: a pass (`"pytest": "passed"`), a failure after a run (`"succeeded": true`, `"pytest": "failed"`, `"failure": "AssertionError: … no structured output …"`) and a failure before a run (`"failure": "FileNotFoundError: adb"`). The file was deleted and `runs.jsonl` restored to its 11 lines. Not yet seen on a real ARTEMIS run.
- **Decision:** Accepted. Lines written before this change keep their old shape; nothing in `evidence/` was rewritten.

---

### P-60: ARTEMIS cases for Save (TC-08) and Apply → Success (TC-06, TC-07)
- **Request:** (Claude Code, Opus 5.5, 2026-11-06; operator Phạm Nguyễn Hoàng Anh) "viết test cho flow 2 và flow 4": task sheet items 8 (Flow 2 Save: TC-07, TC-08) and 9 (Flow 4 Application: TC-06).
- **Output:**
  - `e2e_test/test_saved.py` TC-08: Save from Detail, Saved list, open the saved card, unsave, Undo.
  - `e2e_test/test_apply.py` TC-06: Apply Form → Validate CV → Review → Submit → Success, plus the `application_create` Logcat check. TC-07: an applied listing shows the `You applied on` banner, `View application` and Application Detail.
  - Every asserted string was read from the screens first: `internship_detail_screen.dart`, `detail_bottom_bar.dart`, `saved_screen.dart`, `cv_validation_step.dart`, `application_review_screen.dart`, `application_success_screen.dart`, `application_detail_screen.dart`.
  - `FILL_PERSONAL` and a new `UPLOAD_SAMPLE_CV` moved to `conftest.py`. TC-19's instruction text is unchanged (compared as strings).
  - `docs/test-plan.md` §3: TC-06/07/08 rewritten to the built flow, Ready (not run).
- **Verification:** `python -m py_compile` on the changed files → OK; `uv run pytest --collect-only -q` → 16 tests collected, including the three new ones. **Not run on a device**: the operator runs them.
- **Decision:**
  - Modified from the old plan rows. TC-06 follows the flow the app has (Validate CV → Review → Success), because CV Match Check (2d) is not built (DC-09, task 5).
  - TC-08 compares Saved counts instead of emptying Saved first, so the account's saved listings stay.
  - TC-06 / TC-07 use `Developer` listings and TC-08 uses `Python` listings. Applying to or saving TC-05's `Intern` listing would remove the `Apply now` / `Save` buttons it asserts.
  - TC-06 uses the fictional `Sample_CV.pdf`, so the account's own CV is not sent to `validateCv`.
  - Superseded on 2026-11-06: when `dev` (PR #24, CV Match) was merged in, TC-06 became Lập's version (CV Match → Validate CV → Submit) and TC-07 searches `Intern` instead of `Developer` (see P-62).
  - TC-11 (export), TC-13 and TC-15 (notifications) were not written: those screens do not exist yet (tasks 1–3), and writing them now would mean guessing UI (AGENTS.md rule 1).

---

### P-61: TC-14 accepts Back closing the app after sign-out
- **Request:** (Claude Code, Opus 5.5, 2026-11-06; operator Phạm Nguyễn Hoàng Anh) "Sửa TC-14" after a first exploratory run failed with `assert False is True` on `login_button_visible`.
- **Output:**
  - Cause, from the run's steps and its last screenshot (trace `5e93964f`): sign-out reached Login. Back from Login then closed the app to the Android home screen. That is correct (Login is the root after sign-out, and no signed-in screen came back), but the test required Login to stay on screen.
  - `e2e_test/test_auth.py` TC-14 now reports `login_after_sign_out`, `after_back` (`login` / `android_home` / `other_app_screen`), `bottom_nav_visible_after_back` and, after reopening the app if Back closed it, `login_after_reopen`. It asserts Login after sign-out, `after_back` in (`login`, `android_home`), no bottom navigation, and Login again after reopening (still signed out).
  - `docs/test-plan.md` §3 TC-14 row updated to match.
- **Verification:** `python -m py_compile test_auth.py` → OK; `uv run pytest test_auth.py --collect-only -q` → 2 tests collected. The new TC-14 has **not been run on a device yet**.
- **Decision:** Accepted. The app behaviour is right and the expectation was wrong. Back closing the app after sign-out is standard Android behaviour, and the security check (no way back into signed-in screens) is kept and made stronger by reopening the app.

---

### P-62: Merge `dev` (PR #24) into `test/e2e-flow1`, each owner's version kept
- **Request:** (Claude Code, Opus 5.5, 2026-11-06; operator Phạm Nguyễn Hoàng Anh) merge `dev` before the evidence runs; the operator's rule: "nào liên quan đến tôi thì lấy của tôi, nào của thành viên khác thì lấy của họ, ví dụ TC-06 lấy của Lập".
- **Output:**
  - `docs/test-plan.md` §3: TC-03/04/05/07/08 rows from this branch (PR #24 had put back older `Planned` rows, including TC-05 `Done (3/3, 2026-11-05)`); TC-06 row from `dev` (Lập, CV Match).
  - `e2e_test/test_apply.py`: Lập's TC-06 unchanged, plus this branch's TC-07, which now searches `Intern` for an applied listing (Lập's TC-06 applies to a Home card, not a `Developer` one).
  - AI log: PR #24 had dropped two entries and reused their numbers. Lập's P-50 – P-56 are kept as they are. The dropped entries are restored with new numbers: the ARTEMIS setup (was P-50) → P-57, Hảo's Search bookmark fix (was P-51) → P-58. This branch's P-52 – P-54 → P-59 – P-61. The README and `code-review.md` rows that PR #24 lost are restored with the new numbers; the 2026-11-05 evidence file points at P-57.
- **Verification:** `git show b23c144:…` vs `origin/dev` confirmed what PR #24 removed; `pytest --collect-only` after the merge → 16 tests; no conflict markers left; the only duplicate IDs left are the older P-21 – P-27.
- **Decision:** Applied the operator's ownership rule. Not changed: Lập's TC-06 itself, although it applies to the first unapplied Home card (it may be TC-05's `Intern` listing) and uses the account's own CV — raised with the operator to pass on to Lập.

---

### P-63: ARTEMIS evidence for TC-01, TC-02, TC-14, TC-16, TC-17 (2026-11-06)
- **Request:** (Claude Code, Opus 5.5, 2026-11-06; operator Phạm Nguyễn Hoàng Anh) "giờ chạy lấy evidence ik để làm doc", then "Đổi sang 3.5 ngay" when `gemini-3.1-flash-lite` ran out of daily quota.
- **Output:**
  - A profile APK built from `origin/dev` `a5d1e4a`, installed on `emulator-5554`, with notifications granted by `adb`.
  - Three counted runs each of TC-02, TC-16, TC-17 (`gemini-3.1-flash-lite`) and TC-14, TC-01 (`gemini-3.5-flash-lite`, swapped on the host for the day).
  - `evidence/artemis/e2e-environment-20261106.md` and `runs-20261106.jsonl`: all 21 runs, six of them exploratory, plus the cancelled attempt `0a061c60`.
  - `docs/test-plan.md`: header model and app-build rows; §1 builds a profile APK and grants notifications; §3 marks the five cases Done (3/3, 2026-11-06); §4 adds a results row for each case and the failures with their causes.
  - `docs/guides/artemis-e2e.md`: profile build, the notification grant, the 500-requests-per-day limit and what to do when a model runs out.
- **Verification:** both `uv run pytest … --count 3 -v` runs are logged in the evidence file: 9 passed in 724.66 s and 6 passed in 717.43 s. Every number comes from `runs.jsonl` (now with the `pytest` field) and from the daemon's `/api/sessions/{id}`, `/steps` and `/usage`. The 429 message gave the daily limit (`quotaValue: 500`) and the reset (about 7.4 h, 15:00 in Vietnam).
- **Decision:**
  - The exploratory runs are recorded, not dropped. The TC-16 freeze on the debug build is recorded as timing and fixed by the profile build. The old TC-14 failure is recorded as a wrong expectation, fixed in `512c8f4`.
  - The day's model swap stays local to the ARTEMIS host: the committed `artemis-local.patch` keeps `gemini-3.1-flash-lite` as primary.

---

### P-64: One shared application, Flow 2 / Flow 3 runs and their records (2026-11-06)
- **Request:** (Claude Code, Opus 5.5, 2026-11-06; operator Phạm Nguyễn Hoàng Anh) run Flow 2 and Flow 3 once each, then three times while the quota lasted. "Tạo 1 cái trước để tui xem trước": create one application first, which the cases share.
- **Output:**
  - Application **Client Success Intern — Wegrow** submitted by hand with `adb` taps (no model calls). The Profile CV (609 B, 2026-11-02) is unreadable to `validateCv`, so for this application only it was replaced with the full fictional `Sample_CV.pdf`.
  - Four exploratory runs: TC-09, TC-07, TC-08 passed; TC-10 failed.
  - Counted runs: TC-07 3/3, TC-09 3/3, TC-08 0/3.
  - `evidence/artemis/e2e-environment-20261106.md` §Flow 2 and Flow 3, 13 more lines in `runs-20261106.jsonl`.
  - `docs/test-plan.md`: TC-07 and TC-09 Done (3/3, 2026-11-06), TC-08 and TC-10 rows rewritten, §4 rows, failure rows.
- **Verification:**
  - `pdf-parse` 2.4.5 (the library the function uses) read 522 characters from the full sample CV locally.
  - Counted command: 6 passed, 3 failed in 703.80 s.
  - Causes were checked against step screenshots: the Saved order (`saved_screen.dart`) and the offline Applications screen showing the cached list.
  - Saved screenshots from before and after the TC-08 runs show the account's SENZU BASE listing unsaved and Nexlab "Intern AI Software Engineer" added.
- **Decision:**
  - TC-08 and TC-10 failures are recorded as wrong expectations plus one timing miss, not as app bugs. Their fixes are P-65.
  - The account's Saved list was left as it is (the owner's choice).
  - Raised for the owners: the Saved `Recent` label orders by posting date; Lập's TC-06 will stop at Validate CV while the Profile CV is the old sample.

---

### P-65: TC-08 finds its card by title; TC-10 runs offline with `adb`
- **Request:** (Claude Code, Opus 5.5, 2026-11-06; operator Phạm Nguyễn Hoàng Anh) "Làm luôn", after the TC-08 and TC-10 failures in P-64.
- **Output:**
  - `e2e_test/test_saved.py` TC-08 finds the saved listing by its title, reports `saved_card_found` instead of the first card, and may unsave only that card, with `Undo` as one quick sequence.
  - `e2e_test/test_applications.py` TC-10 (now `test_tc10_application_list_stays_visible_offline`) turns Wi-Fi and data off with `set_network(False)` and back on in `finally`. It asserts a visible card, a position, the `N application(s)` line, no error and no `Retry`.
  - Commit `f9b5f43`.
- **Verification:** `python -m py_compile` → OK; `pytest --collect-only` → 16 tests. **Not run on a device yet**: there was no model quota left before the 15:00 reset.
- **Decision:**
  - Accepted. TC-10 now checks what the app does offline (Firestore cache). An error with `Retry` would appear only when the stream itself fails.
  - TC-10 loses its "Native" part, because the native sign-in case TC-01 already covers native UI.

---

### P-66: ARTEMIS cases TC-13 (open a notification) and TC-15 (permission dialog)
- **Request:** (Claude Code, Opus 5.5, 2026-11-06; operator Phạm Nguyễn Hoàng Anh) "Viết TC-13, TC-15". These became possible once PR #24 (FCM, Notification Center) was merged.
- **Output:**
  - `e2e_test/test_notifications.py`:
    - TC-13 sends the app to the background, waits up to 180 s for the operator to send one FCM message with route `/saved`, then has the agent open it from the shade. It checks the `Saved` screen and that the Notifications screen lists the same title as `Read`.
    - TC-15 revokes `POST_NOTIFICATIONS`, clears its flags, relaunches the app, and has the agent read the dialog and tap `Allow`. It checks `Home` and the granted permission, and always grants the permission back in `finally`.
  - `conftest.py` helpers: `reset_notification_permission`, `grant_notification_permission`, `notification_permission_granted`, `app_notification_titles` (parses `dumpsys notification --noredact`), `send_app_to_background`.
  - `docs/test-plan.md` §3 TC-13/TC-15 rows, now Ready (not run); the guide explains TC-13's manual send.
- **Verification:**
  - Every asserted string was read from the code: route handling in `notification_target.dart`; `NotificationCoordinator.signedIn` asks for the permission and `_open` marks a notification read; the `Notifications` title and `Read`/`Unread` labels.
  - By hand on the emulator: `pm revoke` + `pm clear-permission-flags` + relaunch showed "Allow internly to send you notifications?" with `Allow` / `Don't allow`. `Allow` granted it again.
  - The helpers ran on the device (permission `True`, no internly notification in the shade).
  - `py_compile` → OK; `pytest --collect-only` → 18 tests.
  - **Not run with ARTEMIS yet.**
- **Decision:**
  - TC-13 is semi-manual, because the suite must not hold a service-account key.
  - TC-15 replaces "fresh install" with a permission reset that leaves the sign-in in place; the old "Firebase demo area shows permission granted" check became an `adb` check, because that area is not built (task 4).

---

### P-67: TC-06 (Lập's) made runnable
- **Request:** (Claude Code, Opus 5.5, 2026-11-06; operator Phạm Nguyễn Hoàng Anh) "sửa lại tc 06 giúp Lập đi". The fix was asked for on Lập's behalf. The case stays Lập's: his CV match assertions are unchanged.
- **Output:** `e2e_test/test_apply.py` TC-06:
  - **CV.** `push_sample_cv()` and `UPLOAD_SAMPLE_CV` replace the Profile CV for the application. The 2026-11-02 Profile sample is too short for `validateCv` (P-64), and no personal CV is sent to the functions.
  - **Listing.** `CHOOSE_LISTING` searches `Developer` and takes the first card with no `Applied` badge and at least three skill tags. A Home card without skills shows "Nothing to compare yet" with no gaps. A first draft also skipped `Recruitment Intern` by name to protect TC-05; P-68 removed that and made TC-05 itself skip applied listings.
  - **Validate CV.** Its extra "tap 'Continue to review'" is gone, because the app moves to `Review application` by itself (`cv_validation_screen.dart` `onValid`).
  - **Assertions.** `FILL_PERSONAL` added; the success recap must now equal the chosen card's title and company.
  - `docs/test-plan.md` TC-06 row updated to match.
- **Verification:**
  - Copy checked in `cv_match_step.dart`: `% match`, `N of M requirements matched`, `Gaps to review`, and `Continue` enabled while loading. The CV match → Validate CV → Review → `Application submitted!` path was walked by hand on 2026-11-06 (P-64).
  - `py_compile` → OK; `pytest --collect-only` → TC-06 and TC-07 collected.
  - **Not run with ARTEMIS yet.**
- **Decision:** Applied at the operator's request; to be confirmed with Lập. Each run still submits a real application, as the flow requires.

---

### P-68: TC-05 takes the first unapplied, unsaved card
- **Request:** (Claude Code, Opus 5.5, 2026-11-06; operator Phạm Nguyễn Hoàng Anh) "ok sửa đi". The request asked to stop protecting TC-05 by a hard-coded listing title in TC-06 and to make TC-05 itself robust.
- **Output:**
  - `e2e_test/test_detail.py` TC-05 searches `Intern` and opens the first card with no `Applied` badge whose bookmark is not filled. TC-06 and TC-08 apply to and save listings, applications cannot be deleted, and the case asserts `Apply now` and `Save`.
  - `test_apply.py` `CHOOSE_LISTING` no longer names `Recruitment Intern`: listings come from the sync and expire after about 7 days, so a title in a test goes stale.
  - The `test_saved.py` comment no longer mentions TC-05.
  - `docs/test-plan.md` TC-05 row changed to Ready, to rerun. Its 2026-11-05 result (3/3) was obtained with the earlier "first card" wording, and the §4 row keeps it as history. TC-06 row updated to match.
- **Verification:** `py_compile` → OK; `pytest --collect-only` → 18 tests. **Not run on a device yet**: TC-05 needs three new runs.
- **Decision:** Accepted. TC-05 still checks the same behaviour (Detail opens the tapped card; `Apply now`, `Save`; Back keeps the query) but no longer depends on which listing is first.

---

## Entry template

```markdown
### P-nn: <short title>
- **Request:** <summary of the task, or a link to docs/records/prompts/P-nn-….md>
- **Output:** <files / behavior changed>
- **Verification:** <commands + real results, manual checks, or "not verified">
- **Decision:** Accepted / Modified (<how>) / Rejected (<why>)
```
