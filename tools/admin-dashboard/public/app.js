// Internly Ops — browser UI. Talks only to the local Node server; no Firebase
// credential ever reaches the browser.

const state = {
  users: [],
  selectedUid: null,
  recipient: '',
  history: [],
  filter: '',
  ready: false,
  pendingCrash: null,
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
  recipient: $('recipient'),
  recipientHint: $('recipient-hint'),
  clearRecipient: $('clear-recipient'),
  targetPill: $('target-pill'),
  title: $('title'),
  body: $('body'),
  route: $('route'),
  saveHistory: $('save-history'),
  sendForm: $('send-form'),
  sendButton: $('send-button'),
  sendResult: $('send-result'),
  crashAck: $('crash-ack'),
  crashButton: $('crash-button'),
  crashResult: $('crash-result'),
  crashDialog: $('crash-dialog'),
  crashDialogCopy: $('crash-dialog-copy'),
  deliverySummary: $('delivery-summary'),
  deliveryList: $('delivery-list'),
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
    const error = new Error(
      payload.error || `Request failed (${response.status}).`,
    );
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

function showResult(element, text, kind = '') {
  element.textContent = text;
  element.className = `result${kind ? ` ${kind}` : ''}`;
  element.hidden = false;
}

function hideResult(element) {
  element.hidden = true;
  element.textContent = '';
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

function userByUid(uid) {
  return state.users.find((entry) => entry.uid === uid) ?? null;
}

function usersWithToken() {
  return state.users.filter((user) => Boolean(user.token));
}

function setBusy(button, busy, idleLabel, busyLabel) {
  button.disabled = busy;
  button.textContent = busy ? busyLabel : idleLabel;
  button.setAttribute('aria-busy', String(busy));
}

function renderSkeleton(list, count) {
  list.replaceChildren();
  for (let index = 0; index < count; index += 1) {
    const item = document.createElement('li');
    const line = document.createElement('div');
    line.className = index % 2 === 0 ? 'skeleton' : 'skeleton short';
    item.append(line);
    list.append(item);
  }
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
    } else {
      setStatus('bad', 'No credential');
      showBanner(
        status.hint ||
          status.error ||
          'The dashboard has no Firebase access yet.',
      );
    }
  } catch (error) {
    state.ready = false;
    setStatus('bad', 'Server unreachable');
    showBanner(error.message);
  }
  updateRecipientState();
}

async function loadUsers() {
  els.usersSummary.textContent = 'Loading users…';
  renderSkeleton(els.userList, 4);
  try {
    const payload = await api('/api/users');
    state.users = payload.users ?? [];
    renderUsers();
    renderRecipientOptions();
    const count = state.users.length;
    const withToken = usersWithToken().length;
    els.usersSummary.textContent = `${count} user${count === 1 ? '' : 's'} · ${withToken} with a device token${
      payload.authError ? ' · Auth lookup failed' : ''
    }`;
  } catch (error) {
    els.usersSummary.textContent = error.message;
    state.users = [];
    renderUsers();
    renderRecipientOptions();
    if (error.hint) showBanner(error.hint);
  }
  updateRecipientState();
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
    select.className = 'user-row';
    const selected = user.uid === state.selectedUid;
    select.setAttribute('aria-pressed', String(selected));
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

    if (selected) {
      const check = document.createElement('span');
      check.className = 'user-check';
      check.textContent = 'Selected';
      select.append(check);
    }

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
      copy.className = 'button text small';
      copy.textContent = 'Copy token';
      copy.addEventListener('click', () => copyToken(user.token, copy));
      tokenRow.append(copy);
    }

    item.append(tokenRow);
    els.userList.append(item);
  }
}

function renderRecipientOptions() {
  const withToken = usersWithToken();
  const current = state.recipient;

  els.recipient.replaceChildren();
  els.recipient.append(new Option('Choose a recipient…', ''));
  const everyone = new Option(
    `Everyone with a token (${withToken.length})`,
    'all',
  );
  everyone.disabled = withToken.length === 0;
  els.recipient.append(everyone);

  for (const user of state.users) {
    const label = `${displayName(user)} — ${user.email || 'no email'}${
      user.token ? '' : ' · no token'
    }`;
    const option = new Option(label, user.uid);
    option.disabled = !user.token;
    els.recipient.append(option);
  }

  const stillValid =
    current === 'all'
      ? withToken.length > 0
      : Boolean(userByUid(current)?.token);
  state.recipient = stillValid ? current : '';
  els.recipient.value = state.recipient;
}

