import { displayName } from '../format';

export default function ComposePanel({
  users,
  recipient,
  recipientHint,
  targetPill,
  onChangeRecipient,
  onClearRecipient,
  title,
  onTitle,
  body,
  onBody,
  route,
  onRoute,
  saveHistory,
  onSaveHistory,
  canSend,
  sending,
  result,
  onSubmit,
}) {
  const withToken = users.filter((entry) => Boolean(entry.token)).length;

  return (
    <section className="surface compose" aria-labelledby="compose-heading">
      <div className="surface-head">
        <div>
          <p className="eyebrow">Compose</p>
          <h2 id="compose-heading">Send a notification</h2>
        </div>
        <span className="recipient-chip" title={targetPill}>
          {targetPill}
        </span>
      </div>

      <form onSubmit={onSubmit} noValidate>
        <div className="form-grid">
          <label className="field span-2">
            <span className="label">Recipient</span>
            <select
              value={recipient}
              required
              onChange={(event) => onChangeRecipient(event.target.value)}
            >
              <option value="">Choose a recipient…</option>
              <option value="all" disabled={withToken === 0}>
                Everyone with a token ({withToken})
              </option>
              {users.map((user) => (
                <option key={user.uid} value={user.uid} disabled={!user.token}>
                  {displayName(user)} — {user.email || 'no email'}
                  {user.token ? '' : ' · no token'}
                </option>
              ))}
            </select>
            <span className="hint">{recipientHint}</span>
          </label>

          <label className="field span-2">
            <span className="label">Title</span>
            <input
              maxLength={200}
              required
              placeholder="New internship for you"
              value={title}
              onChange={(event) => onTitle(event.target.value)}
            />
          </label>

          <label className="field span-2">
            <span className="label">
              Body <span className="optional">optional</span>
            </span>
            <textarea
              rows={3}
              maxLength={1000}
              placeholder="A Flutter internship just matched your preferences."
              value={body}
              onChange={(event) => onBody(event.target.value)}
            />
          </label>

          <label className="field">
            <span className="label">
              Open route <span className="optional">optional</span>
            </span>
            <input
              list="route-suggestions"
              placeholder="/saved"
              value={route}
              onChange={(event) => onRoute(event.target.value)}
            />
            <datalist id="route-suggestions">
              <option value="/home" />
              <option value="/search" />
              <option value="/saved" />
              <option value="/applications" />
              <option value="/profile" />
            </datalist>
          </label>

          <label className="check-field">
            <input
              type="checkbox"
              checked={saveHistory}
              onChange={(event) => onSaveHistory(event.target.checked)}
            />
            <span>Write to the user&apos;s notification history</span>
          </label>
        </div>

        <div className="form-actions">
          <button
            className="button primary"
            type="submit"
            disabled={!canSend || sending}
            aria-busy={sending}
          >
            {sending ? 'Sending…' : 'Send notification'}
          </button>
          <button
            className="button text"
            type="button"
            onClick={onClearRecipient}
            disabled={!recipient}
          >
            Clear recipient
          </button>
        </div>
        {result ? (
          <div
            className={`result ${result.kind}`}
            role="status"
            aria-live="polite"
          >
            {result.text}
          </div>
        ) : null}
      </form>
    </section>
  );
}
