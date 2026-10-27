# Internly Design System and Components (Flutter reference)

This is the single Flutter-facing reference for Internly's visual language. It consolidates the Lab 2 design sources and records how each token and component maps to code. When this file and the code disagree, fix the code or record the deviation in [`design-traceability.md`](../design-traceability.md) §4 (and update Figma). Do not quietly diverge.

## Sources and precedence

| # | Source | What it defines | Location |
|---|---|---|---|
| 1 | `DESIGN.md` (Lab 2) | Tokens, component rules, accessibility rules. **Source of truth.** | [`DESIGN.md`](DESIGN.md) |
| 2 | Figma page **04 Design System** | Token specimens, the "Stitch Design Contract", icon family | Screenshot shared by the team on 2026-10-21 (not stored in the repo yet, see G-16) |
| 3 | Figma page **05 Components**, "Editable specimen library" | 12 native component sets, 45 specimens with states | Screenshot shared by the team on 2026-10-21 (not stored in the repo yet, see G-16) |
| 4 | Lab 2 README "Flutter handoff" | Token → Flutter and component → widget tables, contrast results | [`lab2-README.md`](lab2-README.md) |
| 5 | Lab 2 AI design log prompts | Pixel details that exist nowhere else (e.g. text field label and focus specs) | Lab 2 repo, `ai/ai-design-log.md` |

If two sources conflict, the higher row wins. Figma (rows 2–3) is the final UI, so it overrides Stitch screenshots and AI-log prompts. Values read from screenshots instead of Figma inspect mode are marked **(verify)** and tracked in [`handoff-gaps.md`](../records/handoff-gaps.md).

Figma file: <https://www.figma.com/design/UQveNSgQNYbuZyaNMa57FQ/Internship-Finder---Design-System> (page 04 `node-id=1-4`, page 05 `node-id=1-5`).

---

## 1. Foundations

Code lives in [`lib/theme/`](../../lib/theme/). Screens read styles through `Theme.of(context)` or the token classes. They never use raw hex values, font sizes, or paddings.

### 1.1 Color: 13 semantic tokens

Rule (Figma 04): *"Use roles, not one-off colors. Status always includes text and a meaningful icon; never use color alone."*

| Figma token | Hex | Usage | Dart constant | `ColorScheme` slot | Figma ↔ code |
|---|---|---|---|---|---|
| `color/primary` | `#2563EB` | Primary CTA, selected navigation, focus, active chips | `AppColors.primary` | `primary`, `secondary`, `onPrimaryContainer`, `onSecondaryContainer` | ✅ match |
| `color/on-primary` | `#FFFFFF` | Text and icons on primary | `AppColors.onPrimary` | `onPrimary`, `onSecondary`, `onError` | ✅ match |
| `color/primary-container` | `#DBEAFE` | Selected chips, low-emphasis brand, info surfaces | `AppColors.primaryContainer` | `primaryContainer`, `secondaryContainer` | ✅ match |
| `color/background` | `#F8FAFC` | Main app background | `AppColors.background` | `ThemeData.scaffoldBackgroundColor` | ✅ match |
| `color/surface` | `#FFFFFF` | Cards, app bars, dialogs, inputs, bottom navigation | `AppColors.surface` | `surface`, `surfaceContainer*` (except highest) | ✅ match |
| `color/surface-variant` | `#F1F5F9` | Secondary surfaces, chips, skeletons, status badges, disabled fills | `AppColors.surfaceVariant` | `surfaceContainerHighest` | ✅ match |
| `color/text/primary` | `#0F172A` | Main text, headings, job titles, company names | `AppColors.textPrimary` | `onSurface`, `shadow` | ✅ match |
| `color/text/secondary` | `#475569` | Metadata, helper text, secondary labels | `AppColors.textSecondary` | `onSurfaceVariant` | ✅ match |
| `color/border` | `#CBD5E1` | Dividers, input borders, card outlines | `AppColors.border` | `outline`, `outlineVariant` | ✅ match |
| `color/success` | `#15803D` | Accepted status, success confirmation | `AppColors.success` | `AppStatusColors.success` (ThemeExtension) | ✅ match |
| `color/warning` | `#B45309` | Under-review status, caution messages | `AppColors.warning` | `AppStatusColors.warning` (ThemeExtension) | ✅ match |
| `color/error` | `#DC2626` | Errors, failed states, destructive actions | `AppColors.error` | `error` | ✅ match |
| `color/disabled` | `#94A3B8` | Disabled text, icons, controls | `AppColors.disabled` | `AppStatusColors.disabled` + button themes | ✅ match |

