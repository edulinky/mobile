import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../shared/admin";
import {notify} from "../shared/notify";

/**
 * A teacher right-swipes a Job Card.
 *
 * This is the ONE one-directional flow in the product, and the spec is explicit
 * about it: *"Teacher → Job Card: Right swipe triggers an Immediate Notification
 * to the Institution."* No mutual swipe, no match — the institution simply gets
 * an application. That asymmetry is deliberate: the counterparty is an
 * organisation receiving a job application, not a person being swiped on.
 */
export const applyToJob = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  if (request.auth?.token.role !== "teacher") {
    throw new HttpsError("permission-denied", "Only teachers can apply.");
  }

  const jobId = typeof request.data?.jobId === "string" ? request.data.jobId : "";
  if (!jobId) {
    throw new HttpsError("invalid-argument", "jobId is required.");
  }

  const [meSnap, jobSnap] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("jobCards").doc(jobId).get(),
  ]);

  if (!meSnap.exists) {
    throw new HttpsError("not-found", "Your profile was not found.");
  }
  if (meSnap.get("is_banned") === true) {
    throw new HttpsError("permission-denied", "Your account is suspended.");
  }
  // Same gate as student discovery: an unverified teacher must not be able to
  // reach an institution either.
  if (meSnap.get("verified_status") !== "approved") {
    throw new HttpsError(
      "failed-precondition",
      "Your account is awaiting verification."
    );
  }
  if (!jobSnap.exists || jobSnap.get("status") !== "active") {
    throw new HttpsError("not-found", "That job is no longer open.");
  }

  const instId = jobSnap.get("inst_id") as string;

  // Deterministic id: applying twice is a no-op, not a duplicate application.
  const appId = `${jobId}_${uid}`;
  const appRef = db.collection("applications").doc(appId);
  if ((await appRef.get()).exists) {
    return {ok: true, alreadyApplied: true};
  }

  await appRef.set({
    application_id: appId,
    job_id: jobId,
    teacher_id: uid,
    inst_id: instId,
    teacher_name: (meSnap.get("display_name") as string) ?? "",
    teacher_photo_url: (meSnap.get("photo_url") as string) ?? "",
    job_title: (jobSnap.get("title") as string) ?? "",
    status: "new",
    created_at: FieldValue.serverTimestamp(),
  });

  await db
    .collection("jobCards")
    .doc(jobId)
    .update({applicant_count: FieldValue.increment(1)});

  // "Immediate Notification to the Institution" — the spec's words.
  await notify({
    uid: instId,
    type: "job_application",
    title: "New application",
    body: `${meSnap.get("display_name") ?? "A teacher"} applied to "${
      jobSnap.get("title") ?? "your job"
    }".`,
    data: {jobId, teacherId: uid},
  });

  logger.info("applyToJob", {uid, jobId, instId});
  return {ok: true, alreadyApplied: false};
});
