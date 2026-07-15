"use client";

import {useEffect, useState} from "react";
import {api} from "@/lib/api";
import {Shell} from "@/components/Shell";

interface Limits {
  primary: number;
  discovery: number;
}

const ROLES: {key: string; label: string; note: string}[] = [
  {
    key: "teacher",
    label: "Teacher",
    note:
      "The requirements leave this one to you (FR-3.2: “limited swipes, to be " +
      "defined by Admin”). This is that dial.",
  },
  {
    key: "student",
    label: "Student",
    note:
      "The requirements fix this at 15 primary + 5 discovery (FR-3.1). Change " +
      "it only if the product decision has actually changed.",
  },
];

/**
 * Free-tier swipe limits, per role.
 *
 * One setting for the whole role — not per user. It applies to **every free user
 * in that role**, on their next swipe (the quota is re-read each time, so there
 * is no redeploy and no cache to wait out). Premium users skip the quota check
 * entirely, so this only ever moves the free tier.
 */
function Quotas() {
  const [quotas, setQuotas] = useState<Record<string, Limits> | null>(null);
  const [draft, setDraft] = useState<Record<string, Limits>>({});
  const [busy, setBusy] = useState<string | null>(null);
  const [saved, setSaved] = useState<string | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    api
      .getQuotas()
      .then((res) => {
        setQuotas(res.data.quotas);
        setDraft(res.data.quotas);
      })
      .catch((e) => {
        setQuotas({});
        setError(e instanceof Error ? e.message : String(e));
      });
  }, []);

  function edit(role: string, field: keyof Limits, raw: string) {
    const value = raw === "" ? 0 : Number(raw);
    if (!Number.isFinite(value)) return;
    setDraft((d) => ({...d, [role]: {...d[role], [field]: Math.floor(value)}}));
    setSaved(null);
  }

  async function save(role: string) {
    const next = draft[role];
    setBusy(role);
    setError("");
    try {
      await api.setQuotas(role, next.primary, next.discovery);
      setQuotas((q) => ({...(q ?? {}), [role]: next}));
      setSaved(role);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setBusy(null);
    }
  }

  if (quotas === null) return <div className="empty">Loading…</div>;

  return (
    <>
      <h1>Swipe quotas</h1>
      <p className="sub">
        Free-tier right swipes per rolling 24 hours. <strong>Left swipes are
        never metered</strong> — only expressions of interest are — and premium
        users are unlimited, so these numbers only move the free tier. A change
        takes effect on the next swipe; no redeploy.
      </p>

      {error && <div className="err" style={{marginBottom: 12}}>{error}</div>}

      {ROLES.map((r) => {
        const current = quotas[r.key];
        const next = draft[r.key];
        if (!current || !next) return null;
        const dirty =
          current.primary !== next.primary ||
          current.discovery !== next.discovery;
        const total = next.primary + next.discovery;

        return (
          <div className="card" key={r.key}>
            <div className="name" style={{marginBottom: 4}}>
              {r.label}{" "}
              <span className="badge badge-pending">{total} / day</span>
            </div>
            <div className="meta" style={{marginBottom: 14}}>{r.note}</div>

            <div style={{display: "flex", gap: 16, alignItems: "flex-end"}}>
              <div style={{flex: 1, maxWidth: 200}}>
                <label htmlFor={`${r.key}-primary`}>Primary subject</label>
                <input
                  id={`${r.key}-primary`}
                  type="number"
                  min={0}
                  max={1000}
                  value={next.primary}
                  disabled={busy === r.key}
                  onChange={(e) => edit(r.key, "primary", e.target.value)}
                />
              </div>
              <div style={{flex: 1, maxWidth: 200}}>
                <label htmlFor={`${r.key}-discovery`}>Discovery / related</label>
                <input
                  id={`${r.key}-discovery`}
                  type="number"
                  min={0}
                  max={1000}
                  value={next.discovery}
                  disabled={busy === r.key}
                  onChange={(e) => edit(r.key, "discovery", e.target.value)}
                />
              </div>
              <button
                className="btn-primary"
                disabled={!dirty || busy === r.key}
                onClick={() => save(r.key)}
              >
                {busy === r.key ? "Saving…" : "Save"}
              </button>
              {saved === r.key && !dirty && (
                <span className="meta" style={{color: "var(--sky-deeper)"}}>
                  Saved
                </span>
              )}
            </div>
          </div>
        );
      })}

      <p className="sub" style={{marginTop: 20}}>
        The two budgets are <strong>separate</strong>: spending all the discovery
        swipes cannot eat into the primary-subject ones. A swipe counts as
        “primary” when the person swiped teaches or studies the swiper&apos;s own
        primary subject.
      </p>
    </>
  );
}

export default function Page() {
  return (
    <Shell>
      <Quotas />
    </Shell>
  );
}
