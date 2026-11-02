<!-- Raw output of the AI review (Claude Code, Opus 5.5 subagent, independent context: given only the PR diff and AGENTS.md), saved verbatim. 2026-11-02. -->

## PR #11 — R1 review
Reviewed: `3c2c313...5355902` (diff of lib/, test/)

| # | File:line (dev HEAD) | Kind | Severity | Finding |
|---|---|---|---|---|
| 1 | lib/features/internships/screens/internship_detail_screen.dart:137 | bug | major | The save-error SnackBar's `Retry` action (and `View saved` at line 152) reuses the Detail's `ref` and `context`. The SnackBar stays on screen after the route closes, so tapping it after Back throws a `StateError` and the save never runs again. |
| 2 | lib/features/internships/widgets/detail_bottom_bar.dart:73 | bug | major | `excludeSemantics: true` on the Save toggle also removes the InkWell's tap action. Assistive tech sees a "button" it cannot activate, and the tap-target guideline test skips the control. |
| 3 | lib/features/internships/viewmodels/internship_detail_viewmodel.dart:92 | bug | minor | Unsaving an expired listing opened from its saved copy immediately turns the screen into "This internship is no longer available". There is no feedback or confirmation, and the listing can never be saved again. |
| 4 | lib/core/utils/listing_text.dart:9 | bug | minor | The heading regex treats a `#` with no space before it as closing hashes, so `## Skills: C#` shows as "Skills: C". Separately, `_emphasis` (line 12) turns `__init__` into `init`. |
| 5 | lib/features/internships/screens/search_results_screen.dart:455 | test gap | minor | Search → Detail (`push`, Back returns to the same results) and Saved → Detail (saved_screen.dart:225) have no tests. Only Home → Detail is covered (router_test.dart:138). |
| 6 | lib/features/saved/viewmodels/saved_viewmodel.dart:85 | maintainability | minor | `toggleAndReport` copies the whole body of `toggle`: repeated-tap guard, direction check, save/remove and the `internship_save` event. The two copies will drift apart. |

### Details
1. **Retry / View saved run on a disposed screen.**
   - **Scenario:** a save fails on Detail (for example offline), so `_toggleSave` shows the error with a `Retry` action. In Flutter 3.47 a SnackBar with an action persists by default (`persist = persist ?? action != null`). The student presses Back. The SnackBar lives on the root `ScaffoldMessenger`, so it is now shown over Home, Search or Saved. Tapping `Retry` calls `_toggleSave(context, ref, …)` with the unmounted `ConsumerElement`, and `ref.read` throws `StateError('Using "ref" when a widget is about to or has been unmounted is unsafe…')` (flutter_riverpod 3.4.3 `_assertNotDisposed`).
   - **Impact:** the future is `unawaited`, so this is an uncaught async error that reaches Crashlytics. Nothing is saved, and the student gets no message. `View saved` (line 152) has the same problem during its 4 s window: `context.go` runs on a deactivated context.
   - **Fix:** guard both actions, or stop the SnackBar from outliving the route:
     ```dart
     onPressed: () {
       if (!context.mounted) return;
       unawaited(_toggleSave(context, ref, internship, wasSaved: wasSaved));
     },
     ```
     Also capture `GoRouter.of(context)` before the `await` for `View saved`, or use `persist: false` and hide the SnackBar when the Detail is popped.
   - **Test to add:** failed save → Back → tap Retry → no exception.

2. **Save toggle has no accessibility tap action.**
   - **Cause:** `Semantics(button: true, label: …, excludeSemantics: true, child: Material(InkWell(onTap: …)))`. `excludeSemantics` drops all child semantics, including the `Semantics(onTap: simulateTap)` that InkWell adds.
   - **Verified:** a throwaway widget test with Flutter 3.47.6 (scratchpad, repo untouched) reports `hasAction(SemanticsAction.tap) == false` for the "Save internship" node, and the node is not focusable.
   - **Impact:**
     - Switch Access, Voice Access ("tap Save internship") and semantics-driven E2E such as ARTEMIS (AGENTS.md rule 12) cannot trigger Save, a core Flow 2e action.
     - `meetsGuideline(androidTapTargetGuideline)` skips nodes that have no tap action, so the screen test passes without checking this control.
     - The widget tests only pass because `tester.tap` hits by position.
   - **Fix:** `Semantics(button: true, label: …, onTap: onPressed, excludeSemantics: true, …)`, or remove `excludeSemantics` and wrap only the icon and text in `ExcludeSemantics`.
   - **Test to add:** `expect(tester.getSemantics(find.bySemanticsLabel('Save internship')), containsSemantics(isButton: true, hasTapAction: true));`

