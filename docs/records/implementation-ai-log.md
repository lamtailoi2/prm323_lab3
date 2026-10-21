# Implementation AI log

Every AI-assisted change is recorded here: the **exact prompt**, a summary of what the AI produced, **how it was verified**, and what the team **accepted, modified or rejected**. Only record verification that actually ran. "Not verified" is a valid entry.

| Field | Meaning |
|---|---|
| Prompt | Verbatim user prompt (long prompts are stored in `docs/records/prompts/` and linked) |
| Output | What the AI changed or produced |
| Verification | Commands run, with their real results, or manual checks |
| Decision | Accepted · Modified (how) · Rejected (why) |

---

## Session 2026-10-21: repository initialization

Tool: Claude Code (Opus 5.5, `claude-opus-5-5`), run from `prm323_lab3/` with read access to `../prm323_lab2/`. Operator: Lâm Tài Lợi.

### P-01: Initialize the repository
- **Prompt:** [`prompts/P-01-initialize-internly.md`](prompts/P-01-initialize-internly.md) (verbatim), plus: "các file design docs sẽ nằm ở ../prm323_lab2" ("the design docs are in ../prm323_lab2").
- **Output:** inspected the empty working directory (not a Git repo), the toolchain (Flutter 3.47.3, Dart 3.13.3, Xcode 26.5; Android SDK incomplete; no Firebase / FlutterFire CLI) and the Lab 2 repo (`03f4aa3`). Found no `flutter-handoff.md` (G-01). Ran `git init` and `flutter create --org com.group3 --project-name internly --platforms android,ios --empty`, committed unchanged as the scaffold. Read the installed package sources to confirm current APIs before coding (google_sign_in 7.2, firebase_auth 7, Riverpod 3.4, go_router 18).
- **Verification:** `git log` shows the scaffold commit; package APIs checked in `~/.pub-cache`.
- **Decision:** Accepted. App ID `com.group3.internly` is an assumption (G-21).

### P-02: "flutter repo cho cả ios / android nhé" ("make the Flutter repo for both iOS and Android")
- **Output:** platforms `android,ios`; iOS setup steps (URL scheme, APNs) added to `firebase-setup.md`; logged as G-15 / DC-07.
- **Verification:** `flutter build ios --simulator --debug`, see P-08.
- **Decision:** Accepted.

### P-03: "nếu cần thiết hãy copy các file docs từ lab2 qua nhé" ("copy the Lab 2 docs over if needed")
- **Output:** read-only snapshot in `docs/design/` (DESIGN.md, screen-spec, design-decisions, user-flow, persona, Lab 2 README, 8 final screenshots) with a provenance note. Intermediate Stitch rounds and the AI design log were not copied. Lab 2's uncommitted change (`assets/stitch/home-final.png`) was left untouched.
- **Verification:** file list compared with the source; source commit recorded.
- **Decision:** Accepted.

### P-04: "design system và components. Viết design system thành dạng md cho dễ" ("design system and components: write the design system up as Markdown"), with screenshots of Figma pages 04 and 05
- **Output:** [`design-system.md`](../design/design-system.md) consolidating DESIGN.md + Figma 04/05 + the README handoff: tokens with Dart and `ColorScheme` mapping, the 12 component sets with states, source precedence, and usage rules. Added `material_symbols_icons` because Figma 04 specifies Material Symbols Rounded.
- **Verification:** manual comparison against the screenshots; values not readable from the screenshots are marked **verify** and listed in G-07.
- **Decision:** Accepted.

### P-05: "đối chiếu lại với theme (token) đã tạo nhé" ("cross-check against the theme tokens already created")
- **Output:** Figma ↔ code table. All 13 colors, 8 text styles, spacing, radius and elevation tokens match. Component differences fixed in `AppTheme` / widgets: Secondary button border → primary; disabled fill → surfaceVariant for all variants; pressed = reduced emphasis, no ripple; loading keeps the default look; App Bar without bottom border (DC-06); StateView rewritten to the Figma Loading / Empty / Error specimens. Computed WCAG contrast for the new color pairs: Rejected badge 4.41:1 and selected chip 4.24:1 fail AA (G-19). Fixes were proposed as DC-04 / DC-05, not applied.
- **Verification:** contrast computed with a script (WCAG 2.1 formula); `flutter analyze` → no issues; theme assertions in `test/theme/app_theme_test.dart`.
- **Decision:** Accepted. DC-04 and DC-05 await team approval.

