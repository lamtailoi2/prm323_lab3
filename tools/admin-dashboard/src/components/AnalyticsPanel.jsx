export default function AnalyticsPanel({ data, error, loading, onRefresh }) {
  let summary = 'Loading GA4 realtime…';
  if (error) {
    summary = error;
  } else if (data) {
    const quota = Number.isFinite(data.quotaRemaining)
      ? ` · ${data.quotaRemaining} tokens left this hour`
      : '';
    const cached = data.cached ? ' · cached' : '';
    summary =
      `${data.activeUsers ?? 0} active user(s) · ` +
      `${data.totalEvents ?? 0} event(s) in the last 30 minutes${quota}${cached}`;
  }

  const rows = data?.rows ?? [];

  return (
    <section className="surface analytics" aria-labelledby="analytics-heading">
      <div className="surface-head">
        <div>
          <p className="eyebrow">GA4 realtime</p>
          <h2 id="analytics-heading">Analytics</h2>
        </div>
        <div className="actions">
          <span className="tag">Last 30 min</span>
          <button
            className="button ghost small"
            type="button"
            onClick={onRefresh}
            disabled={loading}
            aria-busy={loading}
          >
            Reload
          </button>
        </div>
      </div>
      <p className="body-copy">
        Active users and top events from Google Analytics 4. GA4 reports the
        last 30 minutes; the dashboard refreshes every 15 seconds.
      </p>
      <p className="meta-line" role="status" aria-live="polite">
        {summary}
      </p>
      <ul className="history-list" aria-label="Realtime events">
        {rows.length === 0 ? (
          <li className="empty">
            {error
              ? 'No GA4 data is available right now.'
              : data
                ? 'No GA4 events in the last 30 minutes.'
                : 'Loading GA4 realtime…'}
          </li>
        ) : (
          rows.map((row) => (
            <li className="delivery-row" key={row.event}>
              <span className="delivery-name">{row.event}</span>
              <span className="delivery-status ok">
                {Number.isFinite(row.users)
                  ? `${row.users} users · ${row.events} events`
                  : `${row.events} events`}
              </span>
            </li>
          ))
        )}
      </ul>
    </section>
  );
}
