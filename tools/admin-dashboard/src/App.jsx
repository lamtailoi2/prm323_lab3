import { useCallback, useEffect, useMemo, useRef, useState } from 'react';

import { api } from './api';
import AnalyticsPanel from './components/AnalyticsPanel';
import Banner from './components/Banner';
import ComposePanel from './components/ComposePanel';
import CrashDialog from './components/CrashDialog';
import CrashPanel from './components/CrashPanel';
import DeliveryPanel from './components/DeliveryPanel';
import HistoryPanel from './components/HistoryPanel';
import LoginScreen from './components/LoginScreen';
import Topbar from './components/Topbar';
import UsersRail from './components/UsersRail';
import { signOut, watchAuth } from './firebase';
import { displayName } from './format';

export default function App() {
  const [user, setUser] = useState(undefined);
  const [status, setStatus] = useState(null);
  const [statusError, setStatusError] = useState(null);
  const [banner, setBanner] = useState('');

  const [users, setUsers] = useState([]);
  const [usersLoading, setUsersLoading] = useState(false);
  const [usersError, setUsersError] = useState(null);
  const [authError, setAuthError] = useState(null);
  const [filter, setFilter] = useState('');

  const [selectedUid, setSelectedUid] = useState(null);
  const [recipient, setRecipient] = useState('');

  const [history, setHistory] = useState([]);
  const [historyLoading, setHistoryLoading] = useState(false);
  const [historyError, setHistoryError] = useState(null);

  const [analyticsData, setAnalyticsData] = useState(null);
  const [analyticsLoading, setAnalyticsLoading] = useState(false);
  const [analyticsError, setAnalyticsError] = useState(null);

  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [route, setRoute] = useState('');
  const [saveHistory, setSaveHistory] = useState(true);
  const [sending, setSending] = useState(false);
  const [sendResult, setSendResult] = useState(null);

  const [crashAck, setCrashAck] = useState(false);
  const [crashing, setCrashing] = useState(false);
  const [crashResult, setCrashResult] = useState(null);

  const [delivery, setDelivery] = useState(null);

  const crashDialog = useRef(null);
  const historyRequest = useRef(0);

  useEffect(() => watchAuth(setUser), []);

  const loadStatus = useCallback(async () => {
    setStatusError(null);
    try {
      const payload = await api('/api/status');
      setStatus(payload);
      setBanner(
        payload.ready
          ? ''
          : payload.hint ||
              payload.error ||
              'The dashboard has no Firebase access yet.',
      );
    } catch (error) {
      setStatus(null);
      setStatusError({
        message: error.message,
        hint: error.hint ?? null,
        status: error.status ?? null,
      });
      setBanner(error.hint || error.message);
    }
  }, []);

  const loadUsers = useCallback(async () => {
    setUsersLoading(true);
    setUsersError(null);
    try {
      const payload = await api('/api/users');
      setUsers(payload.users ?? []);
      setAuthError(payload.authError ?? null);
    } catch (error) {
      setUsers([]);
      setUsersError(error.message);
      if (error.hint) setBanner(error.hint);
    } finally {
      setUsersLoading(false);
    }
  }, []);

  const loadHistory = useCallback(async (uid) => {
    const request = historyRequest.current + 1;
    historyRequest.current = request;

    if (!uid) {
      setHistory([]);
      setHistoryError(null);
      setHistoryLoading(false);
      return;
    }

    setHistoryLoading(true);
    setHistoryError(null);
    try {
      const payload = await api(
        `/api/notifications?uid=${encodeURIComponent(uid)}`,
      );
      if (historyRequest.current !== request) return;
      setHistory(payload.notifications ?? []);
    } catch (error) {
      if (historyRequest.current !== request) return;
      setHistory([]);
      setHistoryError(error.message);
      if (error.hint) setBanner(error.hint);
    } finally {
      if (historyRequest.current === request) setHistoryLoading(false);
    }
  }, []);

  const loadAnalytics = useCallback(async () => {
    if (document.visibilityState === 'hidden') return;
    setAnalyticsLoading(true);
    try {
      const payload = await api('/api/analytics/realtime');
      setAnalyticsData(payload);
      setAnalyticsError(null);
    } catch (error) {
      setAnalyticsData(null);
      setAnalyticsError(
        error.hint ? `${error.message} ${error.hint}` : error.message,
      );
    } finally {
      setAnalyticsLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!user) return undefined;
    loadStatus();
    loadUsers();
    return undefined;
  }, [user, loadStatus, loadUsers]);

  useEffect(() => {
    if (!user) return undefined;
    loadAnalytics();
    const timer = setInterval(loadAnalytics, 15000);
    return () => clearInterval(timer);
  }, [user, loadAnalytics]);

  const usersWithToken = useMemo(
    () => users.filter((entry) => Boolean(entry.token)),
    [users],
  );

  const selectedUser =
    users.find((entry) => entry.uid === selectedUid) ?? null;
  const recipientUser =
    recipient === 'all'
      ? null
      : (users.find((entry) => entry.uid === recipient) ?? null);

  const hasRecipient =
    recipient === 'all'
      ? usersWithToken.length > 0
      : Boolean(recipientUser?.token);

  const canSend = Boolean(status?.ready) && hasRecipient;
  const canCrash = canSend && crashAck && !crashing;

  // Drop a recipient that lost its device token after a reload.
  useEffect(() => {
    if (!recipient) return;
    const valid =
      recipient === 'all'
        ? usersWithToken.length > 0
        : Boolean(users.find((entry) => entry.uid === recipient)?.token);
    if (!valid) setRecipient('');
  }, [recipient, users, usersWithToken.length]);

  const filteredUsers = useMemo(() => {
    const needle = filter.trim().toLowerCase();
    if (!needle) return users;
    return users.filter((entry) =>
      [entry.name, entry.email, entry.uid]
        .filter(Boolean)
        .some((value) => value.toLowerCase().includes(needle)),
    );
  }, [filter, users]);

  const usersSummary = usersLoading
    ? 'Loading users…'
    : usersError
      ? usersError
      : `${users.length} user${users.length === 1 ? '' : 's'} · ${
          usersWithToken.length
        } with a device token${authError ? ' · Auth lookup failed' : ''}`;

  const unreadCount = history.filter((entry) => !entry.read).length;
  const historySummary = !selectedUid
    ? 'Select a recipient to see their history.'
    : historyLoading
      ? `Loading ${displayName(selectedUser)}…`
      : historyError
        ? historyError
        : history.length === 0
          ? `${displayName(selectedUser)} · 0 notifications`
          : `${displayName(selectedUser)} · ${history.length} notification${
              history.length === 1 ? '' : 's'
            } · ${unreadCount} unread`;

  let targetPill = 'No recipient';
  let recipientHint = 'Pick one student or everyone with a device token.';
  if (recipient === 'all') {
    targetPill = `Everyone · ${usersWithToken.length} device${
      usersWithToken.length === 1 ? '' : 's'
    }`;
    recipientHint = 'The message goes to every user with a device token.';
  } else if (recipientUser) {
    targetPill = `To ${displayName(recipientUser)}`;
    recipientHint = recipientUser.token
      ? `Sending to ${displayName(recipientUser)}.`
      : 'This user has no device token. Open the app while signed in to register one.';
  }

  const credential = status?.credentials?.found
    ? 'service-account key'
    : 'application-default credentials';
  const projectLine = status
    ? `${status.projectId || 'unknown project'} · ${credential}`
    : statusError
      ? 'Dashboard unavailable'
      : 'Connecting…';
  const statusKind = status?.ready ? 'ok' : status || statusError ? 'bad' : '';
  const statusText = status?.ready
    ? 'Ready'
    : status
      ? 'No credential'
      : statusError
        ? statusError.status === 503
          ? 'Not configured'
          : 'Unavailable'
        : 'Checking credentials…';

  function selectUser(uid) {
    setSelectedUid(uid);
    const target = users.find((entry) => entry.uid === uid);
    setRecipient(target?.token ? uid : '');
    loadHistory(uid);
  }

  function changeRecipient(value) {
    setRecipient(value);
    if (value && value !== 'all') {
      setSelectedUid(value);
      loadHistory(value);
    }
  }

  function clearRecipient() {
    setRecipient('');
  }

  function currentTarget() {
    if (!recipient) return null;
    return recipient === 'all'
      ? { target: 'all', uid: null }
      : { target: 'uid', uid: recipient };
  }

  function describeRecipient() {
    if (recipient === 'all') {
      return `everyone with a token (${usersWithToken.length} device${
        usersWithToken.length === 1 ? '' : 's'
      })`;
    }
    return recipientUser ? displayName(recipientUser) : 'the selected recipient';
  }

  async function sendNotification(event) {
    event.preventDefault();
    if (!status?.ready) {
      setSendResult({
        text: 'The dashboard has no Firebase credential yet.',
        kind: 'bad',
      });
      return;
    }
    const target = currentTarget();
    if (!target) {
      setSendResult({ text: 'Choose a recipient first.', kind: 'bad' });
      return;
    }

    setSending(true);
    setSendResult(null);
    try {
      const payload = await api('/api/send', {
        method: 'POST',
        body: JSON.stringify({
          ...target,
          title,
          body,
          route,
          saveHistory,
        }),
      });

      const failures = (payload.results ?? []).filter((entry) => !entry.ok);
      const lines = [
        `Sent ${payload.successCount} of ${payload.requested}.`,
        `History entries written: ${payload.historyWritten}.`,
      ];
      if (payload.historyError) {
        lines.push(`History was not written: ${payload.historyError}`);
      }
      if (failures.length) {
        lines.push(
          `Failed (${failures.length}): ${failures
            .slice(0, 5)
            .map((entry) => entry.error)
            .join(', ')}${failures.length > 5 ? '…' : ''}`,
        );
      }
      setSendResult({
        text: lines.join('\n'),
        kind: failures.length ? 'bad' : 'ok',
      });
      setDelivery({
        kind: 'Notification',
        successLabel: 'Delivered',
        requested: payload.requested,
        results: payload.results ?? [],
      });

      if (target.target === 'uid') {
        await loadHistory(target.uid);
      } else {
        await loadUsers();
      }
      await loadStatus();
    } catch (error) {
      setSendResult({ text: error.message, kind: 'bad' });
      if (error.hint) setBanner(error.hint);
    } finally {
      setSending(false);
    }
  }

  function openCrashDialog() {
    const dialog = crashDialog.current;
    if (!dialog) return;
    dialog.returnValue = '';
    dialog.showModal();
  }

  async function sendCrash() {
    const target = currentTarget();
    if (!target) return;

    setCrashing(true);
    setCrashResult(null);
    try {
      const payload = await api('/api/test-crash', {
        method: 'POST',
        body: JSON.stringify(target),
      });
      const failures = (payload.results ?? []).filter((entry) => !entry.ok);
      const lines = [
        `Crash command sent to ${payload.successCount} of ${payload.requested}.`,
      ];
      if (failures.length) {
        lines.push(
          `Failed (${failures.length}): ${failures
            .slice(0, 5)
            .map((entry) => entry.error)
            .join(', ')}${failures.length > 5 ? '…' : ''}`,
        );
      }
      setCrashResult({
        text: lines.join('\n'),
        kind: failures.length ? 'bad' : 'ok',
      });
      setDelivery({
        kind: 'Crash command',
        successLabel: 'Command sent',
        requested: payload.requested,
        results: payload.results ?? [],
      });
      setCrashAck(false);
    } catch (error) {
      setCrashResult({ text: error.message, kind: 'bad' });
      if (error.hint) setBanner(error.hint);
    } finally {
      setCrashing(false);
    }
  }

  async function deleteNotification(id) {
    if (!selectedUid) return;
    try {
      await api(
        `/api/notifications/${encodeURIComponent(selectedUid)}/${encodeURIComponent(id)}`,
        { method: 'DELETE' },
      );
      setHistory((current) => current.filter((entry) => entry.id !== id));
    } catch (error) {
      setBanner(error.message);
    }
  }

  async function clearHistory() {
    if (!selectedUid) return;
    if (!window.confirm('Delete every stored notification for this user?')) {
      return;
    }
    try {
      const payload = await api(
        `/api/notifications?uid=${encodeURIComponent(selectedUid)}`,
        { method: 'DELETE' },
      );
      setHistory([]);
      setSendResult({
        text: `Deleted ${payload.deleted} notification(s).`,
        kind: 'ok',
      });
    } catch (error) {
      setBanner(error.message);
    }
  }

  async function handleSignOut() {
    await signOut();
    setStatus(null);
    setStatusError(null);
    setBanner('');
    setUsers([]);
    setSelectedUid(null);
    setRecipient('');
    setHistory([]);
    setAnalyticsData(null);
    setDelivery(null);
    setSendResult(null);
    setCrashResult(null);
    setCrashAck(false);
  }

  if (user === undefined) {
    return <div className="session">Checking session…</div>;
  }

  if (user === null) {
    return <LoginScreen />;
  }

  if (statusError?.status === 403) {
    return (
      <main className="login">
        <section className="login-card" aria-labelledby="denied-title">
          <p className="eyebrow">Operations desk</p>
          <h1 id="denied-title">Access denied</h1>
          <p className="body-copy">
            {user.email || user.uid} is signed in but is not on the admin
            allowlist. Ask the owner to add it to <code>ADMIN_EMAILS</code>, or
            sign in with another account.
          </p>
          <div className="form-actions">
            <button
              className="button primary"
              type="button"
              onClick={handleSignOut}
            >
              Sign out
            </button>
          </div>
        </section>
      </main>
    );
  }

  return (
    <>
      <a className="skip-link" href="#workspace">
        Skip to workspace
      </a>

      <Topbar
        projectLine={projectLine}
        statusKind={statusKind}
        statusText={statusText}
        adminEmail={status?.admin?.email || user.email}
        onSignOut={handleSignOut}
      />

      <Banner text={banner} />

      <main id="workspace">
        <UsersRail
          users={users}
          filteredUsers={filteredUsers}
          filter={filter}
          onFilter={setFilter}
          summary={usersSummary}
          loading={usersLoading}
          selectedUid={selectedUid}
          onSelect={selectUser}
          onRefresh={loadUsers}
        />

        <div className="workspace">
          <ComposePanel
            users={users}
            recipient={recipient}
            recipientHint={recipientHint}
            targetPill={targetPill}
            onChangeRecipient={changeRecipient}
            onClearRecipient={clearRecipient}
            title={title}
            onTitle={setTitle}
            body={body}
            onBody={setBody}
            route={route}
            onRoute={setRoute}
            saveHistory={saveHistory}
            onSaveHistory={setSaveHistory}
            canSend={canSend}
            sending={sending}
            result={sendResult}
            onSubmit={sendNotification}
          />

          <CrashPanel
            ack={crashAck}
            onAck={setCrashAck}
            disabled={!canCrash}
            crashing={crashing}
            onSend={openCrashDialog}
            result={crashResult}
          />

          <AnalyticsPanel
            data={analyticsData}
            error={analyticsError}
            loading={analyticsLoading}
            onRefresh={loadAnalytics}
          />

          <div className="activity-grid">
            <DeliveryPanel delivery={delivery} users={users} />
            <HistoryPanel
              selectedUid={selectedUid}
              summary={historySummary}
              history={history}
              loading={historyLoading}
              onRefresh={() => loadHistory(selectedUid)}
              onClear={clearHistory}
              onDelete={deleteNotification}
            />
          </div>
        </div>
      </main>

      <footer>
        Ops console · the service-account key stays on the server · only
        allowlisted admins can send.
      </footer>

      <CrashDialog
        ref={crashDialog}
        copy={
          `This sends a data-only crash command to ${describeRecipient()}. ` +
          'The app closes immediately; the fatal report uploads on its next launch.'
        }
        onClose={() => {
          if (crashDialog.current?.returnValue === 'confirm') sendCrash();
        }}
      />
    </>
  );
}
