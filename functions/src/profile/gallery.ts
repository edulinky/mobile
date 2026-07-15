import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {FieldValue} from "firebase-admin/firestore";
import {db, storage} from "../shared/admin";

const MAX_GALLERY_PHOTOS = 6;

/**
 * The gallery stores Storage **paths**, not URLs — the app resolves each path to
 * a download URL through the Storage SDK. That means a user can never point
 * their gallery at an arbitrary remote image (their photos are shown to other
 * users), because the path is validated here to live under their own folder.
 */
export const addGalleryPhoto = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const path = typeof request.data?.path === "string" ? request.data.path : "";
  if (!path.startsWith(`gallery/${uid}/`) || path.includes("..")) {
    throw new HttpsError("invalid-argument", "Invalid gallery path.");
  }

  const [exists] = await storage.bucket().file(path).exists();
  if (!exists) {
    throw new HttpsError("not-found", "Photo was not uploaded.");
  }

  const userRef = db.collection("users").doc(uid);
  const snap = await userRef.get();
  const gallery = (snap.get("gallery") as string[] | undefined) ?? [];
  if (gallery.includes(path)) return {ok: true, gallery};
  // The cap is enforced here, not in the rules — rules can't count an array.
  if (gallery.length >= MAX_GALLERY_PHOTOS) {
    throw new HttpsError(
      "failed-precondition",
      `You can have at most ${MAX_GALLERY_PHOTOS} photos.`
    );
  }

  await userRef.update({gallery: FieldValue.arrayUnion(path)});
  logger.info("addGalleryPhoto", {uid, path});
  return {ok: true, gallery: [...gallery, path]};
});

/** Removes a gallery photo from the doc and deletes the underlying object. */
export const removeGalleryPhoto = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const path = typeof request.data?.path === "string" ? request.data.path : "";
  if (!path.startsWith(`gallery/${uid}/`) || path.includes("..")) {
    throw new HttpsError("invalid-argument", "Invalid gallery path.");
  }

  await db
    .collection("users")
    .doc(uid)
    .update({gallery: FieldValue.arrayRemove(path)});

  // Best-effort: the doc is the source of truth, so a failed delete (already
  // gone) must not fail the call.
  try {
    await storage.bucket().file(path).delete();
  } catch (e) {
    logger.warn("removeGalleryPhoto: object delete failed", {uid, path, e});
  }

  logger.info("removeGalleryPhoto", {uid, path});
  return {ok: true};
});
