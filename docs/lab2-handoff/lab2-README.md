# Internship Finder — PRM323 Lab 2

AI-assisted UI/UX design for a mobile internship app: **Google Stitch → Figma**. Group 3.

Internship Finder helps university IT and Software Engineering students discover internships that match their skills, save the ones they like, apply with a stored CV and track every application in one place.

## Quick links

| Artifact | Link |
|---|---|
| Figma file (view access) | https://www.figma.com/design/UQveNSgQNYbuZyaNMa57FQ/Internship-Finder---Design-System |
| Interactive prototype (Flow 1 start) | https://www.figma.com/proto/UQveNSgQNYbuZyaNMa57FQ/Internship-Finder---Design-System?page-id=132%3A494&node-id=456-1467&starting-point-node-id=456%3A1467&scaling=scale-down |
| GitHub repository | https://github.com/lamtailoi2/prm323_lab2 |

Figma pages, in order:

| Page | Content | Direct link |
|---|---|---|
| 01 User Flow | Three flow diagrams with happy path, alternative and error branches | [open](https://www.figma.com/design/UQveNSgQNYbuZyaNMa57FQ/Internship-Finder---Design-System?node-id=130-228) |
| 02 Wireframe | Low-fidelity layout of every screen and state | [open](https://www.figma.com/design/UQveNSgQNYbuZyaNMa57FQ/Internship-Finder---Design-System?node-id=130-229) |
| 03 Final UI | Final screens with loading, empty, error and success states; responsive check at 360 / 412 dp | [open](https://www.figma.com/design/UQveNSgQNYbuZyaNMa57FQ/Internship-Finder---Design-System?node-id=0-1) |
| 04 Design System | Color, typography, spacing, radius and elevation tokens | [open](https://www.figma.com/design/UQveNSgQNYbuZyaNMa57FQ/Internship-Finder---Design-System?node-id=1-4) |
| 05 Components | Component library (31 components, 96 variants) | [open](https://www.figma.com/design/UQveNSgQNYbuZyaNMa57FQ/Internship-Finder---Design-System?node-id=1-5) |
| 06 Prototype | Clickable prototype of the three flows (12 starting points) | [open](https://www.figma.com/design/UQveNSgQNYbuZyaNMa57FQ/Internship-Finder---Design-System?node-id=132-494) |

## Project overview

| Item | Description |
|---|---|
| Product | Internship Finder, a mobile app (Android, 360–412 dp wide) |
| Target users | Third- and fourth-year IT / Software Engineering students looking for an internship |
| Persona | **Minh Nguyen, 21**, third-year Software Engineering student in Ho Chi Minh City. Searches in short mobile sessions of 2 to 5 minutes, reads English job descriptions slowly, applies to several companies and needs to know where each application stands. Details: [`ux/persona.md`](ux/persona.md) |
| Problem statement | IT students in their third and fourth year need a fast way to find, save and track internship applications that match their skills, because listings are scattered across many sources and they lose track of where they have applied. |
| Success criterion | Find an internship by skill and work mode in under 30 seconds, and submit an application from Internship Detail in under 2 minutes with a stored CV. |

## Team

| Member | Screens | Additional responsibility |
|---|---|---|
| Phạm Nguyễn Hoàng Anh | Internship Detail, Apply Internship | Flow 1: Search & Apply, `README.md` |
| Nguyễn Tấn Kim Hảo | Saved Internships, My Applications | Flow 2: Save Internship |
| Lâm Tài Lợi | Home, Profile | `DESIGN.md`, Design System, merging the Figma file |
| Mai Duy Lập | Search, Filter | `persona.md`, problem statement, success metric |
| Nguyễn Minh Tú | CV Upload, Application Detail / Success | Flow 3: Track Application, error and recovery states |

Every member wrote the Stitch prompts for their own screens and refined them over several rounds (see the AI log).

## Design process

| Step | What we did | Evidence |
|---|---|---|
| Analyze | Persona, problem statement, success criterion, information architecture and three user flows | [`ux/persona.md`](ux/persona.md), [`ux/user-flow.md`](ux/user-flow.md), Figma 01 |
| Generate | Generated the first version of each screen in Google Stitch from verbatim prompts that state persona, task, mobile platform, constraints and style. `DESIGN.md`, `persona.md` and `user-flow.md` were given to Stitch as context | [`ai/ai-design-log.md`](ai/ai-design-log.md), [`design/DESIGN.md`](design/DESIGN.md) |
| Critique | AI critique in every round, referencing Nielsen heuristics, accessibility and the persona | [`ai/ai-design-log.md`](ai/ai-design-log.md) |
| Refine | 28 refinement rounds across 10 screens with before / after screenshots and an Accept or Modify decision for every output | [`ai/ai-design-log.md`](ai/ai-design-log.md), [`ai/screenshots/`](ai/screenshots/), [`design/design-decisions.md`](design/design-decisions.md) |
| Prototype | Wireframes, final UI, design system, components and a clickable prototype in Figma | Figma 02–06 |
| Handoff | Screen specifications and the token → Flutter and component → widget mappings below | [`design/screen-spec.md`](design/screen-spec.md), [Flutter handoff](#flutter-handoff) |

## Repository structure

```
prm323_lab2/
├── README.md                  # This file: overview, links and artifact index
├── ux/
│   ├── persona.md             # Persona, journey map, problem statement, success criterion
│   └── user-flow.md           # Information architecture, 3 user flows, flow-to-screen mapping, error and recovery summary
├── design/
│   ├── DESIGN.md              # Design system rules and tokens (source of truth for Stitch and Figma)
│   ├── design-decisions.md    # Key design decisions with reasons and accessibility checklist
│   └── screen-spec.md         # Purpose, content, actions, states and design intent of each screen
├── ai/
│   ├── ai-design-log.md       # Verbatim prompts, outputs, AI critique, refinement prompts and decisions per round
│   └── screenshots/           # Stitch outputs (r0, r1, r2, … final) referenced by the AI log
├── handoff/                   # Flutter handoff (flutter-handoff.md, to be added)
└── assets/
    ├── figma/                 # Reserved for exported Figma assets (empty)
    └── stitch/                # Reserved for exported Stitch assets (empty)
```

## Screens

Eleven screens. Overlays and states are not counted as separate screens.

| # | Screen | Level | States and overlays in Figma |
|---|---|---|---|
| 1 | Home | Top-level tab | Loading, populated, error |
| 2 | Search | Top-level tab | Default, Filter bottom sheet |
| 3 | Search Results | Nested under Search | Loading, populated, empty, applied badge, saved card, Filter bottom sheet |
| 4 | Internship Detail | Nested | Loading, populated, expanded, saved (+ snackbar), save failed, already applied, error |
| 5 | Saved Internships | Top-level tab | Loading, populated, empty, removed + Undo |
| 6 | Application Form | Nested under Internship Detail | Prefilled, empty profile, validation error, CV uploading, CV upload failed, Replace CV sheet, University picker, Document viewer |
| 7 | Application Review | Nested under Application Form | Populated, submitting |
| 8 | Application Success | End of the apply flow | Success |
| 9 | My Applications | Top-level tab | Loading, populated, withdrawn (+ Undo), empty, error |
| 10 | Application Detail | Nested under My Applications | Loading, submitted, under review, withdraw dialog, withdrawn, error, Document viewer (view only) |
| 11 | Profile | Top-level tab | Populated, Edit Profile, validation error |

## User flows and prototype

| Flow | Goal | Branches (same names as the prototype starting points) |
|---|---|---|
| Flow 1 – Search & Apply | Find a suitable internship and submit an application | 1a CV upload error · 1b Empty profile · 1c Detail load error · 1d Already applied (no duplicate application) · 1e Save while browsing |
| Flow 2 – Save Internship | Save an internship and open it again later | 2a Unsave + Undo · 2b Empty saved list · 2c Save error + Retry |
| Flow 3 – Track Application | See the status of a submitted application | 3a No applications · 3b List load error · 3c Detail load error · 3d Withdraw + Undo |

Full diagrams and the flow-to-screen mapping: [`ux/user-flow.md`](ux/user-flow.md) and Figma page 01.

**How to run the prototype**

1. Open the [prototype link](https://www.figma.com/proto/UQveNSgQNYbuZyaNMa57FQ/Internship-Finder---Design-System?page-id=132%3A494&node-id=456-1467&starting-point-node-id=456%3A1467&scaling=scale-down). The device is **Android Compact**; screens are 390 × 868 so the bottom navigation is never cut off.
2. Pick a starting point from the flow list on the left: Flow 1, 1a, 1b, 1c, Flow 2, 2a, 2b, 2c, Flow 3, 3a, 3b, 3c (12 in total). Branches 1d, 1e and 3d are reached from inside Flow 1 and Flow 3.
3. The prototype uses variables (for example saved and applied state), so a saved or applied internship stays saved or applied when you come back to it. Snackbars hide after a few seconds and loading screens move on automatically.

## Design system

Figma page 04 holds the tokens and page 05 the components. Variables live in the collection **Internship Finder — DESIGN.md** (27 variables, Light mode); text and effect styles follow the same names.

| Token group | Values |
|---|---|
| Color | 13 semantic tokens (primary `#2563EB`, on-primary, primary-container, background `#F8FAFC`, surface, surface-variant, text primary `#0F172A`, text secondary `#475569`, border `#CBD5E1`, success `#15803D`, warning `#B45309`, error `#DC2626`, disabled `#94A3B8`) plus 4 helper colors for pressed, error container, disabled container and inverse surface |
| Typography | Inter, 8 text styles: `type/display` 28, `type/heading/large` 24, `type/heading/medium` 20, `type/title` 18, `type/body/medium` 16, `type/body/small` 14, `type/label/medium` 14, `type/caption` 12 |
| Spacing | 4 / 8 / 12 / 16 / 24 / 32 dp; 16 dp screen margins, 24 dp between sections |
| Radius | 8 (tags), 12 (buttons, fields), 16 (cards, dialogs, sheets), full (pills, avatars) |
| Elevation | `elevation/0` none, `elevation/1` cards, `elevation/2` dialogs and sheets |

**Components (31 components, 96 variants)** — all nine required groups are covered:

| Group | Components |
|---|---|
| Actions & messages | Button (primary / secondary / text, with pressed, disabled and loading states), Save Toggle, Filter Chip, Skill Tag, Badge, Application Status, Snackbar, Info Banner |
| Inputs | Text Field (default, focused, filled, error, disabled), Search Field, Text Area, Upload Dropzone, Bottom Sheet Option Row |
| Cards | Internship Card, Job Summary Card, CV File Card, Upload Progress Card, Match Card, Map Preview Card |
| Navigation & content | App Bar, Bottom Navigation, Progress Stepper, Meta Tile, Section Header, Bullet Item, Benefit Item, Review Row |
| Feedback states | Dialog, Loading, Empty State, Error State |

## AI workflow

- **Tool:** Google Stitch for generation and refinement; Figma for the final UI, design system and prototype.
- **Context given to Stitch:** `design/DESIGN.md`, `ux/persona.md`, `ux/user-flow.md`.
- **Log:** [`ai/ai-design-log.md`](ai/ai-design-log.md) covers 10 screens and 28 refinement rounds. Each round records the AI critique, the verbatim refinement prompt, before / after screenshots, the changes, the decision (Accept or Modify) and the reason. AI output that we removed, such as stock photos, invented statistics and an off-palette badge in Internship Detail, is explained in the reasons.
- **Screenshots:** [`ai/screenshots/`](ai/screenshots/), named `<screen>-r0.png`, `-r1.png`, … `-final.png`.

Example (Internship Detail): r0 → R1 "less reading" (page 33 % shorter) → R2 "location at a glance" (address became a map preview) → R3 "one consistent layout" (no truncated text, one palette, accepted as the base of the final UI).

## Accessibility and responsive layout

| Check | Result |
|---|---|
| Text contrast (WCAG 2.1 AA, ≥ 4.5:1) | Text primary 17.85:1 · text secondary 7.58:1 · white on primary button 5.17:1 · primary link 5.17:1 · success 5.02:1 · warning 5.02:1 · error 4.83:1 |
| Touch targets ≥ 48 × 48 dp | Buttons 48 dp high (Save 97 × 48, Apply now 249 × 48), icon buttons 48 × 48, bottom navigation items 78 × 60 |
| Text size | Body text 14–16 sp; 12 sp only for short labels and captions |
| Not color alone | Status badges use icon + label; field errors use a red border, an icon and a message; matched skills use a check icon |
| Responsive | Internship Detail checked at 360 dp and 412 dp on Figma page 03 (section "Responsive check · 360 / 412 dp"): text wraps and nothing is clipped |

## Flutter handoff

Per-screen handoff (layout, components, states, interactions, navigation, UI constraints) will be added in `handoff/flutter-handoff.md`. The screen content and states are already defined in [`design/screen-spec.md`](design/screen-spec.md). Flutter code is not part of Lab 2.

**Token → Flutter**

| Design token | Flutter |
|---|---|
| `color/primary` | `ColorScheme.primary` |
| `color/on-primary` | `ColorScheme.onPrimary` |
| `color/text/primary` | `ColorScheme.onSurface` |
| `color/text/secondary` | `ColorScheme.onSurfaceVariant` |
| `color/error` | `ColorScheme.error` |
| `color/success`, `color/warning` | `ThemeExtension` for status colors |
| `type/body/medium` (Inter 16) | `TextTheme.bodyLarge` |
| `spacing/16` | `EdgeInsets.all(16)` |
| `radius/12` | `BorderRadius.circular(12)` |
| `elevation/1` | `BoxShadow(offset: Offset(0, 1), blurRadius: 3)` |

**Component → widget**

| Figma component | Flutter widget |
|---|---|
| Button | `FilledButton`, `OutlinedButton`, `TextButton` |
| Text Field | `TextFormField` with `InputDecoration` |
| Search Field | `SearchBar` |
| Filter Chip | `FilterChip` |
| Internship Card | `Card` + `InkWell` |
| App Bar | `AppBar` |
| Bottom Navigation | `NavigationBar` |
| Dialog | `AlertDialog` with `showDialog` |
| Snackbar | `SnackBar` + `SnackBarAction` |
| Bottom sheets (Filters, Replace CV, University picker) | `showModalBottomSheet` |
| Loading / Empty / Error | Skeleton placeholders, `CircularProgressIndicator`, a shared state view widget |

## Known limitations

- The persona is based on team assumptions and published sources; the quick interviews in `ux/persona.md` section 12 still need to be run.
- Detail screens in the prototype use one data set (FPT Software, Flutter Developer Intern). Only the FPT items, and the Data Analyst card in My Applications, open them; bookmarks on other cards are not wired.
- Text field borders (`#CBD5E1` on white) are below 3:1; every field keeps a visible label above it, so the field is still identifiable.
