"use client";

import {httpsCallable} from "firebase/functions";
import {functions} from "./firebase";

/** Every one of these re-checks `role === "admin"` server-side. */
export const api = {
  approveTeacher: (uid: string) =>
    httpsCallable(functions, "approveTeacher")({uid}),

  rejectTeacher: (uid: string, reason: string) =>
    httpsCallable(functions, "rejectTeacher")({uid, reason}),

  banUser: (uid: string, banned: boolean, reason = "") =>
    httpsCallable(functions, "banUser")({uid, banned, reason}),

  setFeatured: (uid: string, featured: boolean) =>
    httpsCallable(functions, "setFeatured")({uid, featured}),

  /** Free-tier swipe limits per role (effective values, defaults included). */
  getQuotas: () =>
    httpsCallable<
      Record<string, never>,
      {quotas: Record<string, {primary: number; discovery: number}>}
    >(functions, "getQuotas")({}),

  setQuotas: (role: string, primary: number, discovery: number) =>
    httpsCallable(functions, "setQuotas")({role, primary, discovery}),

  /** Publishes the review on the teacher's profile and counts it in their rating. */
  approveReview: (reviewId: string) =>
    httpsCallable(functions, "approveReview")({reviewId}),

  /** Keeps the review on record, but it is never shown and never counted. */
  rejectReview: (reviewId: string, reason: string) =>
    httpsCallable(functions, "rejectReview")({reviewId, reason}),

  /** Close a report: "actioned" (we banned/warned) or "dismissed" (no case). */
  resolveReport: (reportId: string, status: "actioned" | "dismissed") =>
    httpsCallable(functions, "resolveReport")({reportId, status}),

  sendUserEmail: (uid: string, subject: string, body: string) =>
    httpsCallable<
      {uid: string; subject: string; body: string},
      {ok: boolean; to: string}
    >(functions, "sendUserEmail")({uid, subject, body}),

  /** dryRun returns the recipient count WITHOUT sending anything. */
  previewBulkEmail: (role: string) =>
    httpsCallable<
      {role: string; dryRun: boolean},
      {recipients: number; skipped: number}
    >(functions, "sendBulkEmail")({role, dryRun: true}),

  sendBulkEmail: (role: string, subject: string, body: string, html: string) =>
    httpsCallable<
      {role: string; subject: string; body: string; html: string},
      {sent: number; failed: number}
    >(functions, "sendBulkEmail")({role, subject, body, html}),

  /** Short-lived signed URLs — certificates are unreadable by any client SDK. */
  getCertificateUrls: (uid: string) =>
    httpsCallable<{uid: string}, {urls: {path: string; url: string}[]}>(
      functions,
      "getCertificateUrls"
    )({uid}),
};
