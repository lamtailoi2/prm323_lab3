# Evidence

Screenshots, exports and traces that prove each Lab 3 requirement (§6, §7, §8). Every "it works" claim in the report and slides links to a file here. The Firebase project ID in console screenshots must match `android/app/google-services.json`.

| Folder | What goes in it |
|---|---|
| `auth/` | Signed-out and signed-in screens; console Authentication → Users |
| `storage/` | Upload progress and URL in the app; Firebase console Storage file list under `reports/<uid>/`; the matching Firestore metadata document; the $1 budget alert settings |
| `fcm/` | Test message received in foreground, background and terminated states; Notification Center |
| `analytics/` | One DebugView screenshot per event in `docs/analytics-plan.md` |
| `crashlytics/` | Dashboard with the non-fatal error and the test crash, showing user ID and custom keys |
| `remote-config/` | Console values and the app before / after a change |
| `artemis/` | `runs.jsonl`, results table, trace IDs, screenshots / replays, exploratory session report |
| `uat/` | Screen recordings, failure screenshots and questionnaires from the UAT sessions (see [`uat/README.md`](uat/README.md)) |
| `code-review/` | Raw output of the AI review tool for each PR |
| `screens/` | App screenshots next to their Figma frames at 360 and 412 dp |
| `ranking/` | Ranking and tiebreaker checks (Home Recommended, experience bands) that do not need a screenshot |

Name files `<area>-<what>-<yyyymmdd>.png` (e.g. `analytics-login-20261105.png`). Never include personal data or secrets in screenshots.