The Lab 2 README mentions **four helper colors** (pressed, error container, disabled container, inverse surface), but none of them has a documented value. Figma 05 resolves three of them by behavior, so no extra color is needed:

| Helper | Resolution | Source |
|---|---|---|
| pressed | Reduced emphasis of the existing color (`AppTheme.pressedOpacity = 0.7`, **verify**) | Figma 05 Button: *"Pressed uses reduced emphasis, not a new color."* |
| disabled container | `color/surface-variant` | Figma 05 disabled Button / Text Field specimens, AI log text-field spec |
| error container | Not used: status badges use `surface-variant` | Figma 05 Application Status: *"Use surfaceVariant, never invented semantic tints."* |
| inverse surface | Material default (`onSurface` = `#0F172A`), used by `SnackBar` | Open: G-07 |

### 1.2 Typography: Inter, 8 styles

Font: **Inter 4.1**, bundled in `assets/fonts/inter/` (weights 400/500/600/700, OFL licence) with a `Roboto` fallback. Rules: body text ≥ 14 sp; at most three sizes on a typical screen; job titles stronger than metadata.

| Figma style | Size / weight / line height | Usage (Figma 04) | `AppTypography` | `TextTheme` slot | Figma ↔ code |
|---|---|---|---|---|---|
| `type/display` | 28 / 700 / 36 | Major welcome titles, sparingly | `display` | `headlineMedium` | ✅ |
| `type/heading/large` | 24 / 700 / 32 | Screen and job detail titles | `headingLarge` | `headlineSmall` | ✅ |
| `type/heading/medium` | 20 / 600 / 28 | Section and grouped content headings | `headingMedium` | `titleLarge` | ✅ |
| `type/title` | 18 / 600 / 24 | Card, dialog and profile section titles | `title` | `titleMedium` | ✅ |
| `type/body/medium` | 16 / 400 / 24 | Main copy, descriptions, form inputs | `body` | `bodyLarge` (README mapping) | ✅ |
| `type/body/small` | 14 / 400 / 20 | Metadata, helper text, company details | `bodySmall` | `bodyMedium` | ✅ |
| `type/label/medium` | 14 / 600 / 20 | Buttons, chips, form labels, status labels | `label` | `labelLarge`, `titleSmall` | ✅ |
| `type/caption` | 12 / 500 / 16 | Dates, compact metadata, **navigation labels** | `caption` | `bodySmall`, `labelMedium`, `labelSmall` | ✅ |

> Naming trap: the token `type/body/small` maps to Flutter's `bodyMedium`, and `type/caption` maps to Flutter's `bodySmall`. Prefer `AppTypography.<token>` in code reviews when the intent matters.

### 1.3 Spacing: 4–32 dp

Rule (Figma 04): *"16 dp screen margins and card gaps · 12–16 dp internal padding · 24 dp major sections · 8 dp related text."*

| Token | Value | `AppSpacing` | Semantic alias |
|---|---|---|---|
| `spacing/4` | 4 | `s4` | — |
| `spacing/8` | 8 | `s8` | `related` |
| `spacing/12` | 12 | `s12` | — |
| `spacing/16` | 16 | `s16` | `screenHorizontal`, `betweenCards` |
| `spacing/24` | 24 | `s24` | `section` |
| `spacing/32` | 32 | `s32` | — |

### 1.4 Radius

Rule (Figma 04): *"Apply the same corner recipe across each family. Do not introduce additional radius values."*

| Token | Value | Components | `AppRadii` |
|---|---|---|---|
| `radius/8` | 8 | Small chips, badges, tags | `small`, `smallAll` |
| `radius/12` | 12 | Buttons, fields, filter chips | `medium`, `mediumAll` |
| `radius/16` | 16 | Cards, dialogs, bottom sheets | `large`, `largeAll` |
| `radius/full` | 999 | Pills, circular actions, avatars | `full`, `fullAll` |

### 1.5 Elevation

Rule (Figma 04): *"Separation before shadow. Prefer borders and background contrast. Reserve elevation/2 for temporary surfaces above the screen."*

| Token | Shadow | Usage | `AppElevation` | Figma ↔ code |
|---|---|---|---|---|
| `elevation/0` | none | Default surfaces, forms, flat lists | `level0` | ✅ |
| `elevation/1` | `0 1 3 rgba(15,23,42,0.08)` | Cards only when separation is needed | `level1` (`0x14` alpha = 0.08) | ✅ |
| `elevation/2` | `0 8 24 rgba(15,23,42,0.12)` | Dialogs, overlays, bottom sheets | `level2` (`0x1F` alpha = 0.12) | ✅ token. `AppDialog` draws `level2` exactly; plain `AlertDialog` and bottom sheets still use Material's elevation shadow (G-07) |

