# Internly — data model analysis and ERD

Derived from the current source tree on 2026-11-10: every field below was read
from a `fromFirestore` / `toFirestore` factory, a service write, a security
rule, or the sync function — not from a design document. Files are named per
entity.

- Diagram source: [`diagrams/internly-erd.mmd`](diagrams/internly-erd.mmd)
- Rendered: `diagrams/internly-erd.png`
- Re-export: `npx -y @mermaid-js/mermaid-cli -i docs/records/diagrams/internly-erd.mmd -o docs/records/diagrams/internly-erd.png -b white -s 2`

## 1. What kind of model this is

The app has **two very different data shapes**, and the ERD keeps them apart:

| Store | Shape | Written by |
|---|---|---|
| Cloud Firestore | Document store: collections, subcollections, no joins, no foreign keys | Cloud Functions (Admin SDK) + the signed-in client |
| Cloud Storage for Firebase | Object store: one flat key space `cvs/{uid}/…`, `reports/{uid}/…` | The signed-in client, constrained by `storage.rules` |

So this is **not** a relational schema. Three differences matter for reading
the diagram:

1. **A "foreign key" here is a string the code interprets.** `PROFILE.defaultCvId`
   holds a `users/{uid}/cvs` document id; `APPLICATION.jobKey` equals an
   `internships` document id. Firestore does not enforce either, and nothing
   cascades — the service does the work (`user_profile_service.dart:197-230`,
   `saved_internship_service.dart:88-112`).
2. **Path is the identity.** `users/{uid}/applications/{jobKey}` — the document
   ID *is* the listing key, so "one application per listing per student" is
   enforced by the ID, not by a constraint or index (`application_service.dart:169-176`).
3. **Duplication is deliberate** (see §4). Several entities copy fields from
   another entity on purpose.

The same UID appears on Google's side too: `AppUser` (`lib/models/app_user.dart`)
comes from Firebase Auth and is never written to Firestore — email and photo are
read from the auth session. That is why `USER` in the ERD has no document.

## 2. Entities

### USER — Firebase Auth, not a document

`lib/models/app_user.dart`. `uid` is the primary key for everything else;
`email`, `displayName` and `photoUrl` come from the Google account.
`firebase/firestore.rules:20-21` makes `request.auth.uid` the only thing a
request may write to.

### PROFILE — `users/{uid}`

`lib/models/user_profile.dart:15-88`, written by `user_profile_service.dart`
merge-per-section (`updateDetails`, `updateSkills`, `updatePreferences`,
`updateCv`, `addCv`). Every field is optional: the document does not exist until
the first save.

Notable fields:

- `details.*` — `fullName`, `headline`, `university`, `major`, `yearOfStudy`,
  `graduationYear`, `phone`, `city`, `bio` (≤ 300).
- `skills` — values from `knownSkills`, used by Search matching and the
  Internship Detail Skill match (G-23, G-24).
- `preferences` — `targetRoles`, `experience`, `workModes`, `location`.
- `cv` — **legacy mirror** of the default CV (`user_profile.dart:43-47`),
  kept so builds that only knew this field still work.
- `defaultCvId` — FK to `users/{uid}/cvs`; `null` means "the legacy mirror is
  the default" (`user_profile.dart:52-54`).
- `givenName` — Google's given name for the Home greeting.
- `fcmToken`, `fcmTokenUpdatedAt` — written by `notification_service.dart:146-149`,
  the only place the push token lives.

### CV_LIBRARY — `users/{uid}/cvs/{id}`

`CvFile` (`user_profile.dart:318-402`), `user_profile_service.dart:101-194`.
Fields `fileName`, `url` (real download URL), `storagePath`, `sizeBytes`
(optional, 0 when absent), `uploadedAt`, `label` (optional display name).
Only ever built from an `UploadedFile` returned by `FileStorageService`, so a
fake URL cannot enter the library (AGENTS.md rule 7).

### CV_MIRROR — `users/{uid}.cv` (a map, not a document)

Same fields minus `id`. Drawn separately because it is a **denormalised copy**
with its own lifetime: the first `addCv` migrates it into the library
(`user_profile_service.dart:146-168`), and `setDefaultCv(legacyCvId)` can point
back at it.

### SAVED_INTERNSHIP — `users/{uid}/savedInternships/{key}`

