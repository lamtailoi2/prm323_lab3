# State diagrams and business flows

Diagrams that complement [`business-rules.md`](business-rules.md) §2.4 (the
application state machine) and [`business-process-swimlane.md`](business-process-swimlane.md)
(the student and admin swimlanes). They are **derived from the code**: read them
with the `BR-xx` rule and the file in the last column, because if a diagram and
the code disagree, the code wins.

Scope:

- every state machine the app actually has, including the ones that had no
  diagram yet (session, generic `ViewState`, CV library, saved, report export,
  notification, sync job, listing lifetime);
- three business flows: the end-to-end student journey, the report export, and
  the admin back office.

## 1. Legend

| Symbol | Meaning |
|---|---|
| `[*]` | Start (`-->` from `[*]`) or end (`--> [*]`) |
| Diamond | Branch point; the label carries its `BR-xx` rule ID |
| `E<n>` | Exception branch from [`business-rules.md`](business-rules.md) §4 |
| `TC-xx` | Test case in [`test-plan.md`](test-plan.md) §3 |
| Dotted edge | Call into Firebase, a callable function or an external system |
| `ViewState` names | Class names from `lib/core/state/view_state.dart` |

## 2. State diagrams

| Diagram | Source | Shows | Code | Rules |
|---|---|---|---|---|
| Session and routing | [`diagrams/state-session.mmd`](diagrams/state-session.mmd) · [PNG](diagrams/state-session.png) | Splash → Login or app shell, cancelled sign-in, sign-out | `lib/app/router.dart` (`authRedirect`), `lib/services/auth_service.dart` | BR-A1 … BR-A3 |
| Generic data screen | [`diagrams/state-view-state.mmd`](diagrams/state-view-state.mmd) · [PNG](diagrams/state-view-state.png) | `ViewLoading` ↔ `ViewData` / `ViewEmpty` / `ViewError` and Retry | `lib/core/state/view_state.dart`, `lib/core/widgets/state_view.dart` | BR-D6, BR-A5 |
| CV library and default CV | [`diagrams/state-cv-library.mmd`](diagrams/state-cv-library.mmd) · [PNG](diagrams/state-cv-library.png) | Empty / legacy mirror / 1 CV / 2+ CVs, add, set default, remove, file retention | `cv_library_viewmodel.dart`, `lib/core/utils/cv_library.dart`, `user_profile_service.dart`, `application_service.cvStoragePaths()` | BR-C1 … BR-C6 |
| Application | [`diagrams/state-application.mmd`](diagrams/state-application.mmd) · [PNG](diagrams/state-application.png) | Six statuses, student-reported `Update status`, withdraw, 24 h Undo | `lib/models/internship_application.dart`, `application_service.dart`, `application_detail_viewmodel.dart` | BR-P8, BR-T1 … BR-T8 |
| Saved internship | [`diagrams/state-saved.mmd`](diagrams/state-saved.mmd) · [PNG](diagrams/state-saved.png) | Save, idempotent re-save, unsave + Undo, failed write | `saved_internship_service.dart`, `lib/features/saved/` | BR-S1 … BR-S4 |
| Report export | [`diagrams/state-report-export.mmd`](diagrams/state-report-export.mmd) · [PNG](diagrams/state-report-export.png) | Load → ready / empty / error → exporting → uploaded → saved, same-day replace | `report_export_viewmodel.dart`, `lib/services/report_export_service.dart` | G-05, analytics row 14 |
| Notification | [`diagrams/state-notification.mmd`](diagrams/state-notification.mmd) · [PNG](diagrams/state-notification.png) | Permission, received, unread / read, deep link, test-crash command, badge | `notification_service.dart`, `notification_center_viewmodel.dart`, `unread_notifications_provider.dart` | BR-N3, BR-N6 … BR-N13 |
| Sync job | [`diagrams/state-sync-job.mmd`](diagrams/state-sync-job.mmd) · [PNG](diagrams/state-sync-job.png) | Cron → backfill / round-robin → fetch → upsert → expire, failure keeps the last pool | `functions/src/sync.ts`, `functions/src/selection.ts` | BR-D1, BR-A4 |
| Listing lifetime | [`diagrams/state-listing.mmd`](diagrams/state-listing.mmd) · [PNG](diagrams/state-listing.png) | Active, re-sync merge, expiry, deletion; snapshots survive | `functions/src/sync.ts`, `internship_service.dart` | BR-D1, BR-D5, G-25 |

