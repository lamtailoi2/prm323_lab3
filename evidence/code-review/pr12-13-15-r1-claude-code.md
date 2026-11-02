<!-- Raw output of the AI review (Claude Code, Opus 5.5 subagent, independent context: given only the PR diffs and AGENTS.md), saved verbatim. 2026-11-02. -->

## PRs #12, #13, #15 — R1 review
Reviewed: `bb3e1e1...dcd7644`, `a2d9b85...c7b36a7`, `fe286dc...9375b27` (diffs of lib/, test/, functions/)

| # | PR | File:line (dev HEAD) | Kind | Severity | Finding |
|---|---|---|---|---|---|
| 1 | #13, #15 | lib/features/applications/viewmodels/applied_providers.dart:15; lib/core/utils/distinct_listings.dart:10-14 | bug | major | Lists now keep only the best-ranked copy of a job, but the Applied badge and the Saved state still match the exact copy key, so when a re-sync changes which copy is kept, the badge and bookmark disappear and the student can apply to the same job again. |
| 2 | #13 | lib/features/internships/viewmodels/search_results_viewmodel.dart:258; lib/features/internships/viewmodels/search_viewmodel.dart:162 | bug | major | Copies are merged before the query filter runs, so a job that only matched through a dropped copy's `searchKeyword` no longer appears in Search Results, the `Show N results` preview or `result_count`. |
| 3 | #12 | lib/features/internships/models/search_filter_criteria.dart:49, 93-105 | bug | major | The shared `matches` folds accents for the Location filter but not for the typed query, so `ha noi`, `Hanoi` or `thuc tap` return 0 results for `Hà Nội` / `Thực tập sinh …` listings. |
| 4 | #12 | lib/features/internships/screens/search_screen.dart:142 | bug | minor | `_openFilters` waits for the Firestore search-history write before navigating, so `Show N results` closes the sheet and then nothing happens while offline (slow networks add a delay). |
| 5 | #12 | lib/features/internships/viewmodels/search_viewmodel.dart:102-106 (pool starts empty at :71) | bug | minor | `countMatching` counts an empty `_pool` until the first snapshot arrives (or after an error), so the Search tab sheet shows `Show 0 results →` and does not update when the data loads. |
| 6 | #12 | lib/features/internships/models/search_filter_criteria.dart:81-91 | bug | minor | Two of the three allowance options (`Above 5M VND/mo`, `Negotiable`) are counted as active filters but filter nothing, so the student sees a filter chip on unfiltered results. |
| 7 | #13 | lib/features/internships/viewmodels/search_results_viewmodel.dart:347-355 | bug (analytics) | minor | `search_filter_apply` leaves out job type and allowance, so a filter that #15 made work (Job type) is logged the same as applying no filter at all, even when it narrows results to zero. |
| 8 | #15 | lib/features/applications/viewmodels/applied_providers.dart:11; lib/core/widgets/internship_card.dart:168-170 | test gap | minor | `appliedInternshipKeysProvider` has no test: every screen test replaces it with `Stream.value(keys)`. The `isApplied` change to the shared InternshipCard has no test at both widths and no tap-target check. |

### Details
1. **Applied badge and Saved state are lost when the kept copy changes.** The sync writes the same job under several keywords, each copy with its own `job_id`, key and `searchRank`, and re-runs rewrite `searchRank` (`functions/src/sync.ts:63-72`, `merge: true`). Scenario: "Thực tập sinh Java · FPT Software" is copy A (rank 2, `IT internship Vietnam`) and copy B (rank 5, `thực tập backend`). The student applies to A (`users/{uid}/applications/kA`) and saves it. The next rotating sync moves A to rank 9, so `distinctListings` now keeps B. Home and Search Results then show card B with `appliedKeys.contains(kB) == false` (no `Applied`) and an empty bookmark. Detail for B shows `Apply now` again (`internship_detail_viewmodel.dart:159` compares `jobKey`), which creates a second application, and saving B puts the job in Saved twice. Fix: compare by job identity rather than copy key. Applications already store `title` and `companyName`:
   ```dart
   String jobIdentity(String t, String c) => '${foldText(t)}|${foldText(c)}';
   // applied_providers.dart
   {for (final a in applications) jobIdentity(a.title, a.companyName)}
   // cards / Detail
   isApplied: appliedJobs.contains(jobIdentity(i.title, i.companyName))
   ```
   For Saved, either make `distinctListings(listings, prefer: savedKeys)` keep the copy the student saved, or keep the merged copies' keys and check `any`. Add a test where the saved or applied copy is not the best-ranked one.

