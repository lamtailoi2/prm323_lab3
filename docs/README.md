# Documentation

## Lab 3 deliverables (paths required by the handout)

| File | Content |
|---|---|
| [`design-traceability.md`](design-traceability.md) | Lab 2 screen / flow / component → route, widget, data source, status; every design deviation |
| [`architecture.md`](architecture.md) | MVVM layers, folder structure, sequence diagram, ViewModels → services, data ownership |
| [`analytics-plan.md`](analytics-plan.md) | Analytics events with typed parameters and the question each answers |
| [`test-plan.md`](test-plan.md) | ARTEMIS end-to-end test cases, coverage, results, exploratory session |
| [`code-review.md`](code-review.md) | AI code review findings, decisions, fix commits, AI tool disclosure |

## Business rules

[`business-rules.md`](business-rules.md) — User and Admin actors, actor/system map, swimlanes, `BR-xx` codes at every branch point, application state machine, exception catalogue, and BR ↔ test traceability.

[`business-process-swimlane.md`](business-process-swimlane.md) — the same rules as one council-facing page: one actor/system diagram, the end-to-end student swimlane (prepare → discover → apply → track) and the admin swimlane, exception branches, state machine, and the branch ↔ state ↔ test table.

## Folders

| Folder | Content |
|---|---|
| [`design/`](design/README.md) | UI source of truth: Lab 2 design copies (`DESIGN.md`, `screen-spec.md`, `user-flow.md`, `persona.md`, screenshots) and [`design-system.md`](design/design-system.md) (tokens and components ↔ Flutter) |
| [`guides/`](guides/firebase-setup.md) | How-to: [`firebase-setup.md`](guides/firebase-setup.md) (Firebase, Google Sign-In, Storage, Remote Config, SerpAPI key) |
| [`records/`](records/handoff-gaps.md) | Project records: [`handoff-gaps.md`](records/handoff-gaps.md) (gaps and decisions), [`implementation-ai-log.md`](records/implementation-ai-log.md) (AI prompts and decisions), [`test-report.md`](records/test-report.md) (Flutter test runs), [`prompts/`](records/prompts/P-01-initialize-internly.md) (long prompts, verbatim) |

Screenshots and console evidence live in [`../evidence/`](../evidence/README.md), not here.
