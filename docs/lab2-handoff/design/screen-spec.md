# Internship Finder — Screen Specifications

> **Lab 3 revision (2026-10-21, DC-08 / DC-09).** Flows are now Flow 1 Search → Flow 2 Apply (with the Save sub-flow 2e and the new CV Match Check, 2d) → Flow 3 Track. The CV Match Check screen is new and still needs a Figma frame (handoff-gaps G-24). This copy no longer matches Lab 2 commit `03f4aa3`.

This document defines the UX purpose, content, actions, related flows, states, and design intent for each Internship Finder screen. It follows `design/DESIGN.md` as the source of truth for navigation, component naming, colors, typography, spacing, CTA hierarchy, and consistency rules.

## Home

### Purpose

Home helps students quickly start discovering relevant internships without needing to configure many options first. It gives a clear entry point into search and highlights opportunities that match student interests, skills, or recent activity.

### Main Content

- Greeting or short welcome message.
- Prominent search entry point.
- Recommended internship cards.
- Recently posted or popular internships.
- Quick filter shortcuts such as `Remote`, `Flutter`, `React`, or `Software Intern`.
- Bottom navigation with Home selected.

### Primary Action

Start searching for internships through the prominent search field or search entry point.

### Secondary Actions

- Open an internship detail from a card.
- Save an internship from a card.
- Use a quick filter shortcut.
- Navigate to Search, Saved, Applications, or Profile.

### Related Flows

- Flow 1: Search Internship (start).
- Flow 2e: Save for later (save from a card).

### States

- Loading.
- Populated.
- Error.

### Design Intent

Home should reduce the effort required to begin. The search entry should be visually prominent because discovery is the main task. Internship Cards should use the same reusable structure as Search Results and Saved Internships to support recognition and consistency. Recommended content should be scannable, with job titles stronger than company metadata. The screen should avoid overwhelming students with too many categories or competing CTAs.

## Search

### Purpose

Search lets students express what they are looking for and refine internship opportunities by keyword, skill, work mode, location, or other common criteria.

### Main Content

- Search field with placeholder such as `Search internships, companies, or skills`.
- Filter chips for work mode, location, skills, job type, and allowance range.
- Recent searches or suggested searches when no query has been entered.
- Optional clear filters action.
- Bottom navigation with Search selected.

### Primary Action

Search internships using the search field.

### Secondary Actions

- Select or remove filter chips.
- Clear the search query.
- Clear filters.
- Open Search Results after entering a query or selecting filters.

### Related Flows

- Flow 1: Search Internship.
- Flow 2e.2: Save for later (target of the empty Saved action `Search internships`).
- Flow 3a: Track Application (target of the empty-state action `Find internships`).

### States

- Default.
- Populated.
- Empty.

### Design Intent

The search field should dominate the top area because search is the primary task. Filter chips should be easy to scan and use selected/unselected states from the design system. The screen should keep choices focused so students with limited work experience are not forced to understand complex recruitment filters. Clear actions should be visible but lower emphasis than searching.

## Search Results

### Purpose

Search Results displays internships matching the user's search and filters, helping students compare options quickly and choose which listing to inspect further.

### Main Content

- Search summary or editable search field.
- Active filter chips.
- Result count, such as `24 internships found`.
- Internship Card list.
- Optional sort control if needed.
- Bottom navigation with Search selected.

### Primary Action

Open an internship detail from the results list.

### Secondary Actions

- Save an internship.
- Adjust filters.
- Edit search query.
- Clear filters.
- Retry loading results if an error occurs.

### Related Flows

- Flow 1: Search Internship (1a no results, 1b load error).
- Flow 2c: Already applied (`Applied` badge on the card).
- Flow 2e: Save for later (save from a card).

### States

- Loading.
- Populated.
- Empty.
- Error.
- Applied: cards the student has already applied to show an `Applied` badge (Flow 2c).

### Design Intent

Results should prioritize scanability. Each Internship Card must make the job title, company, location, work mode, and tags easy to compare. Metadata should be visually secondary but readable. Empty results should support recovery with a useful action such as clearing filters. Loading should use skeleton cards so the layout remains predictable while content loads.

