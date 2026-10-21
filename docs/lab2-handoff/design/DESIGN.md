# Internship Finder — Design Guidelines

## 1. Design Goals

Internship Finder should help university students quickly discover, compare, save, apply for, and track internship opportunities. The UI must feel modern, clean, professional, student-friendly, and trustworthy.

Main priorities:

| Priority | Guideline |
|---|---|
| Clarity | Users should immediately understand the screen purpose, available actions, and next step. |
| Fast task completion | Search, filter, save, apply, and track application status should require minimal effort. |
| Strong visual hierarchy | Job title, company, location, application status, and CTA must be easy to scan. |
| Low cognitive load | Use predictable layouts, short labels, readable cards, and clear grouping. |
| Professional appearance | The app should feel suitable for career, recruitment, and employer-related content. |

Avoid:

- Decorative UI that distracts from internship content.
- Dense screens with too many controls.
- Long unstructured paragraphs.
- Multiple primary buttons competing on the same screen.
- Inconsistent spacing, typography, colors, corner radius, or component styles.
- A visual style that feels like social media instead of a career product.

## 2. Target Platform

Internship Finder is a mobile-first application.

| Requirement | Value |
|---|---:|
| Base screen size | 360 x 800 dp |
| Responsive check width | 412 dp |
| Interaction model | Touch-first |
| Minimum touch target | 48 x 48 dp |
| Minimum body text size | 14sp |

The design should later be implementable in Flutter. Avoid visual effects or layouts that would require complex custom rendering without clear user value.

## 3. Visual Direction

The product should look like a modern mobile recruitment app with a light theme, clean surfaces, restrained color, and clear spacing.

Use:

- Light theme with white or near-white surfaces.
- Professional blue / blue-indigo brand color.
- Clean card-based presentation for internship listings and application items.
- Subtle shadows only when separation is needed.
- Rounded but professional components.
- Clear spacing between sections and cards.
- Minimal visual decoration, but not empty screens.

Do not use:

- Excessive gradients.
- Glassmorphism.
- Overly decorative illustrations.
- Neon colors.
- Inconsistent corner radius.
- Excessive shadows.
- Too many competing primary buttons.

## 4. Color System

Use semantic tokens. Do not create random one-off colors per screen.

| Token | Hex | Intended usage |
|---|---:|---|
| `color.primary` | `#2563EB` | Main brand color, primary CTA, selected navigation, focused inputs, active chips. |
| `color.onPrimary` | `#FFFFFF` | Text and icons on primary backgrounds. |
| `color.primaryContainer` | `#DBEAFE` | Selected chip background, low-emphasis brand highlight, info surfaces. |
| `color.background` | `#F8FAFC` | Main app background. |
| `color.surface` | `#FFFFFF` | Cards, app bars, dialogs, text fields, bottom navigation. |
| `color.surfaceVariant` | `#F1F5F9` | Secondary surfaces, chip backgrounds, skeleton loading blocks. |
| `color.textPrimary` | `#0F172A` | Main text, headings, job titles, company names. |
| `color.textSecondary` | `#475569` | Metadata, helper text, secondary labels. |
| `color.border` | `#CBD5E1` | Dividers, input borders, card outlines. |
| `color.success` | `#15803D` | Accepted status, success confirmation. |
| `color.warning` | `#B45309` | Pending or under-review status, caution messages. |
| `color.error` | `#DC2626` | Error messages, failed state, destructive actions. |
| `color.disabled` | `#94A3B8` | Disabled text, icons, and controls. |

Accessibility considerations:

- Normal text contrast should target at least WCAG 4.5:1.
- Large text and UI control boundaries should target at least 3:1 where applicable.
- Use `color.textPrimary` for important readable content.
- Use `color.textSecondary` only for secondary information, not critical labels.
- Do not communicate application status by color alone. Always include a visible text label.
- Keep color usage restrained so the primary action remains obvious.

## 5. Typography

Use `Inter` as the preferred font. If Inter is unavailable, use `Roboto`.

