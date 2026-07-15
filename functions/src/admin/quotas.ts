import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {db} from "../shared/admin";
import {requireAdmin, audit} from "../shared/adminGuard";
import {limitsForRole} from "../shared/quotas";

/** The roles that actually swipe. An institution never does. */
const QUOTA_ROLES = ["student", "teacher"];

/** Nobody needs 10,000 swipes a day; a typo that big is a mistake, not a policy. */
const MAX_LIMIT = 1000;

/**
 * The current free-tier limits, per role.
 *
 * A callable rather than a direct read: `config/*` is `allow read: if false` for
 * every client, because the quota config is operational data — a free user who
 * can read it learns nothing useful, and a client that could *write* it would
 * grant itself unlimited swipes.
 *
 * Returns the effective values — the `config/quotas` override where one exists,
 * the built-in default where it does not — so the panel shows what is actually
 * being enforced, not an empty form.
 */
export const getQuotas = onCall(async (request) => {
  requireAdmin(request);

  const quotas: Record<string, {primary: number; discovery: number}> = {};
  for (const role of QUOTA_ROLES) {
    quotas[role] = await limitsForRole(role);
  }
  return {quotas};
});

/**
 * Set the free-tier swipe limits for a role.
 *
 * This is FR-3.2 — the teacher quota is "to be defined by Admin", which is why
 * the limits live in a Firestore doc rather than a constant: changing them must
 * not need a redeploy.
 *
 * It applies to **every free user in that role**, immediately (the next swipe
 * re-reads the config). Premium users are unaffected — they skip the quota check
 * entirely — so this only ever moves the free tier.
 */
export const setQuotas = onCall(async (request) => {
  const actor = requireAdmin(request);

  const role = typeof request.data?.role === "string" ? request.data.role : "";
  const primary = Number(request.data?.primary);
  const discovery = Number(request.data?.discovery);

  if (!QUOTA_ROLES.includes(role)) {
    throw new HttpsError("invalid-argument", "Unknown role.");
  }
  for (const [name, value] of [
    ["primary", primary],
    ["discovery", discovery],
  ] as const) {
    if (!Number.isInteger(value) || value < 0 || value > MAX_LIMIT) {
      throw new HttpsError(
        "invalid-argument",
        `${name} must be a whole number between 0 and ${MAX_LIMIT}.`
      );
    }
  }

  const before = await limitsForRole(role);
  await db.doc("config/quotas").set(
    {[role]: {primary, discovery}},
    {merge: true}
  );

  // Changing what every free user in a role is allowed to do is exactly the kind
  // of action that must be attributable later.
  await audit(actor, "set_quotas", role, {
    before,
    after: {primary, discovery},
  });

  logger.info("setQuotas", {actor, role, primary, discovery});
  return {ok: true, role, primary, discovery};
});