## Internship Detail

### Purpose

Internship Detail helps students decide whether an internship is relevant and whether they should apply or save it for later.

### Main Content

- Job title.
- Company name.
- Location, work mode, allowance or salary if available, and posted date.
- Primary `Apply now` CTA.
- Save action.
- Job description.
- Requirements.
- Benefits.
- Company information.

### Primary Action

Apply for the internship using `Apply now`.

### Secondary Actions

- Save or unsave the internship.
- Go back to previous list.
- Share or view company information if included.

### Related Flows

- Flow 1: Search Internship (end; 1c load error).
- Flow 2: Apply Internship (start; `Apply now`).
- Flow 2c: Already applied.
- Flow 2e: Save for later (`Save`).

### States

- Loading.
- Populated.
- Error.
- Already applied: a success banner `You applied on …` and `View application` replace `Apply now`, so the student cannot send a duplicate application (Flow 2c).

### Design Intent

The visual order should support decision-making: job identity first, key metadata second, apply action third, then detailed information. `Apply now` should visually dominate Save because applying is the main conversion action. Save should remain accessible but lower emphasis. Long content should be grouped with section headings and bullets to reduce cognitive load. The screen must remain scrollable and readable on 360 x 800 dp.

## Saved Internships

### Purpose

Saved Internships lets students return to opportunities they want to review or apply to later.

### Main Content

- List of saved Internship Cards.
- Optional saved count.
- Empty state when no internships are saved.
- Bottom navigation with Saved selected.

### Primary Action

Open a saved internship detail.

### Secondary Actions

- Unsave an internship.
- Search for more internships.
- Navigate to other main destinations.

### Related Flows

- Flow 2e: Save for later, a sub-flow of Apply. Opening a saved internship leads to Internship Detail → `Apply now` (2e.1 unsave + Undo, 2e.2 empty list, 2e.3 save error).

### States

- Loading.
- Populated.
- Empty.
- Error.

### Design Intent

Saved Internships should reuse the same Internship Card component as Home and Search Results to avoid fragmented patterns. The empty state should be supportive and actionable, such as `No saved internships yet` with `Search internships`. Unsave should be easy but not visually destructive unless confirmation is needed for a bulk action. The list should stay clean and scannable.

## Application Form

### Purpose

Application Form collects the information needed to apply for an internship and helps students submit a complete, valid application.

### Main Content

- Internship summary with job title and company.
- Student personal information fields.
- Skills or relevant experience fields.
- CV / Resume upload or selected CV area.
- Optional cover message or short introduction.
- Helper text for unclear fields.
- Validation messages when needed.

### Primary Action

Continue to the CV Match Check.

### Secondary Actions

- Upload or replace CV.
- Edit profile-related information.
- Cancel or go back to Internship Detail.

### Related Flows

- Flow 2: Apply Internship (2a CV upload error, 2b empty profile).

### States

- Default.
- Validation error.
- Loading.

### Design Intent

The form should prevent errors before submission by using clear labels, helper text, and validation messages near the field that caused the issue. CV errors should be specific and recoverable, with an obvious action such as `Upload CV` or `Replace CV`. The CTA should remain clear, but disabled or blocked states must explain what is missing. The screen should keep the process short and avoid making students rewrite information already stored in Profile.

## CV Match Check

*New in Lab 3 (DC-09). Needs a Figma frame (G-24); reuse existing components (Match Card, Skill Tag, Bullet Item, Info Banner, Button).*

### Purpose

CV Match Check shows the student, before review, which requirements of the internship their CV and profile already cover and which they do not show yet, with a concrete suggestion for each gap. It helps students submit a stronger application without slowing them down.

### Main Content

- Internship summary with job title and company.
- Match summary such as `3 of 4 requirements matched`.
- Matched requirements, each with a check icon and label.
- Unmatched requirements, each with a label (not color alone) and one plain-language suggestion, e.g. `Add REST API to your skills if you have used it`.
- "Nice to have" items shown as optional, not as gaps.
- Note that the check is a guide and does not block applying.