## 3. Business flows

| Flow | Source | Shows | Rules |
|---|---|---|---|
| End-to-end student journey | [`diagrams/business-flow-overview.mmd`](diagrams/business-flow-overview.mmd) · [PNG](diagrams/business-flow-overview.png) | Sign-in → Profile/CV → discover → save → apply → track → report, with the app and Firebase writes for each step | BR-A, BR-C, BR-D, BR-P, BR-S, BR-T |
| Report export | [`diagrams/business-flow-report-export.mmd`](diagrams/business-flow-report-export.mmd) · [PNG](diagrams/business-flow-report-export.png) | `/profile/export` → PDF → Storage → metadata → open, including empty, error and same-day re-export | G-05, analytics row 14 |
| Admin back office | [`diagrams/business-flow-admin.mmd`](diagrams/business-flow-admin.mmd) · [PNG](diagrams/business-flow-admin.png) | Sign-in + allowlist → recipients → validation → FCM → history → device, including 400/409 and the data-only crash command | BR-N1 … BR-N11 |

## 4. What these add to the existing documents

- `business-rules.md` §2.4 already draws the application state machine; the
  version here adds the two correction transitions students can make with
  `Update status` and the exact writes (`statusUpdatedAt`, `previousStatus`,
  `withdrawnAt`).
- `business-process-swimlane.md` draws the student and admin swimlanes but stops
  before report export and notification history. The overview and the two
  detailed flows here cover those, plus the report export path end to end.
- The remaining state machines (session, `ViewState`, CV library, saved,
  notification, sync, listing) had no diagram; they are the states the
  ViewModels and services actually expose, not a proposed design.
- No diagram invents a state the code cannot write. In particular: the app only
  writes `submitted` when recording an application (BR-P8); `withdrawn` is
  written only by Withdraw (BR-T4); `under_review` … `rejected` come from
  `Update status` (BR-T8).

## 5. Render the PNGs

Run from the repository root. Mermaid CLI downloads once through `npx` and needs
a Chromium that Puppeteer can launch.

```powershell
cd D:\PRM\prm323_lab3
```

```powershell
Get-ChildItem docs/records/diagrams/state-*.mmd, docs/records/diagrams/business-flow-*.mmd | ForEach-Object { npx -y @mermaid-js/mermaid-cli -i $_.FullName -o ($_.FullName -replace '\.mmd$', '.png') -b white -s 2 }
```

Confirm every source has its PNG and the sizes are non-zero:

```powershell
Get-ChildItem docs/records/diagrams/state-*.mmd, docs/records/diagrams/business-flow-*.mmd | ForEach-Object { $png = $_.FullName -replace '\.mmd$', '.png'; if (Test-Path $png) { "{0} -> {1} bytes" -f $_.Name, (Get-Item $png).Length } else { "MISSING: $($_.Name)" } }
```

One file at a time, when editing a single diagram:

```powershell
npx -y @mermaid-js/mermaid-cli -i docs/records/diagrams/state-application.mmd -o docs/records/diagrams/state-application.png -b white -s 2
```

## 6. Maintenance

1. Change the state transition in code and this diagram in the same PR; keep the
   `BR-xx` labels stable.
2. If a branch changes, update the diagram, the PNG and the matching row in
   [`business-rules.md`](business-rules.md) §2–§5 together.
3. Do not add a state the app cannot reach. A planned state belongs in
   [`handoff-gaps.md`](records/handoff-gaps.md), not in these diagrams.