2. **Merging copies before filtering drops valid matches.** `searchKeyword` is stored per copy and is one of the fields the query matches (`search_filter_criteria.dart:99-100`). Scenario: the job above is kept as copy A (keyword `IT internship Vietnam`). The student searches `backend`: the title, company, skills and A's keyword all miss, and copy B (`thực tập backend`), which matched before #13, has already been dropped. Result: the job is missing, and `search.result_count` and the `Show N results` count are too low. Fix: keep every copy and merge after filtering:
   ```dart
   _rawList = data;
   List<Internship> _applyFilters(raw, q, c) =>
       distinctListings(raw.where((i) => c.matches(i, query: q)));
   ```
   Do the same in `SearchViewModel.countMatching`: keep the raw pool and merge only for Trending and the count. Add a test where the query matches only the lower-ranked copy's keyword.

3. **The typed query is not accent-folded.** `q = query.trim().toLowerCase()` and `location.toLowerCase().contains(q)` are compared without folding. With the `hl=vi` sync, locations and many titles are Vietnamese. `ha noi`, `Hanoi`, `ho chi minh`, `thuc tap` or `lap trinh` therefore return 0 results, while the sheet's `Ha Noi` option (through `matchesPreferredLocation`) matches the same listings. The logic was moved unchanged from `_applyFilters`, but #12 made it the shared matcher for both screens. Fix: `final q = foldText(query);` and `bool has(String? s) => s != null && foldText(s).contains(q);` for title, company, skills, keyword and location, plus a test for `ha noi`→`Hà Nội` and `thuc tap`→`Thực tập sinh`.

4. **The history write blocks navigation.** `record()` runs a `.get()` and then `batch.commit()`. Offline, a Firestore write future does not complete until the server confirms it, so `await viewModel.recordSearch(term)` never returns. The sheet closes and Search Results never opens, even though `watchActive()` could show cached results. On slow networks it adds two round trips before navigating. This contradicts the ViewModel's own comment: "Recording history must never block the search itself". `_submit` (:104) has the same pattern. Fix: `unawaited(viewModel.recordSearch(term));` and then `context.go(...)`, as `SearchResultsViewModel.setQuery` already does.

5. **The preview count shows 0 before the data arrives.** If the student taps the filter icon on the Search tab before the first `watchActive()` snapshot (cold start), or after Trending failed, every selection shows `Show 0 results →`. The sheet only recomputes on its own `setState`, so the label stays 0 after the pool loads. Fix: return `int?` (null until the first snapshot or on error) and label the button `Show results →`, or have the sheet watch a provider so the count updates.

6. **Allowance options that do nothing.** `criteriaCount` counts `Above 5M VND/mo` and `Negotiable`, so a chip and a filter count appear, but `matches` only handles `Paid only`. Choosing `Above 5M VND/mo` still lists `Not disclosed` and `3,000,000 VND / mo` listings. #15 fixed the same kind of silent no-op for Job type. Fix: implement both options with the allowance parser (an amount ≥ 5,000,000 VND; `formatAllowance(...) == 'Negotiable'`), or remove the two options and record the gap in `handoff-gaps.md`. Add tests.

7. **The filter analytics leave out the filters that now work.** Applying only `Job type: Internship` with 0 results logs `{work_mode: any, location: any, skill_count: 0, result_count: 0}`, the same as tapping `Show N results` without choosing anything. The plan's question "which filters narrow results to zero" cannot be answered for job type or allowance. Fix: add `job_type` and `allowance` string parameters (the option or `any`, ≤ 100 chars), update `docs/analytics-plan.md` row 5, and extend the ViewModel test.

8. **Missing tests for the Applied badge.** Neither the `application.jobKey` mapping nor the reset on sign-out (rule 11, via `applicationServiceProvider`) is tested; the three screen tests override the whole provider. The shared InternshipCard gained a badge in the allowance/posted row with no widget test at 360 and 412 dp and no `meetsGuideline(androidTapTargetGuideline)` check. Fix: add a `ProviderContainer.test` with a fake `ApplicationService` and a uid override (emits keys, then `{}` after sign-out), and an InternshipCard test `for (final width in checkWidths)` with a long allowance and `isApplied: true` that checks there is no overflow, the `Applied` label is shown, and the semantics end in `Applied`.
