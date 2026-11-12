# AGENTS.md: Internly coding conventions and rules

Instructions for everyone who changes this repository, human or AI agent. Read this file before writing code. If a rule blocks you, raise it in the pull request instead of working around it.

## Project in brief

- **Internly**: Flutter app (graded on Android; iOS also builds) for IT students to find, save, apply to and track internships. Product overview: [`README.md`](README.md).
- **Architecture:** MVVM + Riverpod 3 + go_router; data from **SerpAPI (Google Jobs)** + Firebase. Details: [`docs/architecture.md`](docs/architecture.md).
- **Constraint:** zero cost. Use only free plans and free tiers (handoff-gaps G-26).
- **UI source of truth:** the Lab 2 design in [`docs/design/`](docs/design/README.md) and Figma, consolidated in [`docs/design/design-system.md`](docs/design/design-system.md).
- **Open decisions:** [`docs/records/handoff-gaps.md`](docs/records/handoff-gaps.md). Read the relevant gap before building a feature.

## Commands

```bash
flutter pub get                 # install dependencies
dart format lib test            # format (CI expects formatted code)
flutter analyze                 # must print "No issues found!"
flutter test                    # all tests must pass
flutter run -d <device> --dart-define-from-file=.env   # needs Firebase config + .env (docs/guides/firebase-setup.md)

# Rules tests (emulators only; run from the repository root)
npm --prefix firebase/tests install                    # once
firebase emulators:exec --only firestore,storage --project demo-internly "npm --prefix firebase/tests test"
firebase emulators:exec --only firestore,storage --project demo-internly "npm --prefix firebase/tests run demo"   # http://localhost:5500
```

Run `dart format`, `flutter analyze` and `flutter test` before every commit you ask someone to review. Paste the real results in the PR; never claim a result you did not see.

The rules commands need `firebase-tools` and a JDK on `PATH` (`java -version` must work; the CLI ignores `JAVA_HOME` alone). Details and troubleshooting: [`firebase/tests/README.md`](firebase/tests/README.md).

## Golden rules

1. **Do not invent UI.** Screens, copy, colors, typography, spacing, radii, icons and flows come from Lab 2 / Figma. If something is missing, add it to `docs/records/handoff-gaps.md`. If you must deviate (platform constraint, accessibility failure, API limit), record it in `docs/design-traceability.md` §4 **in the same PR** and update Figma; an unrecorded difference is graded as a defect.
2. **MVVM layering is strict.** View → ViewModel → Service → Firebase. Views never import Firebase or call services. ViewModels never hold a `BuildContext`.
3. **Riverpod only** for state and dependency injection. No `provider`, Bloc, GetX, `setState` for business state, or singletons accessed from widgets.
4. **Tokens only.** No `Color(0x…)`, raw font sizes, raw `EdgeInsets` numbers or new radius values in feature code. Use `AppColors`, `Theme.of(context).textTheme`, `AppSpacing`, `AppRadii`, `AppSizes`, `AppElevation`.
5. **Reuse shared components** from `lib/core/widgets/` before creating new ones. A new shared component must match a Figma component and be added to `design-system.md`.
6. **Every data screen has an explicit `ViewState`** (`core/state/view_state.dart`: loading, empty, error, data) owned by its ViewModel, rendered with the skeleton / `StateView.empty` / `StateView.error` + `Retry`.
7. **Never fake success.** No placeholder URLs saved as real results, no hard-coded "uploaded" states, no fake Firebase config, no tests that only tap without asserting a visible result.
8. **No secrets in the repository:** service-account keys, API secrets, model API keys, `.env`, keystores, `.p8`, passwords. The SerpAPI key is a Cloud Function secret (`SERPAPI_KEY` in Secret Manager), never in the app or `.env`. The shared debug key (`DEBUG_KEYSTORE_BASE64`) goes in the untracked `.env`, shared privately, never via Git, and is read with `String.fromEnvironment`. Firebase app config files are allowed (`docs/guides/firebase-setup.md` §11).
9. **Rules are final; keep user data under `users/{uid}`.** `firebase/firestore.rules` lets a signed-in user read and write only their own `users/{uid}/**` subtree (any subcollection), so features need no rules change. The shared `/internships/{key}` pool is the one exception: signed-in users read it, only the scheduled function writes it; `/sync/**` is function-only. Never add another shared or other users' data without a discussed rules change; files go only to `reports/{uid}` / `cvs/{uid}` (`firebase/storage.rules`).
10. **Stay in scope.** Implement what the spec and the task ask for. No speculative features, abstractions or dependencies.
11. **User data is user-scoped.** Every provider holding user data watches `currentUserIdProvider`, so sign-out drops it.
12. **Testable by ARTEMIS.** Key widgets (buttons, list items, cards) have a Semantics label or tooltip; shared components already do.

## Where code goes

