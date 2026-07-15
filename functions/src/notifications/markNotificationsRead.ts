import {onCall, HttpsError} from "firebase-functions/v2/https";
import {db} from "../shared/admin";

/** Marks all of the caller's notifications read (clearing the nav badge). */
export const markNotificationsRead = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const unread = await db
    .collection("notifications")
    .doc(uid)
    .collection("items")
    .where("read", "==", false)
    .limit(500)
    .get();

  if (unread.empty) return {ok: true, updated: 0};

  const batch = db.batch();
  unread.docs.forEach((d) => batch.update(d.ref, {read: true}));
  await batch.commit();

  return {ok: true, updated: unread.size};
});
