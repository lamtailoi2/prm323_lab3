# P-01: Initialization prompt (verbatim)

Given to Claude Code (model `claude-opus-5-5`) on 2026-10-21 in `prm323_lab3/`, followed by the user's note: "các file design docs sẽ nằm ở ../prm323_lab2" ("the design docs are in ../prm323_lab2").

---

# Task: Initialize Internly — Internships Finder

You are a senior Flutter engineer responsible for initializing the repository for **Internly**, a mobile application that helps students discover and manage internship opportunities.

Your task is to inspect the existing project and Lab 2 design handoff, establish a clean and maintainable Flutter foundation, and prepare the repository for incremental feature development.

## 1. First: Inspect Before Coding

Before making changes:

1. Inspect the current working directory, existing files, Git status, Flutter/Dart installation, and current project configuration.
2. Locate and read all available design specifications, especially:
   - `flutter-handoff.md`
   - Figma links and design documentation
   - `DESIGN.md`
   - `design/screen-spec.md`
   - Design tokens, component specifications, personas, and user flows
3. Create `docs/handoff-gaps.md` documenting missing, ambiguous, or conflicting requirements.
4. Do not overwrite existing work or regenerate an existing Flutter project unnecessarily.
5. If critical specifications are missing, record assumptions and unresolved decisions. Ask only when a decision is necessary to proceed safely.

**The Lab 2 design is the source of truth for the UI.** Do not invent replacement screens, colors, typography, spacing, or user flows.

## 2. Product Context

Product name: Internly  
Product type: Internship finder and application tracking mobile app  
Platform: Android  
Framework: Flutter and Dart  
Backend: Firebase  
Architecture: MVVM  
State management: Riverpod  
Navigation: Use the routing solution already established by the project if appropriate; otherwise choose a maintainable Flutter-compatible solution.

Expected functional areas, subject to verification against the handoff:

- Home: Browse by Skill, Recommended, Recently Posted
- Search: Search, filter, and sort internships
- Internship details
- Saved internships
- Applications and application status tracking
- User profile
- Google Sign-In and sign-out
- Notification Center
- PDF report export

Treat this list as a product overview, not permission to invent additional screens or features. Reconcile it with the actual Lab 2 screen inventory and the three required user flows.

## 3. Architecture Requirements

Use MVVM with a strict separation of responsibilities.

### Models
- Plain Dart data models.
- Explicit serialization/deserialization for Firestore documents.
- Handle document IDs, timestamps, optional fields, and invalid or missing data safely.

### Services
- All Firebase and external API access belongs in services.
- Create focused services such as:
  - `AuthService`
  - `InternshipService`
  - `SavedInternshipService`
  - `ApplicationService`
  - `UserProfileService`
  - `NotificationService`
  - `AnalyticsService`
  - `RemoteConfigService`
  - `CrashlyticsService`
  - `ReportExportService`
  - `FileStorageService`
- Adjust the service inventory to match the actual scope. Avoid unnecessary abstractions.

### ViewModels
- Own screen state and business logic.
- Expose data, loading, empty, and error states.
- Call services through injected dependencies.
- Keep UI widgets free of business logic.

### Views and Widgets
- Render ViewModel state and forward user actions.
- Never access Firebase directly.
- Reuse components from the design system.
- Keep screens small and composable.

### Dependency Injection
- Use Riverpod consistently for state management and dependency injection.
- Avoid mixing Riverpod with Provider or adding a second state management framework.

## 4. Initial Directory Structure

Establish a feature-oriented structure while preserving the required MVVM separation.

