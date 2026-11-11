# UAT plan: Internly student app

User acceptance testing for Lab 3. Real students run the four main flows on an Android build **without coaching**; the team records what they do, how long it takes and where they get stuck. Results go to [`records/uat-results.md`](records/uat-results.md); screenshots and recordings go to [`../evidence/uat/`](../evidence/uat/README.md).

Two rounds, in this order:

| Round | Who | Purpose |
|---|---|---|
| **R1 Internal** | 2 team members who did **not** build the screen under test | Catch defects and wording problems before external participants see the app |
| **R2 External** | 3 students matching the persona (third-year IT, uses one hand, campus network) and not on the team | The acceptance evidence: ease of use, task success, time on task |

Do not coach in R2. If a participant asks how to do something, answer with a question ("What would you try?") and note the moment as a finding.

## Quick start

1. Build and install the profile APK on the test device (details in §4):
   ```bash
   flutter build apk --profile --dart-define-from-file=.env
   adb install -r build/app/outputs/flutter-apk/app-profile.apk
   ```
2. Sign in with a fresh Google test account and upload the two prepared PDF CVs to Profile → `CV library`.
3. Open [`records/uat-results.md`](records/uat-results.md), copy the session block and fill the header before the participant starts.
4. Start the screen recorder, then run A1 → D4 from §9 without demonstrating anything.
5. Fill the results, defect log and questionnaire the same day, and move the files into [`../evidence/uat/`](../evidence/uat/README.md).

## 1. Acceptance criteria

The app is accepted when all of the following hold after R2:

1. Every **P1 scenario** (A1, B2, B4, C1, C3, C4, C5, D1) passes for **all 3** external participants.
2. At least **90%** of all scenario results across R2 are `Pass` (blocked-by-environment rows are excluded and explained).
3. No open defect of severity **S1** or **S2**; every S3 has a recorded workaround.
4. The two persona targets are met on the participant's own device: find a matching internship in **under 30 s** and finish the apply-by-email flow in **under 2 min** (median of the 3 participants).
5. Average score of the post-session questionnaire is **≥ 4.0 / 5**.
6. Every session has a recording (or timestamped notes when recording was refused) and a completed row in `records/uat-results.md`.

Anything that fails these criteria sends the build back to the team; the fix is recorded against the UAT row, not silently dropped.

## 2. Scope

| Flow | Scenarios | Screens |
|---|---|---|
| **A. Sign in / out** | A1–A3 | Splash, Login, Home, Profile |
| **B. Search and save** | B1–B7 | Home, Search, Filter sheet, Search Results, Internship Detail, Saved |
| **C. Apply by email and track** | C1–C10 | Internship Detail, Apply by email, CV Match, Validate CV, Success, My Applications, Application Detail |
| **D. Profile and CV library** | D1–D4 | Profile, Edit profile, CV library, Add CV sheet, Edit skills / Edit preferences sheets |

**Out of scope for this UAT**, with the reason:

| Item | Why |
|---|---|
| Notifications (FCM, Notification Center, notification preferences) | Covered by the FCM evidence and ARTEMIS TC-13 / TC-15, not a student acceptance task |
| `Profile → Firebase demo` (Remote Config, Crashlytics buttons) | Lab 3 demo tooling, not a student task |
| Local admin dashboard | Operator tool, tested by `npm test` in `tools/admin-dashboard` |
| `Report export` | Not built: the Profile row is disabled and reads `Coming soon.` (G-05). UAT records this as a known gap, it is not a failure |

## 3. Participants and roles

| Role | Responsibility |
|---|---|
| Facilitator | Reads each scenario, keeps time, never demonstrates the app |
| Note-taker | Writes the result per scenario, quotes, defects and the time on task |
| Participant | Uses the app and thinks aloud |

Rules:

- Every participant signs a one-paragraph consent: test data only, screen recording kept in `evidence/uat/` and deleted after grading.
- Use a **fresh Google account per participant** so saved jobs, CVs and applications start empty. Do not reuse the team's account.
- Record the device, Android version and build SHA in the session header.
- The participant's name is **not** written anywhere; use `E1`, `E2`, `E3` and `R1-A`, `R1-B`.

## 4. Environment and test data

| Item | Value |
|---|---|
| Build | Profile APK from the commit under test: `flutter build apk --profile --dart-define-from-file=.env` then `adb install -r build/app/outputs/flutter-apk/app-profile.apk` |
| Device | The participant's own Android phone when possible; otherwise the team's emulator. APIs 33+ (notification permission exists but is not part of these flows) |
| Network | Normal Wi-Fi; B7 switches to airplane mode on purpose |
| Listings | The scheduled sync must have run: Home shows `Recommended for you` / `Recently Posted`, and at least one listing has a recruiter email in its description |
| CVs | Two readable PDF CVs prepared by the team, in the participant's Profile `CV library`, for C2 and C9 |
| Account | Fresh Google test account, already added on the device; no password stored in the repository |
| Reset between participants | Sign out, then remove the test account's data only if the next participant needs an empty library; never delete another user's documents |

## 5. Session procedure