### P-06: "bạn chỉ dựng init dự án thôi (dựng common, componenets, utils, ...) các thứ dùng chung còn details để đó cho ng khác làm" ("only set up the project init: common code, components, utils… leave the details to others")
- **Context:** sent after the user **rejected** a tool call that was writing feature models (application status, application, exported report).
- **Output:** scope reduced. Removed the feature models already written (Internship, WorkMode, StoredFile, UserProfile, SavedInternship, ApplicationStatus); kept the shared `AppUser`. Built the remaining shared components with primitive inputs only (`AppTextField`, `AppSearchField`, `InternshipCard`, `AppTag`, `StatusBadge`, `showAppDialog`, skeletons, `Validators`). Feature screens are placeholders (DC-02). Notification, report and file-storage service interfaces were **not** created; their constraints are documented as gaps (G-04, G-05, G-12, G-13). Firestore rules contain only the shared ownership rules plus a commented template.
- **Verification:** see P-08.
- **Decision:** **Modified** at the user's request (AI scope reduced). Rejected tool call: writing feature models.

### P-07: "overview dự án ghi vào README, tạo AGENTS.md cho coding convention, rule, tóm tắt overview" ("put the project overview in README; create AGENTS.md for coding conventions, rules and a short overview"), then "trong code-review lưu ý là agents k review quá 3 vòng" ("in code-review, note that agents must not review more than 3 rounds")
- **Output:** `README.md` (product overview, stack, setup, run, test, ownership, docs, limitations); `AGENTS.md` (golden rules, folder placement, Dart / Riverpod conventions, testing, docs-per-PR, Git workflow, definition of done); `CLAUDE.md` importing `AGENTS.md`; a 3-round AI review cap in `code-review.md` and `AGENTS.md`.
- **Verification:** documentation only; links checked by reading.
- **Decision:** Accepted.

### Note: manual change by the user
- The user moved `docs/design-system.md` to `docs/design/design-system.md` (next to `DESIGN.md`). The AI kept the new location, fixed the six relative links inside the file, repointed references in README, AGENTS.md and docs, and marked the file as the one editable Lab 3 file in the snapshot README. Verified with a script that checks every relative Markdown link (the only remaining broken links are `ai/…` links inside the verbatim Lab 2 README, which only resolve in the Lab 2 repository).

### P-08: Verification run (initialization)
Commands the AI executed, with their real results (details in [`test-report.md`](test-report.md)):

| Command | Result |
|---|---|
| `dart format lib test` | Formatted; no further diffs |
| `flutter analyze` | `No issues found!` |
| `flutter test` | 65 tests, all passed |
| `flutter build ios --simulator --debug` (SPM) | **Failed**: SPM dependency conflict, firebase-ios-sdk 13 vs GoogleSignIn-iOS 9 (`gtm-session-fetcher`) (G-20) |
| `flutter build ios --simulator --debug` (CocoaPods) | **Passed**: `✓ Built build/ios/iphonesimulator/Runner.app` (Firebase iOS 12.19.0, GoogleSignIn 9.2.0, GTMSessionFetcher 3.5.0) |
| Android build | **Not run**: Android SDK incomplete on this machine (no cmdline-tools / platforms) |

- **Decision:** SPM disabled for the project (CocoaPods); accepted as a workaround until `google_sign_in_ios` supports GoogleSignIn-iOS 10.

### P-09: "cái này tối đa là 3 thoi chứ k phải bắt buộc nhé" ("this is a maximum of 3, not mandatory"), about the AI review round rule
- **Output:** AGENTS.md and `code-review.md` now say 3 rounds is a cap, not a quota; stop when no blocker or major remains.
- **Verification:** documentation only.
- **Decision:** Accepted (commit `13040d2`).

### P-10: "https://github.com/lamtailoi2/prm323_lab3.git push lên trên này đi" ("push to this repository")
- **Output:** checked that the GitHub repository was empty (private) before pushing, added `origin`, and pushed `main` with upstream tracking. No force push.
- **Verification:** `gh repo view` → `isEmpty: false`, default branch `main`; `git status -sb` → `main...origin/main`.
- **Decision:** Accepted.

