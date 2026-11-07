# P-46 review round 1 — correctness subagent (raw output)

Reviewer: OpenCode review subagent, one round, only the P-46 change set.
Scope: `functions/src/config.ts`, `functions/src/config.test.ts`, `lib/core/utils/job_level.dart`, `lib/models/internship.dart` (`level` getter only), `lib/core/utils/job_role.dart` (`accountant` words only), `lib/features/internships/screens/internship_detail_screen.dart` (`_JobHeader` badges + `_DetailBadge`), and the matching test additions. Unrelated uncommitted Apply/Confirm work ignored.

| ID | Severity | file:line | Issue | Why it matters | Suggested fix |
|---|---|---|---|---|---|
| R1-01 | major | `lib/core/utils/job_level.dart:22-26` (+ `functions/src/config.ts:10-19`) | Every one of the 8 keywords encodes a level (`internship`/`thuc tap` → Intern, `fresher`, `junior`). Since `sync` always writes `searchKeyword`, the keyword fallback makes `level` non-null for **every** synced listing. | The documented "no level → no badge" path is effectively dead in production, and a title like `Senior Backend Engineer` returned by an intern query gets an **Intern** badge. The level is then the query, not the job. | Only fall back to the keyword when the title has no explicit level/seniority, or exclude `senior`/`lead`/`manager`/`principal` before the fallback. Reconcile the doc comment with the actual behaviour. |
| R1-02 | minor | `functions/src/sync.ts:69` (interaction with `job_level.dart:25`) | `searchKeyword` is overwritten (`merge: true`) by whichever keyword last re-found the listing. | A generic title matched by both an intern and a fresher/junior query flips its level badge as the rotation cycles. | Persist the first/original keyword, or derive level only from the title + explicit level keywords and keep it stable. |
| R1-03 | minor | `test/features/internships/internship_detail_screen_test.dart:209` | `find.textContaining('Experience:')` searches `Text` widgets, but `Experience: …` is only a `Semantics` label. It can never match, so the assertion is vacuously true. | The "hides the level badge" test would still pass if the badge were shown; it gives false confidence. | Assert `find.bySemanticsLabel(RegExp(r'^Experience:'))` is `findsNothing`. |
| R1-04 | minor | `test/core/utils/job_level_test.dart:39-41` | The "returns null when no level" case omits `searchKeyword`, which never happens for synced data (see R1-01). No test covers a title with explicit seniority + intern keyword, nor `Internship.level` wiring. | The test suite does not catch the main false-positive/always-level behaviour. | Add cases: `('Senior Backend Engineer', 'IT internship Vietnam')`, generic title + fresher/junior keyword, and a model-level `level` getter test. |
| R1-05 | minor | `lib/core/utils/job_role.dart:76` | `'accountant'` uses whole-word matching, so `Accountants`/`Accountancy` are not rejected. | `Junior Accountants Data Entry` could fall through to `dataAi` (the `data` term). | Add `'accountants'`/`'accountancy'` or match a stem. |
| R1-06 | minor | `functions/src/config.test.ts:13` | `KEYWORDS.length <= 8` is an arbitrary cap and does not verify the actual quota model (4 runs/day × cycle, backfill). | It will fail on a legitimate 9th keyword while proving nothing about the 250/month limit. | Assert the computed monthly usage (e.g. `4*31 + KEYWORDS.length <= 250`) and `PAGES_PER_KEYWORD === 1`. |
| R1-07 | minor | `lib/features/internships/screens/internship_detail_screen.dart:276-294` | Badges render independently: a listing with `role == null` (non-IT) but a level still shows an experience badge. | A non-IT listing that slips into Detail shows e.g. "Intern" with no role context. Home filters `role != null`, so this is mostly a Saved/edge path. | Consider showing the level badge only when `role != null`, or require both. |

## What is fine

- Keyword list genuinely contains intern, fresher and junior queries and still does one keyword/page per run; quota math (≈120/month + 8 backfill = ~128 < 250) and the ~2-day refresh vs 7-day expiry are correct (`config.ts:1-27`, `index.ts:30-38`).
- Word-boundary matching correctly rejects `international` (and `internal`/`internet`); the test at `job_level_test.dart:35-37` is valid.
- The `_DetailBadge` semantics wrapper (`excludeSemantics: true` + `bySemanticsLabel`) is correct and accessible.
- No Dart/TS correctness or lint issues found; `functions` tests 19/19 and the three Dart test files 31/31 pass.

## Verdict

**Changes requested** — no blocker, but R1-01 is a real correctness/UX problem (level badge is always keyword-derived and can mislabel senior roles). Fix R1-01 (and ideally R1-02/R1-03), then this is good to merge.
