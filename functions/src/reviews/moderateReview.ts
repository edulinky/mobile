import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../shared/admin";
import {requireAdmin, audit} from "../shared/adminGuard";

/**
 * Publish a review.
 *
 * This is the moment it becomes visible on the teacher's public profile and
 * starts counting toward their rating. The aggregate is NOT updated here — the
 * `onReviewWritten` trigger owns that, so a status flipped any other way (a
 * console edit, a future bulk tool) still keeps `avg_rating` honest.
 */
export const approveReview = onCall(async (request) => {
  const actor = requireAdmin(request);
  const reviewId =
    typeof request.data?.reviewId === "string" ? request.data.reviewId : "";
  if (!reviewId) {
    throw new HttpsError("invalid-argument", "reviewId is required.");
  }

  const ref = db.collection("reviews").doc(reviewId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Review not found.");

  await ref.update({
    status: "approved",
    moderated_by: actor,
    moderated_at: FieldValue.serverTimestamp(),
    rejection_reason: FieldValue.delete(),
  });
  await audit(actor, "approve_review", snap.get("target_id") as string, {
    reviewId,
    rating: snap.get("rating"),
  });

  logger.info("approveReview", {actor, reviewId});
  return {ok: true};
});

/**
 * Reject a review: it stays in the database (the reviewer can see it was turned
 * down, and it is evidence if the same person keeps trying) but it is never
 * shown on the profile and never counts toward the rating.
 */
export const rejectReview = onCall(async (request) => {
  const actor = requireAdmin(request);
  const reviewId =
    typeof request.data?.reviewId === "string" ? request.data.reviewId : "";
  const reason =
    typeof request.data?.reason === "string" ? request.data.reason.trim() : "";
  if (!reviewId) {
    throw new HttpsError("invalid-argument", "reviewId is required.");
  }

  const ref = db.collection("reviews").doc(reviewId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Review not found.");

  await ref.update({
    status: "rejected",
    moderated_by: actor,
    moderated_at: FieldValue.serverTimestamp(),
    rejection_reason: reason,
  });
  await audit(actor, "reject_review", snap.get("target_id") as string, {
    reviewId,
    reason,
  });

  logger.info("rejectReview", {actor, reviewId});
  return {ok: true};
});
