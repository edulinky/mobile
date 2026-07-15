"use client";

import {useEffect, useState} from "react";
import {collection, onSnapshot, query, where} from "firebase/firestore";
import {db} from "@/lib/firebase";
import {api} from "@/lib/api";
import {Shell} from "@/components/Shell";
import {ReasonDialog} from "@/components/ReasonDialog";

interface Teacher {
  uid: string;
  displayName: string;
  email: string;
  photoUrl: string;
  city: string;
  certCount: number;
  status: string;
  rejectionReason: string;
}

/**
 * A rejected teacher must remain reachable. They disappear from the "pending"
 * queue, and if an admin rejected them by mistake there would otherwise be no
 * way to undo it — they would be stuck unless they happened to re-submit.
 */
const TABS = [
  {key: "pending", label: "Pending"},
  {key: "rejected", label: "Rejected"},
  {key: "approved", label: "Approved"},
] as const;
type TabKey = (typeof TABS)[number]["key"];

function Queue() {
  const [tab, setTab] = useState<TabKey>("pending");
  const [rows, setRows] = useState<Teacher[] | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [certs, setCerts] = useState<Record<string, {path: string; url: string}[]>>({});
  const [error, setError] = useState("");
  /** The teacher we are rejecting, if the reason dialog is open. */
  const [rejecting, setRejecting] = useState<Teacher | null>(null);

  useEffect(() => {
    setRows(null);
    const q = query(
      collection(db, "users"),
      where("verified_status", "==", tab)
    );
    return onSnapshot(q, (snap) => {
      setRows(
        snap.docs.map((d) => {
          const x = d.data();
          return {
            uid: d.id,
            displayName: x.display_name ?? "",
            email: x.email ?? "",
            photoUrl: x.photo_url ?? "",
            city: x.geo_location?.city ?? "",
            certCount: (x.cert_paths ?? []).length,
            status: x.verified_status ?? "",
            rejectionReason: x.rejection_reason ?? "",
          };
        })
      );
    });
  }, [tab]);

  async function act(uid: string, fn: () => Promise<unknown>) {
    setBusy(uid);
    setError("");
    try {
      await fn();
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(null);
    }
  }

  async function viewCerts(uid: string) {
    await act(uid, async () => {
      const res = await api.getCertificateUrls(uid);
      setCerts((c) => ({...c, [uid]: res.data.urls}));
    });
  }

  if (rows === null) return <div className="empty">Loading…</div>;

  return (
    <>
      <h1>Verifications</h1>
      <p className="sub">
        Until approved, a teacher is invisible in discovery and cannot swipe.
        Rejections and approvals are both reversible from here.
      </p>

      <div className="tabs">
        {TABS.map((t) => (
          <button
            key={t.key}
            className={`tab ${tab === t.key ? "active" : ""}`}
            onClick={() => setTab(t.key)}
          >
            {t.label}
          </button>
        ))}
      </div>

      {error && <div className="err" style={{marginBottom: 12}}>{error}</div>}

      {rows.length === 0 && (
        <div className="empty">
          {tab === "pending" ? "Nothing to review. 🎉" : `No ${tab} teachers.`}
        </div>
      )}

      {rows.map((t) => (
        <div className="card" key={t.uid}>
          <div className="row">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img className="avatar" src={t.photoUrl || "/avatar.svg"} alt="" />
            <div className="grow">
              <div className="name">{t.displayName || "(no name)"}</div>
              <div className="meta">
                {t.email} · {t.city || "no city"} ·{" "}
                {t.certCount === 0
                  ? "no documents"
                  : `${t.certCount} document${t.certCount === 1 ? "" : "s"}`}
              </div>
              {t.status === "rejected" && t.rejectionReason && (
                <div className="meta" style={{color: "var(--error)"}}>
                  Rejected: {t.rejectionReason}
                </div>
              )}
            </div>
            <button
              className="btn-ghost"
              disabled={busy === t.uid || t.certCount === 0}
              onClick={() => viewCerts(t.uid)}
            >
              View documents
            </button>
            {/* An approved teacher can be rejected (revoking access); a
                rejected one can be approved (undoing a mistake). */}
            {t.status !== "rejected" && (
              <button
                className="btn-danger"
                disabled={busy === t.uid}
                onClick={() => setRejecting(t)}
              >
                Reject
              </button>
            )}
            {t.status !== "approved" && (
              <button
                className="btn-primary"
                disabled={busy === t.uid}
                onClick={() => act(t.uid, () => api.approveTeacher(t.uid))}
              >
                Approve
              </button>
            )}
          </div>

          {certs[t.uid] && (
            <div className="certs">
              {certs[t.uid].map((c, i) => (
                <a key={c.path} href={c.url} target="_blank" rel="noreferrer">
                  Document {i + 1} ↗
                </a>
              ))}
              <span className="meta">links expire in 15 minutes</span>
            </div>
          )}
        </div>
      ))}

      {rejecting && (
        <ReasonDialog
          title="Reject verification"
          description={`This is shown to ${
            rejecting.displayName || "the teacher"
          }, who can then submit new documents. Be specific.`}
          placeholder="e.g. The document is not legible. Please upload a clearer scan of your teaching qualification."
          confirmLabel="Reject"
          danger
          onCancel={() => setRejecting(null)}
          onConfirm={(reason) => {
            const uid = rejecting.uid;
            setRejecting(null);
            act(uid, () => api.rejectTeacher(uid, reason));
          }}
        />
      )}
    </>
  );
}

export default function Page() {
  return (
    <Shell>
      <Queue />
    </Shell>
  );
}
