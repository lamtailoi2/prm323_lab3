# MobAI end-to-end scenarios

The 10 end-to-end scenarios required for Lab 3. Each scenario **asserts a visible outcome**: a tap that succeeds is not a pass on its own.

The MobAI script format was not part of the handoff, so the specs below are tool-neutral (preconditions → steps → visible assertions). Translate each one into MobAI's format in `mobai_tests/<nn>-<name>.*` when the screens exist, and record every run in [`../docs/test-report.md`](../docs/test-report.md).

## Conventions for testability

- Assert on **visible text from the design** (labels, empty/error copy, status labels). Copy changes must update these specs.
- Icon-only buttons need a `tooltip` (it becomes the accessibility label), e.g. `Save`, `Remove from saved`, `Filters`, `Clear search`, `Back`.
- Use a dedicated **test Google account**. Never store its password in this repository.
- Seed data must exist before the run (handoff-gaps G-14). Record the data set version in the run log.

## Scenarios

Status: **Spec** (written, screens not built) · **Ready** (runnable) · **Passing** · **Failing**.

| # | Scenario | Lab 2 source | Status |
|---|---|---|---|
| 01 | Google Sign-In | Lab 3 | Spec |
| 02 | Flow 1: Search & Apply | user-flow.md Flow 1 | Spec |
| 03 | Flow 2: Save Internship | user-flow.md Flow 2 | Spec |
| 04 | Flow 3: Track Application | user-flow.md Flow 3 | Spec |
| 05 | Error and recovery | Flow 1c / 3b (network) | Spec |
| 06 | Create, edit and delete the main entity | Lab 3 (entity: G-08) | Blocked by G-08 |
| 07 | Top-level navigation | DESIGN.md §9 | Ready (placeholders) |
| 08 | Profile and Remote Config | Lab 3 (G-06, G-11) | Spec |
| 09 | PDF export and upload | Lab 3 (G-05, G-12) | Spec |
| 10 | Sign-out | Lab 3 | Ready |

---

### 01: Google Sign-In
- **Pre:** app installed, signed out, test Google account on the device.
- **Steps:** launch → tap `Continue with Google` → choose the test account.
- **Assert:** the bottom navigation is visible with `Home` selected; the Home screen title is visible; `Continue with Google` is gone.

### 02: Flow 1, Search & Apply
- **Pre:** signed in; profile has name, email, phone and a CV; at least one active listing matching "Flutter" + Remote that the user has not applied to.
- **Steps:** Home → tap the search field → type `Flutter` → open Filters → select `Remote` → `Show … results` → open the first card → `Apply now` → check the prefilled form → `Continue to review` → `Submit application`.
- **Assert:** Application Success shows the internship title and company; `View application` opens Application Detail with status `Submitted`; opening the same internship again shows `You applied on …` instead of `Apply now` (Flow 1d).

### 03: Flow 2, Save Internship
- **Pre:** signed in; Saved list empty.
- **Steps:** open an internship from Home → `Save` → tap `Saved` in the bottom navigation → open the saved card → back → unsave it → `Undo`.
- **Assert:** the snackbar `Saved to your list` appears; Saved shows the card with a filled bookmark; after unsave, `Removed from Saved` appears and the item is gone; after `Undo` the item is back.

### 04: Flow 3, Track Application
- **Pre:** signed in; at least one submitted application.
- **Steps:** tap `Applications` → open the application.
- **Assert:** the list shows position, company, submitted date and a status badge with label + icon; the detail shows the same status label and the submitted CV file name.

### 05: Error and recovery
- **Pre:** signed in; network can be toggled (airplane mode).
- **Steps:** airplane mode on → open My Applications (or an Internship Detail) → airplane mode off → tap `Retry`.
- **Assert:** the error state is visible with a plain-language message and `Retry`; after `Retry`, the list (or detail) content is visible and the error state is gone.

### 06: Create, edit and delete the main entity
- **Blocked by:** handoff-gaps G-08 (which entity, and which edit/delete UI).
- **Assert (once decided):** the created item is visible in its list; the edited value is visible after reopening; the deleted item is no longer visible after a refresh.

### 07: Top-level navigation
- **Pre:** signed in.
- **Steps:** tap `Search`, `Saved`, `Applications`, `Profile`, `Home` in turn.
- **Assert:** each tap shows that destination's screen title, the tapped item is shown as selected, and all five items (icon + label) stay visible.

### 08: Profile and Remote Config
- **Pre:** signed in; Remote Config parameters published (G-11) with values different from the defaults.
- **Steps:** open Profile → open the configuration / diagnostics section (G-06).
- **Assert:** the current parameter values and their source (`remote`) are visible, and the behavior they control is visible in the app (e.g. the number of recommended cards on Home).

### 09: PDF export and upload
- **Pre:** signed in; at least one application exists; storage configured (G-12).
- **Steps:** trigger the export (G-05) → wait for upload → tap the open action.
- **Assert:** a success message with the file name is visible; the report appears in the reports list with its creation date; the PDF opens and shows the user's real data.

### 10: Sign-out
- **Pre:** signed in.
- **Steps:** Profile → `Sign out`.
- **Assert:** the Login screen with `Continue with Google` is visible; pressing back does not return to signed-in screens; relaunching the app shows Login.

## Scenario template

```markdown
### NN: <name>
- **Pre:** <account state, data, device settings>
- **Steps:** <one line per user action, using visible labels>
- **Assert:** <what is visible on screen at the end; at least one assertion per step that changes state>
- **Data cleanup:** <how to reset for the next run>
```
