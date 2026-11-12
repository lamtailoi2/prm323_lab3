# Apply / Application — class and sequence diagrams

Companion to [`data-model-erd.md`](../data-model-erd.md). Rendered from the
source tree on 2026-11-10; every member listed exists in the file named beside
it. The Apply flow has changed since the earlier write-up, so this document
describes the **current** shape.

## The flow as it is now

```
Internship Detail
  └─ /{tab}/internships/:jobKey/apply        ApplyComposeScreen
       ├─ Continue → /apply/match            CvMatchScreen      (advisory, never blocks)
       │              └─ Continue → /apply/validation            (blocking quality gate)
       ├─ Continue → /apply/validation       CvValidationScreen
       └─ "I sent it" → /apply/success       ApplicationSuccessScreen (stateless)
```

Routes: `lib/app/router.dart:55-68`. Screen wiring: `router.dart:261-296`.

The earlier "Application Review" screen no longer exists as a separate step —
`ApplicationReviewViewModel` was replaced by the compose screen, where the
student edits the mail and records the send.

## Files

| Diagram | Source | PNG |
|---|---|---|
| Class diagram (models, services, ViewModels) | `diagrams/apply-domain-classes.mmd` | `apply-domain-classes.png` |
| Sequence: compose → match → validate → record | `diagrams/apply-submit-sequence.mmd` | `apply-submit-sequence.png` |
| Sequence: Application Detail, preview, withdraw, undo | `diagrams/application-detail-sequence.mmd` | `application-detail-sequence.png` |

Re-export any of them:

```bash
npx -y @mermaid-js/mermaid-cli -i docs/records/diagrams/<name>.mmd \
  -o docs/records/diagrams/<name>.png -b white -s 2
```

## 1. Class diagram — how to read it

Three groups, matching the MVVM layers, with arrows that only ever point
downward (`docs/architecture.md` §1).

**ViewModels** (`lib/features/*/viewmodels/`) own a state object and expose
commands. They never import widgets (`package:flutter/foundation.dart` only) and
never hold a `BuildContext`.

- `ApplyComposeViewModel` — the largest one. It loads the listing and the CV
  library, suggests a CV, generates the cover letter, validates the recipient,
  opens the mail app, and finally records the application. Public API:
  `retry`, `setRecipient`, `setSubject`, `setBody`, `selectLibraryCv`,
  `regenerate`, `openEmail`, `markSent`, `buildSession`
  (`apply_compose_viewmodel.dart:273-500`).
- `CvMatchViewModel` — `run(...)` → `ViewState<CvMatchResult>`
  (`cv_match_viewmodel.dart:23`).
- `CvValidationViewModel` — `validate(storagePath)` →
  `ViewState<CvValidationResult>` (`cv_validation_viewmodel.dart:21`).
- `ApplicationDetailViewModel` — `retry`, `withdraw`, `undoWithdrawal`,
  `previewCv` (`application_detail_viewmodel.dart:113-190`).
- `MyApplicationsViewModel` — `selectStatus`, `retry`; derives counts and the
  filtered list from one listener (`my_applications_viewmodel.dart:53`).

**Services** (`lib/services/`) are interfaces plus a Riverpod provider in the
same file. The diagram marks them `<<interface>>` deliberately: the ViewModel
only ever sees the interface, and tests swap in fakes.

| Service | Called by | Backed by |
|---|---|---|
| `ApplicationService` | Compose (write), Detail, My Applications | Firestore `users/{uid}/applications` |
| `CvMatchService` | CvMatchViewModel | callable `matchCv` |
| `CvValidationService` | CvValidationViewModel | callable `validateCv` |
| `CvSelectService` | ApplyComposeViewModel | callable `selectCv` |
| `CoverLetterService` | ApplyComposeViewModel | callable `composeCoverLetter` |
| `UserProfileService` | Compose, Profile | Firestore `users/{uid}` + `/cvs` |
| `InternshipService` | Compose, Detail | Firestore `internships` (read-only) |
| `FileStorageService` | Compose | Cloud Storage `cvs/{uid}` |
| `ExternalLinkService` | Compose (mailto), Detail (CV preview) | platform launcher |
| `AnalyticsService` | all of the above | Firebase Analytics |

