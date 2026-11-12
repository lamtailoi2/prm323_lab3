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
| R1-A | Internal | 2026-11-11 12:47 | `42ea1e0` · profile APK | Medium Phone API 37 (`emulator-5554`) | Automated walkthrough (team account) | 13 Pass · 11 Not run | `e2e_test/artifacts/recordings/uat-r1-20261111.mp4` |
| R1-B | Internal | Not run | — | — | — | — | — |
| E1 | External | Not run | — | — | — | — | — |
| E2 | External | Not run | — | — | — | — | — |
| E3 | External | Not run | — | — | — | — | — |

---

### Session R1-A (internal, automated walkthrough)

> **Disclosure.** This is **not** a human acceptance session. The team asked for the flows to be driven automatically and recorded as internal UAT evidence. The driver (adb taps + UI assertions, script kept outside the repository) ran the scenarios below on the team's own Google account. The questionnaire was not answered because no participant used the app by hand. Do not present this row as an external (`E1`–`E3`) result.

| Item | Value |
|---|---|
| Date and time | 2026-11-11 12:47 (Asia/Ho_Chi_Minh) |
| Build | `42ea1e0` · `app-profile.apk` |
| Device / Android | Medium Phone API 37 (`emulator-5554`), Google Play services present |
| Account | the team's own Google account (name, email and CV appear on screen; the video is therefore **not** committed) |
| Driver / operator | adb-driven script (Command Code) / team operator |
| Recording | `e2e_test/artifacts/recordings/uat-r1-20261111.mp4` — 241 s, 9.3 MB, git-ignored |
| Consent | not applicable (team account, internal round) |

#### Scenario results

| ID | Result | Time (s) | Observation | Evidence |
|---|---|---|---|---|
| UAT-A1 | Not run | — | Sign-in cannot be automated (Google account picker); the app was already signed in | — |
| UAT-A2 | Not run | — | Same reason as A1 | — |
| UAT-A3 | Not run | — | Sign-out would end the session and cannot be reversed automatically | — |
| UAT-B1 | Pass | 16.6 | Home shows `Find your next internship` and `Browse by Role`; the search field opens Search | video 0:00–0:17 |
| UAT-B2 | Pass | 41.9 | Query `developer`, `Filters` → `Remote`, `Show 2 results →`, filtered list | video 0:17–0:59 |
| UAT-B3 | Not run | — | Empty-result path not driven in this run | — |
| UAT-B4 | Pass | 26.9 | Detail opens with `Apply now` and `Save internship` | video 0:59–1:26 |
| UAT-B5 | Pass | 11.8 | `Save internship` → `Saved to your list`; `Saved` shows the listing | video 1:26–1:38 |
| UAT-B6 | Pass | 9.6 | Unsave → `Removed from Saved` → `Undo` restores it | video 1:38–1:47 |
| UAT-B7 | Not run | — | Airplane-mode error path not driven | — |
| UAT-C1 | Pass | 47.7 | `Apply by email` with `To`, `Subject`, `Cover letter`, `CV / Resume` and the AI draft banner | video 1:47–2:35 |
| UAT-C2 | Pass | 23.6 | `Change CV` sheet, second CV chosen, sheet closes | video 2:35–2:59 |
| UAT-C3 | Pass | 8.4 | `Open email app` opens Gmail with the draft; Back returns to Compose | video 2:59–3:07 |
| UAT-C4 | Pass | 7.3 | `I've sent it` records the application and opens the success recap | video 3:07–3:15 |
| UAT-C5 | Pass | 7.2 | My Applications lists the application with `Submitted` | video 3:15–3:22 |
| UAT-C6 | Pass | 11.0 | Application Detail shows `Status tracker`, `Step 1 of 4`, `Active step` | video 3:22–3:33 |
| UAT-C7 | Pass | 15.1 | Withdraw → confirm → `Application withdrawn` → `Undo` restores `Submitted` | video 3:33–3:48 |
| UAT-C8 | Pass | 14.7 | Detail shows `You applied on …` and `View application` instead of `Apply now` | video 3:48–4:01 |
| UAT-C9 | Not run | — | Optional Validate CV not driven in this run | — |
| UAT-C10 | Not run | — | Back-without-sending not driven in this run | — |
| UAT-D1 | Not run | — | Would change the team's real profile | — |
| UAT-D2 | Not run | — | Would change the team's real CV library | — |
| UAT-D3 | Not run | — | Would change the team's real skills/preferences | — |
| UAT-D4 | Not run | — | Needs a manual sign-in again | — |

**Persona targets:** not measured — the 30 s / 2 min targets assume a human searching and reading, not scripted taps.

#### Defects found

| Defect | Scenario | Severity | What happened | Expected | Evidence | Status |
|---|---|---|---|---|---|---|
| — | — | — | No functional defect observed on the 13 automated rows | — | — | — |

The run did change account data as designed: it saved and unsaved one listing, changed the CV for one application, recorded one application, then withdrew and undid it. The application stays recorded (there is no delete action), so this account now has that test application.

#### Questionnaire

Not answered — no human participant in this run.

#### Sign-off

| Role | Name | Signature | Date |
|---|---|---|---|
| Participant | — (automated) | — | 2026-11-11 |
| Operator | team | — | 2026-11-11 |

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

**Afterwards (2026-11-12):** the report export gap above is closed — `Profile → Firebase demo → Report export` now opens `/profile/export` and exports a PDF of the student's applications (G-05, DC-36, P-71). The sessions above were not re-run; the feature is covered by ARTEMIS TC-11 and the Flutter tests instead.
