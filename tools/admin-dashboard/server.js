// Internly admin dashboard — local only.
//
// Node + Firebase Admin SDK. The browser UI talks to this server, which holds
// the only privileged credential. The service-account key is never part of the
// repository: it is read from INTERNLY_ADMIN_SA, GOOGLE_APPLICATION_CREDENTIALS
// or ~/.internly-admin/service-account.json.
//
// Run: npm install && npm start → http://127.0.0.1:4317

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import express from 'express';
import admin from 'firebase-admin';

import {
  chunk,
  normaliseMessageId,
  requireText,
  toIso,
  validateRoute,
} from './lib/admin.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PORT = Number(process.env.PORT || 4317);
const HOST = '127.0.0.1';
const PROJECT_ID = process.env.INTERNLY_PROJECT_ID || null;

const DEFAULT_CREDENTIAL_PATH = path.join(
  os.homedir(),
  '.internly-admin',
  'service-account.json',
);

const credentialPath =
  process.env.INTERNLY_ADMIN_SA ||
  process.env.GOOGLE_APPLICATION_CREDENTIALS ||
  DEFAULT_CREDENTIAL_PATH;

const credentialFound = fs.existsSync(credentialPath);

let initError = null;
let credentialSource = credentialFound ? credentialPath : 'application-default';

try {
  if (credentialFound) {
    const serviceAccount = JSON.parse(fs.readFileSync(credentialPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: PROJECT_ID || serviceAccount.project_id,
    });
  } else {
    admin.initializeApp(PROJECT_ID ? { projectId: PROJECT_ID } : undefined);
  }
} catch (error) {
  initError = error;
}

const db = () => admin.firestore();
const messaging = () => admin.messaging();
const auth = () => admin.auth();

const app = express();
app.use(express.json({ limit: '64kb' }));
app.use(express.static(path.join(__dirname, 'public')));

function credentialHint() {
  return (
    'Create a service-account key in Firebase Console → Project settings → ' +
    'Service accounts → Generate new private key, save it as ' +
    `${DEFAULT_CREDENTIAL_PATH} (never inside the repository), then restart ` +
    'the dashboard.'
  );
}

function readinessError() {
  if (initError) return initError;
  if (!credentialFound && !process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    const error = new Error(
      'No admin credential found. The dashboard has no Firebase access.',
    );
    error.status = 503;
    error.hint = credentialHint();
    return error;
  }
  return null;
}

function sendError(res, error) {
  const notReady = readinessError();
  const cause = notReady || error;
  const message = cause.message || 'Request failed.';
  const status =
    cause.status ||
    (cause.code === 5
      ? 404
      : /credential|permission|PERMISSION_DENIED|default credentials/i.test(
            message,
          )
        ? 503
        : 500);
  res.status(status).json({
    error: message,
    hint:
      status === 503
        ? cause.hint || credentialHint()
        : undefined,
  });
}

const handle = (fn) => (req, res) => {
  Promise.resolve(fn(req, res)).catch((error) => sendError(res, error));
};

function isoOrNull(value) {
  return toIso(value);
}

app.get(
  '/api/status',
  handle(async (_req, res) => {
    let projectId = PROJECT_ID;
    try {
      projectId = admin.app().options.projectId || projectId;
    } catch {
      // The app did not initialise; the UI shows the credential hint instead.
    }
    res.json({
      projectId: projectId || null,
      ready: !readinessError(),
      credentials: {
        source: credentialSource,
        found: credentialFound,
        defaultPath: DEFAULT_CREDENTIAL_PATH,
        envOverride: Boolean(
          process.env.INTERNLY_ADMIN_SA ||
            process.env.GOOGLE_APPLICATION_CREDENTIALS,
        ),
      },
      error: initError ? initError.message : null,
      hint: readinessError()?.hint ?? null,
    });
  }),
);