| Token | Size | Weight | Line height | Recommended usage |
|---|---:|---:|---:|---|
| `text.display` | 28sp | 700 | 36sp | Welcome screen and major hero title, used sparingly. |
| `text.heading1` | 24sp | 700 | 32sp | Main screen title, job detail title. |
| `text.heading2` | 20sp | 600 | 28sp | Section heading, grouped content heading. |
| `text.title` | 18sp | 600 | 24sp | Internship card title, dialog title, profile section title. |
| `text.body` | 16sp | 400 | 24sp | Main text, job description, form input text. |
| `text.bodySmall` | 14sp | 400 | 20sp | Metadata, helper text, company details. |
| `text.label` | 14sp | 600 | 20sp | Buttons, chips, tabs, form labels, status labels. |
| `text.caption` | 12sp | 500 | 16sp | Dates, compact badges, minor metadata. |

Typography rules:

- Use no more than three text sizes on a typical screen.
- Job titles should be visually stronger than metadata.
- Body text must not be smaller than 14sp.
- Long job descriptions should use clear section headings and readable line height.

## 6. Spacing System

Use a small consistent spacing scale.

| Token | Value |
|---|---:|
| `spacing.1` | 4dp |
| `spacing.2` | 8dp |
| `spacing.3` | 12dp |
| `spacing.4` | 16dp |
| `spacing.5` | 24dp |
| `spacing.6` | 32dp |

Usage rules:

- Use `spacing.4` / 16dp as the standard horizontal screen padding.
- Use `spacing.3` / 12dp or `spacing.4` / 16dp for internal component padding.
- Use `spacing.4` / 16dp between internship cards.
- Use `spacing.5` / 24dp between major sections.
- Use `spacing.2` / 8dp between closely related text elements.
- Avoid cramped forms and dense job cards.

## 7. Border Radius

Use reusable radius tokens. Avoid random radius values.

| Token | Value | Components |
|---|---:|---|
| `radius.small` | 8dp | Small chips, badges, compact tags. |
| `radius.medium` | 12dp | Buttons, text fields, filter chips. |
| `radius.large` | 16dp | Internship cards, dialogs, bottom sheets, profile sections. |
| `radius.full` | 999dp | Pills, circular icon buttons, avatars. |

## 8. Elevation and Shadows

Use a very small elevation system.

| Token | Shadow | Usage |
|---|---|---|
| `elevation.0` | None | Default surfaces, forms, flat lists. |
| `elevation.1` | `0 1 3 rgba(15, 23, 42, 0.08)` | Cards, search surface, app bar separation. |
| `elevation.2` | `0 8 24 rgba(15, 23, 42, 0.12)` | Dialogs, overlays, bottom sheets. |

Rules:

- Prefer borders or background contrast before shadows.
- Use `elevation.1` only when cards need separation from the background.
- Use `elevation.2` only for temporary surfaces above the main screen.
- Avoid heavy shadows.

## 9. Layout Rules

All screens must follow consistent mobile layout principles.

- Use Auto Layout in Figma for screens, cards, lists, forms, and components.
- Use a consistent 16dp horizontal margin.
- Create clear vertical sections.
- Avoid cramped layouts.
- Prioritize one main action per screen.
- Support scrolling for long content.
- Use cards only when they improve grouping and scanning.
- Use bottom navigation for main destinations.

Recommended bottom navigation:

| Destination | Purpose |
|---|---|
| Home | Recommended internships, quick discovery, recent opportunities. |
| Search | Search, filter, and browse internship results. |
| Saved | Internships saved for later. |
| Applications | Submitted applications and status tracking. |
| Profile | Personal information, skills, CV, preferences, settings. |

## 10. Core Component Rules

### Button

Variants:

| Variant | Usage |
|---|---|
| Primary | Main action such as `Apply now`, `Search internships`, `Save changes`. |
| Secondary | Supporting action such as `View details`, `Upload CV`, `Edit profile`. |
| Text / Tertiary | Low-emphasis action such as `Cancel`, `Clear filters`, `Learn more`. |

States:

| State | Requirement |
|---|---|
| Default | Clear label, minimum height 48dp. |
| Pressed | Visible feedback through darker color or reduced emphasis. |
| Disabled | Use disabled styling and prevent interaction. |
| Loading | Show spinner or progress indicator and prevent duplicate submission. |

Rules:

- Use one obvious primary CTA per screen.
- Use full-width button when the action is dominant.
- Minimum button height is 48dp.
- Labels must be specific, such as `Apply now`, not vague labels like `Submit`.

### Text Field

States:

