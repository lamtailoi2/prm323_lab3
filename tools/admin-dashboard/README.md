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
  device token and when it was last stored. Copy a token with one click.
- **Send notification** — title, optional body, optional in-app `route`
  (`/home`, `/search`, `/saved`, `/applications`, `/profile` or a path below
  one of them, e.g. `/home/internships/<jobKey>`), to one user or every user
  with a token. The server reports per-recipient successes and FCM error codes.
  A single send covers up to 1000 user documents (duplicate tokens are sent
  once).
- **Notification history** — reads `users/{uid}/notifications` (newest first,
  read / unread, route, time) and deletes one entry or clears the list.

When **Write to the user's notification history** is checked, the server also
writes the document with the FCM message ID as its ID, the same ID the app uses
when it receives the message, so the two writes merge instead of duplicating.

The app keeps the Crashlytics test crash (Profile → Diagnostics → *Simulate app
crash*); the dashboard does not trigger crashes remotely.

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