app.get(
  '/api/users',
  handle(async (req, res) => {
    const limit = Math.min(Number(req.query.limit) || 200, 1000);
    const snapshot = await db().collection('users').limit(limit).get();

    const authByUid = new Map();
    let authError = null;
    try {
      const listed = await auth().listUsers(limit);
      for (const user of listed.users) {
        authByUid.set(user.uid, {
          email: user.email ?? null,
          displayName: user.displayName ?? null,
          photoUrl: user.photoURL ?? null,
          disabled: user.disabled ?? false,
          lastSignInAt: user.metadata?.lastSignInTime ?? null,
        });
      }
    } catch (error) {
      // Token data is still useful when the Auth API is unavailable.
      authError = error.message;
    }

    const users = snapshot.docs.map((doc) => {
      const data = doc.data() ?? {};
      const account = authByUid.get(doc.id) ?? {};
      authByUid.delete(doc.id);
      return {
        uid: doc.id,
        name: data.fullName ?? account.displayName ?? null,
        email: account.email ?? null,
        photoUrl: account.photoUrl ?? null,
        token: typeof data.fcmToken === 'string' ? data.fcmToken : null,
        tokenUpdatedAt: isoOrNull(data.fcmTokenUpdatedAt),
        lastSignInAt: account.lastSignInAt,
        hasProfile: true,
      };
    });

    // Signed-in accounts that never wrote to Firestore still show up, so a
    // missing token is visible instead of hidden.
    for (const [uid, account] of authByUid) {
      users.push({
        uid,
        name: account.displayName ?? null,
        email: account.email ?? null,
        photoUrl: account.photoUrl ?? null,
        token: null,
        tokenUpdatedAt: null,
        lastSignInAt: account.lastSignInAt,
        hasProfile: false,
      });
    }

    users.sort((a, b) =>
      `${a.name ?? a.email ?? a.uid}`.localeCompare(
        `${b.name ?? b.email ?? b.uid}`,
      ),
    );
    res.json({ users, authError });
  }),
);

app.get(
  '/api/notifications',
  handle(async (req, res) => {
    const uid = requireText(req.query.uid, 128);
    if (uid.error) {
      res.status(400).json({ error: 'A user id is required.' });
      return;
    }
    const limit = Math.min(Number(req.query.limit) || 100, 500);
    const snapshot = await db()
      .collection('users')
      .doc(uid.value)
      .collection('notifications')
      .orderBy('receivedAt', 'desc')
      .limit(limit)
      .get();

    res.json({
      notifications: snapshot.docs.map((doc) => {
        const data = doc.data() ?? {};
        return {
          id: doc.id,
          title: data.title ?? '(no title)',
          body: data.body ?? '',
          route: data.route ?? null,
          read: data.read === true,
          receivedAt: isoOrNull(data.receivedAt),
        };
      }),
    });
  }),
);

app.delete(
  '/api/notifications/:uid/:id',
  handle(async (req, res) => {
    await db()
      .collection('users')
      .doc(req.params.uid)
      .collection('notifications')
      .doc(req.params.id)
      .delete();
    res.json({ deleted: req.params.id });
  }),
);

app.delete(
  '/api/notifications',
  handle(async (req, res) => {
    const uid = requireText(req.query.uid, 128);
    if (uid.error) {
      res.status(400).json({ error: 'A user id is required.' });
      return;
    }
    const collection = db()
      .collection('users')
      .doc(uid.value)
      .collection('notifications');
    const snapshot = await collection.limit(500).get();
    if (snapshot.empty) {
      res.json({ deleted: 0 });
      return;
    }
    const batch = db().batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    res.json({ deleted: snapshot.size });
  }),
);