`lib/services/saved_internship_service.dart:88-112`. Two fields only:
`internship` (a **full copy** of the `/internships/{key}` document) and
`savedAt`. The copy is written by reading the live listing first; if it is gone
the write fails with `notFound` instead of saving a stub.

### APPLICATION — `users/{uid}/applications/{jobKey}`

`lib/models/internship_application.dart:47-132`, written by
`application_service.dart:96-140` (`createApplication`), `withdraw` (line 151),
`undoWithdrawal` (line 161).

- Required: `title`, `companyName`, `appliedAt`, `status`.
- `status` ∈ `submitted`, `under_review`, `interview`, `accepted`, `rejected`,
  `withdrawn` (`ApplicationStatus`, line 9-37). Anything else makes the document
  malformed and the service skips and logs it.
- `nextStepAt` — optional interview slot or reply deadline.
- `withdrawnAt`, `previousStatus` — written only by `withdraw` / `undoWithdrawal`
  so Undo can restore the exact earlier status, not a guessed `submitted`.
- `cvFileName`, `cvUrl`, `cvStoragePath`, `cvSizeBytes` — snapshot of the CV
  that was actually sent.
- `applicant` — embedded map `ApplicationApplicant` (line 139-184):
  `fullName` (required), `email`, `phone`, `university`, `yearOfStudy`,
  `skills`, `shortIntroduction`.

### NOTIFICATION — `users/{uid}/notifications/{id}`

`lib/models/app_notification.dart:13-67`. `title`, `body` (optional — a
title-only push is valid), `receivedAt`, `route` (optional deep link),
`read` (default false). Written by the FCM foreground / background / opened-app
handlers so the history is the same in every app state (G-13).

### SEARCH_HISTORY — `users/{uid}/searchHistory/{id}`

`lib/features/internships/models/search_history_entry.dart:8-40`,
`search_history_service.dart:57-68`. `term`, `searchedAt`. Auto-id, but
`record()` first deletes any document with the same term (case-sensitive
`where('term', isEqualTo:)`) so a repeat search moves to the top instead of
duplicating.

### REPORT — `users/{uid}/reports/{fileNameWithoutExtension}`

`lib/models/exported_report.dart:14-63`, written by
`report_export_service.dart` (`export`) after the PDF upload succeeds
(G-05). Required: `fileName`, `url`, `storagePath`, `createdAt`.
`sizeBytes` and `itemCount` default to 0 on documents without them. The file
itself is the Storage object `reports/{uid}/{fileName}` (below); `url` is the
download URL Cloud Storage returned, never a placeholder. The document id is
`application-report-YYYY-MM-DD`, so one report per day: exporting again the
same day replaces it instead of adding a duplicate row.

### INTERNSHIP — `internships/{key}`

`lib/models/internship.dart:43-167`, written **only** by the scheduled
function (`functions/src/sync.ts:64-73`). The document stores the raw SerpAPI
job object, not the parsed model:

| Field | Meaning |
|---|---|
| `raw` | the SerpAPI `jobs_results` entry, unchanged |
| `searchKeyword` | the query that found it |
| `searchRank` | position in that response (0 = most relevant) |
| `syncedAt` | server timestamp of the last write |
| `expiresAt` | `syncedAt + 7 days`; the app filters on it, the function deletes past it |

Everything the UI shows (title, company, salary, work mode, skills, posted age,
apply link) is derived at read time by `Internship.fromFirestore` →
`Internship.fromSerpApi`. `key` is the FNV-1a hash of `job_id`
(`core/utils/job_key.dart`) because the raw ID is long and may contain `/`.

### SYNC_CONFIG / SYNC_STATE — `sync/{config,state}`

`functions/src/sync.ts:36, 95-118`. Function bookkeeping only; clients are
denied (`firestore.rules:44-46`). `config.lastKeywordIndex` is the round-robin
cursor over the five keywords; `state` records the last run's counts and
`lastError` (the app reads the effect, never these documents).

### STORAGE_CV / STORAGE_REPORT — Cloud Storage objects

`firebase/storage.rules:27-35`. `cvs/{uid}/{fileName}` and
`reports/{uid}/{fileName}`, PDF only, 1 byte – 10 MB, owner-only. Metadata lives
in Firestore (`CV_LIBRARY`, the CV snapshot on `APPLICATION`, and `REPORT`),
never here.

