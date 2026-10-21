# Design change log

Every UI difference from the Lab 2 design (DESIGN.md, screen-spec, Figma) is recorded here **before or with** the pull request that introduces it. Changes that need team approval start as **Proposed** and are applied only after approval.

| Field | Meaning |
|---|---|
| ID | `DC-nn`, never reused |
| Status | Proposed · Approved · Applied · Rejected · Temporary (to be removed) |
| Reason | Why the Lab 2 design could not be followed as is (gap ID, accessibility rule, platform limit…) |

| ID | Date | Screen / component | Change | Reason | Status | PR / commit |
|---|---|---|---|---|---|---|
| DC-01 | 2026-10-21 | Login (new) | Interim Login screen: "Internly" title (`type/display`), one-line tagline, error row (icon + message), full-width Primary `Continue with Google` with loading state. Uses only existing tokens and components. | Lab 3 requires Google Sign-In; Lab 2 has no Login screen (G-03). | Temporary: the auth owner finalises it | init |
| DC-02 | 2026-10-21 | Home, Search, Saved, Applications, Profile | Placeholder screens (App Bar "Main" + empty state "… is not built yet") so the app shell, routing and auth can run before the features exist. | Initialization scaffolding. | Temporary: each feature owner replaces theirs | init |
| DC-03 | 2026-10-21 | Profile (placeholder) | Sign out shown as a full-width Secondary button. The final design puts "Sign Out" in the "Settings & Support" list (Stitch Profile final). | Lets the sign-in/sign-out loop be tested before Profile is built. | Temporary | init |
| DC-04 | 2026-10-21 | Application Status badge, "Rejected" | Proposal: keep the `error` icon but render the label in `textPrimary`, **or** use `surface` instead of `surfaceVariant` behind this badge (error on white = 4.83:1). | `error` on `surfaceVariant` = 4.41:1 < 4.5:1 (DESIGN.md §13; G-19). | Proposed | — |
| DC-05 | 2026-10-21 | Filter Chip, selected | Proposal: selected label in `textPrimary` (14.63:1) while keeping the `primaryContainer` fill and the primary check icon. | `primary` on `primaryContainer` = 4.24:1 < 4.5:1 (G-19). | Proposed | — |
| DC-06 | 2026-10-21 | App Bar, Bottom Navigation | Followed Figma page 05 over the Stitch prompt: no 1 px bottom border on the App Bar ("clean surface"), no indicator pill in the Bottom Navigation. | Source precedence: Figma final UI overrides Stitch output (design-system.md). | Applied | init |
| DC-07 | 2026-10-21 | Whole app (iOS) | iOS uses the same Material components and tokens as Android; no Cupertino adaptation. | Team asked for Android + iOS; Lab 2 only designed Android (G-15). | Applied | init |

## How to add an entry

1. Add a row with the next ID and status **Proposed**.
2. Link the gap ID or rule that makes the change necessary.
3. After approval, set **Approved**, implement, then set **Applied** with the PR link.
4. Update [`design-system.md`](lab2-handoff/design/design-system.md) if a token or component changed, and [`fidelity-check.md`](fidelity-check.md) for the affected screens.
