import {onRequest} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import * as crypto from "crypto";
import {FieldValue} from "firebase-admin/firestore";
import {auth, db} from "../shared/admin";

const WEBHOOK_SECRET = process.env.REVENUECAT_WEBHOOK_SECRET ?? "";

/**
 * Events that mean "this person is entitled right now".
 *
 * **CANCELLATION is deliberately NOT here, and deliberately not a revocation
 * either.** In RevenueCat (and in the stores) a cancellation means *auto-renew
 * was turned off* — the subscriber keeps what they paid for until the period
 * ends, and only then does EXPIRATION fire. Downgrading someone the moment they
 * cancel takes away time they have already paid for, which is a refund request
 * and a one-star review.
 */
const GRANT = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "UNCANCELLATION",
  "PRODUCT_CHANGE",
  "NON_RENEWING_PURCHASE",
  "SUBSCRIPTION_EXTENDED",
]);

/** Events that mean the entitlement is actually gone. */
const REVOKE = new Set([
  "EXPIRATION",
  "SUBSCRIPTION_PAUSED",
  "REFUND",
  "TRANSFER", // the sub moved to another app_user_id; this one no longer has it
]);

/**
 * RevenueCat → our subscription state.
 *
 * An HTTPS function, not a callable: RevenueCat is calling us, not a signed-in
 * client, so there is no Firebase auth context to check.
 *
 * **The server is the only thing that decides who paid.** The app never writes
 * `sub_status` — the Firestore rules forbid it — because a client that could set
 * its own subscription state is a client with free unlimited swipes. This webhook
 * is the single writer.
 *
 * That makes the endpoint itself the attack surface: an unauthenticated URL that
 * grants premium grants it to anyone who finds it. So every request must carry
 * the shared secret in `Authorization` (set in the RevenueCat dashboard), and it
 * is compared in constant time — a plain `!==` on a secret leaks its length and,
 * given enough tries, its contents.
 */
export const revenuecatWebhook = onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return;
  }

  // Fail closed. A misconfigured secret must mean "nobody gets premium", never
  // "everybody does".
  if (!WEBHOOK_SECRET) {
    logger.error("revenuecatWebhook: REVENUECAT_WEBHOOK_SECRET is not set");
    res.status(500).send("Not configured");
    return;
  }

  const provided = req.get("Authorization") ?? "";
  const expected = `Bearer ${WEBHOOK_SECRET}`;
  const ok =
    provided.length === expected.length &&
    crypto.timingSafeEqual(Buffer.from(provided), Buffer.from(expected));
  if (!ok) {
    logger.warn("revenuecatWebhook: rejected an unauthenticated call");
    res.status(401).send("Unauthorized");
    return;
  }

  const event = req.body?.event ?? {};
  const type = String(event.type ?? "");
  // We call `Purchases.logIn(uid)` in the app, so app_user_id IS the Firebase
  // uid. Without that, a purchase cannot be attached to an account at all.
  const uid = String(event.app_user_id ?? "");

  if (!uid) {
    // Nothing to do, but 200: a non-2xx makes RevenueCat retry forever.
    logger.warn("revenuecatWebhook: event with no app_user_id", {type});
    res.status(200).send("ok");
    return;
  }

  const grant = GRANT.has(type);
  const revoke = REVOKE.has(type);
  if (!grant && !revoke) {
    // TEST, BILLING_ISSUE, SUBSCRIBER_ALIAS… nothing to change.
    logger.info("revenuecatWebhook: ignored", {type, uid});
    res.status(200).send("ok");
    return;
  }

  const userRef = db.collection("users").doc(uid);
  const snap = await userRef.get();
  if (!snap.exists) {
    logger.warn("revenuecatWebhook: unknown user", {uid, type});
    res.status(200).send("ok");
    return;
  }
  const role = snap.get("role") as string | undefined;

  try {
    const update: Record<string, unknown> = {
      sub_status: grant ? "premium" : "free",
      sub_updated_at: FieldValue.serverTimestamp(),
      sub_expires_at: event.expiration_at_ms ?
        new Date(Number(event.expiration_at_ms)) :
        FieldValue.delete(),
      sub_product_id: grant ? String(event.product_id ?? "") : FieldValue.delete(),
    };

    // FR-3.3: "Premium Teacher: Unlimited swipes + Featured badge." The badge is
    // a paid perk, so it rides the subscription — granted here, and taken back on
    // expiry. Leaving it to an admin to hand out means a teacher pays and does
    // not get what they paid for until someone notices.
    //
    // Students have no Featured badge, so their `featured` is left alone.
    if (role === "teacher") {
      update.featured = grant;
    }
    await userRef.update(update);

    // The claim is what the Firestore RULES can see (the user doc is a read the
    // rules would have to pay for on every write). It lags by up to an hour on
    // its own, so the app force-refreshes its token right after a purchase.
    await auth.setCustomUserClaims(uid, {
      ...((await auth.getUser(uid)).customClaims ?? {}),
      isPremium: grant,
    });

    logger.info("revenuecatWebhook", {uid, type, role, premium: grant});
    res.status(200).send("ok");
  } catch (e) {
    // 5xx so RevenueCat retries — a dropped RENEWAL means a paying customer
    // silently loses premium, which is the worst bug this system can have.
    logger.error("revenuecatWebhook: failed", {uid, type, e});
    res.status(500).send("error");
  }
});
