import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";

const PLACES_API_KEY = process.env.PLACES_API_KEY ?? "";

interface AutocompleteData {
  input?: unknown;
  sessionToken?: unknown;
}

/**
 * City autocomplete proxy → Places API (New). Key stays server-side (.env).
 *
 * - `enforceAppCheck: true` → only calls from our genuine, attested app are
 *   accepted (the city picker runs pre-registration, so there's no auth to rely
 *   on — App Check is the guard).
 *
 * Scales to zero: the first search after an idle period pays a cold start. Set
 * `minInstances: 1` to trade ~$3/month for a warm instance if that ever matters.
 */
export const placesAutocomplete = onCall(
  {enforceAppCheck: true},
  async (request) => {
    if (!PLACES_API_KEY) {
      throw new HttpsError(
        "failed-precondition",
        "Places API key not configured."
      );
    }
    const data = (request.data ?? {}) as AutocompleteData;
    const input = typeof data.input === "string" ? data.input.trim() : "";
    const sessionToken =
      typeof data.sessionToken === "string" ? data.sessionToken : undefined;
    if (input.length < 2) return {suggestions: []};

    const resp = await fetch(
      "https://places.googleapis.com/v1/places:autocomplete",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-Api-Key": PLACES_API_KEY,
        },
        body: JSON.stringify({
          input,
          includedPrimaryTypes: ["(cities)"],
          // Pinned so a stored city name is identical no matter the device
          // locale ("London", never "Londres").
          languageCode: "en",
          ...(sessionToken ? {sessionToken} : {}),
        }),
      }
    );

    if (!resp.ok) {
      const body = await resp.text();
      logger.error("placesAutocomplete failed", {status: resp.status, body});
      throw new HttpsError("internal", "Autocomplete request failed.");
    }

    const json = (await resp.json()) as {
      suggestions?: Array<Record<string, any>>;
    };
    const suggestions = (json.suggestions ?? [])
      .map((s) => {
        const p = (s.placePrediction ?? {}) as Record<string, any>;
        const sf = (p.structuredFormat ?? {}) as Record<string, any>;
        return {
          placeId: (p.placeId as string) ?? "",
          primaryText:
            (sf.mainText?.text as string) ?? (p.text?.text as string) ?? "",
          secondaryText: (sf.secondaryText?.text as string) ?? "",
          fullText: (p.text?.text as string) ?? "",
        };
      })
      .filter((s) => s.placeId.length > 0);

    return {suggestions};
  }
);