function updateRecipientState() {
  const recipient = state.recipient;
  const user = userByUid(recipient);
  const withToken = usersWithToken();

  let chip = 'No recipient';
  let hint = 'Pick one student or everyone with a device token.';

  if (recipient === 'all') {
    chip = `Everyone · ${withToken.length} device${
      withToken.length === 1 ? '' : 's'
    }`;
    hint = 'The message goes to every user with a device token.';
  } else if (user) {
    chip = `To ${displayName(user)}`;
    hint = user.token
      ? `Sending to ${displayName(user)}.`
      : 'This user has no device token. Open the app while signed in to register one.';
  }

  els.targetPill.textContent = chip;
  els.targetPill.title = chip;
  els.recipientHint.textContent = hint;
  els.recipient.value = recipient;
  els.clearRecipient.disabled = !recipient;

  const hasRecipient =
    recipient === 'all'
      ? withToken.length > 0
      : Boolean(user?.token);
  els.sendButton.disabled = !state.ready || !hasRecipient;
  els.crashButton.disabled =
    !state.ready || !hasRecipient || !els.crashAck.checked;
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
  const user = userByUid(uid);
  state.recipient = user?.token ? uid : '';
  renderUsers();
  renderRecipientOptions();
  updateRecipientState();
  loadHistory();
}

async function loadHistory() {
  const uid = state.selectedUid;
  if (!uid) {
    els.historySummary.textContent = 'Select a recipient to see their history.';
    els.historyList.replaceChildren();
    return;
  }

  const user = userByUid(uid);
  els.historySummary.textContent = `Loading ${displayName(user)}…`;
  renderSkeleton(els.historyList, 3);
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
  const user = userByUid(state.selectedUid);
  els.historySummary.textContent = `${displayName(user)} · ${
    state.history.length
  } notification${state.history.length === 1 ? '' : 's'} · ${unread} unread`;

  for (const notification of state.history) {
    const item = document.createElement('li');

    const main = document.createElement('div');
    main.className = 'history-main';

    const title = document.createElement('span');
    title.className = 'history-title';
    title.textContent = notification.title;
    main.append(title);

    if (notification.body) {
      const body = document.createElement('p');
      body.className = 'history-body';
      body.textContent = notification.body;
      main.append(body);
    }

    const meta = document.createElement('div');
    meta.className = 'history-meta';

    const badge = document.createElement('span');
    badge.className = `badge ${notification.read ? 'read' : 'unread'}`;
    badge.textContent = notification.read ? 'Read' : 'Unread';
    meta.append(badge);

    const time = document.createElement('span');
    time.className = 'history-time';
    time.textContent = formatTime(notification.receivedAt);
    meta.append(time);

    if (notification.route) {
      const route = document.createElement('span');
      route.className = 'route';
      route.textContent = notification.route;
      meta.append(route);
    }

    main.append(meta);
    item.append(main);

    const actions = document.createElement('div');
    actions.className = 'history-actions';

    const remove = document.createElement('button');
    remove.type = 'button';
    remove.className = 'button ghost small danger-text';
    remove.textContent = 'Delete';
    remove.setAttribute(
      'aria-label',
      `Delete notification ${notification.title}`,
    );
    remove.addEventListener('click', () => deleteNotification(notification.id));
    actions.append(remove);
    item.append(actions);

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
    showResult(
      els.sendResult,
      `Deleted ${payload.deleted} notification(s).`,
      'ok',
    );
  } catch (error) {
    showBanner(error.message);
  }
}

function renderDelivery(payload, { kind, successLabel }) {
  const results = payload.results ?? [];
  const success = results.filter((entry) => entry.ok).length;
  const failed = results.length - success;

  els.deliverySummary.textContent = `${kind}: ${success} of ${
    payload.requested
  } ${success === 1 ? 'device' : 'devices'}${
    failed ? ` · ${failed} failed` : ''
  }`;
  els.deliveryList.replaceChildren();

  if (results.length === 0) {
    const empty = document.createElement('li');
    empty.className = 'empty';
    empty.textContent = 'No recipient was reached.';
    els.deliveryList.append(empty);
    return;
  }

  for (const result of results) {
    const user = userByUid(result.uid);
    const item = document.createElement('li');
    item.className = 'delivery-row';

    const name = document.createElement('span');
    name.className = 'delivery-name';
    name.textContent = displayName(user) === 'Unknown user'
      ? result.uid
      : displayName(user);
    item.append(name);

    const status = document.createElement('span');
    status.className = `delivery-status ${result.ok ? 'ok' : 'bad'}`;
    status.textContent = result.ok
      ? successLabel
      : `Failed${result.error ? ` · ${result.error}` : ''}`;
    item.append(status);

    els.deliveryList.append(item);
  }
}

