"use client";

import {useEffect, useState} from "react";
import {collection, onSnapshot, query, where} from "firebase/firestore";
import {db} from "@/lib/firebase";
import {api} from "@/lib/api";
import {Shell} from "@/components/Shell";
import {ReasonDialog} from "@/components/ReasonDialog";
import {EmailDialog} from "@/components/EmailDialog";

interface Report {
  id: string;
  reporterId: string;
  reporterName: string;
  reportedId: string;
  reportedName: string;
  reportedRole: string;
  reason: string;
  details: string;
  at: Date | null;
}

const TABS = [
  {key: "open", label: "Open"},
  {key: "actioned", label: "Actioned"},
  {key: "dismissed", label: "Dismissed"},
] as const;
type TabKey = (typeof TABS)[number]["key"];

/**
 * A per-report list buries the thing that matters most: repeat offenders. One
 * report is often noise — someone annoyed at being passed on. Five reports from
 * five different people is a pattern, and in a flat list you would have to
 * *notice* the same name five times.
 */
type View = "byUser" | "byReport";

interface FlaggedUser {
  uid: string;
  name: string;
  role: string;
  reports: Report[];
  reasons: string[];
  reporters: number;
  oldest: Date | null;
}

function groupByUser(rows: Report[]): FlaggedUser[] {
  const map = new Map<string, FlaggedUser>();
  for (const r of rows) {
    const g = map.get(r.reportedId) ?? {
      uid: r.reportedId,
      name: r.reportedName,
      role: r.reportedRole,
      reports: [],
      reasons: [],
      reporters: 0,
      oldest: null,
    };
    g.reports.push(r);
    if (!g.reasons.includes(r.reason)) g.reasons.push(r.reason);
    if (!g.oldest || (r.at && r.at < g.oldest)) g.oldest = r.at;
    map.set(r.reportedId, g);
  }
  for (const g of map.values()) {
    g.reporters = new Set(g.reports.map((r) => r.reporterId)).size;
  }
  // Most-reported first — the pattern is the signal.
  return [...map.values()].sort(
    (a, b) => b.reporters - a.reporters || b.reports.length - a.reports.length
  );
}

function hoursSince(d: Date | null): number {
  if (!d) return 0;
  return (Date.now() - d.getTime()) / 3_600_000;
}

