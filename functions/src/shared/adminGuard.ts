import {HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "./admin";

/**
 * The gate on every admin action.
 *
 * The `admin` role is deliberately NOT in `APP_ROLES` — it can never be selected
 * at registration, only granted out-of-band via `setRole` by an existing admin
 * (or by the bootstrap script). So this check is the whole gate.
 */
export function requireAdmin(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  if (request.auth?.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Admins only.");
  }
  return uid;
}

/**
 * Append-only record of who did what. An admin can approve a teacher, ban a
 * user, or delete content — actions with real consequences for real people, so
 * they must be attributable after the fact.
 */
export async function audit(
  actorUid: string,
  action: string,
  targetUid: string,
  details: Record<string, unknown> = {}
): Promise<void> {
  await db.collection("auditLog").add({
    actor_uid: actorUid,
    action,
    target_uid: targetUid,
    details,
    created_at: FieldValue.serverTimestamp(),
  });
}