### 1.6 Iconography

**Material Symbols Rounded, Regular (weight 400, fill 0), 20 dp or 24 dp. One consistent family.** (Figma 04 "Stitch Design Contract"). In code: `package:material_symbols_icons`, using the `Symbols.<name>_rounded` constants. `AppSizes.iconSmall` = 20 and `AppSizes.icon` = 24. Use `Icon(..., fill: 1)` only where a filled state is designed (the saved bookmark).

Icons used by the components below: `home`, `search`, `bookmark`, `description` (Applications), `person`, `tune` (filter), `close` (clear), `notifications`, `arrow_back`, `location_on`, `work`, `send`, `hourglass_top`, `event`, `check_circle`, `cancel`, `wifi_off`, `error`. Confirm exact glyph names in Figma when building each component.

### 1.7 Layout and accessibility

| Rule | Value | Code |
|---|---|---|
| Base viewport | 360 × 800 dp | `AppSizes.baseWidth` |
| Responsive check | 412 dp | `AppSizes.responsiveCheckWidth`; widget tests render at both widths |
| Touch target | ≥ 48 × 48 dp | `AppSizes.minTouchTarget`; `MaterialTapTargetSize.padded`; button/icon-button minimum sizes |
| Body text | ≥ 14 sp | Typography tokens |
| Text contrast | ≥ 4.5:1 (normal), ≥ 3:1 (large text, controls) | See §3 for computed results |
| Meaning | Never color alone: every status has label + icon; selection has a check | Component specs below |

---

## 2. Components (Figma page 05)

Page 05 shows **12 native component sets / 45 specimens**. The Lab 2 README lists 31 components; the other 19 are not on page 05 and are listed in §2.13.

Status legend: **Themed** = done through `ThemeData`, no custom widget needed · **Built** = custom widget in `lib/` · **Planned** = to be built in the feature task named.

### 2.1 Button: 12 specimens · Built (`AppButton`)

*"One primary action per screen. All variants use radius12 and a 48 dp minimum height. Pressed uses reduced emphasis, not a new color."*

| Variant | Default | Pressed | Disabled | Loading | Flutter |
|---|---|---|---|---|---|
| Primary | `primary` fill, `onPrimary` label | fill at reduced opacity | `surfaceVariant` fill, `disabled` label | default look + spinner + label | `FilledButton` |
| Secondary | `surface` fill, `primary` 1 px border + label | border and label at reduced opacity | `surfaceVariant` fill, `border` outline, `disabled` label | default look + spinner + label | `OutlinedButton` |
| Text | transparent fill, `primary` label | label at reduced opacity | transparent fill, `disabled` label | default look + spinner + label | `TextButton` |

- Label `type/label/medium`, radius 12, min height 48, no ripple (`NoSplash`, transparent overlay).
- `AppButton(isLoading: true)` blocks taps and keeps the default colors. Screen readers hear "<label>, loading".
- Labels must be specific: `Apply now`, not `Submit`. Use `expand: true` for the dominant full-width action.

### 2.2 Text Field: 5 specimens · Built (`AppTextField`) + Themed (`InputDecorationThemeData`)

*"Labels persist in every state. Input height ≥ 48 dp; helper text remains readable. Focus uses primary; errors include an explicit message."*

| State | Spec | Theme |
|---|---|---|
| Default | Label above the field (`label`, `textPrimary`), placeholder (`body`, `textSecondary`), helper below (`bodySmall`, `textSecondary`), 1 px `border`, radius 12, white | ✅ |
| Focused | 2 px `primary` border | ✅ |
| Filled | Value `body` / `textPrimary`; label stays | ✅ |
| Error | `error` border, error icon inside on the right, `error` message below | ✅ border/message; icon added by `AppTextField` |
| Disabled | `surfaceVariant` fill, label and helper in `disabled` | ✅ fill; label color by `AppTextField` |

The label sits **above** the field, so `AppTextField` renders it as a separate `Text`. Do not use `InputDecoration.labelText` (floating label). Validation belongs to the ViewModel: pass the message as `errorText` (helpers in `core/utils/validators.dart`).

### 2.3 Search Field: 2 specimens · Built (`AppSearchField`)