| State | Requirement |
|---|---|
| Default | Visible label and optional placeholder. |
| Focused | Primary-colored border or focus indicator. |
| Filled | Keep content readable and label visible. |
| Error | Error border and visible error message. |
| Disabled | Lower contrast and non-editable appearance. |

Include:

- Label, such as `Full name`, `Email`, `Preferred location`.
- Placeholder as an example, not a replacement for label.
- Helper text when guidance is needed.
- Error message that explains the problem clearly.

### Internship Card

Must support:

- Job title.
- Company name.
- Location.
- Work mode, such as `On-site`, `Remote`, or `Hybrid`.
- Skills / tags.
- Save action.
- Optional salary or allowance.
- Optional posted date.

Rules:

- Job title should be the strongest text.
- Company name should be easy to find.
- Metadata should be visually secondary but readable.
- Skills should appear as compact tags.
- Save action should be easy to reach but not compete with the title.
- Cards must be reusable across Home, Search Results, and Saved.

### Search Field

Search field requirements:

- Leading search icon.
- Placeholder such as `Search internships, companies, or skills`.
- Clear action when text is entered.
- Optional filter action on the trailing side.
- Minimum height 48dp.

### Filter Chip

Filter chips must have selected and unselected states.

| State | Visual treatment |
|---|---|
| Unselected | `color.surfaceVariant` background and `color.textSecondary` text. |
| Selected | `color.primaryContainer` background and `color.primary` text, optional check icon. |

Use chips for work mode, location, skills, job type, allowance range, and status filters.

### App Bar

App bar requirements:

- Clear title.
- Optional back button on secondary screens.
- Optional action such as save, edit, or notification.
- Keep layout simple and consistent.

### Bottom Navigation

Bottom navigation must include:

- Home.
- Search.
- Saved.
- Applications.
- Profile.

State rules:

- Selected item uses `color.primary`.
- Unselected items use `color.textSecondary`.
- Always show icon + label.
- Do not rename destinations across screens.

### Dialog

Variants:

| Variant | Usage |
|---|---|
| Confirmation | Confirm applying, saving changes, or submitting a CV. |
| Cancellation | Confirm discarding edits or cancelling an action. |
| Error | Explain a failed action and provide recovery. |

Dialog rules:

- Use short title and clear body text.
- Provide one primary action and one secondary action when possible.
- Avoid long forms inside dialogs.

### Empty State

Must include:

- Icon or simple illustration.
- Short explanation.
- One useful action.

Examples:

- Saved: `No saved internships yet` with `Search internships`.
- Applications: `You have not applied yet` with `Find internships`.
- Search: `No results found` with `Clear filters`.

### Error State

Must include:

- Understandable message.
- Possible reason.
- Retry action.

Example: `We could not load internships. Check your connection and try again.` with `Retry`.

### Loading State

Prefer:

- Skeleton loading for content lists and internship cards.
- Spinner for short actions such as applying or saving profile changes.
- Avoid blank loading screens.

## 11. Internship-Specific UI Patterns

### Job Search

Recommended pattern:

- Prominent search field near the top.
- Filter access through a filter button or horizontal chips.
- Readable result list using Internship Card.
- Optional result count such as `24 internships found`.
- Simple sorting and filtering suitable for students.

### Job Detail

Recommended visual order:

1. Job title.
2. Company.
3. Primary metadata.
4. Apply CTA.
5. Job description.
6. Requirements.
7. Benefits.
8. Company information.

Rules:

- Keep `Apply now` visible and easy to find.
- Use section headings for long content.
- Use bullet points for requirements and benefits.
- Include save action without making it compete with apply.

### Saved Jobs

- Use the same Internship Card component.
- Provide a clear empty state.
- Allow users to unsave without leaving the screen.
- Do not create a separate saved-card style unless necessary.

### Applications

Show:

- Company.
- Position.
- Submitted date.
- Current status.

Do not rely only on color to communicate application status. Use both label and visual treatment.

Recommended statuses:

| Status | Visual treatment |
|---|---|
| Submitted | Neutral badge with clear label. |
| Under review | Warning badge with clear label. |
| Interview | Primary badge with clear label. |
| Accepted | Success badge with clear label. |
| Rejected | Error or neutral badge with clear label. |

### Profile

Sections may include:

