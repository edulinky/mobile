"use client";

import {useEffect, useState} from "react";
import {collection, limit, onSnapshot, orderBy, query} from "firebase/firestore";
import {db} from "@/lib/firebase";
import {Shell} from "@/components/Shell";

interface Entry {
  id: string;
  actor: string;
  action: string;
  target: string;
  details: Record<string, unknown>;
  at: Date | null;
}

function Audit() {
  const [rows, setRows] = useState<Entry[] | null>(null);

  useEffect(() => {
    const q = query(
      collection(db, "auditLog"),
      orderBy("created_at", "desc"),
      limit(200)
    );
    return onSnapshot(q, (snap) => {
      setRows(
        snap.docs.map((d) => {
          const x = d.data();
          return {
            id: d.id,
            actor: x.actor_uid ?? "",
            action: x.action ?? "",
            target: x.target_uid ?? "",
            details: x.details ?? {},
            at: x.created_at?.toDate?.() ?? null,
          };
        })
      );
    });
  }, []);

  if (rows === null) return <div className="empty">Loading…</div>;

  return (
    <>
      <h1>Audit log</h1>
      <p className="sub">
        Every admin action, append-only. Nobody can edit or delete an entry —
        including the admin who wrote it.
      </p>

      {rows.length === 0 && <div className="empty">No actions yet.</div>}

      {rows.map((e) => (
        <div className="card" key={e.id}>
          <div className="row">
            <div className="grow">
              <div className="name">{e.action}</div>
              <div className="meta">
                actor {e.actor.slice(0, 8)}… → target {e.target.slice(0, 8)}…
                {Object.keys(e.details).length > 0 &&
                  ` · ${JSON.stringify(e.details)}`}
              </div>
            </div>
            <div className="meta">{e.at ? e.at.toLocaleString() : ""}</div>
          </div>
        </div>
      ))}
    </>
  );
}

export default function Page() {
  return (
    <Shell>
      <Audit />
    </Shell>
  );
}
