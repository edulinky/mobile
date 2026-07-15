import {onCall, HttpsError} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {FieldValue, Timestamp} from "firebase-admin/firestore";
import {db} from "../shared/admin";
import {
  bucketFor,
  limitsForRole,
  QUOTA_WINDOW_MS,
  QuotaBucket,
} from "../shared/quotas";
import {createMatchInTx} from "../matches/createMatch";
import {notify} from "../shared/notify";

interface QuotaState {
  windowStart: number;
  used: Record<QuotaBucket, number>;
}

/** Counters reset once the 24h window has elapsed. */
function readQuota(data: FirebaseFirestore.DocumentData | undefined): QuotaState {
  const now = Date.now();
  const startedAt = (data?.window_start as Timestamp | undefined)?.toMillis();
  const expired = startedAt === undefined || now - startedAt >= QUOTA_WINDOW_MS;
  if (expired) {
    return {windowStart: now, used: {primary: 0, discovery: 0}};
  }
  return {
    windowStart: startedAt,
    used: {
      primary: (data?.primary_used as number) ?? 0,
      discovery: (data?.discovery_used as number) ?? 0,
    },
  };
}

/**
 * Records one swipe and, if it completes a mutual right-swipe, creates the match.
 *
 * Everything happens in a **single Firestore transaction**: the quota check, the
 * swipe write, and the match write. Without that, two swipes racing (double-tap,
 * flaky network retry, two devices) could each read "14 used" and both commit,
 * putting a free user over their limit — quota enforcement that can be beaten by
 * tapping fast is not enforcement.
 *
 * Only right swipes (`liked: true`) are metered; passing is free.
 */
