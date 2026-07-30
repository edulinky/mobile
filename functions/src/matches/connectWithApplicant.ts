import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {db} from "../shared/admin";
import {createMatchInTx, matchIdFor} from "./createMatch";
import {notify} from "../shared/notify";

/**
 * An institution "Connects" with a teacher who applied to one of its jobs.
 *
 * This does NOT go through `recordSwipe`: that flow is built for the metered,
 * MUTUAL student<->teacher swipe deck (swipe quotas, subject-matching buckets,
 * requires both sides to have swiped right). None of that applies here — an
 * institution has no swipe quota, and a job application already IS the
 * teacher's one-directional "yes" (see `applyToJob`). So the only thing this
 * checks is that the teacher actually applied to one of the caller's jobs,
 * then creates the match directly.
 *
 * Idempotent: connecting with someone already matched just returns the
 * existing match rather than erroring.
 */
export const connectWithApplicant = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  if (request.auth?.token.role !== "institution") {
    throw new HttpsError(
      "permission-denied",
      "Only institutions can connect with applicants."
    );
  }

  const teacherId =
    typeof request.data?.teacherId === "string" ? request.data.teacherId : "";
  if (!teacherId) {
    throw new HttpsError("invalid-argument", "teacherId is required.");
  }

  const matchId = matchIdFor(uid, teacherId);
  const existing = await db.collection("matches").doc(matchId).get();
  if (existing.exists) {
    return {ok: true, matchId, alreadyConnected: true};
  }

  const [meSnap, teacherSnap, appliedSnap] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("users").doc(teacherId).get(),
    db
      .collection("applications")
      .where("inst_id", "==", uid)
      .where("teacher_id", "==", teacherId)
      .limit(1)
      .get(),
  ]);

  if (!meSnap.exists) {
    throw new HttpsError("not-found", "Your profile was not found.");
  }
  if (meSnap.get("is_banned") === true) {
    throw new HttpsError("permission-denied", "Your account is suspended.");
  }
  if (!teacherSnap.exists || teacherSnap.get("role") !== "teacher") {
    throw new HttpsError("not-found", "That teacher was not found.");
  }
  if (teacherSnap.get("is_banned") === true) {
    throw new HttpsError("not-found", "That profile is no longer available.");
  }
  // The teacher's consent is having applied to one of my jobs — an
  // institution must never be able to message a teacher who never applied,
  // just by knowing their uid from some other screen.
  if (appliedSnap.empty) {
    throw new HttpsError(
      "failed-precondition",
      "This teacher has not applied to any of your jobs."
    );
  }

  await db.runTransaction(async (tx) => {
    createMatchInTx(tx, uid, teacherId);
  });

  const myName = (meSnap.get("display_name") as string) || "An institution";
  const theirName = (teacherSnap.get("display_name") as string) || "Someone";

  await Promise.all([
    notify({
      uid,
      type: "match",
      title: "You have a new connection",
      body: `You and ${theirName} are connected. Say hello.`,
      data: {matchId, otherUid: teacherId},
    }),
    notify({
      uid: teacherId,
      type: "match",
      title: "You have a new connection",
      body: `You and ${myName} are connected. Say hello.`,
      data: {matchId, otherUid: uid},
    }),
  ]);

  logger.info("connectWithApplicant", {uid, teacherId, matchId});
  return {ok: true, matchId, alreadyConnected: false};
});
