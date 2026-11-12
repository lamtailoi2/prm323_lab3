import { useState } from 'react';

import { displayName, formatTime } from '../format';

function copyFallback(token) {
  const helper = document.createElement('textarea');
  helper.value = token;
  document.body.append(helper);
  helper.select();
  document.execCommand('copy');
  helper.remove();
}

function UserRow({ user, selected, onSelect }) {
  const [copied, setCopied] = useState(false);

  async function copyToken() {
    try {
      await navigator.clipboard.writeText(user.token);
    } catch {
      copyFallback(user.token);
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 1500);
  }

  return (
    <li>
      <button
        type="button"
        className="user-row"
        aria-pressed={selected}
        onClick={() => onSelect(user.uid)}
      >
        <span className="user-name">{displayName(user)}</span>
        <span className="user-meta">
          {user.email || 'no email on the Auth record'}
        </span>
        <span className="user-uid">{user.uid}</span>
        {selected ? <span className="user-check">Selected</span> : null}
      </button>

      <div className="token-row">
        <span
          className={`token-state${user.token ? ' has-token' : ''}`}
          title={
            user.tokenUpdatedAt
              ? `Updated ${formatTime(user.tokenUpdatedAt)}`
              : undefined
          }
        >
          {user.token ? 'Device token' : 'No token'}
        </span>
        {user.token ? (
          <button
            type="button"
            className="button text small"
            onClick={copyToken}
          >
            {copied ? 'Copied' : 'Copy token'}
          </button>
        ) : null}
      </div>
    </li>
  );
}

function Skeleton() {
  return (
    <li aria-hidden="true">
      <div className="skeleton" />
      <div className="skeleton short" />
    </li>
  );
}

export default function UsersRail({
  users,
  filteredUsers,
  filter,
  onFilter,
  summary,
  loading,
  selectedUid,
  onSelect,
  onRefresh,
}) {
  let emptyText = null;
  if (!loading && filteredUsers.length === 0) {
    emptyText = users.length
      ? 'No user matches that filter.'
      : 'No users yet. Sign in to the app on a device first.';
  }

  return (
    <aside className="rail" aria-labelledby="users-heading">
      <div className="rail-head">
        <div>
          <p className="eyebrow">Audience</p>
          <h2 id="users-heading">Recipients</h2>
        </div>
        <button
          type="button"
          className="button ghost small"
          onClick={onRefresh}
        >
          Reload
        </button>
      </div>

      <label className="field">
        <span className="label">Filter</span>
        <input
          type="search"
          placeholder="Name, email or uid"
          autoComplete="off"
          value={filter}
          onChange={(event) => onFilter(event.target.value)}
        />
      </label>

      <p className="meta-line" role="status" aria-live="polite">
        {summary}
      </p>
      <ul className="user-list" aria-label="Users">
        {loading
          ? [0, 1, 2, 3].map((index) => <Skeleton key={index} />)
          : filteredUsers.map((user) => (
              <UserRow
                key={user.uid}
                user={user}
                selected={user.uid === selectedUid}
                onSelect={onSelect}
              />
            ))}
        {emptyText ? <li className="empty">{emptyText}</li> : null}
      </ul>
    </aside>
  );
}
