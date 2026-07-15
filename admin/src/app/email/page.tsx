"use client";

import {useEffect, useState} from "react";
import {api} from "@/lib/api";
import {Shell} from "@/components/Shell";
import {EmailDialog} from "@/components/EmailDialog";

const AUDIENCES = [
  {key: "all", label: "Everyone"},
  {key: "student", label: "Students"},
  {key: "teacher", label: "Teachers"},
  {key: "institution", label: "Institutions"},
] as const;

function Bulk() {
  const [role, setRole] = useState<string>("all");
  const [preview, setPreview] = useState<{recipients: number; skipped: number} | null>(null);
  const [composing, setComposing] = useState(false);
  const [sending, setSending] = useState(false);
  const [result, setResult] = useState<{sent: number; failed: number} | null>(null);
  const [error, setError] = useState("");

  // Always show the real recipient count BEFORE anything can be sent. An
  // "email everyone" button with no preview is one misclick from a bad day.
  useEffect(() => {
    let cancelled = false;
    setPreview(null);
    setResult(null);
    api
      .previewBulkEmail(role)
      .then((r) => !cancelled && setPreview(r.data))
      .catch((e) => !cancelled && setError(e instanceof Error ? e.message : String(e)));
    return () => {
      cancelled = true;
    };
  }, [role]);

  return (
    <>
      <h1>Announcement email</h1>
      <p className="sub">
        Sent to many people at once. Every message carries a working unsubscribe
        link, and anyone who has opted out — or been banned — is skipped.
      </p>

      <div className="tabs">
        {AUDIENCES.map((a) => (
          <button
            key={a.key}
            className={`tab ${role === a.key ? "active" : ""}`}
            onClick={() => setRole(a.key)}
          >
            {a.label}
          </button>
        ))}
      </div>

      <div className="card">
        {preview === null ? (
          <div className="meta">Counting recipients…</div>
        ) : (
          <>
            <div className="name">
              {preview.recipients} recipient
              {preview.recipients === 1 ? "" : "s"}
            </div>
            <div className="meta">
              {preview.skipped} skipped (opted out, banned, admin, or no email)
            </div>
            <div style={{height: 16}} />
            <button
              className="btn-primary"
              disabled={preview.recipients === 0}
              onClick={() => setComposing(true)}
            >
              Compose…
            </button>
          </>
        )}

        {result && (
          <div className="meta" style={{marginTop: 14, color: "var(--ok)"}}>
            Sent {result.sent}
            {result.failed > 0 && ` · ${result.failed} failed`}
          </div>
        )}
        {error && <div className="err">{error}</div>}
      </div>

      {composing && preview && (
        <EmailDialog
          title={`Email ${preview.recipients} ${
            role === "all" ? "users" : role + "s"
          }`}
          description="This goes out immediately. There is no undo — an email cannot be recalled."
          confirmLabel={`Send to ${preview.recipients}`}
          busy={sending}
          onCancel={() => setComposing(false)}
          rich
          onSend={async (subject, body, html) => {
            setSending(true);
            setError("");
            try {
              const r = await api.sendBulkEmail(role, subject, body, html);
              setResult(r.data);
              setComposing(false);
            } catch (e) {
              setError(e instanceof Error ? e.message : String(e));
            } finally {
              setSending(false);
            }
          }}
        />
      )}
    </>
  );
}

export default function Page() {
  return (
    <Shell>
      <Bulk />
    </Shell>
  );
}
