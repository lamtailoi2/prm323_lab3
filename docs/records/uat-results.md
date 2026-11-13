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
| R1-A | Internal | 2026-11-11 12:47 | `42ea1e0` · profile APK | Medium Phone API 37 (`emulator-5554`) | Automated walkthrough (team account) | 13 Pass · 11 Not run (completed in R1-B) | `e2e_test/artifacts/recordings/uat-r1-20261111.mp4` |
| R1-B | Internal | 2026-11-12 23:56 – 2026-11-13 00:56 | `0.1.0` (versionCode 1), installed 2026-11-12 21:27 | Medium Phone API 37 (`emulator-5554`) | Automated follow-up (team account) | 10 Pass · 1 Fail | `evidence/uat/uat-r1b-*.png` |
| B7 retest | Internal | 2026-11-13 09:00 – 09:18 | profile APK of `dev` `b97f7a4` (before) and of branch `fix/uat-b7-offline` (after) | `Pixel_API_36` (`emulator-5554`, API 36, macOS host) | Automated retest of UAT-B7 only (test account on that emulator) | Before the fix: Fail (reproduced) · after the fix: **Pass** | `evidence/uat/uat-b7-retest-*.png` |
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

#### How to present the internal rounds (slide 21)

Keep **Evidence** and **Result** separate, and never present the internal rounds
as external UAT.

| Slide element | Exact text |
|---|---|
| Title | `UAT evidence — internal rounds` |
| Evidence | `Round 1 (internal): automated adb walkthroughs · R1-A video 241 s · R1-B screenshots · 24 of 24 scenarios executed` |
| Build / device | `R1-A 42ea1e0 · R1-B 0.1.0 (versionCode 1) · Medium Phone API 37 (emulator-5554) · 2026-11-11/12` |
| Result | `24 Pass after the B7 fix · 0 Blocked · 0 Not run (internal)` (R1-A + R1-B gave 23 Pass · 1 Fail; B7 passed on the 2026-11-13 retest) |
| Pass (24) | `A1–A3, B1–B7, C1–C10, D1–D4` — B7 on the retest after the fix |
| Fixed (1) | `B7 — offline Saved/Search showed an empty state; now error + Retry (S2, UAT-R1B-01)` |
| Not measured | `persona timing targets (scripted runs), questionnaire, consent` |
| Subtitle | `External sessions (E1–E3) not run; the acceptance checklist cannot be completed.` |
| Source chip | `docs/records/uat-results.md` |
| Video | `e2e_test/artifacts/recordings/uat-r1-20261111.mp4` — R1-A, 241 s, 9.3 MB, git-ignored because the team's name, email and CV are visible; hand it in separately, not through Git |
| Screenshots | `evidence/uat/uat-r1b-*.png` — R1-B per-state captures |
| Coverage note | `Report export (TC-11) and notifications (TC-13 / TC-15) are covered by ARTEMIS, not these UAT rounds.` |

Speaking note: “These are internal rounds driven automatically, not human
acceptance sessions. All 24 scenarios were executed across R1-A and R1-B: 23
passed and one failed — B7, where the offline Saved and Search screens showed an
empty state instead of an error with Retry. We fixed it and the B7 retest
passed, so all 24 pass now. The three external sessions were not run, so no
external UAT claim is made and the acceptance checklist cannot be completed.”

Write `24 / 24 Pass` only together with “after the B7 fix”, and only once
`fix/uat-b7-offline` is merged; before that the result is `23 Pass · 1 Fail`
with B7 “fixed on a branch”. Name the B7 failure either way.

R1-B is an automated follow-up, not the planned second team member; say so if
the slide lists participants or sessions. The `evidence/uat/` folder now holds
the R1-B screenshots; the R1-A video stays in the git-ignored
`e2e_test/artifacts/recordings/`, so put its path on the slide or hand it in
separately.

The runs changed the team account: R1-A saved and unsaved one listing, recorded
one application, changed its CV, withdrew and undid it; R1-B added and removed a
test CV, set and cleared preferences, signed out and back in. The recorded
application stays because there is no delete action.

---

### Session R1-B (internal, automated follow-up)

> **Disclosure.** This is **not** the planned second team member and **not** a
> human acceptance session. It completes the 11 scenarios R1-A did not run,
> using adb/uiautomator taps on the same emulator and team account. The
> questionnaire was not answered. Do not present it as an external (`E1`–`E3`)
> result. The screenshots show the team's own name and email, so keep them as
> private evidence and do not publish them.

