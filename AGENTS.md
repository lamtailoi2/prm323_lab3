# AGENTS.md: Internly coding conventions and rules

Instructions for everyone who changes this repository, human or AI agent. Read this file before writing code. If a rule blocks you, raise it in the pull request instead of working around it.

## Project in brief

- **Internly**: Flutter app (Android + iOS) for IT students to find, save, apply to and track internships. Product overview: [`README.md`](README.md).
- **Architecture:** MVVM + Riverpod 3 + go_router + Firebase. Details: [`docs/architecture.md`](docs/architecture.md).
- **UI source of truth:** the Lab 2 design in [`docs/lab2-handoff/`](docs/lab2-handoff/README.md) and Figma, consolidated in [`docs/lab2-handoff/design/design-system.md`](docs/lab2-handoff/design/design-system.md).
- **Open decisions:** [`docs/handoff-gaps.md`](docs/handoff-gaps.md). Read the relevant gap before building a feature.

## Commands

```bash
flutter pub get                 # install dependencies
dart format lib test            # format (CI expects formatted code)
flutter analyze                 # must print "No issues found!"
flutter test                    # all tests must pass
flutter run -d <device>         # run (needs Firebase config, see docs/firebase-setup.md)
```

Run `dart format`, `flutter analyze` and `flutter test` before every commit you ask someone to review. Paste the real results in the PR; never claim a result you did not see.

## Golden rules

1. **Do not invent UI.** Screens, copy, colors, typography, spacing, radii, icons and flows come from Lab 2 / Figma. If something is missing, add it to `docs/handoff-gaps.md`. If you must deviate, log it in `docs/design-change-log.md` **in the same PR**.
2. **MVVM layering is strict.** View → ViewModel → Service → Firebase. Views never import Firebase or call services. ViewModels never hold a `BuildContext`.
3. **Riverpod only** for state and dependency injection. No `provider`, Bloc, GetX, `setState` for business state, or singletons accessed from widgets.
4. **Tokens only.** No `Color(0x…)`, raw font sizes, raw `EdgeInsets` numbers or new radius values in feature code. Use `AppColors`, `Theme.of(context).textTheme`, `AppSpacing`, `AppRadii`, `AppSizes`, `AppElevation`.
5. **Reuse shared components** from `lib/core/widgets/` before creating new ones. A new shared component must match a Figma component and be added to `design-system.md`.
6. **Every data screen has loading, empty and error states** (skeleton or labeled spinner, `StateView.empty`, `StateView.error` with `Retry`).
7. **Never fake success.** No placeholder URLs saved as real results, no hard-coded "uploaded" states, no fake Firebase config, no tests that only tap without asserting a visible result.
8. **No secrets in the client or the repository:** service-account keys, Cloudinary API secret, AWS keys, `.p8`, keystores, passwords. Firebase app config files are allowed (see `docs/firebase-setup.md` §11).
9. **Security rules ship with the data.** A new Firestore collection needs field-validated rules in `firebase/firestore.rules` and emulator tests in the same PR. `allow write: if isOwner(uid)` alone is not acceptable.
10. **Stay in scope.** Implement what the spec and the task ask for. No speculative features, abstractions or dependencies.

## Where code goes

| You are adding… | Put it in | Notes |
|---|---|---|
| A screen | `lib/features/<feature>/screens/<name>_screen.dart` | One screen per file, `XxxScreen` |
| Screen state / logic | `lib/features/<feature>/viewmodels/<name>_viewmodel.dart` | `XxxViewModel` + `xxxViewModelProvider` |
| A widget used by one feature | `lib/features/<feature>/widgets/` | |
| A widget used by 2+ features | `lib/core/widgets/` | Must map to a Figma component |
| A model used by 2+ features | `lib/models/` | Otherwise `features/<feature>/models/` |
| Firebase / HTTP access | `lib/services/<name>_service.dart` | Interface + implementation + provider in one file |
| A pure helper | `lib/core/utils/` | Unit-tested |
| A route | `lib/app/router.dart` | Under the owning tab branch, always with a `name` |
| A design token | `lib/theme/` | Only from DESIGN.md / Figma, and update `design-system.md` |

