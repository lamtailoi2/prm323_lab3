export default function Topbar({
  projectLine,
  statusKind,
  statusText,
  adminEmail,
  onSignOut,
}) {
  return (
    <header className="topbar">
      <div className="brand">
        <span className="brand-mark" aria-hidden="true">
          I.
        </span>
        <div className="brand-copy">
          <p className="eyebrow">Operations desk</p>
          <h1>Internly Ops</h1>
        </div>
      </div>
      <div className="topbar-meta">
        <p className="project-line">{projectLine}</p>
        <div className="status" role="status" aria-live="polite">
          <span className={`status-dot ${statusKind}`} aria-hidden="true" />
          <span>{statusText}</span>
        </div>
        {adminEmail ? <span className="operator">{adminEmail}</span> : null}
        <button className="button ghost small" type="button" onClick={onSignOut}>
          Sign out
        </button>
      </div>
    </header>
  );
}
