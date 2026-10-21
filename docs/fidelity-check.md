# Fidelity check

Compares each implemented screen with the Lab 2 design (Figma page 03 Final UI, `screen-spec.md`, `design-system.md`). Fill in one section per screen when its pull request is opened; reviewers check it before approving.

**Result values:** ✅ matches · ⚠️ differs (logged as DC-nn) · ❌ missing · n/a.

## Component library (initialization)

| Component (Figma 05) | Implementation | Result | Notes |
|---|---|---|---|
| Button (12) | `AppButton` + button themes | ✅ | Pressed opacity estimated (G-07) |
| Text Field (5) | `AppTextField` + `InputDecorationThemeData` | ✅ | |
| Search Field (2) | `AppSearchField` | ✅ | |
| Filter Chip (2) | `ChipThemeData` + `FilterChip` | ⚠️ | Selected label contrast 4.24:1 (G-19, DC-05 proposed) |
| Internship Card (3) | `InternshipCard`, `AppTag` | ✅ | Inner gaps estimated (G-07); allowance format open (G-17) |
| App Bar (2) | `AppTopBar.main` / `.back` | ✅ | Main title style estimated (G-07) |
| Bottom Navigation (5) | `AppShell` + `NavigationBarThemeData` | ✅ | No overflow at 360 / 412 dp (widget test) |
| Dialog (3) | `showAppDialog` / `AppDialog` | ✅ | |
| Loading (2) | `StateView.loading`, `InternshipCardSkeleton` | ✅ | |
| Empty State (3) | `StateView.empty` | ✅ | |
| Error State (1) | `StateView.error` | ✅ | Icon size estimated (G-07) |
| Application Status (5) | `StatusBadge` | ⚠️ | Rejected contrast 4.41:1 (G-19, DC-04 proposed); Withdrawn missing (G-18) |

## Screen template

Copy this block for each screen.

```markdown
### <Screen name>  (PR #__, owner: __)

Figma frame: <link>  ·  Spec: screen-spec.md › <Screen>

| Check | 360 dp | 412 dp | Notes |
|---|---|---|---|
| Layout and visual order match Figma | | | |
| Tokens only (no raw colors / sizes / paddings) | | | |
| Shared components reused (card, buttons, states) | | | |
| One primary action | | | |
| Loading state | | | |
| Empty state | | | |
| Error state + Retry | | | |
| Success / validation states (if any) | | | |
| Touch targets ≥ 48 dp (`androidTapTargetGuideline`) | | | |
| Text ≥ 14 sp body, no clipping / overflow | | | |
| Status / selection not by color alone | | | |
| Copy matches the design (labels, empty / error text) | | | |
| Screenshot (app) next to the Figma frame | | | |

Differences: DC-__ (link) or "none".
```

## Screens

| # | Screen | Owner | PR | Status |
|---|---|---|---|---|
| 1 | Home | | | Not started (placeholder) |
| 2 | Search | | | Not started (placeholder) |
| 3 | Search Results | | | Not started |
| 4 | Internship Detail | | | Not started |
| 5 | Saved Internships | | | Not started (placeholder) |
| 6 | Application Form | | | Not started |
| 7 | Application Review | | | Not started |
| 8 | Application Success | | | Not started |
| 9 | My Applications | | | Not started (placeholder) |
| 10 | Application Detail | | | Not started |
| 11 | Profile | | | Not started (placeholder) |
| — | Login (Lab 3) | | | Interim (DC-01) |
| — | Notification Center (Lab 3) | | | Not designed (G-04) |
| — | PDF export (Lab 3) | | | Not designed (G-05) |
