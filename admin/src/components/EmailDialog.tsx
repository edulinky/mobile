"use client";

import {useCallback, useEffect, useRef, useState} from "react";
import {RichText} from "./RichText";

/** Compose an email. Used for both a single user and a bulk send. */
export function EmailDialog({
  title,
  description,
  confirmLabel,
  busy = false,
  rich = false,
  onSend,
  onCancel,
}: {
  title: string;
  description?: string;
  confirmLabel: string;
  busy?: boolean;
  /** Rich text (announcements). Off for a one-to-one note. */
  rich?: boolean;
  /** `html` is empty in plain mode. */
  onSend: (subject: string, body: string, html: string) => void;
  onCancel: () => void;
}) {
  const [subject, setSubject] = useState("");
  const [body, setBody] = useState("");
  const [html, setHtml] = useState("");
  const ref = useRef<HTMLInputElement>(null);

  // The plain-text version is always sent alongside the HTML: some clients force
  // it, and it is what shows in notification previews.
  const onRichChange = useCallback((h: string, text: string) => {
    setHtml(h);
    setBody(text);
  }, []);

  useEffect(() => {
    ref.current?.focus();
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" && !busy) onCancel();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onCancel, busy]);

  const empty = subject.trim().length === 0 || body.trim().length === 0;

  return (
    <div className="overlay" onMouseDown={() => !busy && onCancel()}>
      <div
        className="modal"
        style={{maxWidth: 560}}
        onMouseDown={(e) => e.stopPropagation()}
      >
        <h2>{title}</h2>
        {description && (
          <p className="sub" style={{margin: "6px 0 16px"}}>{description}</p>
        )}

        <label htmlFor="subject">Subject</label>
        <input
          id="subject"
          ref={ref}
          value={subject}
          maxLength={200}
          onChange={(e) => setSubject(e.target.value)}
        />

        <div style={{height: 14}} />
        <label htmlFor="body">Message</label>
        {rich ? (
          <RichText onChange={onRichChange} />
        ) : (
          <>
            <textarea
              id="body"
              value={body}
              rows={10}
              maxLength={10000}
              placeholder="Plain text. Blank lines become paragraphs."
              onChange={(e) => setBody(e.target.value)}
            />
            <div className="counter">{body.length}/10000</div>
          </>
        )}

        <div className="modal-actions">
          <button className="btn-ghost" onClick={onCancel} disabled={busy}>
            Cancel
          </button>
          <button
            className="btn-primary"
            disabled={empty || busy}
            onClick={() => onSend(subject.trim(), body.trim(), html)}
          >
            {busy ? "Sending…" : confirmLabel}
          </button>
        </div>
      </div>
    </div>
  );
}