lib/
  main.dart
  firebase_options.dart
  app/
    app.dart
    router.dart
  theme/
    app_theme.dart
    app_colors.dart
    app_typography.dart
    app_spacing.dart
    app_radii.dart
  core/
    constants/
    errors/
    utils/
    widgets/
  models/
  services/
  features/
    auth/
      models/
      services/
      viewmodels/
      screens/
      widgets/
    home/
      viewmodels/
      screens/
      widgets/
    internships/
      models/
      services/
      viewmodels/
      screens/
      widgets/
    saved/
      viewmodels/
      screens/
      widgets/
    applications/
      models/
      services/
      viewmodels/
      screens/
      widgets/
    profile/
      viewmodels/
      screens/
      widgets/
    notifications/
      models/
      services/
      viewmodels/
      screens/
      widgets/
    report_export/
      services/
      viewmodels/
      screens/
  firebase_options.dart

firebase/
  firestore.rules

docs/
  handoff-gaps.md
  design-change-log.md
  fidelity-check.md
  analytics-plan.md
  implementation-ai-log.md
  test-report.md
  code-review.md
  architecture.md

mobai_tests/
assets/
test/

This is a proposed baseline, not a requirement to create empty folders indiscriminately. Remove duplication, keep one authoritative location for each concern, and document any structural deviations.

Do not duplicate `firebase_options.dart`; it should exist in exactly one location.

Also initialize the required repository-level files:
- `README.md`
- `.gitignore`
- `.env.example` only if environment variables are genuinely needed
- Appropriate analysis/lint configuration
- A minimal test suite
- Firebase rules scaffolding

## 5. Design System

Translate the actual Lab 2 design tokens into Flutter theme definitions.

Requirements:
- Define colors, typography, spacing, corner radii, and component variants centrally.
- Build reusable widgets for components identified in the handoff.
- Avoid hard-coded visual values scattered across screens.
- Preserve loading, empty, error, and interaction states.
- Check touch targets of at least 48 × 48 dp and layouts at widths of 360 dp and 412 dp.
- If a design change is necessary, record it in `docs/design-change-log.md` with its reason.

Do not invent final theme values if the design files are unavailable.

## 6. Firebase Foundation

Prepare the codebase for:

- Firebase Core initialization
- Firebase Authentication with Google Sign-In
- Cloud Firestore
- Firebase Cloud Messaging
- Firebase Analytics
- Firebase Crashlytics
- Firebase Remote Config

Requirements:
- Separate Firebase initialization from feature logic.
- Use authenticated routing so signed-out users can access only Login.
- Support authentication loading and error states.
- Ensure data ownership is enforced by Firestore Security Rules.
- Store rules in `firebase/firestore.rules`.
- Keep app configuration separate from privileged secrets.
- Never embed service-account credentials, storage API secrets, or AWS access keys in the client.
- Do not use permissive production Firestore rules.

Create a setup guide for Firebase configuration, Android package registration, Google Sign-In SHA-1, and required console configuration.

Do not fabricate Firebase credentials or claim Firebase is connected when configuration is missing. Use explicit setup instructions and a clearly documented development placeholder where appropriate.

## 7. Data Modeling

Propose and document a Firestore schema for the confirmed Internly features.

Potential entities:
- Internship
- UserProfile
- SavedInternship
- Application
- ExportedReport
- Notification

Before implementing the schema, determine which data is shared across users and which belongs to an individual user.

Requirements:
- User-specific documents must be scoped to the authenticated UID.
- Implement CRUD for the main entity required by the Lab 3 specification.
- Include at least two collections or subcollections.
- Plan at least one filtered or sorted query and one real-time listener.
- Use appropriate document IDs, timestamps, and serialization.
- Provide a documented strategy for seed/demo data.

Do not assume that public internship listings can be created or modified by every authenticated user. Define safe read/write rules according to the actual data ownership model.

## 8. PDF Export and Storage

Prepare an abstraction for generating a branded PDF report, uploading it, and storing its metadata in Firestore.

The report flow must eventually support:
- PDF generation from real user data
- File upload
- File name, owner UID, creation timestamp, and URL metadata
- A UI action to open the exported report
- Loading and upload error handling

Cloudinary may be used as the initial storage option. If selected, document how to restrict unsigned uploads to PDF files and a maximum file size. Never embed an API secret in the Flutter app.

