import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {geohashForLocation} from "geofire-common";
import {db} from "../shared/admin";

const MAX_TITLE = 120;
const MAX_DESCRIPTION = 2000;
const CONTRACT_TYPES = ["full_time", "part_time", "contract"];
const MAX_LEVEL = 80;
// A draft is saved but NOT published: it never appears in any teacher's deck.
// getJobCards only ever returns status === "active".
const UPSERT_STATUSES = ["draft", "active"];
// A pay figure is meaningless without its period: 1200 is a good hourly rate and
// a poor monthly one.
const SALARY_PERIODS = ["hour", "day", "month"];

/**
 * Creates or updates an institution's Job Card.
 *
 * A callable rather than a client write, for the same reason as the user doc:
 * the **geohash must be derived** from coordinates, not supplied — otherwise an
 * institution could hand-write a hash and surface in a city they are not in. It
 * also means `inst_id` and `status` can never be forged.
 */
export const upsertJobCard = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  if (request.auth?.token.role !== "institution") {
    throw new HttpsError(
      "permission-denied",
      "Only institutions can post job cards."
    );
  }

  const d = (request.data ?? {}) as Record<string, unknown>;
  const jobId = typeof d.jobId === "string" && d.jobId.length > 0 ? d.jobId : null;

  const title = typeof d.title === "string" ? d.title.trim() : "";
  const description =
    typeof d.description === "string" ? d.description.trim() : "";
  const contractType =
    typeof d.contractType === "string" ? d.contractType : "full_time";

  // ONE subject per job card, free text.
  const subject = typeof d.subject === "string" ? d.subject.trim() : "";
  // e.g. "KS3", "A-Level", "Secondary" — free text: level naming differs by
  // country, so a fixed list would be wrong somewhere.
  const level = typeof d.level === "string" ? d.level.trim() : "";
  // Epoch millis from the client's date picker; null = start date flexible.
  const startAtMs =
    typeof d.startAtMs === "number" && Number.isFinite(d.startAtMs) ?
      d.startAtMs :
      null;

  if (title.length === 0 || title.length > MAX_TITLE) {
    throw new HttpsError("invalid-argument", "A job title is required.");
  }
  if (subject.length === 0) {
    throw new HttpsError("invalid-argument", "A subject is required.");
  }
  if (level.length > MAX_LEVEL) {
    throw new HttpsError("invalid-argument", "Level is too long.");
  }
  if (description.length > MAX_DESCRIPTION) {
    throw new HttpsError("invalid-argument", "Description is too long.");
  }
  if (!CONTRACT_TYPES.includes(contractType)) {
    throw new HttpsError("invalid-argument", "Invalid contract type.");
  }

  const status = typeof d.status === "string" ? d.status : "active";
  if (!UPSERT_STATUSES.includes(status)) {
    throw new HttpsError("invalid-argument", "Invalid status.");
  }

  const salaryPeriod =
    typeof d.salaryPeriod === "string" ? d.salaryPeriod : "month";
  if (!SALARY_PERIODS.includes(salaryPeriod)) {
    throw new HttpsError("invalid-argument", "Invalid pay period.");
  }

  const salaryMin = typeof d.salaryMin === "number" ? d.salaryMin : null;
  const salaryMax = typeof d.salaryMax === "number" ? d.salaryMax : null;
  if (salaryMin !== null && salaryMax !== null && salaryMin > salaryMax) {
    throw new HttpsError("invalid-argument", "Minimum salary exceeds maximum.");
  }

  const inst = await db.collection("users").doc(uid).get();
  if (!inst.exists) {
    throw new HttpsError("not-found", "Your profile was not found.");
  }
  if (inst.get("is_banned") === true) {
    throw new HttpsError("permission-denied", "Your account is suspended.");
  }

  // The card inherits the institution's location, so a teacher's geo query finds
  // it. Coordinates come from the institution's own verified city, never the
  // request.
  const geo = inst.get("geo_location") as
    | {lat?: number; lng?: number; city?: string}
    | undefined;
  if (typeof geo?.lat !== "number" || typeof geo?.lng !== "number") {
    throw new HttpsError(
      "failed-precondition",
      "Set your institution's city before posting a job."
    );
  }

  const ref = jobId ?
    db.collection("jobCards").doc(jobId) :
    db.collection("jobCards").doc();

  if (jobId) {
    const existing = await ref.get();
    if (!existing.exists) {
      throw new HttpsError("not-found", "That job card no longer exists.");
    }
    // You may only edit your OWN card.
    if (existing.get("inst_id") !== uid) {
      throw new HttpsError("permission-denied", "That is not your job card.");
    }
  }

  await ref.set(
    {
      job_id: ref.id,
      inst_id: uid,
      institution_name: (inst.get("display_name") as string) ?? "",
      institution_logo_url: (inst.get("photo_url") as string) ?? "",
      title,
      subject,
      level,
      description,
      contract_type: contractType,
      salary_min: salaryMin,
      salary_max: salaryMax,
      salary_period: salaryPeriod,
      start_at: startAtMs === null ? null : Timestamp.fromMillis(startAtMs),
      currency: (inst.get("currency") as string) ?? "USD",
      video_url: typeof d.videoUrl === "string" ? d.videoUrl.trim() : "",
      geo_location: {
        lat: geo.lat,
        lng: geo.lng,
        geohash: geohashForLocation([geo.lat, geo.lng]),
        city: geo.city ?? "",
      },
      status,
      applicant_count: jobId ? FieldValue.increment(0) : 0,
      updated_at: FieldValue.serverTimestamp(),
      ...(jobId ? {} : {created_at: FieldValue.serverTimestamp()}),
    },
    {merge: true}
  );

  logger.info("upsertJobCard", {uid, jobId: ref.id, created: jobId === null});
  return {ok: true, jobId: ref.id};
});

/** Close (or reopen) a job card. Closed cards leave the teachers' deck. */
export const setJobCardStatus = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const jobId = typeof request.data?.jobId === "string" ? request.data.jobId : "";
  const requested = request.data?.status;
  const status = ["draft", "active", "closed"].includes(requested as string) ?
    (requested as string) :
    "active";
  if (!jobId) {
    throw new HttpsError("invalid-argument", "jobId is required.");
  }

  const ref = db.collection("jobCards").doc(jobId);
  const snap = await ref.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "That job card no longer exists.");
  }
  if (snap.get("inst_id") !== uid) {
    throw new HttpsError("permission-denied", "That is not your job card.");
  }

  await ref.update({status, updated_at: FieldValue.serverTimestamp()});
  return {ok: true, status};
});
