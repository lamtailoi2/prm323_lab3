import { forwardRef } from 'react';

const CrashDialog = forwardRef(function CrashDialog({ copy, onClose }, ref) {
  return (
    <dialog
      ref={ref}
      className="dialog"
      aria-labelledby="crash-dialog-title"
      onClose={onClose}
    >
      <form method="dialog">
        <p className="eyebrow">Confirm crash</p>
        <h2 id="crash-dialog-title">Close Internly on the selected app(s)?</h2>
        <p className="body-copy">{copy}</p>
        <div className="dialog-actions">
          <button value="cancel" className="button ghost">
            Cancel
          </button>
          <button value="confirm" className="button danger">
            Crash now
          </button>
        </div>
      </form>
    </dialog>
  );
});

export default CrashDialog;
