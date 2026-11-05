# AI-assisted code review

AI finds; we decide (Lab 3 §8). This file holds the review record in the Appendix C format, the AI tool disclosure, and the review process rules.

## Requirements (Lab 3 §8)

- [x] At least one AI review tool run on **pull requests** (not the whole repo); tool output saved in `evidence/code-review/`.
- [x] ≥ **5 findings** tied to a file and line, covering ≥ **2 kinds**: bug, security, architecture (MVVM rule broken), performance, test gap, maintainability.
- [x] A decision for every finding (accepted / modified / rejected) with a valid reason: a requirement in the Lab 3 handout, a rule in §5, a measurable effect (crash, latency, rebuild count) or a real constraint (scope, time, API limits). "The AI said so" and "I didn't like it" are not reasons.
- [x] ≥ **3 fixes**, each in **its own commit naming the finding ID** (e.g. `fix(CR-01): move SerpAPI call out of SearchScreen`), linked below.
- [x] Every AI tool used in the lab disclosed (table at the end).

## Process rules

**At most 3 AI review rounds per pull request.** This is a cap, not a quota: stop as soon as no blocker or major finding remains (often after `R1`). After `R3` the agent stops, and any open findings go to a human reviewer.

**Review only the changes:**

| Round | Input |
|---|---|
| `R1` | The PR diff only: `git diff main...HEAD` |
| `R2`, `R3` | Only the diff since the last reviewed commit (`git diff <last-reviewed-sha>..HEAD`) plus the open findings |

- Read code outside the diff only when a changed line cannot be judged without it, and only that part.
- Record the reviewed SHA range per round. Do not re-report findings already decided.

## Review record (Appendix C)

