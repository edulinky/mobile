import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {FieldValue} from "firebase-admin/firestore";
import {auth, db} from "../shared/admin";
import {requireAdmin, audit} from "../shared/adminGuard";

/** Approve a teacher's certificate. They become discoverable and can swipe. */
export const approveTeacher = onCall(async (request) => {
  const actor = requireAdmin(request);
  const uid = typeof request.data?.uid === "string" ? request.data.uid : "";
  if (!uid) throw new HttpsError("invalid-argument", "uid is required.");

  const ref = db.collection("users").doc(uid);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "User not found.");
  if (snap.get("role") !== "teacher") {
    throw new HttpsError("failed-precondition", "That user is not a teacher.");
  }

  // The onVerificationChanged trigger notifies the teacher — we do not do it
  // here, so an approval made any other way (a console edit) still notifies.
  await ref.update({
    verified_status: "approved",
    verified_at: FieldValue.serverTimestamp(),
    rejection_reason: FieldValue.delete(),
  });
  await audit(actor, "approve_teacher", uid);

  logger.info("approveTeacher", {actor, uid});
  return {ok: true};
});

/** Reject a certificate. The teacher can submit a new one. */
export const rejectTeacher = onCall(async (request) => {
  const actor = requireAdmin(request);
  const uid = typeof request.data?.uid === "string" ? request.data.uid : "";
  const reason =
    typeof request.data?.reason === "string" ? request.data.reason.trim() : "";
  if (!uid) throw new HttpsError("invalid-argument", "uid is required.");

  const ref = db.collection("users").doc(uid);
  if (!(await ref.get()).exists) {
    throw new HttpsError("not-found", "User not found.");
  }

  await ref.update({
    verified_status: "rejected",
    rejection_reason: reason,
  });
  await audit(actor, "reject_teacher", uid, {reason});

  logger.info("rejectTeacher", {actor, uid});
  return {ok: true};
});

/**
 * Ban or unban a user.
 *
 * Setting `is_banned` alone is NOT enough: a Firebase ID token stays valid for
 * up to an hour, so a banned user would keep working — still able to message the
 * very person they were banned for harassing, since chat is gated on the token
 * plus match membership. `revokeRefreshTokens` kills the session at the next
 * refresh, and the Firestore rules re-read `is_banned` on every message send.
 * Both halves are required; neither is sufficient.
 */
export const banUser = onCall(async (request) => {
  const actor = requireAdmin(request);
  const uid = typeof request.data?.uid === "string" ? request.data.uid : "";
  const banned = request.data?.banned !== false; // default: ban
  const reason =
    typeof request.data?.reason === "string" ? request.data.reason.trim() : "";
  if (!uid) throw new HttpsError("invalid-argument", "uid is required.");
  if (uid === actor) {
    throw new HttpsError("failed-precondition", "You cannot ban yourself.");
  }

  const ref = db.collection("users").doc(uid);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "User not found.");
  if (snap.get("role") === "admin") {
    throw new HttpsError("permission-denied", "Admins cannot be banned.");
  }

  await ref.update({
    is_banned: banned,
    ban_reason: banned ? reason : FieldValue.delete(),
  });

  if (banned) {
    // Kill the live session. Without this the ban is advisory for up to an hour.
    await auth.revokeRefreshTokens(uid);
    await auth.updateUser(uid, {disabled: true});
  } else {
    await auth.updateUser(uid, {disabled: false});
  }

  await audit(actor, banned ? "ban_user" : "unban_user", uid, {reason});
  logger.info("banUser", {actor, uid, banned});
  return {ok: true, banned};
});

/** Promote or demote a profile in discovery (a paid perk, admin-granted). */
export const setFeatured = onCall(async (request) => {
  const actor = requireAdmin(request);
  const uid = typeof request.data?.uid === "string" ? request.data.uid : "";
  const featured = request.data?.featured === true;
  if (!uid) throw new HttpsError("invalid-argument", "uid is required.");

  await db.collection("users").doc(uid).update({featured});
  await audit(actor, "set_featured", uid, {featured});
  return {ok: true, featured};
});

/**
 * A signed, short-lived URL to a teacher's certificate.
 *
 * Certificates are `allow read: if false` in the Storage rules — nobody can read
 * them through a client SDK, including their owner. An admin reviewing a
 * verification needs to actually SEE the document, so this mints a temporary URL
 * server-side. That is the only way in, and it is audited.
 */
export const getCertificateUrls = onCall(async (request) => {
  const actor = requireAdmin(request);
  const uid = typeof request.data?.uid === "string" ? request.data.uid : "";
  if (!uid) throw new HttpsError("invalid-argument", "uid is required.");

  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) throw new HttpsError("not-found", "User not found.");

  const paths = (snap.get("cert_paths") as string[] | undefined) ?? [];
  if (paths.length === 0) return {urls: []};

  const {storage} = await import("../shared/admin");
  const bucket = storage.bucket();
  const expires = Date.now() + 15 * 60 * 1000; // 15 minutes is plenty to review

  const urls = await Promise.all(
    paths.map(async (path) => {
      const [url] = await bucket
        .file(path)
        .getSignedUrl({action: "read", expires});
      return {path, url};
    })
  );

  await audit(actor, "view_certificates", uid, {count: urls.length});
  return {urls};
});

/**
 * Close a report.
 *
 * `actioned` = we did something (banned, warned). `dismissed` = no case to
 * answer. Either way it leaves the open queue, because a queue that only grows
 * stops being read — and the 24-hour SLA is measured against it.
 */
export const resolveReport = onCall(async (request) => {
  const actor = requireAdmin(request);
  const reportId =
    typeof request.data?.reportId === "string" ? request.data.reportId : "";
  const status = request.data?.status === "actioned" ? "actioned" : "dismissed";
  if (!reportId) {
    throw new HttpsError("invalid-argument", "reportId is required.");
  }

  const ref = db.collection("reports").doc(reportId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Report not found.");

  await ref.update({
    status,
    resolved_by: actor,
    resolved_at: FieldValue.serverTimestamp(),
  });
  await audit(actor, `report_${status}`, snap.get("reported_id") as string, {
    reportId,
  });

  return {ok: true, status};
});
