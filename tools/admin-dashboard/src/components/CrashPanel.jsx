export default function CrashPanel({
  ack,
  onAck,
  disabled,
  crashing,
  onSend,
  result,
}) {
  return (
    <section className="surface crash" aria-labelledby="crash-heading">
      <div className="surface-head">
        <div>
          <p className="eyebrow">Crashlytics test</p>
          <h2 id="crash-heading">Force a test crash</h2>
        </div>
        <span className="tag danger-tag">Destructive</span>
      </div>
      <p className="body-copy">
        Sends a data-only command to the selected app(s). Each app closes
        immediately and uploads a fatal report on its next launch. Choose{' '}
        <strong>Everyone with a token</strong> above to hit the whole app.
      </p>
      <label className="check-field danger-check">
        <input
          type="checkbox"
          checked={ack}
          onChange={(event) => onAck(event.target.checked)}
        />
        <span>I understand the selected app(s) will close immediately.</span>
      </label>
      <div className="form-actions">
        <button
          className="button danger"
          type="button"
          disabled={disabled}
          onClick={onSend}
        >
          {crashing ? 'Sending…' : 'Send test crash'}
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
    </section>
  );
}
