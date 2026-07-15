import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";

const PLACES_API_KEY = process.env.PLACES_API_KEY ?? "";

interface DetailsData {
  placeId?: unknown;
  sessionToken?: unknown;
}

/**
 * Fetch a place's coordinates → Places API (New). Called once when the user
 * selects a city; ends the autocomplete billing session. App Check enforced.
 * (No minInstances — it's a single call per pick; a rare cold start is fine.)
 */
export const placeDetails = onCall(
  {enforceAppCheck: true},
  async (request) => {
    if (!PLACES_API_KEY) {
      throw new HttpsError(
        "failed-precondition",
        "Places API key not configured."
      );
    }
    const data = (request.data ?? {}) as DetailsData;
    const placeId = typeof data.placeId === "string" ? data.placeId : "";
    const sessionToken =
      typeof data.sessionToken === "string" ? data.sessionToken : undefined;
    if (placeId.length === 0) {
      throw new HttpsError("invalid-argument", "placeId is required.");
    }

    const url = new URL(
      `https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}`
    );
    url.searchParams.set("languageCode", "en");
    if (sessionToken) url.searchParams.set("sessionToken", sessionToken);

    const resp = await fetch(url, {
      headers: {
        "X-Goog-Api-Key": PLACES_API_KEY,
        "X-Goog-FieldMask": "location,displayName,formattedAddress",
      },
    });

    if (!resp.ok) {
      const body = await resp.text();
      logger.error("placeDetails failed", {status: resp.status, body});
      throw new HttpsError("internal", "Place details request failed.");
    }

    const json = (await resp.json()) as {
      location?: {latitude?: number; longitude?: number};
      displayName?: {text?: string};
      formattedAddress?: string;
    };
    const lat = json.location?.latitude;
    const lng = json.location?.longitude;
    if (typeof lat !== "number" || typeof lng !== "number") {
      throw new HttpsError("internal", "Place has no coordinates.");
    }

    return {
      lat,
      lng,
      name: json.displayName?.text ?? json.formattedAddress ?? "",
    };
  }
);
