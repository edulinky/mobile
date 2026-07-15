import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../shared/admin";
import {alertAdmins} from "../shared/adminAlert";

/**
 * Reasons a user can be reported. A fixed list, not free text: it makes reports
 * triageable, and it tells the reporter what this system is actually for.
 */
const REASONS = [
  "harassment",
  "inappropriate_content",
  "spam",
  "fake_profile",
  "underage",
  "safety_concern",
  "other",
];

const MAX_DETAILS = 1000;

/**
 * Report a user.
 *
 * Required by App Store Guideline 1.2 (user-generated content): the app must let
 * users flag objectionable content and abusive users, and the developer must act
 * within 24 hours. Without this the app is rejected.
 *
 * Every report notifies **every admin** immediately — a report that sits unseen
 * for a week is the same as no report at all.
 */
export const reportUser = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const reportedId =
    typeof request.data?.reportedId === "string" ? request.data.reportedId : "";
  const reason = typeof request.data?.reason === "string" ? request.data.reason : "";
  const details =
    typeof request.data?.details === "string" ?
      request.data.details.trim().slice(0, MAX_DETAILS) :
      "";

  if (!reportedId || reportedId === uid) {
    throw new HttpsError("invalid-argument", "A valid user is required.");
  }
  if (!REASONS.includes(reason)) {
    throw new HttpsError("invalid-argument", "Invalid reason.");
  }

  const [reporterSnap, reportedSnap] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("users").doc(reportedId).get(),
  ]);
  if (!reportedSnap.exists) {
    throw new HttpsError("not-found", "That user no longer exists.");
  }

  // One open report per reporter/target pair: re-reporting the same person for
  // the same thing should not flood the queue, but a NEW reason should.
  const reportId = `${uid}_${reportedId}_${reason}`;
  const ref = db.collection("reports").doc(reportId);
  if ((await ref.get()).exists) {
    return {ok: true, alreadyReported: true};
  }

  await ref.set({
    report_id: reportId,
    reporter_id: uid,
    reporter_name: (reporterSnap.get("display_name") as string) ?? "",
    reported_id: reportedId,
    reported_name: (reportedSnap.get("display_name") as string) ?? "",
    reported_role: (reportedSnap.get("role") as string) ?? "",
    reason,
    details,
    status: "open",
    created_at: FieldValue.serverTimestamp(),
  });

  // Tell every admin, NOW. The 24-hour clock (App Store Guideline 1.2) starts
  // here, so the alert has to reach a channel they actually watch — which is
  // email, not the app. See `alertAdmins`.
  const reporterName =
    (reporterSnap.get("display_name") as string) || "Someone";
  const reportedName =
    (reportedSnap.get("display_name") as string) || "a user";
  const reasonLabel = reason.replace(/_/g, " ");

  await alertAdmins({
    type: "report",
    title: "New report",
    subject: `[Report] ${reportedName} — ${reasonLabel}`,
    body:
      `${reporterName} reported ${reportedName} for ${reasonLabel}.\n\n` +
      (details ? `Details: "${details}"\n\n` : "") +
      `Reported user: ${reportedName} (${
        reportedSnap.get("role") ?? "unknown role"
      })\n` +
      `Reported by: ${reporterName}\n\n` +
      "Apple and Google require reports to be reviewed within 24 hours.",
    panelPath: "/reports",
    data: {reportId, reportedId},
  });

  logger.info("reportUser", {uid, reportedId, reason});
  return {ok: true, alreadyReported: false};
});
