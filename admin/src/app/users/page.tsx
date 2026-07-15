"use client";

import {useEffect, useState} from "react";
import {collection, onSnapshot} from "firebase/firestore";
import {db} from "@/lib/firebase";
import {api} from "@/lib/api";
import {Shell} from "@/components/Shell";
import {ReasonDialog} from "@/components/ReasonDialog";
import {EmailDialog} from "@/components/EmailDialog";

interface Row {
  uid: string;
  displayName: string;
  email: string;
  role: string;
  photoUrl: string;
  verified: string;
  banned: boolean;
  featured: boolean;
}

function Users() {
  const [rows, setRows] = useState<Row[] | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [filter, setFilter] = useState("");
  const [error, setError] = useState("");
  /** The user we are banning, if the reason dialog is open. */
  const [banning, setBanning] = useState<Row | null>(null);
  const [emailing, setEmailing] = useState<Row | null>(null);
  const [sending, setSending] = useState(false);

  useEffect(() => {
    return onSnapshot(collection(db, "users"), (snap) => {
      setRows(
        snap.docs.map((d) => {
          const x = d.data();
          return {
            uid: d.id,
            displayName: x.display_name ?? "",
            email: x.email ?? "",
            role: x.role ?? "",
            photoUrl: x.photo_url ?? "",
            verified: x.verified_status ?? "",
            banned: x.is_banned === true,
            featured: x.featured === true,
          };
        })
      );
    });
  }, []);

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

  if (rows === null) return <div className="empty">Loading…</div>;

  const q = filter.trim().toLowerCase();
  const shown = q
    ? rows.filter(
        (r) =>
          r.email.toLowerCase().includes(q) ||
          r.displayName.toLowerCase().includes(q) ||
          r.role.includes(q)
      )
    : rows;

  return (
    <>
      <h1>Users</h1>
      <p className="sub">
        Banning revokes the live session as well as setting the flag — an ID
        token stays valid for up to an hour, so the flag alone would leave them
        able to keep messaging.
      </p>

      <input
        placeholder="Filter by name, email or role…"
        value={filter}
        onChange={(e) => setFilter(e.target.value)}
        style={{marginBottom: 18, maxWidth: 360}}
      />

      {error && <div className="err" style={{marginBottom: 12}}>{error}</div>}

      {shown.map((u) => (
        <div className="card" key={u.uid}>
          <div className="row">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img className="avatar" src={u.photoUrl || "/avatar.svg"} alt="" />
            <div className="grow">
              <div className="name">
                {u.displayName || "(no name)"}{" "}
                {u.banned && <span className="badge badge-banned">Banned</span>}{" "}
                {u.verified === "pending" && (
                  <span className="badge badge-pending">Pending</span>
                )}
                {u.verified === "approved" && (
                  <span className="badge badge-approved">Verified</span>
                )}
                {u.verified === "rejected" && (
                  <span className="badge badge-rejected">Rejected</span>
                )}
              </div>
              <div className="meta">
                {u.email} · {u.role}
                {u.featured && " · featured"}
              </div>
            </div>

            <button
              className="btn-ghost"
              disabled={busy === u.uid || !u.email}
              onClick={() => setEmailing(u)}
            >
              Email
            </button>

            {u.role !== "admin" && (
              <>
                <button
                  className="btn-ghost"
                  disabled={busy === u.uid}
                  onClick={() =>
                    act(u.uid, () => api.setFeatured(u.uid, !u.featured))
                  }
                >
                  {u.featured ? "Unfeature" : "Feature"}
                </button>
                <button
                  className={u.banned ? "btn-ghost" : "btn-danger"}
                  disabled={busy === u.uid}
                  onClick={() => {
                    if (u.banned) {
                      act(u.uid, () => api.banUser(u.uid, false));
                      return;
                    }
                    setBanning(u);
                  }}
                >
                  {u.banned ? "Unban" : "Ban"}
                </button>
              </>
            )}
          </div>
        </div>
      ))}

      {emailing && (
        <EmailDialog
          title={`Email ${emailing.displayName || emailing.email}`}
          description="Sent to this person only. Transactional — no unsubscribe link, so use it for account matters, not marketing."
          confirmLabel="Send"
          busy={sending}
          onCancel={() => setEmailing(null)}
          onSend={async (subject, body) => {
            const uid = emailing.uid;
            setSending(true);
            setError("");
            try {
              await api.sendUserEmail(uid, subject, body);
              setEmailing(null);
            } catch (e) {
              setError(e instanceof Error ? e.message : String(e));
            } finally {
              setSending(false);
            }
          }}
        />
      )}

      {banning && (
        <ReasonDialog
          title={`Ban ${banning.displayName || banning.email}`}
          description="This ends their session immediately (tokens are revoked, not just flagged) and is written to the audit log."
          placeholder="e.g. Repeated harassment of students in chat, reported on 12 July."
          confirmLabel="Ban user"
          danger
          onCancel={() => setBanning(null)}
          onConfirm={(reason) => {
            const uid = banning.uid;
            setBanning(null);
            act(uid, () => api.banUser(uid, true, reason));
          }}
        />
      )}
    </>
  );
}

export default function Page() {
  return (
    <Shell>
      <Users />
    </Shell>
  );
}
