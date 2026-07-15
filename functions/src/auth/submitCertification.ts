import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {FieldValue} from "firebase-admin/firestore";
import {db, storage} from "../shared/admin";
import {alertAdmins} from "../shared/adminAlert";

const MAX_CERTS = 5;

interface SubmitCertificationData {
  certPaths?: unknown;
}

/**
 * A teacher submits their certificates for admin review. The app has already
 * uploaded the files to `certs/{uid}/…` (write-only for the client); here we
 * record them on the user doc and put the teacher in the review queue.
 *
 * Several documents are allowed — a degree, a teaching qualification, a licence
 * are commonly separate files.
 *
 * `verified_status` is server-owned — the Firestore rules forbid the client from
 * touching it — so this callable is the only way in, and it can only ever move a
 * user to "pending", never to "approved".
 */
export const submitCertification = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }
  if (request.auth?.token.role !== "teacher") {
    throw new HttpsError(
      "permission-denied",
      "Only teachers submit certifications."
    );
  }

  const data = (request.data ?? {}) as SubmitCertificationData;
  const raw = Array.isArray(data.certPaths) ? data.certPaths : [];
  const certPaths = raw.filter((p): p is string => typeof p === "string");

  if (certPaths.length === 0) {
    throw new HttpsError("invalid-argument", "At least one file is required.");
  }
  if (certPaths.length > MAX_CERTS) {
    throw new HttpsError(
      "invalid-argument",
      `At most ${MAX_CERTS} documents are allowed.`
    );
  }
  // Every path must be inside the caller's own cert folder — otherwise a teacher
  // could point their user doc at somebody else's uploaded document and be
  // verified on their credentials.
  for (const path of certPaths) {
    if (!path.startsWith(`certs/${uid}/`) || path.includes("..")) {
      throw new HttpsError("invalid-argument", "Invalid certificate path.");
    }
  }

  const bucket = storage.bucket();
  const existence = await Promise.all(
    certPaths.map((p) => bucket.file(p).exists())
  );
  if (existence.some(([exists]) => !exists)) {
    throw new HttpsError("not-found", "A certificate file was not uploaded.");
  }

  const userRef = db.collection("users").doc(uid);
  const snap = await userRef.get();
  if (!snap.exists) {
    throw new HttpsError("not-found", "User profile not found.");
  }
  if (snap.get("verified_status") === "approved") {
    throw new HttpsError("already-exists", "Your account is already verified.");
  }

  await userRef.update({
    cert_paths: certPaths,
    cert_submitted_at: FieldValue.serverTimestamp(),
    verified_status: "pending",
  });

  // A pending teacher cannot discover students, cannot be discovered, and cannot
  // do anything but wait. Until now nothing told an admin they were waiting — the
  // queue was only found by someone remembering to look at it, and the teacher's
  // first experience of the product was an indefinite blank screen.
  const name = (snap.get("display_name") as string) || "A teacher";
  const email = (snap.get("email") as string) || "";
  await alertAdmins({
    type: "teacher_pending",
    title: "Teacher awaiting verification",
    subject: `[Verification] ${name} submitted documents`,
    body:
      `${name} has submitted ${certPaths.length} document(s) for verification.` +
      "\n\n" +
      (email ? `Email: ${email}\n` : "") +
      "They cannot use the app until you approve or reject them.",
    panelPath: "/",
    data: {uid},
  });

  logger.info("submitCertification", {uid, count: certPaths.length});
  return {ok: true, verifiedStatus: "pending", count: certPaths.length};
});
