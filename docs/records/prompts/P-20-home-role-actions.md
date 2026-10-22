# P-20: Home role actions, transparent text buttons and E2E evidence

**Type:** normalized professional brief written for the Lab 3 implementation
log. It is **not** a verbatim transcript. Tool: `opencode`
(`deepseek-v4.1-flash-free`), 2026-10-22.

## Prompt

You are a senior Flutter engineer working in the `prm323_lab3` repository for
**Internly**, an MVVM + Riverpod Flutter app for IT internship discovery. Read
`AGENTS.md`, `docs/design/design-system.md`, `docs/design-traceability.md` and
the relevant Home screen before changing code. The Lab 2 design is the source of
truth; do not invent UI.

### Task

1. Replace the Home skill shortcuts with an IT-only role taxonomy. Show
   `Browse by Role`, role chips and an `All roles` action. Hide non-IT listings.
   Keep skills as tags on listing cards.
2. Keep the SerpAPI sync to three to five IT keywords with
   `location=Vietnam`. City/province filtering belongs to the app's Search
   feature later, not to the scheduled sync.
3. The Home section-header text actions (`All roles`, `View all`) must match the
   design: **no white surface block behind the label; the background is
   transparent**. Keep the primary text color, the 48 dp touch target and the
   existing behavior that opens the Search tab.
4. Add a regression test for the transparent text-button style.
5. Add an ARTEMIS E2E case for the Home role chips and `All roles` navigation.
   Run it if an Android device/emulator and the ARTEMIS host are available.
6. Save the prompt record, test results and E2E evidence.

### Constraints

- Follow MVVM: views do not call services; ViewModels do not hold
  `BuildContext`.
- Use design tokens; no raw colors, font sizes, radii or spacing in feature
  code.
- Do not change the primary or secondary button styles.
- Do not fabricate a run, trace ID or screenshot. If ARTEMIS cannot run, record
  the real environment check and "not run".
- Do not commit secrets, `.env`, service-account keys or model API keys.
- Update the same-PR documentation: AI log, test report, test plan and evidence.

### Acceptance criteria

- `All roles` and `View all` render directly on the page background in default,
  pressed, focused and disabled states; no white pill or surface rectangle.
- Every text action still has a minimum 48 dp touch target and opens Search.
- `flutter analyze` prints `No issues found!`.
- `flutter test` passes, including the new transparent-background assertion.
- A rebuilt simulator/device screenshot shows the transparent actions.
- The E2E case exists in `e2e_test/`; a real run is recorded only when a device
  and ARTEMIS host are reachable, otherwise the blocker is recorded in
  `evidence/artemis/`.

### Verification commands

```bash
dart format lib test
flutter analyze
flutter test
cd functions && npm test && npm run build
cd e2e_test && uv run pytest --count 3 -v   # only with an Android device + ARTEMIS host
```
