import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {geohashForLocation} from "geofire-common";
import {db} from "../shared/admin";

interface UpdateLocationData {
  city?: unknown;
  lat?: unknown;
  lng?: unknown;
  placeId?: unknown;
}

/**
 * Changes the user's city from profile edit. Server-side because `geo_location`
 * drives Phase 4 discovery: the geohash must be derived from the coordinates,
 * not supplied by the caller, or a user could hand-write a hash and surface in a
 * city they aren't in. The Firestore rules forbid clients writing the field, so
 * this callable is the only way in.
 */
export const updateLocation = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const data = (request.data ?? {}) as UpdateLocationData;
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

  await db.collection("users").doc(uid).update({
    geo_location: {
      lat,
      lng,
      geohash: geohashForLocation([lat, lng]),
      city,
      place_id: placeId,
    },
  });

  logger.info("updateLocation", {uid, city});
  return {ok: true};
});