| You are adding… | Put it in | Notes |
|---|---|---|
| A screen | `lib/features/<feature>/screens/<name>_screen.dart` | One screen per file, `XxxScreen` |
| Screen state / logic | `lib/features/<feature>/viewmodels/<name>_viewmodel.dart` | `XxxViewModel` + `xxxViewModelProvider` |
| A widget used by one feature | `lib/features/<feature>/widgets/` | |
| A widget used by 2+ features | `lib/core/widgets/` | Must map to a Figma component |
| A model used by 2+ features | `lib/models/` | Otherwise `features/<feature>/models/` |
| Firebase / HTTP access | `lib/services/<name>_service.dart` | Interface + implementation + provider in one file. SerpAPI only through the scheduled function in `functions/`; app reads only through `InternshipService`; uploads only through `FileStorageService` |
| A Firestore / Storage rules test | `firebase/tests/<rules>.rules.test.mjs` | `node --test`; add the same decision to `demo/server.mjs` when it should appear in the recorded demo |
| A pure helper | `lib/core/utils/` | Unit-tested |
| A route | `lib/app/router.dart` | Under the owning tab branch, always with a `name` |
| A design token | `lib/theme/` | Only from DESIGN.md / Figma, and update `design-system.md` |

## Dart and Flutter conventions

- **Style:** Effective Dart, enforced by `analysis_options.yaml` (strict casts/inference/raw types, single quotes, `prefer_final_locals`, `unawaited_futures`, ordered imports). Format with `dart format` (default 80 columns).
- **Naming:** files `snake_case.dart`; classes `UpperCamelCase`; providers `lowerCamelCaseProvider`; enum storage values `snake_case` strings.
- **Imports:** relative imports inside `lib/`; `package:internly/...` in `test/`. Order: `dart:`, `package:`, then relative (the analyzer enforces this).
- **Widgets:** prefer `StatelessWidget` / `ConsumerWidget`; small and composable; `const` constructors wherever possible; no business logic in `build`.
- **Models:** `@immutable`, `final` fields, `const` constructors. Firestore parsing goes through `FirestoreReader` in `factory X.fromFirestore(String id, Map<String, Object?>? data)`; writes go through `toFirestore()` / `toCreateMap()`. Required fields throw `FormatException`; services skip and log malformed documents. Don't override `==` by ID only, because Riverpod uses `==` to decide whether to notify.
- **Errors:** services catch SDK exceptions and throw `AppException(kind, userMessage, cause: e)`. `message` is plain language and safe to show; `cause` is for logging only. `AppErrorKind.cancelled` is shown as an info message, not as an error.
- **Async in ViewModels:** read all providers **before** the first `await`; after each `await`, check `ref.mounted` before touching `state`; ignore repeated taps while `state.isLoading`.
- **Comments:** explain *why*, not *what*. Reference gap or change IDs (`G-12`, `DC-03`) when code exists because of a decision.
- **UI copy:** use the exact labels from the design (`Apply now`, `Retry`, `Search internships`…), in sentence case, with specific CTAs. Plain, supportive tone (DESIGN.md §14).
- **Accessibility:** touch targets ≥ 48 dp; a `tooltip` on every icon-only button; status and selection never by color alone (label + icon / check); body text ≥ 14 sp; layouts verified at **360 and 412 dp**.

## Riverpod / MVVM templates

```dart
// lib/services/saved_service.dart: interface + Firebase implementation + provider
abstract interface class SavedService {
  Stream<List<String>> watchSavedIds(String uid);
  Future<void> save(String uid, String internshipId);
}

final savedServiceProvider = Provider<SavedService>(
  (ref) => FirestoreSavedService(FirebaseFirestore.instance),
);
```

```dart
// lib/features/saved/viewmodels/saved_viewmodel.dart
final savedViewModelProvider =
    NotifierProvider.autoDispose<SavedViewModel, AsyncValue<void>>(
      SavedViewModel.new,
    );

class SavedViewModel extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> save(String internshipId) async {
    if (state.isLoading) return;
    final service = ref.read(savedServiceProvider);      // read before await
    final analytics = ref.read(analyticsServiceProvider);
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) return;

    state = const AsyncLoading();
    try {
      await service.save(uid, internshipId);
      await analytics.logEvent('internship_save', {'internship_id': internshipId});
      if (ref.mounted) state = const AsyncData(null);
    } on AppException catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
    }
  }
}
```

The View watches the provider, renders the state with shared components, and calls `ref.read(provider.notifier).method()` on user actions. Data screens use `ViewState<T>` instead of `AsyncValue<void>` (see `docs/architecture.md` §3).

## Testing rules

- Every ViewModel: tests with `ProviderContainer.test` and fakes from `test/helpers/fakes.dart` (success, empty, error, repeated tap where relevant).
- Every screen or shared widget: widget tests at both widths (`checkWidths`, `pumpThemed`) asserting visible text and states, plus `meetsGuideline(androidTapTargetGuideline)` for interactive widgets.
- Models / parsing: valid document, missing optional fields, invalid required fields.
- Rules: every change to `firebase/*.rules` extends `firebase/tests/` (allowed and denied case) and keeps `demo/server.mjs` in sync; the emulator suite must pass.
- No test may depend on a real Firebase project or network.
- E2E: ARTEMIS tests in `e2e_test/` follow `docs/test-plan.md` §6 (one instruction per test, JSON report, assertions on reported values, ≥ 3 runs).

