# Lab 2 design handoff (read-only snapshot)

These files are copied unchanged from the Lab 2 repository so this repository is self-contained. They are the **source of truth for the UI** (screens, flows, tokens, components).

| | |
|---|---|
| Source repository | <https://github.com/lamtailoi2/prm323_lab2> |
| Source commit | `03f4aa31631fde8b67b319388c3b4efd0f9f50ae` ("update README.md") |
| Copied on | 2026-10-21 |
| Figma file | <https://www.figma.com/design/UQveNSgQNYbuZyaNMa57FQ/Internship-Finder---Design-System> |

| File | Content |
|---|---|
| [`design/DESIGN.md`](design/DESIGN.md) | Design system rules and tokens |
| [`design/screen-spec.md`](design/screen-spec.md) | Purpose, content, actions, states and intent of each screen. **Revised in Lab 3**: new flow numbers and the CV Match Check screen |
| [`design/design-decisions.md`](design/design-decisions.md) | Key design decisions and accessibility checklist |
| [`ux/user-flow.md`](ux/user-flow.md) | Information architecture, Flows 1–3 with branches. **Revised in Lab 3** (DC-08, DC-09): Search → Apply (Save sub-flow, CV match check) → Track |
| [`ux/persona.md`](ux/persona.md) | Persona, problem statement, success criterion |
| [`lab2-README.md`](lab2-README.md) | Lab 2 overview, token → Flutter and component → widget tables |
| [`screenshots/`](screenshots/) | Final Google Stitch outputs (`*-final.png`). The Figma final UI overrides them where they differ |
| [`design/design-system.md`](design/design-system.md) | **Lab 3 file (editable):** design system + components consolidated for Flutter, Figma ↔ code cross-check |

Not copied: the Lab 2 AI design log and its intermediate screenshots (Lab 2 deliverables, available in the source repository).

**Do not edit the Lab 2 files** except through a deviation entry in `design-traceability.md`. Files maintained in Lab 3: `design/design-system.md`, and `ux/user-flow.md` and `design/screen-spec.md` since DC-08 / DC-09. `lab2-README.md` still shows the original Lab 2 flows. Lab 3 decisions and deviations go to [`../design-traceability.md`](../design-traceability.md) §4. Missing or conflicting requirements go to [`../handoff-gaps.md`](../handoff-gaps.md). The consolidated Flutter reference is [`design/design-system.md`](design/design-system.md).

Links inside the copied files that point to `ai/…` resolve only in the source repository.