*"360 dp width. Long placeholder wraps without truncation; the input grows with it. Clear and filter actions have 48 × 48 dp targets."* Leading `search` icon; placeholder `Search internships, companies, or skills`; trailing `tune` filter action; `close` clear action appears when text is entered. Radius 12, white, 1 px border.

### 2.4 Filter Chip: 2 specimens · Themed (`ChipThemeData`)

*"Use for work mode, skills, location or application status. Selection includes a check; both states retain a 48 dp touch target."* Unselected: `surfaceVariant` / `textSecondary`. Selected: `primaryContainer` / `primary` + check. Radius 12. Use Flutter `FilterChip` directly. ⚠️ The selected label contrast fails AA (§3).

### 2.5 Internship Card: 3 specimens · Built (`InternshipCard`, tags via `AppTag`)

*"Reuse this same card on Home, Search Results and Saved. 328 dp content at 360 dp; radius16, padding16, title18, metadata14, save target48."*

- Content order: company logo (40 dp, `AppSizes.companyLogo`, neutral fallback) + job title (`title`, max 2 lines) + save action (top right) → company (`bodySmall`) → location + work mode with icons (`bodySmall`) → skill tags (`surfaceVariant`, radius 8) → allowance (emphasised) → posted date (`caption`).
- States: Default · Pressed (reduced emphasis) · Saved (`bookmark` filled, `primary`).
- Card surface comes from `CardThemeData`: white, 1 px `border`, radius 16, elevation 0.
- The widget takes display-ready strings (no data model), plus an optional `badge` slot for `Applied` (Flow 2c). Inner gaps (4/8 dp) and the tag text style are **verify**.
- ⚠️ Figma sample data shows `$1,200/month` and "San Francisco", but the Lab 2 AI log standardised allowances to **VND per month** for Vietnamese listings. Format allowance as VND (G-17).

### 2.6 App Bar: 2 specimens · Built (`AppTopBar`)

*"Use Main for top-level destinations and Back for details. Clean surface; back and optional actions each have a 48 dp target."*

| Variant | Spec | Code |
|---|---|---|
| Main | Title (`type/heading/large`, **verify**), optional actions (e.g. `notifications`) | `AppTopBar.main` |
| Back | `arrow_back` + title (`type/title`), optional action (e.g. `bookmark`) | `AppTopBar.back` |

Clean surface: no shadow and no bottom border. Figma overrides the 1 px border in the Stitch prompt.

### 2.7 Bottom Navigation: 5 specimens · Themed (`NavigationBarThemeData`) + `AppShell`

*"Always the same five destinations, with icon + label. Width 360; Applications keeps its full name. Selected primary; unselected textSecondary."*

Destinations and order: **Home** (`home`) · **Search** (`search`) · **Saved** (`bookmark`) · **Applications** (`description`) · **Profile** (`person`). No indicator pill. Labels `type/caption`. Height 60 dp (README: items 78 × 60). Hidden during Application Form / Review / Success (user-flow rule).

### 2.8 Dialog: 3 specimens · Built (`showAppDialog` / `AppDialog`)

*"Temporary surfaces only: radius16, elevation2, short title and 16 sp body. Keep one primary action and one secondary action, each ≥ 48 dp."* Actions are two equal-width buttons, Secondary on the left and Primary on the right:

| Variant | Example | Actions |
|---|---|---|
| Confirm | "Apply for this internship?" | `Cancel` · `Apply now` |
| Cancel | "Discard your changes?" | `Keep editing` · `Discard` |
| Error | "Application not sent" | `Cancel` · `Retry` |

### 2.9 Loading: 2 specimens · Built (`StateView.loading`, `InternshipCardSkeleton`, `SkeletonBox`)

*"Use card-shaped skeletons for lists, a labeled spinner for short waits. Never replace content with a blank screen."* Spinner: 20 dp indicator + label (`bodySmall`), e.g. `Loading internships`; the label is required in code. Skeleton: `surfaceVariant` blocks shaped like the Internship Card.

### 2.10 Empty State: 3 specimens · Built (`StateView.empty`)

*"A consistent 24 dp icon treatment, short explanation and one useful action. Keep tone professional, supportive and specific."*

| Screen | Icon | Title | Message | Action (Primary, full width) |
|---|---|---|---|---|
| Saved | `bookmark` | No saved internships yet | Save opportunities to compare them and apply when you are ready. | Search internships |
| Applications | `description` | You have not applied yet | Find an internship that fits your skills and start your first application. | Find internships |
| Search | `search` | No results found | Try different keywords or clear your filters to see more opportunities. | Clear filters |

### 2.11 Error State: 1 specimen · Built (`StateView.error`)

