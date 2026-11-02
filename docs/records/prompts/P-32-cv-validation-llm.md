# P-32: CV validation via LLM

Verbatim task prompt given to Command Code on 2026-11-01 (branch `feat/LLM-validation`).

---

# CV Validation via LLM (Flow 4 pre-submit step)

## Context

Flow 4 (Application) requires a "Validate CV" step between completing the application form and confirming submission: `Pre-submit Complete → Validate CV (LLM) → Confirm Application → Redirect to Employer Website → …`, with an explicit failure branch `CV Invalid → Update CV → Retry`. This is distinct from the already-open **G-24 CV Match Check** (matches CV/profile against *this internship's* requirements, never blocks). Lập is setting up the LLM side of CV validation: a **generic CV quality gate** — is this file actually a usable CV? — that *can* block submission, unlike CV Match Check.

AGENTS.md rule 8 and G-24 open item #3 require any LLM call to run behind a backend, never with an API key in the app. G-26 already settled the project's zero-cost LLM choice: the **Gemini API free tier** (used today for ARTEMIS, `GEMINI_API_KEY` from Google AI Studio, no billing enabled). This plan reuses that same model/provider decision rather than introducing a second one, and follows the existing `functions/src/sync.ts` pattern (`defineSecret` + Secret Manager) for key handling.

Decisions already made with Lập:
- CV text source: extract text from the uploaded PDF server-side (not just declared profile fields).
- Validation scope: generic CV quality/sanity check (readable, non-empty, actually looks like a CV) — not job-matching.
- Blocking behavior: this generic check **can** block submission (`CV Invalid → Update CV → Retry`); job-matching gaps (G-24) stay advisory and out of scope here.

Nothing for Apply/CV Match Check screens exists in `lib/` yet, and `functions/src` only has the SerpAPI sync — this is a new vertical slice, not a modification of existing Apply code.

## Architecture

```
ApplicationViewModel (new)
  → CvValidationService (lib/services/cv_validation_service.dart)
      → callable Cloud Function `validateCv`
          → downloads cvs/{uid}/{fileName} from Storage (admin SDK, server-side only)
          → extracts text (pdf-parse)
          → calls Gemini (GEMINI_API_KEY secret) with a fixed rubric prompt
          → returns { isValid: bool, reason?: string }
```

The function takes a **Storage path**, not raw bytes — the CV is already uploaded to `cvs/{uid}/…` earlier in Apply (Flow 2a), so the client just passes the path/UID and the function reads it with the Admin SDK (bypasses Storage rules safely, since it only ever reads the caller's own uid, verified from the callable's auth context — never a client-supplied uid).

## Backend: `functions/src/validate-cv.ts` + wiring in `index.ts`

- New `onCall` function `validateCv({ storagePath })`:
  - Reject if `request.auth` is missing, or if `storagePath` doesn't start with `cvs/${request.auth.uid}/` (prevents reading another user's CV).
  - Download the object via `getStorage().bucket().file(storagePath)`.
  - Extract text with `pdf-parse` (new dependency in `functions/package.json`).
  - If extracted text is empty/too short (e.g. < ~50 chars after trim) → short-circuit `{ isValid: false, reason: 'CV appears to be empty or unreadable.' }` without calling Gemini (saves quota, handles corrupt/scanned-image PDFs the same way ARTEMIS-style free-tier limits should be respected).
  - Otherwise call Gemini (`@google/generative-ai`, free-tier model e.g. `gemini-flash-lite` per G-26's fallback note) with a small fixed rubric prompt: confirm the text looks like a real CV/resume (has some identifiable structure — contact info, experience/education/skills) vs. garbage/unrelated text; ask for strict JSON `{ "isValid": boolean, "reason": string }` back.
  - Parse the JSON defensively (model output isn't guaranteed valid JSON); on parse failure, fail *open* — treat as valid rather than blocking a real application on an LLM formatting glitch — and log it.
  - Wrap all errors (download failure, Gemini error) in a thrown `HttpsError`; never leak internal error text as the `reason` shown to the user.
- `GEMINI_API_KEY` as a new `defineSecret`, following `serpApiKey` in `functions/src/index.ts`. Set via `firebase functions:secrets:set GEMINI_API_KEY` — same key source as ARTEMIS's free-tier key, but a **separate secret binding** scoped only to this function (least privilege, rule 8/9 spirit).
- Add `pdf-parse` and `@google/generative-ai` to `functions/package.json` dependencies.
- Unit tests (`functions/src/validate-cv.test.ts`, mirroring `serp.test.ts`/`selection.test.ts` style): path-ownership rejection, empty-text short-circuit, JSON-parse-failure fail-open, a happy path with a stubbed Gemini client (no real network call — "No test may depend on a real Firebase project or network" applies to functions tests too in spirit).

## App: service + ViewModel + screen wiring

- `lib/services/cv_validation_service.dart` (interface + Firebase Functions implementation + provider, same shape as other services):
  ```dart
  abstract interface class CvValidationService {
    Future<CvValidationResult> validate(String storagePath);
  }
  ```
  Calls `FirebaseFunctions.instance.httpsCallable('validateCv')`. Catches `FirebaseFunctionsException` and SDK errors, rethrows as `AppException(kind, userMessage, cause: e)` per AGENTS.md's error convention.
- `CvValidationResult` model (`lib/models/` if reused by 2+ features, else `features/applications/models/`): `{ isValid, reason }`, `@immutable`, `fromJson`-style factory off the callable's result map.
- Slot this into the existing Apply flow design (`user-flow.md` Flow 2 / Flow 4): insert the validate call between "CV ready" and "Confirm Application," owned by the Application/Apply ViewModel (not yet built — this plan only adds the validation piece; building the full Application Form/Review screens is a separate, larger task already tracked by G-24's open items). Expose it as its own `ViewState`-driven step so it can show:
  - loading ("Checking your CV…"),
  - error/invalid → the existing failure branch: message + `Update CV` (reopens the existing `update_cv_sheet.dart` / replace-CV flow already used in Profile) + `Retry`,
  - valid → proceeds automatically to Confirm Application.
- Follow the async ViewModel rules: read `cvValidationServiceProvider` before the `await`, check `ref.mounted` after, ignore repeated taps while loading.

## Analytics & docs (per AGENTS.md "Documentation to update in the same PR")

- Add an analytics event (e.g. `cv_validation_result` with `{ is_valid: bool }`) to `docs/analytics-plan.md`, fired from the ViewModel after the callable resolves; verify in DebugView and screenshot to `evidence/analytics/`.
- Record the new Cloud Function + Gemini secret in `docs/architecture.md` and note the model/provider choice already made in G-26 is being reused (cross-reference, don't re-decide).
- Resolve the relevant part of **G-24 item #3** ("LLM-generated suggestions… must run behind a backend") — note that generic validation now does this; job-matching suggestions remain open/future work. Update `docs/records/handoff-gaps.md`.
- `evidence/<area>/` screenshots: a passing validation and a failing one (e.g. upload a text-only garbage PDF) showing the blocked state + retry.

## Verification

- `functions`: `npm run build` (tsc) and `npm test` (the new `validate-cv.test.ts` plus existing suite) must pass; no real network/Firebase calls in tests.
- App: `dart format lib test`, `flutter analyze` ("No issues found!"), `flutter test` (new `cv_validation_service` fakes in `test/helpers/fakes.dart`, ViewModel tests for loading/valid/invalid/repeated-tap, per AGENTS.md testing rules).
- Manual: deploy function to a dev/test Firebase project, upload a real CV PDF and a garbage PDF through the app, confirm DebugView shows the analytics event and the UI shows the correct branch for each; paste real command output into `docs/records/test-report.md`.
 bắt đầu làm task này
