# Analytics plan

Google Analytics for Firebase through `AnalyticsService` (`lib/services/analytics_service.dart`). Views never log events: ViewModels call the service after the action succeeds (or fails, where noted).

## Rules

1. **Names:** `snake_case`, starting with a letter, at most 40 characters. No reserved prefixes (`firebase_`, `google_`, `ga_`) and no reserved names (e.g. `screen_view` must go through `logScreenView`, and `notification_open`, `app_remove`, `error` are reserved). `AnalyticsNames.isValidEventName` asserts this in debug builds.
2. **Parameters:** at most 25 per event; names up to 40 characters; string values up to 100 characters. Use IDs and enums, not free text.
3. **Privacy:** never log passwords, tokens, email, name, phone, CV file names, cover messages or raw search text containing personal data. The user ID is set to the pseudonymous Firebase UID only (done in `bootstrap.dart`).
4. **Reliability:** analytics failures never block a flow (`FirebaseAnalyticsService` swallows errors).
5. **Verify** every new event in DebugView (see `firebase-setup.md` §7) and record it in `test-report.md`.

## Events

Status: **Implemented** (in code and tested) · **Planned** (owner implements with the feature).

### Session and navigation

| Event | When | Parameters | Status |
|---|---|---|---|
| `login` (GA4 recommended) | Google sign-in succeeded | `method`: `google` | Implemented (`LoginViewModel`) |
| `logout` | User signs out (logged before sign-out) | none | Implemented (`SignOutViewModel`) |
| `screen_view` | Every route change | `screen_name` = the `GoRoute.name` (`home`, `search`, `saved`, `my_applications`, `profile`, `login`, …), `screen_class` = same | Implemented (`router.dart`, automatic for every named route) |

### Main entity (CRUD)

The entity is not decided yet (handoff-gaps G-08). Use the pattern `<entity>_<action>`. If the entity is **Application**:

| Event | When | Parameters | Status |
|---|---|---|---|
| `application_view` | Application Detail loaded | `internship_id`, `status` | Planned |
| `application_create` | Application submitted (Flow 2 end) | `internship_id`, `cv_source` (`profile` / `uploaded`) | Planned |
| `application_update` | Application changed (e.g. withdraw / undo) | `internship_id`, `from_status`, `to_status` | Planned |
| `application_delete` | Application deleted | `internship_id` | Planned |

### Required Lab 2 flow events

| Event | Flow | When | Parameters | Status |
|---|---|---|---|---|
| `search` (GA4 recommended) | Flow 1 | Search submitted | `search_term` (trimmed, max 100 chars, skill/keyword only), `result_count` | Planned |
| `search_filter_apply` | Flow 1 | Filter sheet "Show results" | `work_modes`, `skill_count`, `has_location`, `result_count` | Planned |
| `apply_start` | Flow 2 | `Apply now` tapped on Internship Detail | `internship_id`, `source` (`search` / `saved` / `home`) | Planned |
| `cv_upload_failed` | Flow 2a | CV upload failed | `reason` (`network` / `size` / `type` / `unknown`) | Planned |
| `cv_match_check` | Flow 2d | CV Match Check finished | `internship_id`, `result` (`all_matched` / `gaps` / `failed`), `matched_count`, `missing_count` (counts only, never CV content) | Planned |
| `cv_match_improve` | Flow 2d | A suggestion action is tapped | `action` (`edit_skills` / `replace_cv` / `edit_introduction`) | Planned |
| `internship_save` | Flow 2e | Save succeeded | `internship_id`, `source` (`home` / `search_results` / `detail`) | Planned |
| `internship_unsave` | Flow 2e.1 | Unsave (and `undo` param if undone) | `internship_id`, `undo` (`true` / `false`) | Planned |
| `application_status_view` | Flow 3 | Status visible on Application Detail | `status` | Planned |

### Other Lab 3 features

| Event | When | Parameters | Status |
|---|---|---|---|
| `export_pdf` | PDF report generated **and** uploaded | `report_type`, `page_count`, `size_kb` | Planned |
| `export_pdf_failed` | Generation or upload failed | `stage` (`generate` / `upload` / `save_metadata`), `reason` | Planned |
| `notification_center_open` | Notification Center opened | `unread_count` | Planned |
| `remote_config_view` | Remote Config values displayed | none | Planned |

## Adding an event

1. Add a row here (status Planned), with parameters that follow the rules above.
2. Call `ref.read(analyticsServiceProvider).logEvent('<name>', {...})` from the ViewModel.
3. Assert the call in the ViewModel test with `FakeAnalyticsService` (`test/helpers/fakes.dart`).
4. Verify in DebugView, then set the status to Implemented.