*"Explain the failure and likely cause in plain language. Pair a meaningful icon with the message and a 48 dp recovery action."* Example: `wifi_off` (error color) + "We could not load internships. Check your connection and try again." + full-width Primary `Retry`. There is no separate title. Icon size 32 dp (**verify**).

### 2.12 Application Status: 5 specimens · Built (generic `StatusBadge`; the status → icon/color mapping below belongs to the Applications feature)

*"Noninteractive badges: 14 sp label + meaningful 20 dp icon. Use surfaceVariant, never invented semantic tints. No color-only meaning."*

| Status | Icon | Label/icon color | Background |
|---|---|---|---|
| Submitted | `send` | `textSecondary` (neutral) | `surfaceVariant` |
| Under review | `hourglass_top` | `warning` | `surfaceVariant` |
| Interview | `event` | `primary` | `surfaceVariant` |
| Accepted | `check_circle` | `success` | `surfaceVariant` |
| Rejected | `cancel` | `error` | `surfaceVariant` |
| *Withdrawn* | *not on page 05* | *not specified* | — |

Radius 8 (badge family). ⚠️ **Withdrawn** (Flow 3d) has no specimen (G-18). ⚠️ The Rejected color pair fails AA (§3).

### 2.13 Components not on page 05

Listed in the Lab 2 README but missing from the page 05 screenshot. Their specs must be read from the Figma component library before each is built: Save Toggle, Skill Tag, Badge, Snackbar, Info Banner, Text Area, Upload Dropzone, Bottom Sheet Option Row, Job Summary Card, CV File Card, Upload Progress Card, Match Card, Map Preview Card, Progress Stepper, Meta Tile, Section Header, Bullet Item, Benefit Item, Review Row (G-16).

---

## 3. Contrast check (computed)

WCAG 2.1 ratios were computed from the token hex values on 2026-10-21. The Lab 2 README only reported pairs on white; Figma 05 adds colored text on `surfaceVariant` and `primaryContainer`.

| Foreground | on `surface` #FFF | on `background` #F8FAFC | on `surfaceVariant` #F1F5F9 | on `primaryContainer` #DBEAFE |
|---|---|---|---|---|
| textPrimary | 17.85 | 17.06 | 16.30 | 14.63 |
| textSecondary | 7.58 | 7.24 | 6.92 | 6.21 |
| primary | 5.17 | 4.94 | 4.72 | **4.24 ✗** |
| success | 5.02 | 4.79 | 4.58 | 4.11 |
| warning | 5.02 | 4.80 | 4.58 | 4.12 |
| error | 4.83 | 4.62 | **4.41 ✗** | 3.96 |
| disabled | 2.56 | 2.45 | 2.34 | 2.10 (exempt: disabled) |

Findings (pass mark 4.5:1, because 14 sp semibold is not "large text"):

- **A11Y-1:** *Rejected* badge (`error` on `surfaceVariant`) = **4.41:1**, which fails.
- **A11Y-2:** *Selected filter chip* label (`primary` on `primaryContainer`) = **4.24:1**, which fails. The check icon keeps meaning from being color-only, but the label is still below 4.5:1.
- **A11Y-3:** The input border (`border` on white) is 1.48:1, below 3:1 for UI components. Lab 2 already lists this as a known limitation (a visible label is always present).

These conflict with DESIGN.md §13 ("Normal text contrast must target at least 4.5:1"). The proposed fixes are logged in [`design-traceability.md`](../design-traceability.md) (DC-04, DC-05) as **proposed**. They need team approval before any token or component changes.

---

## 4. Usage rules for developers

1. Import tokens from `lib/theme/`. No `Color(0x…)`, `TextStyle(fontSize: …)` or `EdgeInsets` literals in screens (only `AppSpacing`).
2. Reuse before creating: `AppButton`, `AppTopBar`, `AppTextField`, `AppSearchField`, `InternshipCard`, `AppTag`, `StatusBadge`, `showAppDialog`, `StateView`, `InternshipCardSkeleton`, and the Material widgets themed by `AppTheme` (`FilterChip`, `NavigationBar`, …).
3. One Primary `AppButton` per screen.
4. Every list screen implements Loading (skeleton), Empty (`StateView.empty`) and Error (`StateView.error` + `Retry`).
5. Every status shows label + icon. Selection shows a check.
6. New component or variant → add it here, under the matching Figma set, before using it in a screen.
7. Check new screens at 360 dp and 412 dp (widget test) and fill in the verification checklist in [`design-traceability.md`](../design-traceability.md) §5.