### Primary Action

Continue to Application Review (`Continue to review`).

### Secondary Actions

- Edit skills (Profile or the form's skills section), then re-check.
- Replace CV (Replace CV sheet), then re-check.
- Add to the short introduction (back to Application Form).
- Retry the check if it failed.

### Related Flows

- Flow 2: Apply Internship (2d CV match gaps).

### States

- Checking (loading).
- All matched.
- Gaps found, with suggestions.
- Check failed: error message + `Retry`, and `Continue to review` without the check.

### Design Intent

The screen should feel like a helpful checklist, not a gate. Lead with the summary, then the gaps, because they are the part the student can act on. Suggestions must be honest: never encourage claiming skills or experience the student does not have. `Continue to review` stays visible and dominant so the persona can still apply in under 2 minutes. Status of each requirement uses a label and an icon, never color alone.

## Application Review

### Purpose

Application Review gives students a final chance to confirm their information before submitting, reducing accidental or incomplete applications.

### Main Content

- Internship summary.
- Applicant information summary.
- Skills or experience summary.
- CV / Resume file name or status.
- Optional cover message preview.
- Submission reminder or confirmation text.

### Primary Action

Submit the application.

### Secondary Actions

- Edit application details.
- Replace CV.
- Go back to Application Form.

### Related Flows

- Flow 2: Apply Internship.

### States

- Populated.
- Validation error.
- Loading.

### Design Intent

Review should be calm and structured. Information should be grouped into readable sections so students can verify content quickly. The primary submit action should be visually dominant, while edit actions should be available but secondary. Validation errors should clearly identify what must be fixed before submission. This screen reduces anxiety by making the final submission predictable.

## Application Success

### Purpose

Application Success confirms that the internship application was submitted and guides students to the next useful step.

### Main Content

- Success icon or simple illustration.
- Clear success message.
- Internship title and company.
- Submitted date or short confirmation detail.
- Next-step explanation.

### Primary Action

View the submitted application.

### Secondary Actions

- Return to Home.
- Continue searching internships.

### Related Flows

- Flow 2: Apply Internship (end).

### States

- Success.

### Design Intent

This screen should provide reassurance and closure. The success message must be clear and not overly decorative. The next action should direct students toward tracking their application, supporting the connection between applying and My Applications. The layout should avoid adding unrelated choices immediately after submission.

## My Applications

### Purpose

My Applications helps students track internships they have applied to and understand the current status of each application.

### Main Content

- Application list items showing company, position, submitted date, and current status.
- Status labels such as `Submitted`, `Under review`, `Interview`, `Accepted`, or `Rejected`.
- Empty state when no applications exist.
- Bottom navigation with Applications selected.

### Primary Action

Open Application Detail to view status and details.

### Secondary Actions

- Filter applications by status if needed.
- Search or find internships from the empty state.
- Retry loading applications if an error occurs.

### Related Flows

- Flow 3: Track Application (start).

### States

- Loading.
- Populated.
- Empty.
- Error.

### Design Intent

Application status should be easy to scan and must not rely only on color. Each status needs a visible label and consistent badge treatment. The list should prioritize position, company, submitted date, and status without adding unnecessary details. Empty state copy should be supportive, not discouraging, and should guide users back to discovery.

## Application Detail

### Purpose

Application Detail shows the full status and submitted information for one application, helping students understand progress and available next steps.

### Main Content

- Company and position.
- Current application status with label and visual treatment.
- Submitted date.
- Status timeline or status summary if available.
- Submitted CV and application details.
- Optional employer or company information.
- Optional withdraw action.

### Primary Action

View and understand the current application status.

### Secondary Actions

- Withdraw application if allowed.
- Open confirmation dialog for withdrawal.
- Cancel withdrawal.
- Preview the submitted CV (view only; it cannot be replaced after submission).
- Go back to My Applications.

### Related Flows

- Flow 3: Track Application (end).
- Flow 2: Apply Internship (optional next step via `View application` from Application Success, or from Internship Detail when already applied, Flow 2c).

### States

- Loading.
- Populated: Submitted (right after applying) or a later status such as Under review.
- Error.

### Design Intent

The status should be the strongest information after the job identity. Because application progress can be stressful, the screen should use plain language and avoid ambiguous labels. Withdraw must be visually lower priority than status information and should require confirmation to prevent accidental destructive action. Status meaning should use both label and visual treatment for accessibility.

## Profile

### Purpose

Profile lets students manage personal information, skills, CV / Resume, internship preferences, and settings that support faster discovery and application.

### Main Content

- Personal information summary.
- Skills section.
- CV / Resume section.
- Internship preferences.
- Settings.
- Profile completion indicator if useful.
- Bottom navigation with Profile selected.

### Primary Action

Edit or complete profile information needed for internship applications.

### Secondary Actions

- Upload or replace CV.
- Edit skills.
- Update internship preferences.
- Open settings.
- Navigate to other main destinations.

### Related Flows

- Flow 2: Apply Internship (alternative path via `Edit profile`, and `Edit skills` from the CV Match Check, Flow 2d).

### States

- Loading.
- Populated.
- Validation error.
- Error.

### Design Intent

Profile should make readiness for applications visible without creating pressure. Sections should be grouped clearly so students can update one area at a time. CV and skills should be easy to find because they directly affect application completion and internship matching. Validation messages should be close to the related field or section. The screen should use the same typography, spacing, and card patterns as the rest of the app.

# Screen-to-Flow Mapping

Flow numbers follow `ux/user-flow.md` (Lab 3 revision): Flow 1 = Search Internship, Flow 2 = Apply Internship (includes 2e Save for later), Flow 3 = Track Application.

| Screen | Flow 1: Search | Flow 2: Apply (incl. 2e Save) | Flow 3: Track | Notes |
|---|---|---|---|---|
| Home | Yes (start) | 2e (save from card) | No | Entry point for discovery. |
| Search | Yes | 2e.2 (empty Saved target) | 3a (empty-state target) | Helps users define internship intent before viewing results. |
| Search Results | Yes | 2c (`Applied` badge), 2e (save) | No | Supports comparison, saving, and opening details. |
| Internship Detail | Yes (end) | Yes (start), 2c, 2e | No | Decision screen: apply now or save for later; once applied, `View application` replaces `Apply now`. |
| Saved Internships | No | 2e (sub-flow) | No | Saved internships lead back to `Apply now`. |
| Application Form | No | Yes | No | Collects and validates application information, including CV upload. |
| CV Match Check | No | Yes (2d) | No | New in Lab 3: unmatched requirements and suggestions; never blocks. |
| Application Review | No | Yes | No | Confirms application details before submission. |
| Application Success | No | Yes (end) | No | Confirms submission; `View application` routes to Application Detail. |
| My Applications | No | No | Yes (start) | Main status tracking screen. |
| Application Detail | No | Optional (`View application`, 2c) | Yes (end) | Shows detailed application status and optional withdrawal. |
| Profile | No | Alternative (`Edit profile`, 2d `Edit skills`) | No | Supports application readiness through CV, skills, and preferences. |

# Global Screen Rules

- Use the same bottom navigation destinations: Home, Search, Saved, Applications, Profile.
- Use a consistent app bar pattern with title, optional back button, and optional single action.
- Use the same Internship Card across Home, Search Results, and Saved Internships.
- Keep CTA hierarchy consistent: one clear primary action per screen, with secondary and text actions lower emphasis.
- Use the spacing scale from `DESIGN.md`, with 16dp standard horizontal screen padding.
- Use the same typography tokens, with body text at least 14sp.
- Use the same color tokens, including `color.primary`, `color.background`, `color.surface`, `color.textPrimary`, and `color.textSecondary`.
- Use the same component patterns for buttons, text fields, chips, dialogs, empty states, error states, and loading states.
- Include loading, empty, error, success, and validation states only where relevant.
- Maintain accessible touch targets of at least 48 x 48dp.
- Do not rely only on color for status, validation, or meaning.
- Keep screens scannable by using clear headings, readable metadata, and predictable grouping.
