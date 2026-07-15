// The three self-service roles a user can register as. "admin" is intentionally
// excluded — it is granted only by an out-of-band script (see PLAN.md Phase 8).
export const APP_ROLES = ["student", "teacher", "institution"] as const;

export type AppRole = (typeof APP_ROLES)[number];

export function isAppRole(value: unknown): value is AppRole {
  return (
    typeof value === "string" &&
    (APP_ROLES as readonly string[]).includes(value)
  );
}
