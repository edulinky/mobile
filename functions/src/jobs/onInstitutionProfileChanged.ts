import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {logger} from "firebase-functions/v2";
import {db} from "../shared/admin";

/** Firestore batched writes cap out at 500 operations. */
const BATCH_SIZE = 500;

/**
 * Keeps a job card's `institution_name` / `institution_logo_url` in sync with
 * the institution that posted it.
 *
 * Those two fields are a **denormalized copy**, written once at post time by
 * `upsertJobCard` (so a teacher's discovery query never has to join against
 * `users`). Without this trigger, an institution correcting their name or logo
 * — e.g. after Institution Profile went from an unwired prototype to something
 * that actually saves — would leave every already-posted job (and, via
 * `institution_name`, every chat opened over it) permanently showing the old
 * value, with no way to fix it short of re-editing each job card by hand.
 */
export const onInstitutionProfileChanged = onDocumentUpdated(
  "users/{uid}",
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    if (!before || !after) return;
    if (after.get("role") !== "institution") return;

    const name = (after.get("display_name") as string) ?? "";
    const logoUrl = (after.get("photo_url") as string) ?? "";
    const changed =
      before.get("display_name") !== name || before.get("photo_url") !== logoUrl;
    if (!changed) return;

    const uid = event.params.uid;
    const jobsSnap = await db
      .collection("jobCards")
      .where("inst_id", "==", uid)
      .get();
    if (jobsSnap.empty) return;

    for (let i = 0; i < jobsSnap.docs.length; i += BATCH_SIZE) {
      const batch = db.batch();
      for (const doc of jobsSnap.docs.slice(i, i + BATCH_SIZE)) {
        batch.update(doc.ref, {
          institution_name: name,
          institution_logo_url: logoUrl,
        });
      }
      await batch.commit();
    }

    logger.info("onInstitutionProfileChanged: backfilled job cards", {
      uid,
      count: jobsSnap.size,
    });
  }
);
