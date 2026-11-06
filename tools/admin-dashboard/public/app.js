// Internly admin dashboard — browser UI. Talks only to the local Node server;
// no Firebase credential ever reaches the browser.

const state = {
  users: [],
  selectedUid: null,
  history: [],
  filter: '',
  ready: false,
};

const $ = (id) => document.getElementById(id);

const els = {
  projectLine: $('project-line'),
  statusDot: $('status-dot'),
  statusText: $('status-text'),
  banner: $('banner'),
  usersSummary: $('users-summary'),
  userList: $('user-list'),
  userSearch: $('user-search'),
  refreshUsers: $('refresh-users'),
  target: $('target'),
  targetPill: $('target-pill'),
  title: $('title'),
  body: $('body'),
  route: $('route'),
  saveHistory: $('save-history'),
  sendForm: $('send-form'),
  sendButton: $('send-button'),
  sendResult: $('send-result'),
  historyTitle: $('history-heading'),
  historySummary: $('history-summary'),
  historyList: $('history-list'),
  refreshHistory: $('refresh-history'),
  clearHistory: $('clear-history'),
};

async function api(path, options = {}) {
  const response = await fetch(path, {
    headers: { 'Content-Type': 'application/json' },
    ...options,
  });
  let payload = {};
  try {
    payload = await response.json();
  } catch {
    // A non-JSON error (proxy, server crash) still gets a readable message.
  }
  if (!response.ok) {
    const error = new Error(payload.error || `Request failed (${response.status}).`);
    error.hint = payload.hint;
    throw error;
  }
  return payload;
}

function showBanner(text) {
  els.banner.textContent = text;
  els.banner.hidden = !text;
}

function setStatus(kind, text) {
  els.statusDot.classList.remove('ok', 'bad');
  if (kind) els.statusDot.classList.add(kind);
  els.statusText.textContent = text;
}

function showSendResult(text, kind) {
  els.sendResult.textContent = text;
  els.sendResult.className = `result ${kind}`;
  els.sendResult.hidden = false;
}

function formatTime(iso) {
  if (!iso) return 'time unknown';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return 'time unknown';
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date);
}

function displayName(user) {
  return user?.name || user?.email || user?.uid || 'Unknown user';
}

async function loadStatus() {
  try {
    const status = await api('/api/status');
    state.ready = Boolean(status.ready);
    const credential = status.credentials?.found
      ? 'service-account key'
      : 'application-default credentials';
    els.projectLine.textContent = `${status.projectId || 'unknown project'} · ${credential}`;
    if (status.ready) {
      setStatus('ok', 'Ready');
      showBanner('');
      els.sendButton.disabled = false;
    } else {
      setStatus('bad', 'No credential');
      showBanner(
        status.hint ||
          status.error ||
          'The dashboard has no Firebase access yet.',
      );
      els.sendButton.disabled = true;
    }
  } catch (error) {
    setStatus('bad', 'Server unreachable');
    showBanner(error.message);
    els.sendButton.disabled = true;
  }
}

async function loadUsers() {
  els.usersSummary.textContent = 'Loading users…';
  try {
    const payload = await api('/api/users');
    state.users = payload.users ?? [];
    renderUsers();
    const count = state.users.length;
    const withToken = state.users.filter((user) => user.token).length;
    els.usersSummary.textContent = `${count} user${count === 1 ? '' : 's'} · ${withToken} with a device token${
      payload.authError ? ' · Auth lookup failed' : ''
    }`;
  } catch (error) {
    els.usersSummary.textContent = error.message;
    state.users = [];
    renderUsers();
    if (error.hint) showBanner(error.hint);
  }
}

function filteredUsers() {
  const needle = state.filter.trim().toLowerCase();
  if (!needle) return state.users;
  return state.users.filter((user) =>
    [user.name, user.email, user.uid]
      .filter(Boolean)
      .some((value) => value.toLowerCase().includes(needle)),
  );
}