## Documentation to update in the same PR

| When you… | Update |
|---|---|
| Deviate from the design, or finish / change a screen, route or component | `docs/design-traceability.md` (+ Figma) |
| Find or resolve a missing requirement | `docs/records/handoff-gaps.md` |
| Change a business rule, branch point, state transition or admin behaviour | `docs/business-rules.md` (keep the `BR-xx` ID and §5 traceability row) |
| Add an analytics event | `docs/analytics-plan.md` |
| Run Flutter tests for the PR | `docs/records/test-report.md` |
| Change `firebase/*.rules` | `firebase/tests/` (tests + demo) and a run row in `docs/records/test-report.md` |
| Run a UAT session | `docs/records/uat-results.md` and `evidence/uat/` |
| Use an AI tool, get a review, verify a Firebase feature, run E2E tests | See "Logs and evidence required by Lab 3" below |

## Logs and evidence required by Lab 3

Work that is not logged with evidence is graded as missing. **Never fabricate evidence, test results or history**: record "not run" instead (Lab 3 §11).

| When you… | You must log | Where |
|---|---|---|
| Use **any** AI tool (code generator, chat assistant, review tool, ARTEMIS) | Tool + purpose in the disclosure table (§8); for code changes also the exact prompt, output summary, verification and decision | `docs/code-review.md` (disclosure) + README "AI tools used"; `docs/records/implementation-ai-log.md` |
| Get an AI code review on a PR | Each finding: ID, tool, `file:line`, kind, decision (accepted / modified / rejected) + a valid reason; save the tool's raw output | `docs/code-review.md`; `evidence/code-review/` |
| Fix an accepted review finding | One commit per finding, naming its ID: `fix(CR-03): …`; link the commit in the record | Git history + `docs/code-review.md` |
| Deviate from Figma / Lab 2 | ID, change, reason (platform, accessibility, API limit, team decision); then update Figma | `docs/design-traceability.md` §4 |
| Build or change a screen, route or component | Its row: route, widget, data source, status | `docs/design-traceability.md` §1–3 |
| Make a Firebase service work (Auth, Storage, FCM, Analytics, Crashlytics, Remote Config) | Console / app screenshots showing it works **and** its failure case | `evidence/<area>/` (see `evidence/README.md`) |
| Add or fire an analytics event | Plan row (typed parameters + question) and a DebugView screenshot | `docs/analytics-plan.md`; `evidence/analytics/` |
| Run ARTEMIS tests | Command, ≥ 3 runs per test, pass rate, average time, trace IDs / replays, cause and fix of every flaky / failed / skipped test; the exploratory session report | `docs/test-plan.md` §4–5; `evidence/artemis/` (`e2e_test/artifacts/runs.jsonl`) |
| Run Flutter tests or builds for a PR | The real command output summary | `docs/records/test-report.md` + PR description |

Commits follow the Lab 3 stage order (Plan → Architect → Integrate → Instrument → Test → Review → Report) and show work over several days; do not squash the whole history into one upload.

## Git workflow

- `main` stays releasable. Work on a branch: `feat/<feature>-<topic>`, `fix/<topic>`, `docs/<topic>`, `chore/<topic>`.
- Conventional commit messages: `feat(saved): add unsave with undo`, `fix(auth): …`, `docs: …`, `test: …`, `chore: …`.
- One focused pull request per feature or fix; at least one reviewer; CI-equivalent commands pasted in the description.
- **AI review: at most 3 rounds per pull request.** This is a cap, not a quota. Stop as soon as no blocker or major finding remains; one round is often enough. If findings are still open after round 3, the agent stops and hands them to a human reviewer (see `docs/code-review.md`).
- **Review only what changed.** Round 1 reviews the PR diff (`git diff main...HEAD`), not whole files or the whole codebase. Later rounds review only the diff since the previous round (`git diff <last-reviewed-commit>..HEAD`) plus the open findings. Read surrounding code only when a changed line cannot be judged without it.
- **Rules are deployed only by the owner.** Anyone may change `firebase/*.rules`, but only in a PR that tags the owner. After merge, the owner publishes them (`firebase deploy --only firestore:rules,storage`, or paste into Firebase console → Rules → Publish). Never edit rules only in the console.
- Never rewrite shared history, commit generated build output, or commit secrets. Never fabricate commit history.

## Definition of done (feature)

- [ ] Matches Figma and `screen-spec.md` at 360 and 412 dp (verification checklist in `design-traceability.md` §5)
- [ ] `ViewState` loading / empty / error / data + validation states implemented
- [ ] ViewModel and widget tests added; `flutter analyze` clean; `flutter test` green
- [ ] Rules tests green if `firebase/*.rules` changed
- [ ] All Firestore data under `users/{uid}/…` (no rules change needed)
- [ ] Analytics events from the plan implemented and verified in DebugView
- [ ] Docs updated (table above); ARTEMIS test cases for the feature added to `e2e_test/`
