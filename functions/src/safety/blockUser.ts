import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../shared/admin";
import {matchIdFor} from "../matches/createMatch";

/**
 * Block a user.
 *
 * Required by App Store Guideline 1.2 alongside reporting. A block is stronger
 * than a report: it takes effect immediately and needs no moderator.
 *
 * It is **symmetric and total** — deliberately. If A blocks B:
 *  - neither sees the other in discovery (enforced in `getCandidates`);
 *  - neither can message the other (enforced in the Firestore rules);
 *  - any existing match is marked blocked, so the thread disappears from both
 *    match lists.
 *
 * A one-way block (B can still see A) is worse than useless: the blocked party
 * notices they have been silenced and can simply make a new account, while the
 * person who blocked them still appears in their deck.
 */
export const blockUser = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const targetId =
    typeof request.data?.targetId === "string" ? request.data.targetId : "";
  const blocked = request.data?.blocked !== false; // default: block
  if (!targetId || targetId === uid) {
    throw new HttpsError("invalid-argument", "A valid user is required.");
  }

  const blockRef = db
    .collection("blocks")
    .doc(uid)
    .collection("blocked")
    .doc(targetId);

  const matchRef = db.collection("matches").doc(matchIdFor(uid, targetId));

  if (blocked) {
    await blockRef.set({
      target_id: targetId,
      created_at: FieldValue.serverTimestamp(),
    });
    // Kill the thread if one exists. The rules also deny sends, but a match
    // sitting in the list is a scar the user should not have to look at.
    if ((await matchRef.get()).exists) {
      await matchRef.update({blocked: true, blocked_by: uid});
    }
  } else {
    await blockRef.delete();
    const snap = await matchRef.get();
    // Only the person who blocked can un-blocked the thread.
    if (snap.exists && snap.get("blocked_by") === uid) {
      await matchRef.update({
        blocked: FieldValue.delete(),
        blocked_by: FieldValue.delete(),
      });
    }
  }

  logger.info("blockUser", {uid, targetId, blocked});
  return {ok: true, blocked};
});