function renderUsers() {
  els.userList.replaceChildren();
  const users = filteredUsers();
  if (users.length === 0) {
    const empty = document.createElement('li');
    empty.className = 'empty';
    empty.textContent = state.users.length
      ? 'No user matches that filter.'
      : 'No users yet. Sign in to the app on a device first.';
    els.userList.append(empty);
    return;
  }

  for (const user of users) {
    const item = document.createElement('li');

    const select = document.createElement('button');
    select.type = 'button';
    select.className = user.uid === state.selectedUid ? 'selected' : '';
    select.setAttribute('aria-pressed', String(user.uid === state.selectedUid));
    select.addEventListener('click', () => selectUser(user.uid));

    const name = document.createElement('span');
    name.className = 'user-name';
    name.textContent = displayName(user);
    select.append(name);

    const email = document.createElement('span');
    email.className = 'user-meta';
    email.textContent = user.email || 'no email on the Auth record';
    select.append(email);

    const uid = document.createElement('span');
    uid.className = 'user-uid';
    uid.textContent = user.uid;
    select.append(uid);

    item.append(select);

    const tokenRow = document.createElement('div');
    tokenRow.className = 'token-row';

    const tokenState = document.createElement('span');
    tokenState.className = `token-state${user.token ? ' has-token' : ''}`;
    tokenState.textContent = user.token ? 'Device token' : 'No token';
    if (user.tokenUpdatedAt) {
      tokenState.title = `Updated ${formatTime(user.tokenUpdatedAt)}`;
    }
    tokenRow.append(tokenState);

    if (user.token) {
      const copy = document.createElement('button');
      copy.type = 'button';
      copy.className = 'ghost small';
      copy.textContent = 'Copy token';
      copy.addEventListener('click', () => copyToken(user.token, copy));
      tokenRow.append(copy);
    }

    item.append(tokenRow);
    els.userList.append(item);
  }
}

async function copyToken(token, button) {
  try {
    await navigator.clipboard.writeText(token);
  } catch {
    const helper = document.createElement('textarea');
    helper.value = token;
    document.body.append(helper);
    helper.select();
    document.execCommand('copy');
    helper.remove();
  }
  const original = button.textContent;
  button.textContent = 'Copied';
  setTimeout(() => {
    button.textContent = original;
  }, 1500);
}

function selectUser(uid) {
  state.selectedUid = uid;
  state.history = [];
  renderUsers();
  updateTargetPill();
  loadHistory();
}

function updateTargetPill() {
  const user = state.users.find((entry) => entry.uid === state.selectedUid);
  els.targetPill.textContent =
    els.target.value === 'all'
      ? 'All users with a token'
      : user
        ? displayName(user)
        : 'No user selected';
}

async function loadHistory() {
  const uid = state.selectedUid;
  if (!uid) {
    els.historySummary.textContent = 'Select a user to see their history.';
    els.historyList.replaceChildren();
    els.historyTitle.textContent = 'Notification history';
    return;
  }

  const user = state.users.find((entry) => entry.uid === uid);
  els.historyTitle.textContent = `Notification history — ${displayName(user)}`;
  els.historySummary.textContent = 'Loading…';
  try {
    const payload = await api(
      `/api/notifications?uid=${encodeURIComponent(uid)}`,
    );
    state.history = payload.notifications ?? [];
    renderHistory();
  } catch (error) {
    els.historySummary.textContent = error.message;
    state.history = [];
    renderHistory();
    if (error.hint) showBanner(error.hint);
  }
}