| Item | Value |
|---|---|
| Date and time | 2026-11-12 23:56 – 2026-11-13 00:56 (Asia/Ho_Chi_Minh) |
| Build | `0.1.0` (versionCode 1), installed 2026-11-12 21:27; the commit is not embedded in the APK |
| Device / Android | Medium Phone API 37 (`emulator-5554`), Google Play services present |
| Account | the team's own Google account (same as R1-A) |
| Driver / operator | adb + uiautomator taps (Command Code) / team operator |
| Recording | no continuous video; per-state screenshots in `evidence/uat/uat-r1b-*.png` |
| Consent | not applicable (team account, internal round) |

#### Scenario results

| ID | Result | Observation | Evidence |
|---|---|---|---|
| UAT-A1 | Pass | Signed out, `Continue with Google` → team account → Home with `Find your next internship`; Login no longer shown | `evidence/uat/uat-r1b-a1-home-20261112.png` |
| UAT-A2 | Pass | Cancelled picker → `Sign-in was cancelled. Tap Continue with Google to try again.`; Login stayed | `evidence/uat/uat-r1b-a2-cancelled-20261112.png` |
| UAT-A3 | Pass | Sign out → Login; Back and force-stop/relaunch still Login, no Home behind it | `evidence/uat/uat-r1b-a3-login-20261112.png`, `uat-r1b-a3-relaunch-login-20261112.png` |
| UAT-B3 | Pass | Filters `C#` + `Remote` → `Show 0 results` → `No internships found` + `Clear filters`; clearing restored 115 results | `evidence/uat/uat-r1b-b3-empty-20261112.png`, `uat-r1b-b3-cleared-20261112.png` |
| UAT-B7 | **Fail** | With Wi-Fi/data off and an empty Firestore cache, Saved showed `No saved internships yet` and Search showed `No internships found`; no error state and no `Retry`. Reconnecting auto-restored 2 saved items and the pool | `evidence/uat/uat-r1b-b7-saved-offline-20261112.png`, `uat-r1b-b7-search-offline-20261112.png` |
| UAT-C9 | Pass | `Validate CV` → `Checking your CV…` → returned to Compose with `Your CV passed the check.` | `evidence/uat/uat-r1b-c9-validate-20261112.png`, `uat-r1b-c9-result-20261112.png` |
| UAT-C10 | Pass | Compose opened, Back arrow pressed without sending; Applications stayed 9 (7 Submitted, 2 Withdrawn) | `evidence/uat/uat-r1b-c10-compose-20261112.png`, `uat-r1b-c10-apps-after-20261112.png` |
| UAT-D1 | Pass | `Edit profile`: full-name edit + Back showed `Discard your changes?`; Discard reverted it. Headline changed to `UAT test`, saved, shown on Profile, then restored to `SWE`. The full name itself was not saved, to keep the team account unchanged | `evidence/uat/uat-r1b-d1-discard-20261112.png` |
| UAT-D2 | Pass | Added `Sample_CV.pdf` (3 files), `Set as default` moved the default label, `Remove` confirmed with the submitted-application notice; 2 files remained, the default was promoted to the newest, then the original default was restored | `evidence/uat/uat-r1b-d2-cv-menu-20261112.png`, `uat-r1b-d2-cv-default-20261112.png`, `uat-r1b-d2-cv-removed-20261112.png` |
| UAT-D3 | Pass | Added `Kotlin`, removed it; set `Mobile` + `Remote`, then cleared both back to `Not set` | `evidence/uat/uat-r1b-d3-skill-added-20261112.png`, `uat-r1b-d3-skill-removed-20261112.png`, `uat-r1b-d3-preferences-set-20261112.png`, `uat-r1b-d3-preferences-saved-20261112.png`, `uat-r1b-d3-preferences-cleared-20261112.png` |
| UAT-D4 | Pass | Signed in again: Profile showed the name, 2 CVs with the original default and `Docker`; Saved showed 2; Applications showed 9 (7 Submitted, 2 Withdrawn) | `evidence/uat/uat-r1b-d4-profile-20261112.png`, `uat-r1b-d4-saved-20261112.png`, `uat-r1b-d4-applications-20261112.png` |

**Persona targets:** not measured — the 30 s / 2 min targets assume a human
searching and reading, not scripted taps.

#### Defects found

