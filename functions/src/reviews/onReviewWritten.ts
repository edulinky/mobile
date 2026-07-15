import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {logger} from "firebase-functions/v2";
import {DocumentSnapshot} from "firebase-admin/firestore";
import {db} from "../shared/admin";
import {notify} from "../shared/notify";
import {alertAdmins} from "../shared/adminAlert";

interface Contribution {
  count: number;
  sum: number;
}

/** What this review contributes to the teacher's rating right now. */
function contribution(snap: DocumentSnapshot | undefined): Contribution {
  if (!snap?.exists || snap.get("status") !== "approved") {
    return {count: 0, sum: 0};
  }
  const rating = Number(snap.get("rating"));
  if (!Number.isFinite(rating)) return {count: 0, sum: 0};
  return {count: 1, sum: rating};
}

/**
 * Keeps `avg_rating` / `total_reviews` on the user doc in step with the reviews.
 *
 * A **trigger**, not a line inside `approveReview`, for the same reason as
 * `onVerificationChanged`: the aggregate must survive a status changed any other
 * way — a console edit, a reviewer editing their approved review back into
 * moderation, a review deleted outright. Anything that writes the collection
 * flows through here.
 *
 * It applies a **delta** rather than re-summing every review of the teacher. A
 * re-scan is O(reviews) on every write and races with a concurrent moderation;
 * a delta inside a transaction is O(1) and cannot lose an increment.
 *
 * `rating_sum` is carried on the user doc so the average can be recomputed from
 * a delta at all — an average alone is not enough information to update itself.
 * It is server-owned (locked in the rules) and never shown.
 */
export const onReviewWritten = onDocumentWritten(
  "reviews/{reviewId}",
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;

    const was = contribution(before);
    const now = contribution(after);
    const dCount = now.count - was.count;
    const dSum = now.sum - was.sum;

    // The target never changes for a given review id, but read it from whichever
    // side exists (a delete leaves only `before`).
    const targetId =
      (after?.exists ? after.get("target_id") : before?.get("target_id")) as
      | string
      | undefined;
    if (!targetId) return;

    if (dCount !== 0 || dSum !== 0) {
      const userRef = db.collection("users").doc(targetId);
      await db.runTransaction(async (tx) => {
        const snap = await tx.get(userRef);
        if (!snap.exists) return;

        const total = Math.max(
          0,
          ((snap.get("total_reviews") as number) ?? 0) + dCount
        );
        const sum = Math.max(0, ((snap.get("rating_sum") as number) ?? 0) + dSum);
        // One decimal place: `4.3`, not `4.333333333333333`. The value is
        // rendered as-is next to the stars.
        const avg = total > 0 ? Math.round((sum / total) * 10) / 10 : 0;

        tx.update(userRef, {
          total_reviews: total,
          rating_sum: sum,
          avg_rating: avg,
        });
      });
      logger.info("onReviewWritten: aggregate updated", {
        targetId,
        dCount,
        dSum,
      });
    }

    // A review waiting for moderation is invisible to everyone and counts for
    // nothing, so an unwatched queue means the reviewer is simply ignored. Alert
    // on the *transition* into pending — a new review, or an approved one the
    // author has edited (which pulls it back off the profile) — but not on every
    // write to an already-pending review.
    const wasPending = before?.exists && before.get("status") === "pending";
    const isPending = after?.exists && after.get("status") === "pending";
    if (isPending && !wasPending) {
      const reviewerName = (after?.get("reviewer_name") as string) || "Someone";
      const targetName = (after?.get("target_name") as string) || "a teacher";
      const rating = after?.get("rating") as number;
      const comment = (after?.get("comment") as string) || "";
      await alertAdmins({
        type: "review",
        title: "Review awaiting moderation",
        subject: `[Review] ${targetName} — ${rating}★`,
        body:
          `${reviewerName} left a ${rating}-star review of ${targetName}.\n\n` +
          (comment ? `"${comment}"\n\n` : "") +
          "It is not visible on their profile and does not count toward their " +
          "rating until you approve it.",
        panelPath: "/reviews",
        data: {reviewId: event.params.reviewId},
      });
    }

    // Tell the teacher only when the review actually goes live. A pending review
    // is not news — it may never be published, and naming the reviewer before an
    // admin has looked at it invites exactly the retaliation moderation exists to
    // prevent.
    if (was.count === 0 && now.count === 1) {
      const reviewerName =
        (after?.get("reviewer_name") as string) || "Someone";
      const rating = now.sum;
      await notify({
        uid: targetId,
        type: "review",
        title: "You have a new review",
        body: `${reviewerName} rated you ${rating} out of 5.`,
        data: {reviewId: event.params.reviewId},
      });
    }
  }
);
