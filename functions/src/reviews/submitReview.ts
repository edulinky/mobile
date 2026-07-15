import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../shared/admin";
import {matchIdFor} from "../matches/createMatch";

const MAX_COMMENT = 1000;

/** One review per pair, so a re-submission overwrites rather than stacks. */
export function reviewIdFor(targetId: string, reviewerId: string): string {
  return `${targetId}_${reviewerId}`;
}

/**
 * Leave (or replace) a review of a teacher.
 *
 * **A match is the price of admission.** Anyone signed in could otherwise post a
 * one-star review of a teacher they have never met — which is how a ratings
 * system becomes a weapon, and how a competitor's profile gets buried. Requiring
 * a match means the two people actually connected on the platform, and it costs
 * the attacker a right-swipe from *both* sides to fake.
 *
 * Reviews are **not published on submit**. They land as `pending` and an admin
 * releases them (`approveReview`). Written text about a named person, shown on
 * their public profile, is the single highest-risk piece of user content in the
 * app — moderating it before it is visible is much cheaper than taking it down
 * after.
 */
export const submitReview = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const targetId =
    typeof request.data?.targetId === "string" ? request.data.targetId : "";
  const rating = Number(request.data?.rating);
  const comment =
    typeof request.data?.comment === "string" ?
      request.data.comment.trim().slice(0, MAX_COMMENT) :
      "";

  if (!targetId || targetId === uid) {
    throw new HttpsError("invalid-argument", "A valid user is required.");
  }
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
    throw new HttpsError("invalid-argument", "Rating must be 1 to 5.");
  }

  const [reviewerSnap, targetSnap] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("users").doc(targetId).get(),
  ]);
  if (!targetSnap.exists) {
    throw new HttpsError("not-found", "That user no longer exists.");
  }
  // Ratings are a teacher-profile feature (the spec lists Reviews & Ratings
  // under Teacher Profiles only). Nobody rates a student.
  if (targetSnap.get("role") !== "teacher") {
    throw new HttpsError(
      "failed-precondition",
      "Only teachers can be reviewed."
    );
  }
  if (reviewerSnap.get("is_banned") === true) {
    throw new HttpsError("permission-denied", "Your account is suspended.");
  }

  // The match check. A blocked match does not count — a block is the opposite of
  // a working relationship, and letting it through would make "block, then
  // one-star them" a two-tap revenge combo.
  const matchSnap = await db
    .collection("matches")
    .doc(matchIdFor(uid, targetId))
    .get();
  if (!matchSnap.exists || matchSnap.get("blocked") === true) {
    throw new HttpsError(
      "failed-precondition",
      "You can only review someone you have matched with."
    );
  }

  const id = reviewIdFor(targetId, uid);
  const ref = db.collection("reviews").doc(id);
  const existing = await ref.get();

  // An edit goes back through moderation — otherwise "post something bland, get
  // approved, edit it into abuse" is an open door. The aggregate is corrected by
  // the onReviewWritten trigger when the status leaves `approved`.
  await ref.set(
    {
      review_id: id,
      target_id: targetId,
      target_name: (targetSnap.get("display_name") as string) ?? "",
      reviewer_id: uid,
      reviewer_name: (reviewerSnap.get("display_name") as string) ?? "",
      reviewer_photo: (reviewerSnap.get("photo_url") as string) ?? "",
      rating,
      comment,
      status: "pending",
      moderated_by: FieldValue.delete(),
      moderated_at: FieldValue.delete(),
      rejection_reason: FieldValue.delete(),
      created_at: existing.exists ?
        existing.get("created_at") :
        FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    },
    {merge: true}
  );

  logger.info("submitReview", {uid, targetId, rating, edit: existing.exists});
  return {ok: true, status: "pending"};
});