function renderHistory() {
  els.historyList.replaceChildren();
  if (!state.selectedUid) return;

  if (state.history.length === 0) {
    const empty = document.createElement('li');
    empty.className = 'empty';
    empty.textContent = 'No notifications stored for this user yet.';
    els.historyList.append(empty);
    els.historySummary.textContent = '0 notifications';
    return;
  }

  const unread = state.history.filter((entry) => !entry.read).length;
  els.historySummary.textContent = `${state.history.length} notifications · ${unread} unread`;

  for (const notification of state.history) {
    const item = document.createElement('li');

    const head = document.createElement('div');
    head.className = 'history-head';

    const title = document.createElement('span');
    title.className = 'history-title';
    title.textContent = notification.title;
    head.append(title);

    const remove = document.createElement('button');
    remove.type = 'button';
    remove.className = 'ghost small danger';
    remove.textContent = 'Delete';
    remove.setAttribute(
      'aria-label',
      `Delete notification ${notification.title}`,
    );
    remove.addEventListener('click', () => deleteNotification(notification.id));
    head.append(remove);

    item.append(head);

    if (notification.body) {
      const body = document.createElement('p');
      body.className = 'history-body';
      body.textContent = notification.body;
      item.append(body);
    }

    const meta = document.createElement('div');
    meta.className = 'history-meta';

    const badge = document.createElement('span');
    badge.className = `badge ${notification.read ? 'read' : 'unread'}`;
    badge.textContent = notification.read ? 'Read' : 'Unread';
    meta.append(badge);

    const time = document.createElement('span');
    time.textContent = formatTime(notification.receivedAt);
    meta.append(time);

    if (notification.route) {
      const route = document.createElement('span');
      route.className = 'route';
      route.textContent = notification.route;
      meta.append(route);
    }

    item.append(meta);
    els.historyList.append(item);
  }
}

async function deleteNotification(id) {
  if (!state.selectedUid) return;
  try {
    await api(
      `/api/notifications/${encodeURIComponent(state.selectedUid)}/${encodeURIComponent(id)}`,
      { method: 'DELETE' },
    );
    state.history = state.history.filter((entry) => entry.id !== id);
    renderHistory();
  } catch (error) {
    showBanner(error.message);
  }
}

async function clearHistory() {
  if (!state.selectedUid) return;
  const confirmed = window.confirm(
    'Delete every stored notification for this user?',
  );
  if (!confirmed) return;
  try {
    const payload = await api(
      `/api/notifications?uid=${encodeURIComponent(state.selectedUid)}`,
      { method: 'DELETE' },
    );
    state.history = [];
    renderHistory();
    showSendResult(`Deleted ${payload.deleted} notification(s).`, 'ok');
  } catch (error) {
    showBanner(error.message);
  }
}

els.sendForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  if (!state.ready) {
    showSendResult('The dashboard has no Firebase credential yet.', 'bad');
    return;
  }

  const target = els.target.value;
  if (target === 'uid' && !state.selectedUid) {
    showSendResult('Select a user first, or choose "All users".', 'bad');
    return;
  }

  els.sendButton.disabled = true;
  els.sendButton.textContent = 'Sending…';
  try {
    const payload = await api('/api/send', {
      method: 'POST',
      body: JSON.stringify({
        target,
        uid: state.selectedUid,
        title: els.title.value,
        body: els.body.value,
        route: els.route.value,
        saveHistory: els.saveHistory.checked,
      }),
    });

    const lines = [
      `Sent ${payload.successCount} of ${payload.requested}.`,
      `History entries written: ${payload.historyWritten}.`,
    ];
    if (payload.historyError) {
      lines.push(`History was not written: ${payload.historyError}`);
    }
    const failures = (payload.results ?? []).filter((entry) => !entry.ok);
    if (failures.length) {
      lines.push(
        `Failed (${failures.length}): ${failures
          .slice(0, 5)
          .map((entry) => entry.error)
          .join(', ')}${failures.length > 5 ? '…' : ''}`,
      );
    }
    showSendResult(lines.join('\n'), failures.length ? 'bad' : 'ok');

    if (target === 'uid') {
      await loadHistory();
    } else {
      await loadUsers();
    }
    await loadStatus();
  } catch (error) {
    showSendResult(error.message, 'bad');
    if (error.hint) showBanner(error.hint);
  } finally {
    els.sendButton.disabled = !state.ready;
    els.sendButton.textContent = 'Send';
  }
});

els.refreshUsers.addEventListener('click', loadUsers);
els.refreshHistory.addEventListener('click', loadHistory);
els.clearHistory.addEventListener('click', clearHistory);
els.userSearch.addEventListener('input', () => {
  state.filter = els.userSearch.value;
  renderUsers();
});
els.target.addEventListener('change', updateTargetPill);

(async function init() {
  await loadStatus();
  await loadUsers();
  updateTargetPill();
})();