## 3. Why each relationship exists

| Relationship | Cardinality | Code | Why it is shaped this way |
|---|---|---|---|
| USER → PROFILE | 1 : 0..1 | `users/{uid}`, optional document | Created on first save, so a new student has no profile at all (`user_profile.dart:15-16`) |
| USER → CV_LIBRARY | 1 : N | `user_profile.dart:52`, `user_profile_service.dart:101` | A student keeps several CVs and picks one per application |
| PROFILE → CV_LIBRARY | N : 0..1 (`defaultCvId`) | `user_profile_service.dart:197-230` | The default CV is a pointer, not a copy, so replacing it does not rewrite the profile; `null` falls back to the legacy mirror |
| USER → APPLICATION | 1 : N | `application_service.dart:85-88` | Self-tracked applications (G-25 #6 — there is no employer side) |
| USER → SAVED_INTERNSHIP | 1 : N | `saved_internship_service.dart:46-48` | Save is a step toward applying (Flow 2e) |
| USER → NOTIFICATION | 1 : N | `notification_service.dart:205-208` | Client-written history so the center works without a backend |
| USER → REPORT | 1 : N | `report_export_service.dart` (`export`) | One metadata document per exported PDF, so earlier reports can be reopened (G-05) |
| USER → SEARCH_HISTORY | 1 : N | `search_history_service.dart:34` | Recent searches, capped at 10 |
| INTERNSHIP → APPLICATION | 1 : N (per student) | `application_service.dart:169` | `jobKey` is both the FK and the document id; listings expire, so `title` and `companyName` are copied |
| INTERNSHIP → SAVED_INTERNSHIP | 1 : N (per student) | `saved_internship_service.dart:95-110` | Same expiry problem: the saved item is a full copy |
| CV_LIBRARY → APPLICATION | 1 : N | `application_service.dart:106-109` | The CV sent is snapshotted (`cvStoragePath`, `cvUrl`, `cvSizeBytes`) so a later Profile change never rewrites history |
| STORAGE_CV → APPLICATION | 1 : N | `storage.rules:32-35` | The file can be deleted from Storage, but the application keeps the URL it was submitted with |
| SYNC_* → INTERNSHIP | bookkeeping | `sync.ts:36-118` | One function owns the pool; clients only read |

Everything under `users/` is reachable **only** by its owner
(`firestore.rules:29-37`), so none of these arrows can cross students.
`/internships` is read-only to clients (`firestore.rules:39-42`).

## 4. Deliberate duplication (and why it is not a mistake)

The diagram shows the same facts in more than one place. That is a considered
decision documented in `docs/architecture.md` §6 rule 1, and it exists because
**listings expire**:

| Copied into | From | Reason |
|---|---|---|
| `SAVED_INTERNSHIP.internship` | `INTERNSHIP` (whole document) | Saved items must still render after the 7-day expiry, when the listing is deleted |
| `APPLICATION.title`, `.companyName` | `INTERNSHIP` | My Applications and Application Detail must show the job after expiry |
| `APPLICATION.cv*` | `CV_LIBRARY` + Storage | The application is a record of what was sent; the profile can change later |
| `APPLICATION.applicant` | `PROFILE.details`/`skills` | Same reason — and the student edits the profile on the next application |
| `CV_LIBRARY` (from `PROFILE.cv`) | legacy mirror | Migration path for builds that predate the library |

Consequence for maintenance: a change to the listing or profile shape does not
retroactively update existing applications. That is intended (a submitted
application should not mutate), but it means `InternshipApplication.fromFirestore`
must keep parsing the snapshot shapes it has ever written.

## 5. What is deliberately absent

- **No employer/organisation entity.** SerpAPI gives a company *name* string,
  not an entity (G-25 #7). Anything employer-side would be invented data.
- **No join table for "saved" or "applied".** Both are already user-scoped
  subcollections keyed by the listing key.
- **No report metadata collection yet.** `reports/{uid}/…` is allowed by the
  storage rules and `FileStorageService` targets it, but no feature writes a
  report document today (G-05, planned).
- **No shared counters or aggregates.** Every count shown in the UI is derived
  from the documents the listener already received (`architecture.md` §6).
