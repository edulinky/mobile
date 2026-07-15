import {FieldValue} from "firebase-admin/firestore";
import {logger} from "firebase-functions/v2";
import {db, messaging} from "./admin";

/** The kinds of activity a user is told about. */
export type NotificationType =
  | "match"
  | "message"
  | "verification_approved"
  | "verification_rejected"
  | "job_application"
  | "review"
  | "report"
  /** Admin-only: a teacher is waiting for verification. */
  | "teacher_pending";

export interface NotifyOptions {
  uid: string;
  type: NotificationType;
  title: string;
  body: string;
  /** Where tapping it should go, e.g. {matchId}. */
  data?: Record<string, string>;
  /** Also send an FCM push. Off for low-value events. */
  push?: boolean;
}

/**
 * Writes an in-app notification and (optionally) sends a push.
 *
 * Both surfaces from one call, deliberately: a push is ephemeral — dismissed,
 * or never delivered because notifications are off — so anything worth pushing
 * is worth persisting somewhere the user can find it later. The inbox is the
 * durable record; the push is the nudge.
 */
export async function notify(opts: NotifyOptions): Promise<void> {
  const {uid, type, title, body, data = {}, push = true} = opts;

  try {
    await db
      .collection("notifications")
      .doc(uid)
      .collection("items")
      .add({
        type,
        title,
        body,
        data,
        read: false,
        created_at: FieldValue.serverTimestamp(),
      });
  } catch (e) {
    logger.error("notify: failed to write in-app notification", {uid, type, e});
  }

  if (!push) return;

  // Push is best effort — a failed notification must never fail the action that
  // triggered it.
  try {
    const user = await db.collection("users").doc(uid).get();
    const tokens = (user.get("fcm_tokens") as string[]) ?? [];
    if (tokens.length === 0) return;

    const res = await messaging.sendEachForMulticast({
      tokens,
      notification: {title, body},
      data: {type, ...data},
    });

    // Prune tokens the device has invalidated, or they pile up forever and
    // every send fans out to dead endpoints.
    const dead = res.responses
      .map((r, i) => (r.success ? null : tokens[i]))
      .filter((t): t is string => t !== null);
    if (dead.length > 0) {
      await db
        .collection("users")
        .doc(uid)
        .update({fcm_tokens: FieldValue.arrayRemove(...dead)});
    }
  } catch (e) {
    logger.warn("notify: push failed", {uid, type, e});
  }
}
