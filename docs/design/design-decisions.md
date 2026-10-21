# Design Decisions

## 1. Mobile-First Design

* **Decision:** Design all screens for a mobile viewport of 360 × 800 dp first.
* **Reason:** The application is intended to provide a focused mobile internship-search experience. Starting with a consistent viewport helps maintain layout consistency across screens.
* **Status:** Initial decision.

## 2. Consistent Color Palette

* **Decision:** Use a consistent primary color, neutral background colors, and semantic colors for success, warning, and error states.
* **Reason:** A shared color system creates visual consistency and helps users distinguish primary actions from supporting information.
* **Status:** Initial decision.

## 3. Typography Hierarchy

* **Decision:** Define reusable text styles for screen titles, section headings, body text, captions, and buttons.
* **Reason:** A clear type hierarchy makes information easier to scan and prevents inconsistent text styling across screens.
* **Status:** Initial decision.

## 4. Primary Action Hierarchy

* **Decision:** Give each screen one visually dominant primary action, such as Search, Apply, Upload CV, or Save.
* **Reason:** A clear primary action reduces competition between buttons and helps users understand the next step.
* **Status:** Initial decision.

## 5. Search and Filter Separation

* **Decision:** Provide distinct search and filter controls, with filters for relevant internship attributes such as location, work arrangement, and internship category.
* **Reason:** Keyword search and structured filtering serve different needs. Separating them makes internship discovery easier to understand and use.
* **Status:** Initial decision.

## 6. Consistent Internship Cards

* **Decision:** Use a reusable internship card pattern across Home, Search Results, and Saved Internships.
* **Reason:** Reusing the same information hierarchy helps users compare opportunities without relearning the layout on different screens.
* **Status:** Initial decision.

## 7. Clear Application Status

* **Decision:** Display application statuses using text labels combined with semantic colors rather than color alone.
* **Reason:** Explicit labels make application progress easier to understand and improve accessibility for users who may have difficulty distinguishing colors.
* **Status:** Initial decision.

## 8. Form Validation and Feedback

* **Decision:** Show validation messages close to the relevant fields and provide clear feedback after important actions, such as submitting an application or uploading a CV.
* **Reason:** Immediate, contextual feedback helps users correct mistakes and understand whether an action succeeded.
* **Status:** Initial decision.

## 9. Consistent Navigation and Interaction

* **Decision:** Keep navigation patterns, back behavior, button styles, and interaction feedback consistent across all screens.
* **Reason:** Predictable interactions reduce the learning effort required to move between internship discovery, saved items, applications, and profile management.
* **Status:** Initial decision.

## 10. Accessibility and Responsive Layout

* **Decision:** Use readable text, sufficient color contrast, appropriately sized touch targets, labels that do not rely on color alone, and layouts checked at 360 dp and 412 dp.
* **Reason:** These constraints help make the interface usable across different device widths and accessibility needs.
* **Status:** Initial decision.

## Accessibility Checklist

* [ ] Check text and component color contrast.
* [ ] Do not communicate meaning through color alone.
* [ ] Check touch target sizes.
* [ ] Check text readability, truncation, and overflow.
* [ ] Verify form labels and validation messages are understandable.
* [ ] Test relevant screens at 360 dp and 412 dp.
* [ ] Check loading, empty, and error states where applicable.
