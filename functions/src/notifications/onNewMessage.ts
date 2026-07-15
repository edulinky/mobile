import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../shared/admin";
import {notify} from "../shared/notify";

/**
 * Fires when a message is written to a match thread.
 *
 * Owns two things the client must NOT own:
 *  - the match doc's `last_message` / `last_message_at` (used to order the match
 *    list) and the per-recipient `unread` count — the rules make `matches/`
 *    server-write-only, so a client cannot fake activity or clear someone
 *    else's badge;
 *  - the FCM push to the recipient.
 */
export const onNewMessage = onDocumentCreated(
  "matches/{matchId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const {matchId} = event.params;
    const senderId = snap.get("sender_id") as string | undefined;
    const text = (snap.get("text") as string | undefined) ?? "";
    if (!senderId) return;

    const matchRef = db.collection("matches").doc(matchId);
    const matchSnap = await matchRef.get();
    if (!matchSnap.exists) return;

    const participants = (matchSnap.get("participants") as string[]) ?? [];
    const recipientId = participants.find((p) => p !== senderId);
    if (!recipientId) return;

    // Preview text is truncated: the push notification is shown on a lock
    // screen, so it should not spill a whole message.
    const preview = text.length > 120 ? `${text.slice(0, 117)}…` : text;

    await matchRef.update({
      last_message: preview,
      last_message_at: FieldValue.serverTimestamp(),
      [`unread.${recipientId}`]: FieldValue.increment(1),
    });

    const senderSnap = await db.collection("users").doc(senderId).get();
    const senderName =
      (senderSnap.get("display_name") as string) || "New message";

    // Inbox + push in one call. A push is ephemeral (dismissed, or never
    // delivered because notifications are off), so anything worth pushing is
    // worth persisting where the user can find it later.
    await notify({
      uid: recipientId,
      type: "message",
      title: senderName,
      body: preview,
      data: {matchId, senderId},
    });
  }
);