| Defect | Scenario | Severity | What happened | Expected | Evidence | Status |
|---|---|---|---|---|---|---|
| UAT-R1B-01 | UAT-B7 | S2 | Offline with an empty Firestore cache, Saved rendered `No saved internships yet` and Search rendered `No internships found`; neither screen showed an error or `Retry`. Reconnecting auto-restored the data | Explicit error state with `Retry` (BR-D6); an empty list must not look like lost data | `evidence/uat/uat-r1b-b7-saved-offline-20261112.png`, `uat-r1b-b7-search-offline-20261112.png` | **Fixed** on branch `fix/uat-b7-offline` (P-101), retested 2026-11-13: Pass (see [B7 retest](#b7-retest-after-the-fix-internal-automated)); closed once the branch is merged into `dev` |

**Reproduction (emulator / debug build; this deletes only the local Firestore cache, not server data):**

```powershell
adb shell am force-stop com.group3.internly
adb shell run-as com.group3.internly rm -f "databases/firestore.%5BDEFAULT%5D.prm-lab3.%28default%29" "databases/firestore.%5BDEFAULT%5D.prm-lab3.%28default%29-journal"
adb shell svc wifi disable
adb shell svc data disable
adb shell am start -W -n com.group3.internly/.MainActivity
```

Open `Saved`, then `Search`, and type a query. Restore the network with `adb shell svc wifi enable; adb shell svc data enable`.

The run changed the test account as designed by the scenarios: it added and
removed one test CV, set and cleared preferences, signed out and back in, and
temporarily changed the headline before restoring it.

#### Questionnaire

Not answered — no human participant in this run.

#### Sign-off

| Role | Name | Signature | Date |
|---|---|---|---|
| Participant | — (automated) | — | 2026-11-13 |
| Operator | team | — | 2026-11-13 |

---

### B7 retest after the fix (internal, automated)

> **Disclosure.** A regression retest of the one failed scenario, driven by adb
> on the macOS host's emulator with the test account signed in. Not a human
> session and not an external (`E1`–`E3`) result. The screenshots show the
> account's name, so keep them as private evidence.

| Item | Value |
|---|---|
| Date and time | 2026-11-13 09:00 – 09:18 (Asia/Ho_Chi_Minh) |
| Builds | Before: profile APK of `dev` `b97f7a4`. After: profile APK of branch `fix/uat-b7-offline` (P-101), built and installed 09:17 |
| Device / Android | `Pixel_API_36` (`emulator-5554`, API 36), macOS host |
| Steps | The reproduction above (force-stop, delete only the local Firestore cache, Wi-Fi and data off, launch), then `Home` → `Saved` → `Search` with a typed query, then Wi-Fi and data on |
| Driver / operator | adb taps (Claude Code) / team operator |

| Build | Home offline | Saved offline | Search offline | Back online | Result |
|---|---|---|---|---|---|
| `dev` `b97f7a4` (before) | `No results found` | `No saved internships yet` | `No internships found` | Search 56 results, Saved 9 items, without Retry | **Fail** (UAT-R1B-01 reproduced) |
| `fix/uat-b7-offline` (after) | `We could not load internships. Check your connection and try again.` + `Retry` | `We couldn’t load your saved internships. Check your connection and try again.` + `Retry` | same message as Home + `Retry` | Search results and Saved (9 items) came back by themselves, no tap needed | **Pass** |

Evidence: `evidence/uat/uat-b7-retest-before-2-saved-offline-20261113.png`,
`uat-b7-retest-before-3-search-offline-20261113.png`,
`uat-b7-retest-after-1-home-offline-20261113.png`,
`uat-b7-retest-after-2-saved-offline-20261113.png`,
`uat-b7-retest-after-3-search-offline-20261113.png`,
`uat-b7-retest-after-4-search-online-20261113.png`,
`uat-b7-retest-after-5-saved-online-20261113.png`.

A first build of the fix (09:03) showed the error on Home and Search, but Saved
stayed on its loading skeleton: Riverpod's default automatic retry keeps a
failed provider in loading. The second build disables that retry for
`savedInternshipsProvider`; the screenshots above are from the second build.
The emulator crashed once (exit 139) between the two builds and was restarted;
no result was taken from the crashed run.

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

**Internal coverage after R1-B (2026-11-13):** all 24 scenarios were executed
across R1-A and R1-B — 23 Pass, 1 Fail (`UAT-R1B-01`, UAT-B7). The external
sessions E1–E3 did not run, so the checklist below stays unfilled and no
acceptance decision is made.

**After the B7 fix (2026-11-13):** UAT-B7 was retested on the fix branch and
passed, so the internal result is 24 of 24 scenarios passing with no open defect
once `fix/uat-b7-offline` is merged. The external sessions are still not run.

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

**Known gaps at the time of R1-A (2026-11-11):** `Report export` was disabled and read `Coming soon.` (G-05), and notifications were covered by TC-13 / TC-15 rather than UAT.

**Afterwards (2026-11-12):** the report export gap above is closed — `Profile → Firebase demo → Report export` now opens `/profile/export` and exports a PDF of the student's applications (G-05, DC-36, P-71). The sessions above were not re-run; the feature is covered by ARTEMIS TC-11 and the Flutter tests instead.