function currentTarget() {
  if (!state.recipient) return null;
  return state.recipient === 'all'
    ? { target: 'all', uid: null }
    : { target: 'uid', uid: state.recipient };
}

function describeRecipient() {
  if (state.recipient === 'all') {
    return `everyone with a token (${usersWithToken().length} device${
      usersWithToken().length === 1 ? '' : 's'
    })`;
  }
  const user = userByUid(state.recipient);
  return user ? displayName(user) : 'the selected recipient';
}

els.sendForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  if (!state.ready) {
    showResult(els.sendResult, 'The dashboard has no Firebase credential yet.', 'bad');
    return;
  }

  const target = currentTarget();
  if (!target) {
    showResult(els.sendResult, 'Choose a recipient first.', 'bad');
    return;
  }

  setBusy(els.sendButton, true, 'Send notification', 'Sending…');
  hideResult(els.sendResult);
  try {
    const payload = await api('/api/send', {
      method: 'POST',
      body: JSON.stringify({
        ...target,
        title: els.title.value,
        body: els.body.value,
        route: els.route.value,
        saveHistory: els.saveHistory.checked,
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
    showResult(
      els.sendResult,
      lines.join('\n'),
      failures.length ? 'bad' : 'ok',
    );
    renderDelivery(payload, {
      kind: 'Notification',
      successLabel: 'Delivered',
    });

    if (target.target === 'uid') {
      await loadHistory();
    } else {
      await loadUsers();
    }
    await loadStatus();
  } catch (error) {
    showResult(els.sendResult, error.message, 'bad');
    if (error.hint) showBanner(error.hint);
  } finally {
    setBusy(els.sendButton, false, 'Send notification', 'Sending…');
    updateRecipientState();
  }
});

els.crashButton.addEventListener('click', () => {
  const target = currentTarget();
  if (!target) return;
  state.pendingCrash = target;
  els.crashDialogCopy.textContent = `This sends a data-only crash command to ${describeRecipient()}. The app closes immediately; the fatal report uploads on its next launch.`;
  els.crashDialog.returnValue = '';
  els.crashDialog.showModal();
});

els.crashDialog.addEventListener('close', () => {
  if (els.crashDialog.returnValue === 'confirm') {
    sendCrash();
  } else {
    state.pendingCrash = null;
  }
});

async function sendCrash() {
  const target = state.pendingCrash;
  state.pendingCrash = null;
  if (!target) return;

  setBusy(els.crashButton, true, 'Send test crash', 'Sending…');
  hideResult(els.crashResult);
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
    showResult(
      els.crashResult,
      lines.join('\n'),
      failures.length ? 'bad' : 'ok',
    );
    renderDelivery(payload, {
      kind: 'Crash command',
      successLabel: 'Command sent',
    });
    els.crashAck.checked = false;
  } catch (error) {
    showResult(els.crashResult, error.message, 'bad');
    if (error.hint) showBanner(error.hint);
  } finally {
    setBusy(els.crashButton, false, 'Send test crash', 'Sending…');
    updateRecipientState();
  }
}

els.recipient.addEventListener('change', () => {
  state.recipient = els.recipient.value;
  if (state.recipient && state.recipient !== 'all') {
    state.selectedUid = state.recipient;
    loadHistory();
  }
  updateRecipientState();
  renderUsers();
});

els.clearRecipient.addEventListener('click', () => {
  state.recipient = '';
  els.recipient.value = '';
  updateRecipientState();
});

els.crashAck.addEventListener('change', updateRecipientState);
els.refreshUsers.addEventListener('click', loadUsers);
els.refreshHistory.addEventListener('click', loadHistory);
els.clearHistory.addEventListener('click', clearHistory);
els.userSearch.addEventListener('input', () => {
  state.filter = els.userSearch.value;
  renderUsers();
});

(async function init() {
  await loadStatus();
  await loadUsers();
  updateRecipientState();
})();
