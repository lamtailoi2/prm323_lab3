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

---

## Entry template

```markdown
### P-nn: <short title>
- **Request:** <summary of the task, or a link to docs/records/prompts/P-nn-….md>
- **Output:** <files / behavior changed>
- **Verification:** <commands + real results, manual checks, or "not verified">
- **Decision:** Accepted / Modified (<how>) / Rejected (<why>)
```
