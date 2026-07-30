import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {geohashQueryBounds, distanceBetween} from "geofire-common";
import {db} from "../shared/admin";
import {canonicalSubject} from "../shared/subjects";

const BATCH_SIZE = 10;
const DEFAULT_RADIUS_KM = 50;
const MAX_RADIUS_KM = 500;

/**
 * The Job Cards deck for a teacher: active cards near them, not already applied
 * to.
 *
 * Same verification gate as student discovery — an unapproved teacher cannot
 * reach institutions either.
 */
export const getJobCards = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const meSnap = await db.collection("users").doc(uid).get();
  if (!meSnap.exists) {
    throw new HttpsError("not-found", "Your profile was not found.");
  }
  const me = meSnap.data() ?? {};
  if (me.role !== "teacher") {
    throw new HttpsError("permission-denied", "Only teachers see job cards.");
  }
  if (me.is_banned === true) {
    throw new HttpsError("permission-denied", "Your account is suspended.");
  }
  if (me.verified_status !== "approved") {
    throw new HttpsError(
      "failed-precondition",
      "Your account is awaiting verification."
    );
  }

  const geo = me.geo_location as {lat?: number; lng?: number} | undefined;
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

  // Jobs I have already applied to never resurface. (Unlike people, there is no
  // "pass" to un-do here: applying is one-directional.)
  //
  // `.select()` with NO field names projects to an EMPTY field set, not "all
  // fields" — every `d.get("job_id")` below would silently be `undefined`,
  // and the exclusion would never fire. The field must be named explicitly.
  const appliedSnap = await db
    .collection("applications")
    .where("teacher_id", "==", uid)
    .select("job_id")
    .get();
  const applied = new Set(appliedSnap.docs.map((d) => d.get("job_id") as string));

  const bounds = geohashQueryBounds(center, radiusM);
  const snapshots = await Promise.all(
    bounds.map(([start, end]) =>
      db
        .collection("jobCards")
        .where("status", "==", "active")
        .orderBy("geo_location.geohash")
        .startAt(start)
        .endAt(end)
        .limit(BATCH_SIZE * 5)
        .get()
    )
  );

  // Only jobs in the subjects this teacher actually teaches (stakeholder call).
  //
  // Subjects are free text on both sides, so they are compared *canonicalized*:
  // case, padding and the common aliases ("maths" → "mathematics") — see
  // `canonicalSubject`.
  //
  // A teacher with NO subjects set is not filtered down to nothing — an empty
  // deck with no explanation reads as "there are no jobs", not "tell us what you
  // teach". They see everything until they fill the field in.
  const mySubjects = new Set(
    ((me.subjects as string[]) ?? [])
      .map((s) => canonicalSubject(String(s)))
      .filter((s) => s.length > 0)
  );
  const filterBySubject = mySubjects.size > 0;

  const cards: Record<string, unknown>[] = [];
  let filteredOut = 0;
  for (const snap of snapshots) {
    for (const doc of snap.docs) {
      if (applied.has(doc.id)) continue;
      const d = doc.data();
      const lat = d.geo_location?.lat;
      const lng = d.geo_location?.lng;
      if (typeof lat !== "number" || typeof lng !== "number") continue;

      const distanceKm = distanceBetween([lat, lng], center);
      if (distanceKm * 1000 > radiusM) continue;

      if (
        filterBySubject &&
        !mySubjects.has(canonicalSubject(String(d.subject ?? "")))
      ) {
        filteredOut++;
        continue;
      }

      cards.push({
        jobId: doc.id,
        instId: d.inst_id,
        institutionName: d.institution_name ?? "",
        institutionLogoUrl: d.institution_logo_url ?? "",
        title: d.title ?? "",
        subject: d.subject ?? "",
        level: d.level ?? "",
        description: d.description ?? "",
        contractType: d.contract_type ?? "full_time",
        salaryMin: typeof d.salary_min === "number" ? d.salary_min : null,
        salaryMax: typeof d.salary_max === "number" ? d.salary_max : null,
        salaryPeriod: d.salary_period ?? "month",
        startAtMs: d.start_at ? d.start_at.toMillis() : null,
        currency: d.currency ?? "USD",
        videoUrl: d.video_url ?? "",
        city: d.geo_location?.city ?? "",
        distanceKm: Math.round(distanceKm * 10) / 10,
      });
    }
  }

  cards.sort(
    (a, b) => (a.distanceKm as number) - (b.distanceKm as number)
  );

  const batch = cards.slice(0, BATCH_SIZE);
  logger.info("getJobCards", {
    uid,
    radiusKm,
    found: cards.length,
    // If this is high while `found` is 0, the market has jobs but none in this
    // teacher's subjects — which is a product signal, not a bug.
    filteredOutBySubject: filteredOut,
  });
  return {jobCards: batch, filteredOutBySubject: filteredOut};
});
