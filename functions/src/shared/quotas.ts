import {db} from "./admin";
import {canonicalSubject} from "./subjects";

/**
 * Free-tier right-swipe quotas, per rolling 24h window.
 *
 * From the requirements: a free Student gets **20 right swipes / 24h**, split
 * **15 primary-subject + 5 discovery** — the two buckets are separate budgets,
 * so burning all 5 discovery swipes must not eat into the 15 primary ones.
 * The Teacher quota is "to be defined by Admin", hence the overridable config
 * doc rather than a constant.
 *
 * Left swipes (passes) are NOT metered — only expressions of interest are.
 * Premium users (`sub_status != "free"`) are unlimited.
 */
export interface QuotaLimits {
  primary: number;
  discovery: number;
}

const DEFAULTS: Record<string, QuotaLimits> = {
  student: {primary: 15, discovery: 5},
  teacher: {primary: 15, discovery: 5},
  institution: {primary: 9999, discovery: 9999},
};

export const QUOTA_WINDOW_MS = 24 * 60 * 60 * 1000;

/**
 * Limits for a role, letting an admin override them at `config/quotas`
 * (e.g. `{teacher: {primary: 30, discovery: 10}}`) without a redeploy.
 */
export async function limitsForRole(role: string): Promise<QuotaLimits> {
  const fallback = DEFAULTS[role] ?? DEFAULTS.student;
  try {
    const snap = await db.doc("config/quotas").get();
    const override = snap.get(role) as Partial<QuotaLimits> | undefined;
    if (!override) return fallback;
    return {
      primary: typeof override.primary === "number" ?
        override.primary :
        fallback.primary,
      discovery: typeof override.discovery === "number" ?
        override.discovery :
        fallback.discovery,
    };
  } catch {
    return fallback;
  }
}

/** Which budget a right-swipe draws from. */
export type QuotaBucket = "primary" | "discovery";

/**
 * A swipe is "primary" when the target teaches/studies the swiper's own primary
 * subject; everything else is "discovery".
 *
 * Compared through `canonicalSubject` — the same table the job deck uses. A
 * student whose primary subject is "Maths" swiping a teacher who wrote
 * "Mathematics" was silently spending from the 5-swipe discovery budget instead
 * of the 15-swipe primary one: the same string-equality bug, just quieter,
 * because nothing visibly disappeared.
 */
export function bucketFor(
  swiperPrimarySubject: string,
  targetSubjects: string[]
): QuotaBucket {
  const primary = canonicalSubject(swiperPrimarySubject);
  if (!primary) return "discovery";
  const match = targetSubjects.some((s) => canonicalSubject(s) === primary);
  return match ? "primary" : "discovery";
}
