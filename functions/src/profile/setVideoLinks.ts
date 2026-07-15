import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {db} from "../shared/admin";

const MAX_VIDEOS = 4;

// Videos are embedded in a WebView shown to OTHER users. An arbitrary URL there
// is a phishing surface (a page dressed up as EduLinky asking for a password),
// so only these hosts are storable — which is why video_links is not
// client-writable in the Firestore rules.
const ALLOWED_HOSTS = [
  "youtube.com",
  "www.youtube.com",
  "m.youtube.com",
  "youtu.be",
  "vimeo.com",
  "www.vimeo.com",
  "player.vimeo.com",
];

function isAllowedVideoUrl(raw: string): boolean {
  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    return false;
  }
  return url.protocol === "https:" && ALLOWED_HOSTS.includes(url.hostname);
}

/** Replaces the teacher's video links with a validated list. */
export const setVideoLinks = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const raw = request.data?.links;
  if (!Array.isArray(raw)) {
    throw new HttpsError("invalid-argument", "links must be an array.");
  }
  const links = raw
    .filter((l): l is string => typeof l === "string")
    .map((l) => l.trim())
    .filter((l) => l.length > 0);

  if (links.length > MAX_VIDEOS) {
    throw new HttpsError(
      "invalid-argument",
      `At most ${MAX_VIDEOS} videos are allowed.`
    );
  }
  const bad = links.find((l) => !isAllowedVideoUrl(l));
  if (bad) {
    throw new HttpsError(
      "invalid-argument",
      "Only https YouTube or Vimeo links are allowed."
    );
  }

  await db.collection("users").doc(uid).update({video_links: links});
  logger.info("setVideoLinks", {uid, count: links.length});
  return {ok: true, links};
});