3. **Unsaving an expired listing wipes the screen and the copy.**
   - **Scenario:** listing K has been deleted from `/internships` by the sync and is opened from Saved, so the ViewModel shows the saved copy (G-25 #5). The student taps "Saved" to unsave.
     - `savedInternshipsProvider` emits without K.
     - The listener at line 92 (`_resolved && _listing == null`) calls `_emit()`, which sets `ViewEmpty`.
     - The body becomes "This internship is no longer available… removed from Google Jobs" and the bottom bar disappears.
     - `_toggleSave` (screen line 143) shows nothing for an unsave.
   - **Impact:** the loss is permanent. `FirestoreSavedInternshipService.save` copies `/internships/K`, which no longer exists, so saving again fails with `notFound`. One tap silently loses the only copy, and the message wrongly blames the source.
   - **Fix:**
     - Once data has been shown, keep the last internship when the saved copy disappears; only go empty when the listing is missing before the first data.
     - Show "Removed from saved" after an unsave.
     - For an expired listing, ask for confirmation first, because it cannot be saved again.
   - **Test to add:** a ViewModel test where the saved copy is shown, then removed from saved, and the state stays `ViewData`.

4. **Markdown cleanup corrupts IT terms.**
   - **Scenario:** `plainListingText('## Skills: C#\n- Flutter')` returns `'Skills: C\n• Flutter'`, and `'### .NET / C#'` returns `'.NET / C'` (verified by running the function). The trailing `\s*#*\s*$` lets the closing hashes start with no space; CommonMark requires a space before them. C# and F# are common in the IT listings this screen shows. Also, `_emphasis` removes every `__`, so "Python __init__ methods" shows as "Python init methods". The existing test only covers C# outside a heading.
   - **Fix:** use `RegExp(r'^\s{0,3}#{1,6}(?:\s+(.*?))?(?:\s+#+)?\s*$')`. Verified results:
     - `## Skills: C#` → "Skills: C#"
     - `## Requirements ##` → "Requirements"
     - `#hashtag` is still not treated as a heading

     Strip only `**`, which is what the listing text uses. Add tests for a heading that ends in C# and for `__init__`.

5. **Search and Saved entry points are untested.**
   - **What changed:** the Search Results tap changed from a SnackBar to `context.push('/search/internships/<key>')`. The code comment gives the reason: Back should return to the same results (query, filters, scroll). The Saved card now uses `go('/saved/internships/<key>')`. Both depend on the new routes at router.dart:117 and :126.
   - **Gap:** only Home → Detail is tested. The Detail screen test builds its own GoRouter with only `/home/...`. A wrong parent route, a missing `parentNavigatorKey`, or a push that drops the query would still pass CI.
   - **Tests to add:**
     - Start at `/search/results?q=flutter`, tap a card, and expect "Internship details", no `NavigationBar`, and the `search_internship_detail` screen view. Press Back and expect the results with the same query.
     - The same check for a Saved card.

6. **Duplicated save logic.**
   - **Problem:** `toggle` (lines 52–78) and `toggleAndReport` (85–112) repeat the guard, the provider reads, the direction check, the save/remove calls and the `internship_save` parameters; only the result handling differs. A future change, such as an extra event parameter (analytics plan row 7) or handling `notFound`, has to be made in both places. The `SavedWriteResult` doc (line 9) also still lists only remove and restore.
   - **Fix:** make `toggle` delegate:
     ```dart
     Future<void> toggle(Internship internship, {required String source}) async {
       if (_writing) return;
       state = const AsyncLoading();
       final result = await toggleAndReport(internship, source: source);
       if (!ref.mounted) return;
       final error = result.error;
       state = error == null ? const AsyncData(null) : AsyncError(error, StackTrace.current);
     }
     ```
