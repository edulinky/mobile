"use client";

import {useEffect, useRef, useState} from "react";

/**
 * Asks for a written reason before a destructive action.
 *
 * A textarea, not a one-line input: a rejection reason is shown to the teacher
 * and a ban reason goes in the audit log — both deserve more than a sentence
 * fragment, and both are read by a human later.
 */
export function ReasonDialog({
  title,
  description,
  confirmLabel,
  placeholder,
  required = true,
  danger = false,
  onConfirm,
  onCancel,
}: {
  title: string;
  description?: string;
  confirmLabel: string;
  placeholder?: string;
  required?: boolean;
  danger?: boolean;
  onConfirm: (reason: string) => void;
  onCancel: () => void;
}) {
  const [reason, setReason] = useState("");
  const ref = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    ref.current?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onCancel();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onCancel]);

  const empty = required && reason.trim().length === 0;

  return (
    <div className="overlay" onMouseDown={onCancel}>
      <div className="modal" onMouseDown={(e) => e.stopPropagation()}>
        <h2>{title}</h2>
        {description && <p className="sub" style={{margin: "6px 0 14px"}}>{description}</p>}

        <textarea
          ref={ref}
          value={reason}
          placeholder={placeholder}
          onChange={(e) => setReason(e.target.value)}
          rows={5}
          maxLength={500}
        />
        <div className="counter">{reason.length}/500</div>

        <div className="modal-actions">
          <button className="btn-ghost" onClick={onCancel}>
            Cancel
          </button>
          <button
            className={danger ? "btn-danger" : "btn-primary"}
            disabled={empty}
            onClick={() => onConfirm(reason.trim())}
          >
            {confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}
