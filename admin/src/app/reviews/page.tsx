"use client";

import {useEffect, useState} from "react";
import {collection, onSnapshot, query, where} from "firebase/firestore";
import {db} from "@/lib/firebase";
import {api} from "@/lib/api";
import {Shell} from "@/components/Shell";
import {ReasonDialog} from "@/components/ReasonDialog";

interface Review {
  id: string;
  targetId: string;
  targetName: string;
  reviewerId: string;
  reviewerName: string;
  rating: number;
  comment: string;
  rejectionReason: string;
  at: Date | null;
}

const TABS = [
  {key: "pending", label: "Pending"},
  {key: "approved", label: "Approved"},
  {key: "rejected", label: "Rejected"},
] as const;
type TabKey = (typeof TABS)[number]["key"];

function Stars({n}: {n: number}) {
  return (
    <span style={{color: "#F59E0B", letterSpacing: 1}}>
      {"★".repeat(n)}
      <span style={{color: "var(--text-3)"}}>{"★".repeat(5 - n)}</span>
    </span>
  );
}

/**
 * Reviews are held back until an admin releases them.
 *
 * Written text about a named person, published on their profile, is the highest-
 * risk user content in the app — and unlike a chat message it is permanent and
 * public. Moderating before publication is far cheaper than taking it down after.
 */
function Reviews() {
  const [tab, setTab] = useState<TabKey>("pending");
  const [rows, setRows] = useState<Review[] | null>(null);
  const [busy, setBusy] = useState<string | null>(null);
  const [rejecting, setRejecting] = useState<Review | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    setRows(null);
    const q = query(collection(db, "reviews"), where("status", "==", tab));
    return onSnapshot(q, (snap) => {
      setRows(
        snap.docs
          .map((d) => {
            const x = d.data();
            return {
              id: d.id,
              targetId: x.target_id ?? "",
              targetName: x.target_name ?? "",
              reviewerId: x.reviewer_id ?? "",
              reviewerName: x.reviewer_name ?? "",
              rating: x.rating ?? 0,
              comment: x.comment ?? "",
              rejectionReason: x.rejection_reason ?? "",
              at: x.updated_at?.toDate?.() ?? x.created_at?.toDate?.() ?? null,
            };
          })
          // Oldest first: a queue is worked from the front.
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
      <h1>Reviews</h1>
      <p className="sub">
        A review is invisible and uncounted until it is approved. Approving it
        publishes it on the teacher&apos;s profile and updates their rating.
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
          {tab === "pending" ? "Nothing waiting for review. 🎉" : `No ${tab} reviews.`}
        </div>
      )}

      {rows.map((r) => (
        <div className="card" key={r.id}>
          <div className="row">
            <div className="grow">
              <div className="name">
                {r.targetName || r.targetId} <Stars n={r.rating} />
              </div>
              <div className="meta">
                by {r.reviewerName || r.reviewerId}
                {r.at && ` · ${r.at.toLocaleString()}`}
              </div>
              {r.comment && (
                <div
                  className="meta"
                  style={{marginTop: 6, color: "var(--text-2)"}}
                >
                  “{r.comment}”
                </div>
              )}
              {tab === "rejected" && r.rejectionReason && (
                <div className="meta" style={{marginTop: 6}}>
                  Rejected: {r.rejectionReason}
                </div>
              )}
            </div>

            {tab !== "approved" && (
              <button
                className="btn-primary"
                disabled={busy === r.id}
                onClick={() => act(r.id, () => api.approveReview(r.id))}
              >
                Approve
              </button>
            )}
            {tab !== "rejected" && (
              <button
                className="btn-danger"
                disabled={busy === r.id}
                onClick={() => setRejecting(r)}
              >
                Reject
              </button>
            )}
          </div>
        </div>
      ))}

      {rejecting && (
        <ReasonDialog
          title={`Reject review of ${rejecting.targetName || rejecting.targetId}`}
          description="The reviewer sees this reason and can edit and resubmit. If the review is already published, rejecting it removes it and takes it back out of the rating."
          placeholder="e.g. Personal abuse rather than feedback about the teaching."
          confirmLabel="Reject review"
          danger
          onCancel={() => setRejecting(null)}
          onConfirm={(reason) => {
            const target = rejecting;
            setRejecting(null);
            act(target.id, () => api.rejectReview(target.id, reason));
          }}
        />
      )}
    </>
  );
}

export default function Page() {
  return (
    <Shell>
      <Reviews />
    </Shell>
  );
}