function Reports() {
  const [tab, setTab] = useState<TabKey>("open");
  const [view, setView] = useState<View>("byUser");
  const [rows, setRows] = useState<Report[] | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [banning, setBanning] = useState<Report | null>(null);
  /** Warn = email the reported user and close the report, without banning. */
  const [warning, setWarning] = useState<Report | null>(null);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    setRows(null);
    const q = query(collection(db, "reports"), where("status", "==", tab));
    return onSnapshot(q, (snap) => {
      setRows(
        snap.docs
          .map((d) => {
            const x = d.data();
            return {
              id: d.id,
              reporterId: x.reporter_id ?? "",
              reporterName: x.reporter_name ?? "",
              reportedId: x.reported_id ?? "",
              reportedName: x.reported_name ?? "",
              reportedRole: x.reported_role ?? "",
              reason: (x.reason ?? "").replace(/_/g, " "),
              details: x.details ?? "",
              at: x.created_at?.toDate?.() ?? null,
            };
          })
          .sort((a, b) => (a.at?.getTime() ?? 0) - (b.at?.getTime() ?? 0))
      );
    });
  }, [tab]);

  async function act(id: string, fn: () => Promise<unknown>) {
    setBusy(id);
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

  return (
    <>
      <h1>Reports</h1>
      <p className="sub">
        Apple and Google require reports to be acted on within <strong>24
        hours</strong>. Rows past that are flagged.
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
        <span style={{flex: 1}} />
        <button
          className={`tab ${view === "byUser" ? "active" : ""}`}
          onClick={() => setView("byUser")}
        >
          By user
        </button>
        <button
          className={`tab ${view === "byReport" ? "active" : ""}`}
          onClick={() => setView("byReport")}
        >
          By report
        </button>
      </div>

      {error && <div className="err" style={{marginBottom: 12}}>{error}</div>}
      {rows.length === 0 && (
        <div className="empty">
          {tab === "open" ? "No open reports. 🎉" : `No ${tab} reports.`}
        </div>
      )}

      {view === "byUser" &&
        groupByUser(rows).map((u) => {
          const overdue = tab === "open" && hoursSince(u.oldest) > 24;
          return (
            <div
              className="card"
              key={u.uid}
              style={overdue ? {borderLeft: "3px solid var(--error)"} : undefined}
            >
              <div className="row">
                <div className="grow">
                  <div className="name">
                    {u.name || u.uid}{" "}
                    <span className="badge badge-banned">
                      {u.reporters} reporter{u.reporters === 1 ? "" : "s"}
                    </span>{" "}
                    {u.reports.length !== u.reporters && (
                      <span className="badge badge-pending">
                        {u.reports.length} reports
                      </span>
                    )}{" "}
                    {overdue && (
                      <span className="badge badge-rejected">
                        overdue ({Math.floor(hoursSince(u.oldest))}h)
                      </span>
                    )}
                  </div>
                  <div className="meta">
                    {u.role} · {u.reasons.join(", ")}
                    {u.oldest && ` · oldest ${u.oldest.toLocaleString()}`}
                  </div>
                  {u.reports
                    .filter((r) => r.details)
                    .map((r) => (
                      <div
                        key={r.id}
                        className="meta"
                        style={{marginTop: 6, color: "var(--text-2)"}}
                      >
                        “{r.details}” — {r.reporterName || "reporter"}
                      </div>
                    ))}
                </div>

                {tab === "open" && (
                  <>
                    <button
                      className="btn-ghost"
                      disabled={busy === u.uid}
                      onClick={() =>
                        act(u.uid, () =>
                          Promise.all(
                            u.reports.map((r) =>
                              api.resolveReport(r.id, "dismissed")
                            )
                          )
                        )
                      }
                    >
                      Dismiss all
                    </button>
                    <button
                      className="btn-ghost"
                      disabled={busy === u.uid}
                      onClick={() => setWarning(u.reports[0])}
                    >
                      Email
                    </button>
                    <button
                      className="btn-danger"
                      disabled={busy === u.uid}
                      onClick={() => setBanning(u.reports[0])}
                    >
                      Ban user
                    </button>
                  </>
                )}
              </div>
            </div>
          );
        })}

      {view === "byReport" &&
        rows.map((r) => {
        const overdue = tab === "open" && hoursSince(r.at) > 24;
        return (
          <div
            className="card"
            key={r.id}
            style={overdue ? {borderLeft: "3px solid var(--error)"} : undefined}
          >
            <div className="row">
              <div className="grow">
                <div className="name">
                  {r.reportedName || r.reportedId}{" "}
                  <span className="badge badge-rejected">{r.reason}</span>{" "}
                  {overdue && (
                    <span className="badge badge-banned">
                      overdue ({Math.floor(hoursSince(r.at))}h)
                    </span>
                  )}
                </div>
                <div className="meta">
                  {r.reportedRole} · reported by {r.reporterName || r.reporterId}
                  {r.at && ` · ${r.at.toLocaleString()}`}
                </div>
                {r.details && (
                  <div className="meta" style={{marginTop: 6, color: "var(--text-2)"}}>
                    “{r.details}”
                  </div>
                )}
              </div>

              {tab === "open" && (
                <>
                  <button
                    className="btn-ghost"
                    disabled={busy === r.id}
                    onClick={() =>
                      act(r.id, () => api.resolveReport(r.id, "dismissed"))
                    }
                  >
                    Dismiss
                  </button>
                  <button
                    className="btn-ghost"
                    disabled={busy === r.id}
                    onClick={() => setWarning(r)}
                  >
                    Email
                  </button>
                  <button
                    className="btn-danger"
                    disabled={busy === r.id}
                    onClick={() => setBanning(r)}
                  >
                    Ban user
                  </button>
                </>
              )}
            </div>
          </div>
        );
      })}

      {warning && (
        <EmailDialog
          title={`Email ${warning.reportedName || warning.reportedId}`}
          description="A warning, short of a ban. Sending it resolves every open report against them — so if the behaviour continues, the next report starts a fresh 24-hour clock rather than compounding an old one."
          confirmLabel="Send"
          busy={sending}
          onCancel={() => setWarning(null)}
          onSend={async (subject, body) => {
            const target = warning;
            const openForUser = (rows ?? []).filter(
              (x) => x.reportedId === target.reportedId
            );
            setSending(true);
            setError("");
            try {
              await api.sendUserEmail(target.reportedId, subject, body);
              await Promise.all(
                openForUser.map((x) => api.resolveReport(x.id, "actioned"))
              );
              setWarning(null);
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
          title={`Ban ${banning.reportedName || banning.reportedId}`}
          description="Ends their session immediately (tokens revoked, not just flagged), resolves this report, and is written to the audit log."
          placeholder={`e.g. Reported for ${banning.reason} — reviewed the conversation and confirmed.`}
          confirmLabel="Ban user"
          danger
          onCancel={() => setBanning(null)}
          onConfirm={(reason) => {
            const target = banning;
            const openForUser = (rows ?? []).filter(
              (x) => x.reportedId === target.reportedId
            );
            setBanning(null);
            act(target.id, async () => {
              await api.banUser(target.reportedId, true, reason);
              // Resolve EVERY report against them, not just the one clicked —
              // otherwise banning a repeat offender leaves their other reports
              // sitting "open" and permanently overdue.
              await Promise.all(
                openForUser.map((x) => api.resolveReport(x.id, "actioned"))
              );
            });
          }}
        />
      )}
    </>
  );
}

export default function Page() {
  return (
    <Shell>
      <Reports />
    </Shell>
  );
}
