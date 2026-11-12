import { formatTime } from '../format';

export default function HistoryPanel({
  selectedUid,
  summary,
  history,
  loading,
  onRefresh,
  onClear,
  onDelete,
}) {
  return (
    <section className="surface" aria-labelledby="history-heading">
      <div className="surface-head">
        <div>
          <p className="eyebrow">Audit</p>
          <h2 id="history-heading">Notification history</h2>
        </div>
        <div className="actions">
          <button
            className="button ghost small"
            type="button"
            onClick={onRefresh}
            disabled={!selectedUid || loading}
          >
            Reload
          </button>
          <button
            className="button ghost small danger-text"
            type="button"
            onClick={onClear}
            disabled={!selectedUid}
          >
            Clear
          </button>
        </div>
      </div>
      <p className="meta-line">{summary}</p>
      <ul className="history-list">
        {selectedUid && history.length === 0 && !loading ? (
          <li className="empty">
            No notifications stored for this user yet.
          </li>
        ) : (
          history.map((notification) => (
            <li key={notification.id}>
              <div className="history-main">
                <span className="history-title">{notification.title}</span>
                {notification.body ? (
                  <p className="history-body">{notification.body}</p>
                ) : null}
                <div className="history-meta">
                  <span
                    className={`badge ${notification.read ? 'read' : 'unread'}`}
                  >
                    {notification.read ? 'Read' : 'Unread'}
                  </span>
                  <span className="history-time">
                    {formatTime(notification.receivedAt)}
                  </span>
                  {notification.route ? (
                    <span className="route">{notification.route}</span>
                  ) : null}
                </div>
              </div>
              <div className="history-actions">
                <button
                  type="button"
                  className="button ghost small danger-text"
                  aria-label={`Delete notification ${notification.title}`}
                  onClick={() => onDelete(notification.id)}
                >
                  Delete
                </button>
              </div>
            </li>
          ))
        )}
      </ul>
    </section>
  );
}