## Dart and Flutter conventions

- **Style:** Effective Dart, enforced by `analysis_options.yaml` (strict casts/inference/raw types, single quotes, `prefer_final_locals`, `unawaited_futures`, ordered imports). Format with `dart format` (default 80 columns).
- **Naming:** files `snake_case.dart`; classes `UpperCamelCase`; providers `lowerCamelCaseProvider`; enum storage values `snake_case` strings.
- **Imports:** relative imports inside `lib/`; `package:internly/...` in `test/`. Order: `dart:`, `package:`, then relative (the analyzer enforces this).
- **Widgets:** prefer `StatelessWidget` / `ConsumerWidget`; small and composable; `const` constructors wherever possible; no business logic in `build`.
- **Models:** `@immutable`, `final` fields, `const` constructors. Firestore parsing goes through `FirestoreReader` in `factory X.fromFirestore(String id, Map<String, Object?>? data)`; writes go through `toFirestore()` / `toCreateMap()`. Required fields throw `FormatException`; services skip and log malformed documents. Don't override `==` by ID only, because Riverpod uses `==` to decide whether to notify.
- **Errors:** services catch SDK exceptions and throw `AppException(kind, userMessage, cause: e)`. `message` is plain language and safe to show; `cause` is for logging only. `AppErrorKind.cancelled` is not an error state.
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

The View watches the provider, renders `AsyncValue` states with shared components, and calls `ref.read(provider.notifier).method()` on user actions.

## Testing rules

- Every ViewModel: tests with `ProviderContainer.test` and fakes from `test/helpers/fakes.dart` (success, empty, error, repeated tap where relevant).
- Every screen or shared widget: widget tests at both widths (`checkWidths`, `pumpThemed`) asserting visible text and states, plus `meetsGuideline(androidTapTargetGuideline)` for interactive widgets.
- Models / parsing: valid document, missing optional fields, invalid required fields.
- No test may depend on a real Firebase project or network.
- E2E (MobAI) specs in `mobai_tests/` must assert a visible outcome.

## Documentation to update in the same PR

| When you… | Update |
|---|---|
| Deviate from the design | `docs/design-change-log.md` |
| Find or resolve a missing requirement | `docs/handoff-gaps.md` |
| Add an analytics event | `docs/analytics-plan.md` |
| Finish a screen | `docs/fidelity-check.md` |
| Run tests for the PR | `docs/test-report.md` |
| Use an AI tool for the change | `docs/implementation-ai-log.md` (exact prompt, output summary, verification, decision) |
| Get an AI code review | `docs/code-review.md` |

## Git workflow

- `main` stays releasable. Work on a branch: `feat/<feature>-<topic>`, `fix/<topic>`, `docs/<topic>`, `chore/<topic>`.
- Conventional commit messages: `feat(saved): add unsave with undo`, `fix(auth): …`, `docs: …`, `test: …`, `chore: …`.
- One focused pull request per feature or fix; at least one reviewer; CI-equivalent commands pasted in the description.
- **AI review: at most 3 rounds per pull request.** This is a cap, not a quota. Stop as soon as no blocker or major finding remains; one round is often enough. If findings are still open after round 3, the agent stops and hands them to a human reviewer (see `docs/code-review.md`).
- **Review only what changed.** Round 1 reviews the PR diff (`git diff main...HEAD`), not whole files or the whole codebase. Later rounds review only the diff since the previous round (`git diff <last-reviewed-commit>..HEAD`) plus the open findings. Read surrounding code only when a changed line cannot be judged without it.
- Never rewrite shared history, commit generated build output, or commit secrets. Never fabricate commit history.

## Definition of done (feature)

- [ ] Matches Figma and `screen-spec.md` at 360 and 412 dp (fidelity check filled in)
- [ ] Loading / empty / error / validation states implemented
- [ ] ViewModel and widget tests added; `flutter analyze` clean; `flutter test` green
- [ ] Firestore rules + emulator tests for any new collection
- [ ] Analytics events from the plan implemented and verified in DebugView
- [ ] Docs updated (table above); MobAI scenario spec updated