### P-11: "update flow mới đẩy flow save internships xuông flow phụ. Flow này sẽ là trong lúc apply (sau search và trước track)" ("update the flows: push Save Internships down to a sub-flow that happens during Apply, after Search and before Track")
- **Clarification (AI asked, user answered):** three main flows, **Search → Apply → Track**: "tách làm 3 đúng r, nhma trong flow apply phải có xử lý j đó nữa ví dụ check xem cv những điểm nào chưa match, gợi ý cải thiện" ("splitting into 3 is right, but the Apply flow also needs some processing, e.g. check which points of the CV don't match and suggest improvements"). Scope: "Docs Lab 3 + bản copy" (Lab 3 docs plus the Lab 2 copies, now in `docs/design/`).
- **Output:** rewrote `docs/design/user-flow.md` (new flows, branches, diagrams, mappings) and updated `docs/design/screen-spec.md` (related flows, new **CV Match Check** screen section, mapping table). Also updated README, MobAI scenarios 02–03, analytics events (`cv_match_check`, `cv_match_improve`), gaps (G-24), change log (DC-08, DC-09), fidelity-check list, `design-system.md` and an `InternshipCard` comment. Work done on branch `docs/flows-search-apply-track`.
- **Verification:** searched for stale flow references (`Flow 1d`, `Search & Apply`, …); the only remaining ones are the intentional "old → new" description in DC-08 and the verbatim Lab 2 README. Relative links checked with a script.
- **Decision:** Accepted. Matching rules, CV text extraction, any AI-generated suggestions and the Figma frame stay open (G-24).

### P-12: "phần này chỉ review các phần thay đổi k đọc lại hết block mỗi lần review để tránh tốn kém" ("review only the changed parts; don't re-read whole blocks each round, to avoid cost")
- **Output:** AGENTS.md and `code-review.md`: R1 reviews only the PR diff (`git diff main...HEAD`); R2/R3 only the diff since the last reviewed commit plus open findings; record the reviewed SHA per round.
- **Verification:** documentation only.
- **Decision:** Accepted (commit `37216e1`).

### P-13: Lab 3 handout review ("review xem có thiếu gì nữa k đây yêu của lab3", "review whether anything is missing; here are the Lab 3 requirements") with the handout PDF
- **Output:** gap list against the handout: E2E with ARTEMIS instead of MobAI, required Cloud Storage + `storage.rules`, required `docs/design-traceability.md`, cancelled sign-in must show a message, sign-out must clear local data, pinned versions, missing required files, and the risk of the flow change (DC-08/09).
- **Verification:** read the handout (18 pages) and compared each requirement with the repository.
- **Decision:** Accepted.

### P-14: User decisions on the review
- **Prompt (verbatim):** "report/Lab03_<ID>.pdf slides/Lab03_<ID>_slides.pdf này bỏ đi nộp riêng, còn video tạm cứ để vào readme nào có tui sẽ bổ sung 5 k cần hỏi j tui qyết k đổi tên repo, dữ liệu sẽ dùng serph API (google jobs), cloud cái nào free thì dùng, đổi flow, cái nào free thì dùng chắc là ARTEMIS" (report and slides are submitted separately; video link later; no need to ask the lecturer; keep the repository name; data from SerpAPI Google Jobs; use whichever cloud is free; keep the flow change; ARTEMIS).
- **Follow-ups (verbatim):** "tạo .env.example cho tui đi tui k rõ là flutter có dùng .env k" (create `.env.example`; does Flutter use `.env`?) · "có tốn tiền k z, tui k muốn tốn bất kì 1 đồng nào kể cả model AI" (does it cost money? spend nothing, including AI models) · "lab3-requirements.md đề có yêu cầu k thì xoá đi nhiều file lmaws rồi" (delete `lab3-requirements.md` if the handout does not require it; too many files) · "AGENTS.md có rule phải ghi log theo như đề yêu cầu chưa" (does AGENTS.md require the logs the handout asks for?).
- **Output (branch `chore/lab3-spec-alignment`):**
  - Code: pinned dependency versions; `ViewState` sealed class; `SerpApiClient` (key from `.env` via `--dart-define-from-file`, error mapping, no key leaks); cancelled sign-in shows an info message; `currentUserIdProvider` for sign-out clearing; Crashlytics `setCustomKey` + `last_screen`; Remote Config defaults loaded from `firebase/remote-config-defaults.json` with real-time updates; `InternshipCard` Semantics summary.
  - Config: `firebase/storage.rules`, `firebase.json` storage + emulator, `firestore.rules` without the `internships` collection, `.env.example`, `e2e_test/` (pyproject pinned to ARTEMIS `351ca84`, conftest, 3 runnable tests, `.env.example`).
  - Docs: `design-traceability.md` (replaces the design change log and fidelity check), `test-plan.md` (15 cases, coverage table, $0 model), `analytics-plan.md` (Appendix A, 15 events), `code-review.md` (Appendix C + disclosure), `architecture.md` (Mermaid layer and sequence diagrams, ViewModel table), README (pinned versions, deliverables map, AI tools, video placeholder), AGENTS.md (logs and evidence rules), `evidence/README.md`, gaps G-25 / G-26. Removed `mobai_tests/`, `design-change-log.md`, `fidelity-check.md` and, at the user's request, `lab3-requirements.md`.