export const recordSwipe = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const targetId =
    typeof request.data?.targetId === "string" ? request.data.targetId : "";
  const liked = request.data?.liked === true;
  if (!targetId || targetId === uid) {
    throw new HttpsError("invalid-argument", "A valid targetId is required.");
  }

  const meRef = db.collection("users").doc(uid);
  const targetRef = db.collection("users").doc(targetId);
  const quotaRef = db.collection("swipeQuotas").doc(uid);
  const sentRef = db.collection("swipes").doc(uid).collection("sent").doc(targetId);
  // Did they already like me? That is what makes this a match.
  const theirSwipeRef = db
    .collection("swipes")
    .doc(targetId)
    .collection("sent")
    .doc(uid);

  const result = await db.runTransaction(async (tx) => {
    // All reads must precede all writes inside a transaction.
    const [meSnap, targetSnap, quotaSnap, sentSnap, theirSnap] = await Promise.all([
      tx.get(meRef),
      tx.get(targetRef),
      tx.get(quotaRef),
      tx.get(sentRef),
      tx.get(theirSwipeRef),
    ]);

    if (!meSnap.exists) {
      throw new HttpsError("not-found", "Your profile was not found.");
    }
    if (!targetSnap.exists) {
      throw new HttpsError("not-found", "That profile no longer exists.");
    }
    const me = meSnap.data() ?? {};
    const target = targetSnap.data() ?? {};
    if (me.is_banned === true) {
      throw new HttpsError("permission-denied", "Your account is suspended.");
    }
    if (target.is_banned === true) {
      throw new HttpsError("not-found", "That profile is no longer available.");
    }
    // Same gate as getCandidates — an unverified teacher must not be able to
    // reach a student by calling this directly with a uid they already know.
    if ((me.role as string) === "teacher" && me.verified_status !== "approved") {
      throw new HttpsError(
        "failed-precondition",
        "Your account is awaiting verification."
      );
    }

    // A previous LIKE is final: re-swiping is a no-op, not a second quota
    // charge, and never a second match.
    //
    // A previous PASS is not. "Refresh" deliberately re-shows people you passed,
    // so you must be able to change your mind — otherwise you would see them
    // again, like them, and nothing would happen. Re-passing is free (passes are
    // never metered); pass → like is charged exactly once, here.
    const previouslyLiked = sentSnap.exists && sentSnap.get("liked") === true;
    if (previouslyLiked) {
      return {ok: true, alreadySwiped: true, matched: false, matchId: null};
    }
    const changingMind = sentSnap.exists; // a pass we are overwriting

    const role = (me.role as string) ?? "student";
    const isPremium = (me.sub_status as string) !== "free";
    const bucket = bucketFor(
      (me.primary_subject as string) ?? "",
      ((target.subjects as string[]) ?? []).map(String)
    );

    const quota = readQuota(quotaSnap.data());
    let remaining: Record<QuotaBucket, number> | null = null;

    if (liked && !isPremium) {
      const limits = await limitsForRole(role);
      if (quota.used[bucket] >= limits[bucket]) {
        throw new HttpsError(
          "resource-exhausted",
          bucket === "primary" ?
            "You have used all your primary-subject swipes for today." :
            "You have used all your discovery swipes for today."
        );
      }
      quota.used[bucket] += 1;
      remaining = {
        primary: limits.primary - quota.used.primary,
        discovery: limits.discovery - quota.used.discovery,
      };
      tx.set(
        quotaRef,
        {
          window_start: Timestamp.fromMillis(quota.windowStart),
          primary_used: quota.used.primary,
          discovery_used: quota.used.discovery,
        },
        {merge: true}
      );
    }

    tx.set(sentRef, {
      target_id: targetId,
      liked,
      bucket,
      created_at: FieldValue.serverTimestamp(),
    });
    if (changingMind) {
      logger.info("recordSwipe: pass upgraded", {uid, targetId, liked});
    }

    const mutual = liked && theirSnap.exists && theirSnap.get("liked") === true;
    const matchId = mutual ? createMatchInTx(tx, uid, targetId) : null;

    return {ok: true, alreadySwiped: false, matched: mutual, matchId, remaining};
  });

  // Notify AFTER the transaction commits — a transaction can be retried, and
  // sending inside it could fire the same push several times.
  if (result.matched) {
    const [me, them] = await Promise.all([
      db.collection("users").doc(uid).get(),
      db.collection("users").doc(targetId).get(),
    ]);
    const myName = (me.get("display_name") as string) || "Someone";
    const theirName = (them.get("display_name") as string) || "Someone";
    const matchId = result.matchId as string;

    await Promise.all([
      notify({
        uid,
        type: "match",
        title: "You have a new connection",
        body: `You and ${theirName} are connected. Say hello.`,
        data: {matchId, otherUid: targetId},
      }),
      notify({
        uid: targetId,
        type: "match",
        title: "You have a new connection",
        body: `You and ${myName} are connected. Say hello.`,
        data: {matchId, otherUid: uid},
      }),
    ]);
  }

  logger.info("recordSwipe", {uid, targetId, liked, matched: result.matched});
  return result;
});

/** The signed-in user's remaining right-swipes, for the quota banner. */
export const getSwipeQuota = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "You must be signed in.");
  }

  const [meSnap, quotaSnap] = await Promise.all([
    db.collection("users").doc(uid).get(),
    db.collection("swipeQuotas").doc(uid).get(),
  ]);

  const role = (meSnap.get("role") as string) ?? "student";
  const isPremium = (meSnap.get("sub_status") as string) !== "free";
  const limits = await limitsForRole(role);
  const quota = readQuota(quotaSnap.data());

  return {
    unlimited: isPremium,
    primary: {
      used: quota.used.primary,
      limit: limits.primary,
      remaining: Math.max(0, limits.primary - quota.used.primary),
    },
    discovery: {
      used: quota.used.discovery,
      limit: limits.discovery,
      remaining: Math.max(0, limits.discovery - quota.used.discovery),
    },
    resetsAt: quota.windowStart + QUOTA_WINDOW_MS,
  };
});
