import { displayName } from '../format';

export default function DeliveryPanel({ delivery, users }) {
  const results = delivery?.results ?? [];
  const success = results.filter((entry) => entry.ok).length;
  const failed = results.length - success;

  let summary = 'No sends yet.';
  if (delivery) {
    summary = `${delivery.kind}: ${success} of ${delivery.requested} ${
      success === 1 ? 'device' : 'devices'
    }${failed ? ` · ${failed} failed` : ''}`;
  }

  function nameFor(uid) {
    const user = users.find((entry) => entry.uid === uid);
    return displayName(user) === 'Unknown user' ? uid : displayName(user);
  }

  return (
    <section className="surface" aria-labelledby="delivery-heading">
      <div className="surface-head">
        <div>
          <p className="eyebrow">Last run</p>
          <h2 id="delivery-heading">Delivery</h2>
        </div>
      </div>
      <p className="meta-line">{summary}</p>
      <ul className="delivery-list">
        {delivery && results.length === 0 ? (
          <li className="empty">No recipient was reached.</li>
        ) : (
          results.map((result) => (
            <li className="delivery-row" key={result.uid}>
              <span className="delivery-name">{nameFor(result.uid)}</span>
              <span
                className={`delivery-status ${result.ok ? 'ok' : 'bad'}`}
              >
                {result.ok
                  ? delivery.successLabel
                  : `Failed${result.error ? ` · ${result.error}` : ''}`}
              </span>
            </li>
          ))
        )}
      </ul>
    </section>
  );
}