app.post(
  '/api/send',
  handle(async (req, res) => {
    const title = requireText(req.body?.title, 200);
    if (title.error) {
      res.status(400).json({ error: `Notification title: ${title.error}` });
      return;
    }
    const body = typeof req.body?.body === 'string' ? req.body.body.trim() : '';
    if (body.length > 1000) {
      res.status(400).json({ error: 'Keep the body under 1000 characters.' });
      return;
    }
    const route = validateRoute(req.body?.route);
    if (route.error) {
      res.status(400).json({ error: route.error });
      return;
    }
    const saveHistory = req.body?.saveHistory !== false;
    const target = req.body?.target === 'all' ? 'all' : 'uid';

    let recipients;
    if (target === 'uid') {
      const uid = requireText(req.body?.uid, 128);
      if (uid.error) {
        res.status(400).json({ error: 'Choose a user or send to all users.' });
        return;
      }
      const snapshot = await db().collection('users').doc(uid.value).get();
      if (!snapshot.exists) {
        res.status(404).json({ error: `No user document for ${uid.value}.` });
        return;
      }
      const token = snapshot.get('fcmToken');
      if (typeof token !== 'string' || !token.trim()) {
        res.status(409).json({
          error:
            'This user has no FCM token yet. Open the app while signed in ' +
            'and try again.',
        });
        return;
      }
      recipients = [{ uid: uid.value, token: token.trim() }];
    } else {
      const snapshot = await db().collection('users').limit(1000).get();
      const seen = new Set();
      recipients = snapshot.docs
        .map((doc) => ({
          uid: doc.id,
          token: typeof doc.get('fcmToken') === 'string'
            ? doc.get('fcmToken').trim()
            : '',
        }))
        .filter((entry) => {
          if (!entry.token || seen.has(entry.token)) return false;
          seen.add(entry.token);
          return true;
        });
      if (recipients.length === 0) {
        res.status(409).json({
          error:
            'No FCM tokens in the users collection yet. Open the app while ' +
            'signed in first.',
        });
        return;
      }
    }

    const notification = { title: title.value, body };
    const data = route.value ? { route: route.value } : {};
    const message = {
      notification,
      data,
      android: { priority: 'high' },
    };

    const results = [];
    const historyWrites = [];

    for (const group of chunk(recipients, 500)) {
      if (group.length === 1) {
        try {
          const messageId = await messaging().send({
            ...message,
            token: group[0].token,
          });
          results.push({
            uid: group[0].uid,
            ok: true,
            messageId: normaliseMessageId(messageId),
          });
          historyWrites.push({
            uid: group[0].uid,
            messageId: normaliseMessageId(messageId),
            token: group[0].token,
          });
        } catch (error) {
          results.push({
            uid: group[0].uid,
            ok: false,
            error: error.code ?? error.message,
          });
        }
        continue;
      }

      try {
        const response = await messaging().sendEachForMulticast({
          ...message,
          tokens: group.map((entry) => entry.token),
        });
        response.responses.forEach((entry, index) => {
          const recipient = group[index];
          if (entry.success) {
            results.push({
              uid: recipient.uid,
              ok: true,
              messageId: normaliseMessageId(entry.messageId),
            });
            historyWrites.push({
              uid: recipient.uid,
              messageId: normaliseMessageId(entry.messageId),
              token: recipient.token,
            });
          } else {
            results.push({
              uid: recipient.uid,
              ok: false,
              error: entry.error?.code ?? 'unknown',
            });
          }
        });
      } catch (error) {
        group.forEach((recipient) =>
          results.push({
            uid: recipient.uid,
            ok: false,
            error: error.code ?? error.message,
          }),
        );
      }
    }

    let historyWritten = 0;
    let historyError = null;
    if (saveHistory) {
      const validWrites = historyWrites.filter((entry) => entry.messageId);
      try {
        for (const group of chunk(validWrites, 500)) {
          const batch = db().batch();
          group.forEach((entry) => {
            batch.set(
              db()
                .collection('users')
                .doc(entry.uid)
                .collection('notifications')
                .doc(entry.messageId),
              {
                title: notification.title,
                body: notification.body,
                route: route.value,
                receivedAt: admin.firestore.FieldValue.serverTimestamp(),
                read: false,
              },
              { merge: true },
            );
          });
          await batch.commit();
          historyWritten += group.length;
        }
      } catch (error) {
        // The message is already on its way; report the history failure
        // instead of making the caller think the send failed.
        historyError = error.message;
      }
    }

    const successCount = results.filter((entry) => entry.ok).length;
    res.json({
      requested: recipients.length,
      successCount,
      failureCount: results.length - successCount,
      historyWritten,
      historyError,
      results,
    });
  }),
);

app.listen(PORT, HOST, () => {
  console.log(`Internly admin dashboard → http://${HOST}:${PORT}`);
  console.log(
    credentialFound
      ? `Credential: ${credentialSource}`
      : 'No service-account file found; falling back to application-default credentials.',
  );
});
