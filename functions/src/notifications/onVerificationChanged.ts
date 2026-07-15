import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import {logger} from "firebase-functions/v2";
import {notify} from "../shared/notify";

/**
 * Tells a teacher when their certificate is reviewed.
 *
 * Without this, an approval or rejection was completely silent: the teacher's
 * Discover tab would simply start (or never start) working, with no explanation.
 * A rejection in particular had nowhere at all to surface.
 *
 * A Firestore trigger rather than something called from the admin action, so it
 * fires however `verified_status` changes — including a hand edit in the console,
 * which is how approvals happen until the admin panel lands in Phase 8.
 */
export const onVerificationChanged = onDocumentUpdated(
  "users/{uid}",
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    if (!before || !after) return;

    const was = before.get("verified_status") as string | undefined;
    const now = after.get("verified_status") as string | undefined;
    if (was === now) return;
    if (after.get("role") !== "teacher") return;

    const uid = event.params.uid;

    if (now === "approved") {
      await notify({
        uid,
        type: "verification_approved",
        title: "You're verified",
        body: "Your certificate was approved. You can now discover students.",
      });
      logger.info("onVerificationChanged: approved", {uid});
      return;
    }

    if (now === "rejected") {
      await notify({
        uid,
        type: "verification_rejected",
        title: "Verification unsuccessful",
        body: "We could not verify your certificate. You can submit a new one.",
      });
      logger.info("onVerificationChanged: rejected", {uid});
    }
  }
);
