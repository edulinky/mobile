import {onCall, HttpsError} from "firebase-functions/v2/https";
import {db} from "../shared/admin";

/**
 * Clears the caller's unread badge for a match, when they open the thread.
 *
 * A callable rather than a client write, because `matches/` is server-write-only
 * — otherwise a client could clear the *other* person's badge, or fake activity
 * to float itself to the top of their match list.
 */
export const markMatchRead = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const matchId =
    typeof request.data?.matchId === "string" ? request.data.matchId : "";
  if (!matchId) {
    throw new HttpsError("invalid-argument", "matchId is required.");
  }

  const ref = db.collection("matches").doc(matchId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "Match not found.");
  }
  const participants = (snap.get("participants") as string[]) ?? [];
  if (!participants.includes(uid)) {
    throw new HttpsError("permission-denied", "You are not in this match.");
  }

  // Only ever your own counter.
  await ref.update({[`unread.${uid}`]: 0});
  return {ok: true};
});
