import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {geohashQueryBounds, distanceBetween} from "geofire-common";
import {db} from "../shared/admin";

const BATCH_SIZE = 10;
const DEFAULT_RADIUS_KM = 50;
const MAX_RADIUS_KM = 500;

/** Who each role swipes on. (Teacher → Job Cards is added in Phase 6.) */
const TARGET_ROLE: Record<string, string> = {
  student: "teacher",
  teacher: "student",
};

interface Candidate {
  uid: string;
  displayName: string;
  photoUrl: string;
  subjects: string[];
  about: string;
  distanceKm: number;
  avgRating: number;
  totalReviews: number;
  verifiedStatus: string;
  featured: boolean;
  /** Server-side ranking signal only — never returned to the client. */
  likedMe?: boolean;
  hourlyRate: number | null;
  currency: string;
}

/**
 * Returns the next batch of profiles to swipe on: same-ish location, right role,
 * not already swiped, not me, not banned.
 *
 * Location uses a geohash bounding-box query (`geofire-common`) — Firestore has
 * no geo query, so we fetch the boxes covering the radius and filter by true
 * distance afterwards, because a box is coarser than a circle.
 */
export const getCandidates = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const meSnap = await db.collection("users").doc(uid).get();
  if (!meSnap.exists) {
    throw new HttpsError("not-found", "Your profile was not found.");
  }
  const me = meSnap.data() ?? {};
  const myRole = me.role as string;
  const targetRole = TARGET_ROLE[myRole];
  if (!targetRole) {
    throw new HttpsError(
      "failed-precondition",
      "This role has no discovery feed."
    );
  }
  if (me.is_banned === true) {
    throw new HttpsError("permission-denied", "Your account is suspended.");
  }
  // Verification gates discovery in BOTH directions. An unapproved teacher is
  // already invisible to students (filtered below) — they must also not be able
  // to browse or match with students, whose side of a match is often a minor.
  if (myRole === "teacher" && me.verified_status !== "approved") {
    throw new HttpsError(
      "failed-precondition",
      "Your account is awaiting verification."
    );
  }

  const geo = me.geo_location as
    | {lat?: number; lng?: number}
    | undefined;
  if (typeof geo?.lat !== "number" || typeof geo?.lng !== "number") {
    throw new HttpsError(
      "failed-precondition",
      "Set your city before discovering."
    );
  }
  const center: [number, number] = [geo.lat, geo.lng];

  const requested = Number(request.data?.radiusKm);
  const radiusKm = Number.isFinite(requested) ?
    Math.min(Math.max(requested, 1), MAX_RADIUS_KM) :
    DEFAULT_RADIUS_KM;
  const radiusM = radiusKm * 1000;

  // "Refresh" at the end of the deck re-shows people you PASSED. It never
  // re-shows people you LIKED: that like is already pending (or is a match), and
  // showing them again would let you like the same person twice.
  const includePassed = request.data?.includePassed === true;

  const sentSnap = await db
    .collection("swipes")
    .doc(uid)
    .collection("sent")
    .select("liked")
    .get();

  const seen = new Set<string>();
  for (const doc of sentSnap.docs) {
    const wasLiked = doc.get("liked") === true;
    if (wasLiked || !includePassed) seen.add(doc.id);
  }
  seen.add(uid);

  // Blocks are SYMMETRIC: neither party sees the other. A one-way block would
  // let the blocked person keep seeing (and re-reporting, and re-approaching)
  // someone who explicitly wanted them gone.
  const [iBlocked, blockedMe] = await Promise.all([
    db.collection("blocks").doc(uid).collection("blocked").select().get(),
    db.collectionGroup("blocked").where("target_id", "==", uid).select().get(),
  ]);
  for (const d of iBlocked.docs) seen.add(d.id);
  for (const d of blockedMe.docs) {
    const blocker = d.ref.parent.parent?.id;
    if (blocker) seen.add(blocker);
  }

  // Everyone who has ALREADY right-swiped me. Ranking them first is what turns a
  // pending like into a match: otherwise both people must find each other
  // independently in a distance-ordered deck, and the person who already said
  // yes might be card 30 — or never surface at all.
  //
  // This leaks nothing. They render as an ordinary card with no badge; the
  // viewer cannot tell "first because they liked me" from "first because they
  // are nearby". Naming a liker would be a disclosure; ordering is not.
  //
  // BEST EFFORT: this is a ranking signal, not a filter. If it fails — the
  // collection-group index still building, a transient error — we fall back to
  // the plain ordering. A boost must never be able to take discovery down.
  let likedMe = new Set<string>();
  try {
    const likedMeSnap = await db
      .collectionGroup("sent")
      .where("target_id", "==", uid)
      .where("liked", "==", true)
      .select() // ids only
      .get();
    // The doc id is the target; the LIKER is the parent of the `sent`
    // collection.
    likedMe = new Set(
      likedMeSnap.docs
        .map((d) => d.ref.parent.parent?.id)
        .filter((id): id is string => id !== undefined)
    );
  } catch (e) {
    logger.warn("getCandidates: liked-me boost unavailable", {uid, e});
  }

  // A geohash range query needs one query per bounding box.
  const bounds = geohashQueryBounds(center, radiusM);
  const snapshots = await Promise.all(
    bounds.map(([start, end]) =>
      db
        .collection("users")
        .where("role", "==", targetRole)
        .where("is_banned", "==", false)
        .orderBy("geo_location.geohash")
        .startAt(start)
        .endAt(end)
        .limit(BATCH_SIZE * 5) // headroom: many will be filtered out below
        .get()
    )
  );

  const candidates: Candidate[] = [];
  for (const snap of snapshots) {
    for (const doc of snap.docs) {
      if (seen.has(doc.id)) continue;
      const d = doc.data();

      // Teachers must be admin-approved before they are discoverable. Other
      // roles carry "not_required".
      if (targetRole === "teacher" && d.verified_status !== "approved") continue;

      const lat = d.geo_location?.lat;
      const lng = d.geo_location?.lng;
      if (typeof lat !== "number" || typeof lng !== "number") continue;

      // The bounding boxes over-select at the corners — filter to the circle.
      const distanceKm = distanceBetween([lat, lng], center);
      if (distanceKm * 1000 > radiusM) continue;

      candidates.push({
        uid: doc.id,
        displayName: (d.display_name as string) ?? "",
        photoUrl: (d.photo_url as string) ?? "",
        subjects: ((d.subjects as string[]) ?? []).map(String),
        about: (d.about as string) ?? "",
        distanceKm: Math.round(distanceKm * 10) / 10,
        avgRating: (d.avg_rating as number) ?? 0,
        totalReviews: (d.total_reviews as number) ?? 0,
        verifiedStatus: (d.verified_status as string) ?? "not_required",
        featured: d.featured === true,
        hourlyRate: typeof d.hourly_rate === "number" ? d.hourly_rate : null,
        currency: (d.currency as string) ?? "USD",
        likedMe: likedMe.has(doc.id),
      });
    }
  }

  // Ranking: people who already liked me, then featured (a paid perk), then
  // nearest. Putting a pending like in front of you is the highest-value card
  // we can show — one swipe away from a match.
  candidates.sort((a, b) => {
    if (a.likedMe !== b.likedMe) return a.likedMe ? -1 : 1;
    if (a.featured !== b.featured) return a.featured ? -1 : 1;
    return a.distanceKm - b.distanceKm;
  });

  // Strip the ranking signal before it leaves the server — the client must never
  // learn WHO liked them, only that this card came first.
  const batch = candidates
    .slice(0, BATCH_SIZE)
    .map(({likedMe: _likedMe, ...c}) => c);
  logger.info("getCandidates", {
    uid,
    targetRole,
    radiusKm,
    found: candidates.length,
    returned: batch.length,
    likedMeInBatch: candidates.slice(0, BATCH_SIZE).filter((c) => c.likedMe)
      .length,
  });
  return {candidates: batch};
});
