import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {FieldValue} from "firebase-admin/firestore";
import {geohashForLocation} from "geofire-common";
import {auth, db} from "../shared/admin";
import {isAppRole} from "../shared/roles";

interface CompleteRegistrationData {
  role?: unknown;
  displayName?: unknown;
  city?: unknown;
  lat?: unknown;
  lng?: unknown;
  placeId?: unknown;
  primarySubject?: unknown;
}

/**
 * Called by the app immediately after createUserWithEmailAndPassword, at the end
 * of the 3-step registration. Sets the user's `role` Custom Claim (the root of
 * the RBAC system) and writes the initial `users/{uid}` document, including the
 * `geo_location` (lat/lng/geohash/city) needed by Phase 4 discovery.
 *
 * Implemented as a callable — not an Auth onCreate trigger — because the role +
 * city are chosen in the UI and must travel from the client. Social /
 * passwordless sign-ins (Phase 2.5) reuse this same call.
 *
 * Idempotent + anti-elevation: refuses to run if the user already has a role.
 */
export const completeRegistration = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError(
      "unauthenticated",
      "You must be signed in to complete registration."
    );
  }

  const data = (request.data ?? {}) as CompleteRegistrationData;
  if (!isAppRole(data.role)) {
    throw new HttpsError(
      "invalid-argument",
      "role must be one of: student, teacher, institution."
    );
  }
  const role = data.role;
  const displayName =
    typeof data.displayName === "string" ? data.displayName.trim() : "";
  const primarySubject =
    typeof data.primarySubject === "string" ? data.primarySubject.trim() : "";

  // City is mandatory and must come from Places (city string + coordinates).
  const city = typeof data.city === "string" ? data.city.trim() : "";
  const lat = typeof data.lat === "number" ? data.lat : NaN;
  const lng = typeof data.lng === "number" ? data.lng : NaN;
  const placeId = typeof data.placeId === "string" ? data.placeId : "";
  if (
    city.length === 0 ||
    !Number.isFinite(lat) ||
    !Number.isFinite(lng) ||
    lat < -90 ||
    lat > 90 ||
    lng < -180 ||
    lng > 180
  ) {
    throw new HttpsError(
      "invalid-argument",
      "A valid city (with coordinates) is required."
    );
  }
  const geohash = geohashForLocation([lat, lng]);

  const userRef = db.collection("users").doc(uid);
  const existing = await userRef.get();
  if (existing.exists && existing.get("role")) {
    throw new HttpsError(
      "already-exists",
      "This account has already completed registration."
    );
  }

  // Teachers must be admin-verified before appearing in discovery; other roles
  // need no verification.
  const verifiedStatus = role === "teacher" ? "pending" : "not_required";

  // Set the claim first, then write the doc. If the doc write fails, the client
  // rolls back by deleting the half-created auth account.
  await auth.setCustomUserClaims(uid, {role});

  await userRef.set(
    {
      uid,
      role,
      email: request.auth?.token.email ?? null,
      display_name: displayName,
      primary_subject: primarySubject,
      geo_location: {
        lat,
        lng,
        geohash,
        city,
        place_id: placeId,
      },
      sub_status: "free",
      // Every priced amount is stored next to its currency, so adding more
      // currencies later never requires guessing what an old number meant.
      currency: "USD",
      verified_status: verifiedStatus,
      is_banned: false,
      avg_rating: 0,
      total_reviews: 0,
      featured: false,
      created_at: FieldValue.serverTimestamp(),
    },
    {merge: true}
  );

  logger.info("completeRegistration", {uid, role, city});
  return {ok: true, role, verifiedStatus};
});
