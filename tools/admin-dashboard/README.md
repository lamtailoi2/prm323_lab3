# Internly admin dashboard (local)

A small local web tool for the things we used to do in the Firebase Console:
sending test / real FCM notifications, finding a device token, and inspecting
or deleting a student's notification history.

It runs on this machine at <http://127.0.0.1:4317>. The browser never sees a
credential: a Node server holds it and exposes a JSON API.

## One-time setup

1. Firebase Console → ⚙ **Project settings** → **Service accounts** →
   **Generate new private key**. A `.json` file downloads.
2. Save it **outside the repository**, for example:

   ```powershell
   mkdir "$env:USERPROFILE\.internly-admin"
   move "$env:USERPROFILE\Downloads\<project>-firebase-adminsdk-*.json" `
     "$env:USERPROFILE\.internly-admin\service-account.json"
   ```

   The repository already ignores `*service-account*.json` and
   `*-firebase-adminsdk-*.json`; still, never copy the key into the repo.
3. Install and start:

   ```powershell
   cd tools/admin-dashboard
   npm install
   npm start
   ```

4. Open <http://127.0.0.1:4317>.

A different key location can be used with the `INTERNLY_ADMIN_SA` environment
variable. Without a key the server falls back to application-default
credentials (for example `gcloud auth application-default login`); the header
shows which credential is in use.

## What it does

- **Users** — `users/{uid}` joined with Firebase Auth: name, email, uid,
  device token and when it was last stored. Copy a token with one click. The
  recipient picker in the compose form uses the same list.
- **Send notification** — choose **one recipient** or **everyone with a
  token** from the recipient picker. Students without a device token appear
  disabled with the reason, so a send cannot silently target an unreachable
  device. Title, optional body, optional in-app `route` (`/home`, `/search`,
  `/saved`, `/applications`, `/profile` or a path below one of them, e.g.
  `/home/internships/<jobKey>`). The server reports per-recipient successes
  and FCM error codes. A send covers up to 1000 user documents (duplicate
  tokens are sent once).
- **Notification history** — reads `users/{uid}/notifications` (newest first,
  read / unread, route, time) and deletes one entry or clears the list.
- **Analytics (GA4 realtime)** — active users and top events from the GA4
  property linked to the Firebase project, refreshed every 15 s. See
  [Analytics (GA4 realtime)](#analytics-ga4-realtime).
- **Crash test** — sends a data-only FCM command (`type=test_crash`) to the
  same recipient selection. Every selected app closes immediately and uploads
  a fatal report on its next launch. The action requires the acknowledgment
  checkbox and a confirmation dialog; it writes no notification or history
  document. The on-device control stays at Profile → Diagnostics → *Simulate
  app crash*.

When **Write to the user's notification history** is checked, the server also
writes the document with the FCM message ID as its ID, the same ID the app uses
when it receives the message, so the two writes merge instead of duplicating.
The crash command deliberately skips this write: the app recognises the
control message before its notification handlers and crashes instead.

## Analytics (GA4 realtime)

The card reads the GA4 property linked to the Firebase project. It does not
use the Firebase Admin SDK; the server calls the GA4 Data API
(`runRealtimeReport`).

1. GA4 → **Admin** → **Property settings** → **Property details**: copy the
   numeric **Property ID** (not the `G-...` measurement id). It is also in the
   Firebase Console link to the property.
2. Google Cloud Console (the project that owns the service-account key) →
   **APIs & Services** → **Library** → enable **Google Analytics Data API**.
3. GA4 → **Admin** → **Property access management** → add the key's
   `client_email` as **Viewer**.
4. Start the dashboard with the property id (the key path is the same one used
   for Firebase):
   ```powershell
   cd tools/admin-dashboard
   $env:GA4_PROPERTY_ID="123456789"
   $env:INTERNLY_ADMIN_SA="$env:USERPROFILE\.internly-admin\service-account.json"
   npm start
   ```
5. Check the endpoint:
   ```powershell
   curl.exe http://127.0.0.1:4317/api/analytics/realtime
   ```
   It returns `activeUsers`, `totalEvents`, `rows` (`event`, `events`; `users`
   is `null` there because GA4 does not allow `activeUsers` together with the
   `eventName` dimension), `quotaRemaining` and `fetchedAt`. The server makes
   two small queries (totals and top events), caches for 10 s, and the UI
   refreshes every 15 s.

The GA4 realtime report covers the last **30 minutes** (60 for Analytics 360)
and is aggregated, not a per-event DebugView. The Data API is free within its
quota: a standard property allows 200,000 realtime tokens per day, 40,000 per
hour and 14,000 per project per property per hour, so a 15 s poll is well
inside the free tier.

## Security

- The server binds to `127.0.0.1` only.
- No authentication: anyone who can use this machine can use the dashboard.
  Do not expose the port or deploy this server.
- The service-account key is read at startup from outside the repository and
  is never sent to the browser.

## Troubleshooting

| Symptom | Fix |
|---|---|
| Header says **No credential** | Save the key to `%USERPROFILE%\.internly-admin\service-account.json` and restart `npm start`. |
| `permission/insufficient-permissions` | The key belongs to another project, or the service account was restricted in IAM. Generate a fresh key for `prm-lab3`. |
| User shows **No token** | Open the app on that device while signed in; the coordinator stores the token after sign-in. |
| Send reports `messaging/registration-token-not-registered` | The app was uninstalled or the token rotated; open the app again so it stores the new token. |
| Send fails with `messaging/invalid-argument` | Check the custom data: `route` must be an in-app path (the form validates it). |
| Crash command succeeds but the app does not close | Install the current app build (the `type=test_crash` handler is in `NotificationService`) and make sure the chosen user has a device token. Data messages need Google Play services. |
| Analytics says `GA4_PROPERTY_ID is not set` | The env var is missing in the shell that runs `npm start` | Set `GA4_PROPERTY_ID` to the numeric property id and restart. |
| Analytics returns `403 PERMISSION_DENIED` | The service account is not a Viewer on the property, or the Data API is disabled | Add `client_email` in GA4 Property access management and enable the API. |
| Analytics returns `404` | Wrong property id | Use the numeric GA4 property id, not the `G-...` measurement id. |
| Analytics returns `429` | Realtime quota exhausted | Wait for the reset or poll less often; the dashboard already caches for 10 s. |