- Personal information.
- Skills.
- CV / Resume.
- Internship preferences.
- Settings.

Rules:

- Group content into clear cards or sections.
- Make profile completion visible but not stressful.
- Use clear actions such as `Edit skills` and `Upload CV`.
- Keep sensitive information professionally presented.

## 12. Iconography

Use one consistent icon family.

Preferred:

- Material Symbols.
- Material Icons if Material Symbols are unavailable.

Rules:

- Do not mix different icon styles.
- Use icons with labels when meaning may be unclear.
- Icons should support, not replace, important text.
- Standard icon sizes should be 20dp or 24dp.

## 13. Accessibility Rules

- Normal text contrast must target at least 4.5:1.
- Large text and UI controls must target at least 3:1 where applicable.
- Touch targets must be at least 48 x 48dp.
- Body text must be at least 14sp.
- Do not communicate meaning only by color.
- Always provide visible error messages.
- Use clear focus, selected, pressed, disabled, loading, empty, and error states.
- Maintain readable text hierarchy.
- Keep important actions reachable and clearly labeled.

## 14. Content and Tone of Voice

Writing style:

- Concise.
- Supportive.
- Professional.
- Student-friendly.
- Plain language.

Avoid:

- Corporate jargon.
- Long paragraphs.
- Vague CTA labels.
- Overly casual language.

Prefer clear labels:

- `Search internships`.
- `View details`.
- `Save`.
- `Apply now`.
- `View application`.
- `Retry`.
- `Upload CV`.
- `Edit profile`.

## 15. Screen Consistency Rules

All team members must follow:

- Same bottom navigation.
- Same app bar pattern.
- Same Internship Card.
- Same button variants.
- Same spacing scale.
- Same typography tokens.
- Same color tokens.
- Same radius system.
- Same state patterns.

Figma rules:

- No detached copies of components in final screens unless necessary.
- If a component needs a new variant, add it to the component set.
- Keep components, variants, and token names readable.
- Use shared components before creating new ones.

## 16. Figma Token Naming Convention

Color:

- `color/primary`.
- `color/on-primary`.
- `color/primary-container`.
- `color/background`.
- `color/surface`.
- `color/surface-variant`.
- `color/text/primary`.
- `color/text/secondary`.
- `color/border`.
- `color/success`.
- `color/warning`.
- `color/error`.
- `color/disabled`.

Typography:

- `type/display`.
- `type/heading/large`.
- `type/heading/medium`.
- `type/title`.
- `type/body/medium`.
- `type/body/small`.
- `type/label/medium`.
- `type/caption`.

Spacing:

- `spacing/4`.
- `spacing/8`.
- `spacing/12`.
- `spacing/16`.
- `spacing/24`.
- `spacing/32`.

Radius:

- `radius/8`.
- `radius/12`.
- `radius/16`.
- `radius/full`.

Elevation:

- `elevation/0`.
- `elevation/1`.
- `elevation/2`.

## 17. AI / Google Stitch Prompt Rules

Every Stitch prompt should include:

- Target user.
- Screen purpose.
- Main user task.
- Required content.
- Navigation context.
- Design style from this `DESIGN.md`.
- Accessibility constraints.
- Reusable component requirements.

The AI must not freely redefine:

- Brand colors.
- Typography.
- Bottom navigation.
- Component style.
- Spacing system.
- Radius system.
- Internship Card structure.

Prompt template:

```text
Create a mobile screen for Internship Finder for university IT / Software Engineering students aged around 20-23.
Screen purpose: [describe screen purpose].
Main task: [describe main user task].
Required content: [list required content].
Navigation context: [state selected bottom navigation item or back navigation].
Design style: Follow DESIGN.md with light theme, professional blue primary color, Inter typography, 16dp margins, rounded professional cards, and reusable components.
Accessibility: Minimum 14sp body text, 48dp touch targets, visible states, sufficient contrast, and no meaning communicated only by color.
Do not redefine brand colors, typography, bottom navigation, component style, spacing system, or radius system.
```

## 18. Final Design Principles

- One screen, one clear primary action.
- Reuse before creating.
- Clarity before decoration.
- Make internship content easy to scan.
- States are part of the design.
- Accessibility is mandatory.
- Keep the product professional but student-friendly.
- AI proposes, the designer decides.