**Models** (`lib/models/`, `lib/features/*/models/`) are immutable data holders
with `fromFirestore` / `fromSerpApi` factories. Two details are worth noticing
on the diagram:

- `InternshipApplication` **composes** `ApplicationApplicant` and points at two
  enums (`ApplicationStatus`, `ApplicationChannel`). The applicant is embedded,
  not a separate collection, because the application is a snapshot of what was
  sent.
- `UserProfile` composes `ProfileDetails`, `InternshipPreferences` and `CvFile`
  (the legacy mirror), and holds `defaultCvId` as a plain string pointing into
  `users/{uid}/cvs`.

Relationship types used: `-->` dependency (ViewModel uses Service),
`..>` weaker dependency (ViewModel reads a Model type),
`*--` composition (the state object owns that field, the model owns that part).

## 2. Sequence: composing and recording an application

`apply-submit-sequence.mmd`. Nine numbered phases, each mapped to a real call:

| Phase | Code |
|---|---|
| 1 prefill | `build()` subscribes `watchProfile` + `watchCvs`, logs `apply_start` |
| 2 CV suggestion | `selectLibraryCv` / `CvSelectService.select` → `CvSelection` |
| 3 compose draft | `CoverLetterService.compose` → `CoverLetterDraft{subject, body, usedAi}` |
| 4 branch | `buildSession()` returns `ApplySession` or `null` when there is no CV |
| 5 match | `matchCv` callable; `cv_match_check` event |
| 6 validate | `validateCv` callable — ownership check, PDF text, ≥ 50 chars, Gemini |
| 7 send | `openEmail()` builds a `mailto:` URI and launches the device mail app |
| 8 record | `markSent()` → `createApplication(..., appliedVia: ApplicationChannel.email)` |
| 9 success | `pushReplacement` with the recap in `extra`; the screen is stateless |

Two design points the diagram makes visible:

- **The app never sends the email itself.** Phase 7 hands off to the device's
  mail client; phase 8 records what the student did. That is why
  `ApplicationChannel` exists (`in_app` vs `email`, `internship_application.dart:41-56`).
- **A Profile sync failure is not a submission failure.** After the Firestore
  write succeeds, `updateApplyDetails` / `updateSkills` run inside a
  `try/catch` that only records to Crashlytics
  (`application_review_viewmodel.dart` predecessor → now
  `apply_compose_viewmodel.dart:markSent`).

Error paths shown: validation error on the recipient, guard failures
(no listing, no name, double tap), and `AppException` from Firestore.

## 3. Sequence: Application Detail, withdraw and undo

`application-detail-sequence.mmd`. Four phases:

1. **Load** — one listener on `watchApplications()` plus one on
   `watchByKey(jobKey)`; the ViewModel picks the document whose `jobKey` matches
   the route and logs `view_application` once per screen
   (`application_detail_viewmodel.dart:213-285`).
2. **Preview** — `previewCv()` opens the snapshotted `cvUrl`; it never reads the
   current Profile CV, because the application is a record of the past.
3. **Withdraw** — `withdraw()` writes `status: withdrawn`,
   `withdrawnAt: serverTimestamp`, `previousStatus: <old>`. The service reads the
   old status itself so the client cannot claim one it did not have.
4. **Undo** — `undoWithdrawal()` restores `previousStatus` and deletes
   `withdrawnAt`; the ViewModel only offers it while
   `withdrawnAt + 24h > nowProvider()`.

The listener means the UI never assumes the result of its own write: the badge
changes when the new snapshot arrives, not when the `await` returns.

## 4. Where these diagrams disagree with older docs

`docs/records/apply-flow-mvvm-architecture.md` and
`docs/records/data-model-erd.md` were written before this refactor. Superseded
facts:

| Older doc says | Current code |
|---|---|
| `ApplyFormViewModel` | `ApplyComposeViewModel` |
| `ApplicationReviewViewModel` + `ApplicationReviewScreen` | removed; Compose records the send |
| `applyForm → validation → review → success` | `apply → (match) → validation → success` |
| `ApplicationApplicant.email` only | plus `appliedVia` and `recipientEmail` on the document |
| CV Match was advisory and separate | Match now sits *before* Validate as an optional step |

The ERD has been updated for `appliedVia` / `recipientEmail`; the MVVM write-up
still needs the same pass.
