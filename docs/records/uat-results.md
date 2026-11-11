# UAT results

One section per session, filled **during or immediately after** the session. The plan, participants and scenario wording are in [`../uat-plan.md`](../uat-plan.md); recordings go to [`../../evidence/uat/`](../../evidence/uat/README.md).

Rules:

- A session that did not happen is recorded as **Not run**, with the reason. Never copy a previous result into a new session.
- Use `Pass`, `Fail`, `Blocked` (environment or app unavailable) or `Not run`. `Fail` always has a defect row.
- Participants stay anonymous (`E1`, `E2`, `E3` for external; `R1-A`, `R1-B` for internal).
- One row per scenario per participant. The same defect seen twice is one defect with two evidence links.

## Session index

| Session | Round | Date | Build | Device | Participant | Result | Record |
|---|---|---|---|---|---|---|---|
| R1-A | Internal | Not run | — | — | — | — | — |
| R1-B | Internal | Not run | — | — | — | — | — |
| E1 | External | Not run | — | — | — | — | — |
| E2 | External | Not run | — | — | — | — | — |
| E3 | External | Not run | — | — | — | — | — |

---

## Template: one session

Copy this block for each participant and replace `E1`.

### Session E1 (external)

| Item | Value |
|---|---|
| Date and time | `<yyyy-mm-dd hh:mm>` |
| Build | `<commit SHA>` · profile APK |
| Device / Android | `<phone model>` / API `<level>` |
| Account | fresh Google test account (no password stored) |
| Facilitator / note-taker | `<initials>` / `<initials>` |
| Recording | `evidence/uat/uat-e1-<yyyymmdd>.mp4` (screen) / notes file |
| Consent | signed, kept by the team |

#### Scenario results

| ID | Result | Time (s) | Observation (what the participant did or said) | Evidence |
|---|---|---|---|---|
| UAT-A1 | | | | |
| UAT-A2 | | | | |
| UAT-A3 | | | | |
| UAT-B1 | | | | |
| UAT-B2 | | | | |
| UAT-B3 | | | | |
| UAT-B4 | | | | |
| UAT-B5 | | | | |
| UAT-B6 | | | | |
| UAT-B7 | | | | |
| UAT-C1 | | | | |
| UAT-C2 | | | | |
| UAT-C3 | | | | |
| UAT-C4 | | | | |
| UAT-C5 | | | | |
| UAT-C6 | | | | |
| UAT-C7 | | | | |
| UAT-C8 | | | | |
| UAT-C9 | | | | |
| UAT-C10 | | | | |
| UAT-D1 | | | | |
| UAT-D2 | | | | |
| UAT-D3 | | | | |
| UAT-D4 | | | | |

**Persona targets** (from `uat-plan.md` §1): find an internship under 30 s — `<seconds>`; apply under 2 min — `<seconds>`.

#### Defects found

| Defect | Scenario | Severity | What happened | Expected | Evidence | Status / fix |
|---|---|---|---|---|---|---|
| UAT-E1-01 | | S1 / S2 / S3 / S4 | | | | open / fixed in `<commit>` / accepted |

#### Questionnaire

| Statement | Score (1–5) |
|---|---|
| The app was easy to use. | |
| I found an internship that fits me quickly. | |
| The steps to apply were clear. | |
| I always knew what to do next. | |
| I would use Internly for my internship search. | |

Most confusing moment:  
What they would change first:  

#### Sign-off

| Role | Name | Signature | Date |
|---|---|---|---|
| Participant | E1 | | |
| Facilitator | | | |
| Note-taker | | | |

---

## Acceptance checklist (fill after E3)

| Criterion (`uat-plan.md` §1) | Target | Actual | Met |
|---|---|---|---|
| P1 scenarios pass for all external participants | 8 × 3 | | |
| Overall pass rate in R2 | ≥ 90% | | |
| Open S1 defects | 0 | | |
| Open S2 defects | 0 | | |
| Find an internship (median) | < 30 s | | |
| Apply by email (median) | < 2 min | | |
| Questionnaire average | ≥ 4.0 / 5 | | |
| Sessions with a recording and a completed row | 3 of 3 | | |

**Decision:** `<accepted / accepted with conditions / rejected>` — date, names.

**Known gaps accepted at sign-off:** `Report export` is disabled and reads `Coming soon.` (G-05), and notifications are covered by TC-13 / TC-15 rather than UAT.