- **Verification:** checked `flutter_tools` source: `--dart-define-from-file` accepts `.env` (comments and empty values allowed). Checked the ARTEMIS SDK source (`ArtemisClient.run(..., expected_output, locked_app_package)`, `TaskResult.output/trace_id`) and its default model config (Gemini). `flutter analyze` → no issues; `flutter test` → 79 passed; `py_compile` of `e2e_test/*.py` passed. ARTEMIS not run (no device / Firebase config / model key here).
- **Decision:** Accepted. Open for the user: Storage on Blaze at $0 (card required) vs Cloudinary free (G-12).

### P-15: "/Users/loi/go/projects/prm323_lab3/docs tổ chức lại folder này đi để tùm lum hết vậy" ("reorganize the docs folder, it is a mess")
- **Output:** kept the five handout-required files at `docs/` root; moved the Lab 2 copies and `design-system.md` to `docs/design/`, `firebase-setup.md` to `docs/guides/`, gaps / AI log / test report / prompts to `docs/records/`; added `docs/README.md` as an index. A script rewrote every relative Markdown link (recomputed from the old to the new location) and path mentions in code comments, UI strings, rules and `pubspec.yaml`.
- **Verification:** dry run reviewed before applying; link and anchor check → 0 problems (except the known `ai/…` links inside the verbatim Lab 2 README); `flutter analyze` → no issues; `flutter test` → 79 passed.
- **Decision:** Accepted.

### P-16: "dùng cloudinary sẽ xử lý quyền truy cập ở tầng service" ("use Cloudinary; handle access control in the service layer")
- **Output:** `FileStorageService` + `CloudinaryStorageService` (unsigned preset, `internly/<reports|cvs>/<uid>/`, signed-in check, PDF signature and 10 MB checks, 128-bit random ids, progress callback, error mapping; new `AppErrorKind.invalidInput`); `.env.example` gains the Cloudinary settings; `storage.rules` marked as reference (not deployed); G-12 resolved with the accepted risks; setup guide §10, README, architecture, traceability, AGENTS.md, evidence and test-plan updated.
- **Verification:** 5 new unit tests (own-folder path, random id, progress to 1.0, signed-out rejection without a request, non-PDF and oversized rejection, missing config, preset / size / quota / network errors). Cloudinary itself not called (no account configured here).
- **Decision:** Accepted. Known limits recorded: public delivery URLs, preset name in the APK.

### P-17: Storage provider: "khoan yêu cầu là firebase file storage giờ bạn có gói nào free (k add thẻ k)" → "dùng blaze plan nhma set limit là 1 đô đc k" → "chốt đi"
(Wait, the requirement is Firebase file storage: is there a free plan without a card? → Use Blaze but set a $1 limit? → Confirmed.)
- **Research (web, cited to the user):** since 2026-02-03 Cloud Storage for Firebase requires Blaze, with no card-free plan except lecturer-issued Google Cloud education credits; budgets only alert and cannot cap spending (a hard cap needs a billing-unlink function that lags and shuts down the project); the Always Free tier applies only to buckets in US-CENTRAL1 / US-EAST1 / US-WEST1.
- **Output:** replaced the Cloudinary implementation with `FirebaseStorageService` (`firebase_storage` 14.0.0): same `FileStorageService` interface, pre-upload checks (signed in, own folder, PDF signature, ≤ 10 MB, random id), progress from `snapshotEvents`, download URL, error-code mapping. `storage.rules` is now deployed. Removed the Cloudinary settings from `.env.example`. G-12 / G-26, the setup guide §10 (Blaze, $1 budget alert, US bucket, unlink billing after grading), README, architecture, traceability, evidence and AGENTS.md updated.
- **Verification:** `flutter analyze` → no issues; `flutter test` → 85 passed (storage validation, path, error mapping, signed-out rejection). Actual uploads not run (no Firebase project configured here). iOS simulator build with the new pod: see `test-report.md` Run 4.
- **Decision:** Accepted (user). Cloudinary code from P-16 removed.

---

## Entry template

```markdown
### P-nn: <short title>
- **Prompt:** "<verbatim prompt>" (or link to docs/records/prompts/P-nn-….md)
- **Output:** <files / behavior changed>
- **Verification:** <commands + real results, manual checks, or "not verified">
- **Decision:** Accepted / Modified (<how>) / Rejected (<why>)
```