| ID | Tool | File:line | Kind | Finding (summary) | Decision | Reason | Fix commit | PR / round |
|---|---|---|---|---|---|---|---|---|
| CR-01 | Claude Code (Opus 5.5 review subagent) | `lib/features/internships/screens/internship_detail_screen.dart:137` | bug | The save-error `Retry` and `View saved` SnackBar actions use the Detail's `ref` / `context`, which are gone once the student goes Back (the SnackBar stays on the root messenger) | **Accepted** | Measurable: a widget test reproduced it (`Bad state: Using "ref" when a widget … has been unmounted`, an uncaught async error that reaches Crashlytics); fixed with a mounted guard and a router captured up front | [`374851d`](https://github.com/lamtailoi2/prm323_lab3/commit/374851d) | #11 R1 |
| CR-02 | Claude Code (Opus 5.5 review subagent) | `lib/features/internships/widgets/detail_bottom_bar.dart:73` | bug (accessibility) | `excludeSemantics` on the Save toggle drops the InkWell's tap action, so TalkBack, Switch Access and ARTEMIS cannot press Save | **Accepted** | AGENTS.md rule 12 and the accessibility rules; a semantics test showed no tap action before the fix | [`7d8dea2`](https://github.com/lamtailoi2/prm323_lab3/commit/7d8dea2) | #11 R1 |
| CR-03 | Claude Code (Opus 5.5 review subagent) | `lib/features/internships/viewmodels/internship_detail_viewmodel.dart:92` | bug | Unsaving an expired listing opened from its saved copy turns Detail into "This internship is no longer available" | **Modified** | The listing stays on screen (reproduced in a ViewModel test); the suggested confirmation dialog and "Removed from saved" message were not added: they have no Figma frame or copy (rule 1) | [`115d053`](https://github.com/lamtailoi2/prm323_lab3/commit/115d053) | #11 R1 |
| CR-04 | Claude Code (Opus 5.5 review subagent) | `lib/core/utils/listing_text.dart:9` | bug | The heading regex reads a trailing `#` without a space as closing hashes, so `## Skills: C#` shows as `Skills: C` | **Modified** | Heading regex fixed as suggested (reproduced: `Skills: C`); `__` stripping kept, because `__bold__` is Markdown bold too and removing it would show raw markers, while `__init__` in a listing is hypothetical | [`bebb355`](https://github.com/lamtailoi2/prm323_lab3/commit/bebb355) | #11 R1 |
| CR-05 | Claude Code (Opus 5.5 review subagent) | `lib/features/internships/screens/search_results_screen.dart:455` | test gap | Search Results → Detail (`push`, Back keeps the results) and Saved → Detail are untested | **Accepted** | Definition of done (route + ViewModel/screen tests); two router tests added | [`67b8bfb`](https://github.com/lamtailoi2/prm323_lab3/commit/67b8bfb) | #11 R1 |
| CR-06 | Claude Code (Opus 5.5 review subagent) | `lib/features/saved/viewmodels/saved_viewmodel.dart:85` | maintainability | `toggleAndReport` repeats the body of `toggle`, including the `internship_save` parameters | **Accepted** | Two copies of the analytics parameters (plan row 7) would drift; `toggle` now delegates, Saved/Home/Detail tests unchanged and passing | [`55d0b91`](https://github.com/lamtailoi2/prm323_lab3/commit/55d0b91) | #11 R1 |
| CR-07 | Claude Code (Opus 5.5 review subagent) | `lib/features/applications/viewmodels/applied_providers.dart:15; lib/core/utils/distinct_listings.dart:10` | bug | Lists keep one synced copy of a job, but the Applied badge and the Saved state match the key of one copy, so they are lost when another copy is kept | **Modified** | The Applied badge and Detail's applied state now match by job identity (folded title + company, the rule lists use to merge copies; test fails without it). The Saved part is not changed: Saved documents are keyed per copy by the Saved feature (another owner); recorded in G-32 | [`273cf7e`](https://github.com/lamtailoi2/prm323_lab3/commit/273cf7e) | #13/#15 R1 |
| CR-08 | Claude Code (Opus 5.5 review subagent) | `lib/features/internships/viewmodels/search_results_viewmodel.dart:258; lib/features/internships/viewmodels/search_viewmodel.dart:162` | bug | Copies are merged before the query filter, so a job found only through a dropped copy's `searchKeyword` disappears from results, the preview count and `result_count` | **Accepted** | Reproduced: `backend` found 0 of 1 matching jobs; copies are now merged after filtering | [`ee23087`](https://github.com/lamtailoi2/prm323_lab3/commit/ee23087) | #13 R1 |
| CR-09 | Claude Code (Opus 5.5 review subagent) | `lib/features/internships/models/search_filter_criteria.dart:49` | bug | The typed query is not accent-folded, so `ha noi`, `Hanoi` or `thuc tap` find nothing in the Vietnamese pool | **Modified** | Diacritics are removed (`removeDiacritics`), and a space-free comparison covers `Hanoi`; `foldText` as suggested was not used because it turns symbols into spaces, making `C#` / `C++` match every `C` (covered by a test) | [`eb62d3e`](https://github.com/lamtailoi2/prm323_lab3/commit/eb62d3e) | #12 R1 |
| CR-10 | Claude Code (Opus 5.5 review subagent) | `lib/features/internships/screens/search_screen.dart:142` | bug | The Search tab awaits the Firestore history write before navigating, so offline the search never opens | **Accepted** | Reproduced with a write that never completes; the write now runs in the background, as Search Results already did | [`8980a95`](https://github.com/lamtailoi2/prm323_lab3/commit/8980a95) | #12 R1 |
| CR-11 | Claude Code (Opus 5.5 review subagent) | `lib/features/internships/viewmodels/search_viewmodel.dart:102` | bug | The Search tab sheet previews `Show 0 results` if opened before the first pool snapshot | **Rejected** | Small measurable effect: only when the sheet is opened before the first snapshot, the number updates on the next selection, and Search Results recomputes from the stream, so no wrong list is shown; a live count needs a change to the shared sheet API. Recorded in G-32 | — | #12 R1 |
| CR-12 | Claude Code (Opus 5.5 review subagent) | `lib/features/internships/models/search_filter_criteria.dart:81` | bug | `Above 5M VND/mo` and `Negotiable` are counted as filters but filter nothing | **Accepted** | Same silent no-op as the Job type bug of #15; both options are in the Figma Filter sheet. Implemented with the allowance parser (`highestVndAmount`, `isNegotiableAllowance`) | [`22f1922`](https://github.com/lamtailoi2/prm323_lab3/commit/22f1922) | #12 R1 |
| CR-13 | Claude Code (Opus 5.5 review subagent) | `lib/features/internships/viewmodels/search_results_viewmodel.dart:347` | bug (analytics) | `search_filter_apply` leaves out job type and allowance, so those filters cannot be told apart from no filter | **Accepted** | The plan's question ("which filters narrow results to zero") needs them; `job_type` and `allowance` added (analytics-plan row 5) | [`1cab0ec`](https://github.com/lamtailoi2/prm323_lab3/commit/1cab0ec) | #13 R1 |
| CR-14 | Claude Code (Opus 5.5 review subagent) | `lib/features/applications/viewmodels/applied_providers.dart:11; lib/core/widgets/internship_card.dart:168` | test gap | No test for the Applied provider or for the card badge at both widths | **Accepted** | AGENTS.md testing rules (shared widget at 360/412 dp, tap targets); provider and card tests added | [`5f1762e`](https://github.com/lamtailoi2/prm323_lab3/commit/5f1762e) | #15 R1 |
| CR-15 | Claude Code (Opus 5.5 review subagent) | `lib/features/internships/viewmodels/apply_form_viewmodel.dart:286` | bug | After an upload fails in the background, `Continue to review` quietly hands over the Profile CV | **Accepted** | Rule 7 (never fake success): the student never chose that CV; reproduced in a test; Continue now asks to retry or choose another CV | [`051adf3`](https://github.com/lamtailoi2/prm323_lab3/commit/051adf3) | #14 R1 |
| CR-16 | Claude Code (Opus 5.5 review subagent) | `lib/features/internships/screens/apply_form_screen.dart:95` | bug | `Edit skills` / banner links use `context.go` to Profile, dropping the form and a CV uploaded or uploading for this internship | **Modified** | `Edit skills` (shown even during an upload) opens the Profile Edit skills sheet over the form; the banner links keep `go` because, after CR-20, they only show when the form holds nothing that would be lost (CV from Profile or none, no upload running) | [`65b123f`](https://github.com/lamtailoi2/prm323_lab3/commit/65b123f) | #14 R1 |
| CR-17 | Claude Code (Opus 5.5 review subagent) | `lib/features/internships/viewmodels/apply_form_viewmodel.dart:314` | security | CVs uploaded for one internship are never deleted when replaced, dropped or abandoned | **Rejected** | Real constraint: deleting needs a `storage.rules` change (rule 9: discussed, owner-deployed) and a retention decision with Flow 4, which reads the uploaded CV's `storagePath`; recorded in G-32 | — | #14 R1 |
| CR-18 | Claude Code (Opus 5.5 review subagent) | `lib/features/internships/viewmodels/apply_form_viewmodel.dart:187` | bug | A Profile load error looks like "no CV yet" (tip and empty upload area, no error, no Retry) | **Accepted** | Rule 6 (explicit error state with Retry); the CV section now shows the error with `Retry` and `Upload CV` | [`4605876`](https://github.com/lamtailoi2/prm323_lab3/commit/4605876) | #14 R1 |
| CR-19 | Claude Code (Opus 5.5 review subagent) | `test/features/internships/apply_form_viewmodel_test.dart:91` | test gap | The `apply_start` "once" test never rebuilds the ViewModel; account switch and the saved-copy fallback are untested | **Accepted** | Rule 11 (user-scoped data): the test now changes the uid; account-switch and saved-copy tests added | [`26fdad4`](https://github.com/lamtailoi2/prm323_lab3/commit/26fdad4) | #14 R1 |
| CR-20 | Claude Code (Opus 5.5 review subagent) | `lib/features/internships/screens/apply_form_screen.dart:146` | maintainability | The Profile tip still shows after a CV was uploaded for this internship, against the method's doc comment | **Accepted** | The comment states the intended behaviour; the code now matches it, with a widget assertion | [`ceb1472`](https://github.com/lamtailoi2/prm323_lab3/commit/ceb1472) | #14 R1 |

Totals: 20 findings (bug 14, test gap 3, maintainability 2, security 1); 13 accepted, 5 modified, 2 rejected; 18 fix commits on branch `fix/code-review-r1`.

### Per-PR log

Reviewer: Claude Code, one Opus 5.5 subagent per PR group with a fresh context, given only the PR diff (`lib/`, `test/`, `functions/`) and AGENTS.md, not the author's notes; line numbers are as at `dev` `4d2aeda`. The PRs were already merged, so R1 ran on each PR's own range and the fixes went to a new branch. Raw outputs: `evidence/code-review/`.

```markdown
### PR #11: feat/internship-detail  (reviewer tool: Claude Code review subagent, date: 2026-11-02)
- R1 · reviewed `3c2c313...5355902` → findings CR-01 … CR-06 (2 major, 4 minor); all fixed
- R2 · not needed: no blocker or major left open
- flutter analyze → No issues found!; flutter test → 525/525 after all fixes

### PRs #12, #13, #15: fix/search-screen, fix/search-analytics, fix/job-type-applied-badge  (same tool and date)
- R1 · reviewed `bb3e1e1...dcd7644`, `a2d9b85...c7b36a7`, `fe286dc...9375b27` → findings CR-07 … CR-14 (3 major, 5 minor)
- CR-07 modified (Saved part recorded in G-32), CR-11 rejected; the rest fixed
- R2 · not needed: no blocker or major left open
- flutter analyze → No issues found!; flutter test → 525/525

### PR #14: feat/apply-pre-submit  (same tool and date)
- R1 · reviewed `9ab527c...107c2a2` → findings CR-15 … CR-20 (2 major, 4 minor)
- CR-17 rejected (rules change and Flow 4 retention, G-32); the rest fixed
- R2 · not needed: no blocker or major left open
- flutter analyze → No issues found!; flutter test → 525/525
```

## AI tools used (disclosure)

| Tool | Version / model | Used for | Where recorded |
|---|---|---|---|
| Google Stitch | — | Lab 2 screen generation and refinement | Lab 2 `ai/ai-design-log.md` |
| Claude Code | Opus 5.5 (`claude-opus-5-5`) | Repository initialization: design tokens, shared widgets, services, routing, tests, documentation; requirement review against the Lab 3 handout; Profile screen, sheets, Edit profile, profile service and tests (P-21); Saved empty state opens Search (P-33); Internship Detail, Search field / filters / analytics, Apply Form, Job type and Applied badge (P-34 – P-43); fixes from the AI review (P-44) | [`implementation-ai-log.md`](records/implementation-ai-log.md) |
| OpenCode | `deepseek-v4.1-flash-free` | Home UI implementation, SerpAPI → Firestore sync function, rules and documentation (P-18); Saved list, the Home Save Toggle, unsave with Undo and the Saved loading state (P-21, P-22, P-26, P-27); Search bookmark merged onto the Saved write path and the legacy `SavedService` removed (P-50) | [`implementation-ai-log.md`](records/implementation-ai-log.md) |
| Command Code | — (implementation assistant; not a review tool) | CV validation implementation: callable `validateCv` + Gemini, Flutter service/ViewModel/step widget, tests and documentation (P-32); work mode read from the listing text so the Search filter no longer returns an empty list (P-45); Filter Skills from the current pool instead of a fixed list (P-46); Flow 2 completion: Validate CV screen, Application Review and Success screens, `ApplicationService.createApplication()`, router steps, tests and documentation (P-47); Flow 3 Application Detail audit, status tracker, withdraw + Undo, `view_application` and E2E TC-09/TC-10 (P-48) | [`implementation-ai-log.md`](records/implementation-ai-log.md) |
| Google ARTEMIS | commit `351ca84` + model on the host | End-to-end test execution and the exploratory session | [`test-plan.md`](test-plan.md) |
| Claude Code (review subagents) | Opus 5.5 (`claude-opus-5-5`), one subagent per PR group with a fresh context and only the diff + AGENTS.md | AI code review R1 of PRs #11–#15 (CR-01 – CR-20) | this file; raw output in `evidence/code-review/` |
