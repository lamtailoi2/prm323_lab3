# Documentation

## Lab 3 deliverables (paths required by the handout)

| File | Content |
|---|---|
| [`design-traceability.md`](design-traceability.md) | Lab 2 screen / flow / component → route, widget, data source, status; every design deviation |
| [`architecture.md`](architecture.md) | MVVM layers, folder structure, sequence diagram, ViewModels → services, data ownership |
| [`analytics-plan.md`](analytics-plan.md) | Analytics events with typed parameters and the question each answers |
| [`test-plan.md`](test-plan.md) | ARTEMIS end-to-end test cases, coverage, results, exploratory session |
| [`uat-plan.md`](uat-plan.md) | User acceptance testing: participants, environment, 24 scenarios with exact copy, acceptance criteria; results in [`records/uat-results.md`](records/uat-results.md) |
| [`code-review.md`](code-review.md) | AI code review findings, decisions, fix commits, AI tool disclosure |

## How to run

| What | Command | Details |
|---|---|---|
| Flutter checks | `dart format lib test` · `flutter analyze` · `flutter test` | [`../AGENTS.md`](../AGENTS.md) § Commands |
| Firestore / Storage rules | `firebase emulators:exec --only firestore,storage --project demo-internly "npm --prefix firebase/tests test"` | [`../firebase/tests/README.md`](../firebase/tests/README.md) |
| Rules demo for a video | same, with `"npm --prefix firebase/tests run demo"`, then <http://localhost:5500> | [`../firebase/tests/README.md`](../firebase/tests/README.md) § Recorded demo |
| End-to-end (ARTEMIS) | `cd e2e_test && uv run pytest --count 3 -v` | [`test-plan.md`](test-plan.md) §1, [`guides/artemis-e2e.md`](guides/artemis-e2e.md) |
| User acceptance | Follow [`uat-plan.md`](uat-plan.md), record in [`records/uat-results.md`](records/uat-results.md) | [`../evidence/uat/README.md`](../evidence/uat/README.md) |

The rules commands need `firebase-tools` and a JDK on `PATH` (`java -version`), and must run from the repository root.

## Business rules

[`business-rules.md`](business-rules.md) — User and Admin actors, actor/system map, swimlanes, `BR-xx` codes at every branch point, application state machine, exception catalogue, and BR ↔ test traceability.

[`business-process-swimlane.md`](business-process-swimlane.md) — the same rules as one council-facing page: one actor/system diagram, the end-to-end student swimlane (prepare → discover → apply → track) and the admin swimlane, exception branches, state machine, and the branch ↔ state ↔ test table.

[`records/state-and-business-flows.md`](records/state-and-business-flows.md) — the state diagrams (session, `ViewState`, CV library, application, saved, report export, notification, sync, listing) and the business flows (student end to end, report export, admin), each mapped to code and `BR-xx`, with the PNG render command.

## Folders

| Folder | Content |
|---|---|
| [`design/`](design/README.md) | UI source of truth: Lab 2 design copies (`DESIGN.md`, `screen-spec.md`, `user-flow.md`, `persona.md`, screenshots) and [`design-system.md`](design/design-system.md) (tokens and components ↔ Flutter) |
| [`guides/`](guides/firebase-setup.md) | How-to: [`firebase-setup.md`](guides/firebase-setup.md) (Firebase, Google Sign-In, Storage, Remote Config, SerpAPI key) |
| [`records/`](records/handoff-gaps.md) | Project records: [`handoff-gaps.md`](records/handoff-gaps.md) (gaps and decisions), [`implementation-ai-log.md`](records/implementation-ai-log.md) (AI prompts and decisions), [`test-report.md`](records/test-report.md) (test runs), [`uat-results.md`](records/uat-results.md) (UAT sessions), [`prompts/`](records/prompts/P-01-initialize-internly.md) (long prompts, verbatim) |

Screenshots and console evidence live in [`../evidence/`](../evidence/README.md), not here.
