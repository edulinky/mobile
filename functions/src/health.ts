import {onCall} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";

/**
 * Health check callable — verifies the Functions pipeline end-to-end from the
 * app. Returns server time and the caller's uid (null if unauthenticated).
 * Deploy with: `firebase deploy --only functions:health`.
 */
export const health = onCall((request) => {
  const uid = request.auth?.uid ?? null;
  logger.info("health check", {uid: uid ?? "anonymous"});
  return {
    status: "ok",
    service: "edulink-functions",
    time: new Date().toISOString(),
    uid,
  };
});
