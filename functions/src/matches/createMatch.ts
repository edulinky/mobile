import {Transaction, FieldValue} from "firebase-admin/firestore";
import {db} from "../shared/admin";

/** Deterministic id, so both directions of a pair resolve to the same match. */
export function matchIdFor(a: string, b: string): string {
  return [a, b].sort().join("_");
}

/**
 * Writes the match document inside the caller's transaction, so a match and the
 * swipe that caused it commit together — never one without the other.
 *
 * FCM notification to both users is wired in Phase 5.
 */
export function createMatchInTx(
  tx: Transaction,
  a: string,
  b: string
): string {
  const matchId = matchIdFor(a, b);
  tx.set(
    db.collection("matches").doc(matchId),
    {
      match_id: matchId,
      // Queried with array-contains to list "my matches".
      participants: [a, b].sort(),
      created_at: FieldValue.serverTimestamp(),
      last_message: null,
      last_message_at: null,
    },
    {merge: true}
  );
  return matchId;
}
