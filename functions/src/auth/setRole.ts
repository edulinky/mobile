import {onCall, HttpsError} from "firebase-functions/v2/https";
import {auth, db} from "../shared/admin";
import {isAppRole} from "../shared/roles";

interface SetRoleData {
  uid?: unknown;
  role?: unknown;
}

/**
 * Admin-only: reassign a user's role. Updates both the Custom Claim and the
 * `users/{uid}` document. The target user must refresh their ID token (or
 * re-authenticate) to pick up the new claim.
 */
export const setRole = onCall(async (request) => {
  if (request.auth?.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Admins only.");
  }

  const {uid, role} = (request.data ?? {}) as SetRoleData;
  if (typeof uid !== "string" || uid.length === 0) {
    throw new HttpsError("invalid-argument", "uid is required.");
  }
  if (!isAppRole(role)) {
    throw new HttpsError(
      "invalid-argument",
      "role must be one of: student, teacher, institution."
    );
  }

  await auth.setCustomUserClaims(uid, {role});
  await db.collection("users").doc(uid).set({role}, {merge: true});

  return {ok: true};
});