1. **Intro (5 min).** Explain the app is being tested, not the participant. Ask them to think aloud. Start the screen recorder (`adb shell screenrecord` or the phone's built-in recorder); start a timer.
2. **Tasks (30–40 min).** Run A1 → D4 in order. Read the scenario text verbatim. Do not point, do not name buttons, do not explain errors.
3. **Time on task.** Start the timer at the first tap of A1 and stop it when the goal of the scenario is on screen. Record seconds in the results file.
4. **Questionnaire (5 min).** The five statements in §8, then two open questions.
5. **Debrief (5 min).** Ask what was confusing, what they expected to happen, and whether they would use it.
6. **Triage (same day).** The team assigns severity (§7), logs defects and links each accepted fix to a commit.

If the app crashes or the network dies, mark the scenario `Blocked`, write the cause, and continue with the next scenario that does not depend on it. Do not retry more than once.

## 6. Locating controls

The app labels every button and icon-only control for ARTEMIS, so a participant can rely on the same text:

- Bottom navigation: `Home`, `Search`, `Saved`, `Applications`, `Profile`.
- Login: `Continue with Google`.
- Detail actions: `Save` / `Saved`, `Apply now` / `View application`.
- Compose: `Open email app`, `I've sent it`, `Change CV`, `Validate CV`, `Check CV match`, `Regenerate`.
- Saved / applications: bookmark tooltip `Save internship` / `Unsave internship`, `Withdraw application`, `Undo`.
- Profile: `Edit profile`, `Add CV`, `CV actions` menu (`View`, `Set as default`, `Remove`), `Sign out`.

## 7. Severity

| Level | Meaning | Example | Action |
|---|---|---|---|
| **S1 Blocker** | The flow cannot be completed | Sign-in fails; `I've sent it` never records the application | Fix before R2 continues |
| **S2 Major** | The flow completes only with a workaround, or data is wrong | Saved list empty after a successful save; wrong status shown | Fix before sign-off |
| **S3 Minor** | Confusing copy, layout or extra taps | Unclear helper text; button needs scrolling at 360 dp | Fix or record a workaround |
| **S4 Cosmetic** | Visual polish only | Spacing, icon alignment | Backlog |

A defect repeated by more than one participant is one defect with several evidence rows.

## 8. Post-session questionnaire

Five statements, 1 = strongly disagree … 5 = strongly agree:

1. The app was easy to use.
2. I found an internship that fits me quickly.
3. The steps to apply were clear.
4. I always knew what to do next.
5. I would use Internly for my internship search.

Open questions: "What was the most confusing moment?" and "What would you change first?"

## 9. Scenario script

Each row is read as written. "Expected" quotes the copy that must appear; anything different is a finding.

### Flow A — Sign in and sign out

| ID | Pri | Task | Expected result | BR |
|---|---|---|---|---|
| UAT-A1 | P1 | Open the app signed out. Tap `Continue with Google` and choose the test account. | Splash, then Home with `Find your next internship`, the bottom tabs `Home`, `Search`, `Saved`, `Applications`, `Profile`, and no Login screen afterwards. | BR-A1, BR-A2 |
| UAT-A2 | P2 | Open the app signed out. Tap `Continue with Google`, then close the account picker without choosing. | An informational message; the Login screen stays and nothing is reported as an error. | BR-A2 |
| UAT-A3 | P1 | Profile → `Sign out`. Then press Back and relaunch the app. | Login screen; Back and relaunch never show a signed-in screen. | BR-A3 |

### Flow B — Search and save

| ID | Pri | Task | Expected result | BR |
|---|---|---|---|---|
| UAT-B1 | P2 | On Home, scroll the feed, then tap the `Search internships` field. | `Browse by Role`, plus `Recommended for you` / `Recently Posted` when the pool has data. Tapping the field opens the Search tab. | BR-D2, BR-D3 |
| UAT-B2 | P1 | On Search, type a skill (for example `flutter`), open `Filters`, choose work mode `Remote` and job type `Internship`, then tap `Show N results →`. Open the first card. | Results list with matching cards; the card opens Internship Detail with the company, title, `Save` and `Apply now`. The whole task takes **under 30 s**. | BR-D4 |
| UAT-B3 | P3 | In `Filters`, choose a combination that cannot match (for example a skill that is not in the pool), then tap `Show 0 results →`. Then tap `Clear filters`. | `No internships found` with `Clear filters`; clearing restores the unfiltered list. | BR-D4 |
| UAT-B4 | P1 | From Search Results, tap a card. Read the detail, then press Back. | Internship Detail with company, title, description, `Save` and `Apply now`; Back returns to the same results. | BR-D5 |
| UAT-B5 | P2 | On Internship Detail, tap `Save`. Then open the `Saved` tab. | Snackbar `Saved to your list` with `View saved`; the listing appears in `Saved`. | BR-S1, BR-S2 |
| UAT-B6 | P3 | In `Saved`, unsave the listing, then tap `Undo` in the snackbar. | Item disappears with `Removed from Saved` + `Undo`; `Undo` puts it back. | BR-S3 |
| UAT-B7 | P3 | Turn on airplane mode, open `Saved` and then `Search Results`, and tap `Retry` after turning the network back on. | Explicit error state with `Retry` (never fake data); after reconnecting, `Retry` loads the list. | BR-D6 |

### Flow C — Apply by email and track

| ID | Pri | Task | Expected result | BR |
|---|---|---|---|---|
| UAT-C1 | P1 | Open an internship, tap `Apply now`. Read the screen, then edit the subject. | `Apply by email` with `To`, `Subject`, `Cover letter`, `CV / Resume`; the banner says either `Drafted from the job description and your Profile. AI can make mistakes, so check it before you send.` or `The AI service was unavailable, so this is a template. Edit it before you send.`; `To` is prefilled when the job post contains an address. | BR-P3, BR-P5 |
| UAT-C2 | P2 | With two CVs in the library, tap `Change CV`, choose the other file, then check Profile → `CV library`. | Sheet titled `Change CV` with `Choose another CV for this application. Your Profile default stays the same.`; the compose CV block shows the new file; the Profile default is unchanged (`Default for applications` still on the old one). | BR-C3, BR-C5 |
| UAT-C3 | P1 | Tap `Open email app`, look at the draft, then return to Internly. | The device mail app opens with the recipient, subject and letter; on return the snackbar reads `Email app opened. Attach your CV there.` | BR-P6 |
| UAT-C4 | P1 | Tap `I've sent it`. | Success screen, and the application appears in `Applications` with `Submitted`. If Profile has no full name, the screen says `Add your name in Profile to record this application` instead. The apply task takes **under 2 min** from `Apply now`. | BR-P7, BR-P8, BR-P11 |
| UAT-C5 | P1 | Open the `Applications` tab with one recorded application, then again with a fresh account. | One card per application with title, company and status; on an empty account `You have not applied yet` + `Find internships`. | BR-T2 |
| UAT-C6 | P2 | Tap the application. | `Application Detail` with `Status tracker`, `Step 1 of 4 (25% completed)`, the `Active step` chip on `Submitted`, the submitted date and a view-only CV (no `Replace CV`). | BR-T1, BR-T6, BR-T7 |
| UAT-C7 | P2 | Tap `Withdraw application`, choose `Cancel`, then repeat and choose `Confirm`; finally tap `Undo`. | Dialog `Withdraw application?` with `Confirm` / `Cancel`; after confirming: badge `Withdrawn`, snackbar `Application withdrawn` + `Undo`; `Undo` restores the previous status. | BR-T3, BR-T4, BR-T5 |
| UAT-C8 | P3 | Return to the internship of the recorded application, then check it in Search Results. | Detail shows `You applied on …` and `View application` instead of `Apply now`; the card shows the `Applied` badge. Starting a duplicate application is impossible. | BR-P2 |
| UAT-C9 | P3 | From `Apply by email`, tap `Validate CV`. Try the same with airplane mode on. | `Checking your CV…` then `Your CV looks good` (snackbar `Your CV passed the check.`), or a plain-language reason with `Update CV` / `Retry`; offline says `We could not check your CV`, never “invalid”. | BR-P9 |
| UAT-C10 | P3 | Open `Apply by email`, then press Back without sending. Check `Applications`. | Return to Internship Detail; nothing new is recorded. | BR-P12 |

### Flow D — Profile and CV library

| ID | Pri | Task | Expected result | BR |
|---|---|---|---|---|
| UAT-D1 | P1 | Profile → `Edit profile`. Change `Full name` and `Headline`, tap `Save changes`. Then reopen and press Back after typing. | Profile header shows the new name and headline; leaving with unsaved edits asks `Discard your changes?` with `Cancel`. | — |
| UAT-D2 | P2 | Profile → `CV library` → `Add CV`. Upload a PDF, open the `CV actions` menu, choose `Set as default`, then `Remove`. | Sheet `Add CV` / `Add a CV to your library`; the new file gets `Default for applications`; the menu offers `View`, `Set as default`, `Remove`; removing asks `Remove this CV?` and the item disappears. | BR-C1, BR-C2, BR-C3, BR-C4 |
| UAT-D3 | P2 | Edit `Technical skills` and `Internship preferences`. | Changes appear as tags on Profile and survive reopening the app. | BR-C3 |
| UAT-D4 | P2 | Sign out, sign in again with the same account. | Profile, CV library and default, saved internships and applications are restored; no other user's data appears. | BR-A3, BR-A4 |

## 10. Traceability

| UAT | Business rules | Related automated test |
|---|---|---|
| A1–A3 | BR-A1 – BR-A3 | ARTEMIS TC-01, TC-14; `test/app/router_test.dart` |
| B1–B7 | BR-D1 – BR-D6, BR-S1 – BR-S4 | ARTEMIS TC-03, TC-04, TC-05, TC-08; Search / Saved widget tests |
| C1–C10 | BR-P1 – BR-P12, BR-T1 – BR-T7 | ARTEMIS TC-06, TC-07, TC-09, TC-18, TC-19; compose / application tests |
| D1–D4 | BR-C1 – BR-C5, BR-A4 | Profile and CV-library tests; rules tests |

## 11. Records to fill in

| File | Content |
|---|---|
| [`records/uat-results.md`](records/uat-results.md) | One section per session: environment, per-scenario result, time on task, defects, questionnaire scores, sign-off |
| [`../evidence/uat/`](../evidence/uat/README.md) | Screen recordings, screenshots of failures, photos/scans of the paper questionnaire |

Nothing in either file may be pre-filled with a pass. A session that did not happen stays `Not run`.