Do not implement a fake successful upload or save placeholder URLs as real results.

## 9. Notifications, Remote Config, Crashlytics, and Analytics

Create clear service interfaces and document the implementation plan.

Remote Config:
- At least two parameters with in-app defaults.
- Parameters must change real app behavior.
- Display current values for demonstration.

FCM:
- Support foreground and background notification handling.
- Request Android 13+ notification permission.
- Support notification navigation.
- Provide a Notification Center consistent with the design.

Crashlytics:
- Initialize reporting.
- Plan a handled-exception demonstration and an explicit test-crash control.
- Never trigger a test crash during normal startup.

Analytics:
- Create `docs/analytics-plan.md`.
- Include login, logout, screen_view, main-entity view/create/update/delete, export_pdf, and at least two events associated with the required Lab 2 flows.
- Use valid event names and appropriate parameters.
- Never log passwords, tokens, or unnecessary personal information.

## 10. Testing and Code Quality

Set up:
- Unit tests for models and business logic
- ViewModel tests where practical
- Service tests using appropriate fakes or mocks
- Widget tests for reusable UI components
- A test structure ready for the required 10 MobAI end-to-end scenarios

The eventual MobAI suite must cover:
1. Google Sign-In
2. Lab 2 flow 1
3. Lab 2 flow 2
4. Lab 2 flow 3
5. Error/recovery path
6. Create, edit, and delete the main entity
7. Top-level navigation
8. Profile and Remote Config
9. PDF export and upload
10. Sign-out

Each test must assert a visible outcome, not just successful taps.

For the initialization stage:
- Run `dart format`.
- Run `flutter analyze`.
- Run available tests.
- Report actual results and any environment blockers.
- Do not claim tests passed if they were not executed.

## 11. Documentation and AI Traceability

Initialize all required documentation files with meaningful templates rather than empty placeholders.

`README.md` must explain:
- Product overview
- Prerequisites
- Flutter setup
- Dependency installation
- Android run commands
- Firebase setup
- Google Sign-In configuration
- Storage configuration
- Testing commands
- Known limitations

`docs/architecture.md` must explain module responsibilities, dependency flow, state management, and data ownership.

`docs/handoff-gaps.md` must record actual gaps and resolutions.

`docs/design-change-log.md` must track UI changes and reasons.

`docs/implementation-ai-log.md` must be maintained during development. Record the exact prompts, output summaries, verification methods, and accepted/modified/rejected decisions. Do not fabricate completed work or verification evidence.

Prepare templates for the fidelity check, analytics plan, test report, and AI code review.

## 12. Git Workflow

- Inspect existing Git history before making changes.
- Preserve existing work.
- Use meaningful commits for completed stages.
- Do not create fake commit history.
- Do not commit secrets, personal credentials, test account passwords, or generated sensitive files.
- Use a feature branch and pull request for subsequent code review.

If this repository is being submitted for PRM393 Lab 3, verify the lecturer's required repository naming convention before finalizing the GitHub repository name.

## 13. Scope of This Initialization Task

Do not attempt to implement every screen and Firebase feature in a single pass.

Complete these steps first:

1. Inspect the existing repository and handoff.
2. Record gaps and assumptions.
3. Initialize or validate the Flutter project.
4. Establish the architecture and Riverpod dependency injection.
5. Set up the design-token foundation using actual source values.
6. Establish Firebase initialization and configuration instructions.
7. Create the required documentation templates.
8. Add minimal meaningful tests.
9. Run formatting, analysis, and tests where possible.
10. Summarize the resulting repository structure, files changed, commands executed, actual results, blockers, and the next recommended implementation task.

Do not silently replace existing files. Do not introduce unnecessary dependencies. Do not build speculative features. Keep every implementation understandable and maintainable.

**Definition of done:** the repository is a clean, documented, analyzable Flutter foundation with an explicit path to implement the Lab 2 Internly design, Firebase integration, required user flows, security rules, and automated tests.
