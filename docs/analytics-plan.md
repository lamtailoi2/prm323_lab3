# Analytics event plan

Google Analytics for Firebase through `AnalyticsService` (`lib/services/analytics_service.dart`). The plan follows Lab 3 Appendix A: every event has typed parameters, the product question it answers, and the Lab 2 flow step it measures. Read in funnel order, the events show **where students leave each flow** and **how close the app comes to the Lab 2 success criterion** (find an internship in < 30 s; apply in < 2 min).

## Rules

1. **Names:** Firebase recommended names where one fits (`login`, `search`, `screen_view`); otherwise `snake_case`, at most 40 characters, starting with a letter, with no reserved prefix (`firebase_`, `google_`, `ga_`) and no reserved name (`notification_open`, `error`, `app_remove`, …). `AnalyticsNames.isValidEventName` asserts this in debug builds.
2. **Parameters:** at most 25 per event; string values ≤ 100 characters (truncate titles). Use IDs and enums, never free text typed by the user except the search term.
3. **No personal data:** no email, name, phone, CV file name, cover message or token. The user ID is the pseudonymous Firebase UID, set after sign-in (`bootstrap.dart`).
4. **`internship_id`:** a short stable key derived from the SerpAPI `job_id` (the raw `job_id` is longer than 100 characters; see G-25).
5. **Who logs:** ViewModels, after the action succeeds (or fails, where stated). Views never log.
6. **Evidence:** a DebugView screenshot for every event in `evidence/analytics/` (Lab 3 §6).

## Events

Status: **Implemented** (in code and tested) · **Planned** (owner implements with the feature).

| # | Event | Trigger | Parameters (type) | Question it answers | Flow step | Status |
|---|---|---|---|---|---|---|
| 1 | `login` | Google sign-in succeeds | `method` (string, `google`) | How many students return each week? | Sign-in | Implemented |
| 2 | `logout` | Student signs out (logged before sign-out) | — | How long do sessions last before sign-out? | Sign-out | Implemented |
| 3 | `screen_view` | Every named route is shown | `screen_name` (string), `screen_class` (string) | Which screens do students reach in each flow, and where do they stop? | All flows | Implemented (`router.dart`) |
| 4 | `search` | Home feed loads or a role filter changes | `search_term` (string: `IT` or a role label, ≤ 100), `result_count` (int), `elapsed_sec` (int, Home opened → results) | Which roles are browsed, which return nothing, and do students reach results in < 30 s? | Flow 1 | Implemented (Home) |
| 5 | `search_filter_apply` | Filter sheet "Show results" | `work_mode` (string), `location` (string, city), `skill_count` (int), `result_count` (int) | Which filters do students use, and which narrow results to zero? | Flow 1 | Planned |
| 6 | `view_internship` | Internship Detail opens | `internship_id` (string), `internship_title` (string), `company_name` (string), `source` (string: `home` / `search` / `saved`) | Which internships are opened most after a search? | Flow 1 end / Flow 2 start | Planned |
| 7 | `internship_save` | Save succeeds | `internship_id` (string), `source` (string) | Which saved internships later turn into applications? | Flow 2e | Planned |
| 8 | `apply_start` | `Apply now` tapped | `internship_id` (string), `source` (string: `detail` / `saved`) | How many detail views lead to starting an application? | Flow 2 | Planned |
| 9 | `cv_match_check` | CV Match Check finishes | `internship_id` (string), `result` (string: `all_matched` / `gaps` / `failed`), `matched_count` (int), `missing_count` (int) | How often do CVs miss requirements, and do gaps stop students from submitting? | Flow 2d | Planned |
| 10 | `application_create` | Application submitted | `internship_id` (string), `cv_source` (string: `profile` / `uploaded`), `duration_sec` (int, `apply_start` → submit) | How many started applications are submitted, and in under 2 minutes? | Flow 2 end | Planned |
| 11 | `view_application` | Application Detail opens | `internship_id` (string), `status` (string) | Which statuses do students check most often? | Flow 3 end | Planned |
| 12 | `application_update` | Student changes an application (e.g. status, withdraw / undo) | `internship_id` (string), `from_status` (string), `to_status` (string) | How do applications progress over time? | Flow 3 (main entity: update) | Planned (G-08) |
| 13 | `application_delete` | Student deletes an application | `internship_id` (string), `status` (string) | Which applications do students give up on? | Flow 3 (main entity: delete) | Planned (G-08) |
| 14 | `export_report` | PDF generated **and** uploaded | `report_type` (string), `item_count` (int), `file_size_kb` (int) | Which students export, and how many applications does a report hold? | Export and upload | Planned |
| 15 | `notification_center_open` | Notification Center opens | `unread_count` (int) | Do students read the notifications they receive? | FCM | Planned |
| 16 | `profile_update` | A Profile section is saved (Edit profile, Edit skills, Update preferences) | `section` (string: `details` / `skills` / `preferences`), `item_count` (int: filled detail fields, skills, or selected roles + work modes + location) | Which parts of the profile do students keep up to date, and how many skills do they declare before applying (CV Match Check input, G-24)? | Flow 2 alternative (`Edit profile`, 2d `Edit skills`) | Implemented (ViewModel tests; DebugView not checked yet) |
| 17 | `cv_upload` | A CV is uploaded **and** saved as the default CV | `source` (string: `profile`; the Apply flow adds `apply_form`), `file_size_kb` (int) | How many students have a CV ready before they reach Apply (Flow 2a)? | Flow 2a (CV from Profile) | Implemented (ViewModel tests; DebugView not checked yet) |

Coverage required by Lab 3 §6 (≥ 7 events): sign-in (1), sign-out (2), main search / primary action (4, 8, 10), each detail screen (6, 11), export and upload (14).

## Funnels to build in the console

| Funnel | Steps | Success criterion |
|---|---|---|
| Find (Flow 1) | `screen_view(home)` → `search` → `view_internship` | `search.elapsed_sec` < 30 |
| Apply (Flow 2) | `view_internship` → `apply_start` → `cv_match_check` → `application_create` | `application_create.duration_sec` < 120 |
| Save → apply (2e) | `internship_save` → `apply_start(source=saved)` → `application_create` | — |

## Adding an event

1. Add or update its row here, with typed parameters and the question it answers.
2. Call `ref.read(analyticsServiceProvider).logEvent('<name>', {...})` from the ViewModel (read the provider before any `await`).
3. Assert it in the ViewModel test with `FakeAnalyticsService`.
4. Check it in DebugView, save the screenshot in `evidence/analytics/`, and set the status to Implemented.
