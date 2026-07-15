import {onCall, HttpsError, CallableRequest} from "firebase-functions/v2/https";
import {onRequest} from "firebase-functions/v2/https";
import {logger} from "firebase-functions/v2";
import {FieldValue} from "firebase-admin/firestore";
import {db} from "../shared/admin";
import {
  sendMail,
  unsubscribeUrlFor,
  verifyUnsubscribeToken,
} from "../shared/mailer";

const MAX_SUBJECT = 200;
const MAX_BODY = 10000;
/** Sent in chunks so one huge run cannot exhaust the function's memory/time. */
const BULK_CHUNK = 20;

function requireAdmin(request: CallableRequest): string {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "You must be signed in.");
  if (request.auth?.token.role !== "admin") {
    throw new HttpsError("permission-denied", "Admins only.");
  }
  return uid;
}

async function audit(
  actor: string,
  action: string,
  target: string,
  details: Record<string, unknown>
): Promise<void> {
  await db.collection("auditLog").add({
    actor_uid: actor,
    action,
    target_uid: target,
    details,
    created_at: FieldValue.serverTimestamp(),
  });
}

function validate(subject: string, body: string): void {
  if (subject.length === 0 || subject.length > MAX_SUBJECT) {
    throw new HttpsError("invalid-argument", "A subject is required.");
  }
  if (body.length === 0 || body.length > MAX_BODY) {
    throw new HttpsError("invalid-argument", "A message body is required.");
  }
}

/**
 * Email ONE user. Transactional: an admin writing to a specific person about
 * their account, so it does not require opt-in and carries no unsubscribe link.
 */
export const sendUserEmail = onCall(async (request) => {
  const actor = requireAdmin(request);
  const uid = typeof request.data?.uid === "string" ? request.data.uid : "";
  const subject = (request.data?.subject ?? "").toString().trim();
  const body = (request.data?.body ?? "").toString().trim();

  if (!uid) throw new HttpsError("invalid-argument", "uid is required.");
  validate(subject, body);

  const snap = await db.collection("users").doc(uid).get();
  if (!snap.exists) throw new HttpsError("not-found", "User not found.");
  const to = snap.get("email") as string | undefined;
  if (!to) throw new HttpsError("failed-precondition", "User has no email.");

  await sendMail({to, subject, body});
  await audit(actor, "send_user_email", uid, {subject});

  logger.info("sendUserEmail", {actor, uid});
  return {ok: true, to};
});

/**
 * Email MANY users.
 *
 * This is marketing/announcement mail, and it is treated as such:
 *  - **Opt-out is respected.** Anyone with `email_opt_out: true` is skipped, and
 *    that is enforced here, not in the admin UI.
 *  - **Every message carries a signed unsubscribe link** plus a List-Unsubscribe
 *    header. Bulk mail without a working unsubscribe is a legal problem (GDPR,
 *    CAN-SPAM), not just rude — and it is how a sending domain gets blacklisted.
 *  - **Banned users are skipped** — they should not be receiving anything.
 *  - A failed address never aborts the run; failures are counted and reported.
 *
 * `dryRun` returns the recipient count without sending, so the admin UI can show
 * exactly who would receive it BEFORE anything leaves.
 */
export const sendBulkEmail = onCall(
  {timeoutSeconds: 540, memory: "512MiB"},
  async (request) => {
    const actor = requireAdmin(request);
    const subject = (request.data?.subject ?? "").toString().trim();
    const body = (request.data?.body ?? "").toString().trim();
    // Rich HTML from the admin's editor. Sanitised in the mailer, against an
    // allowlist — never passed through as-is.
    const html = typeof request.data?.html === "string" ? request.data.html : "";
    const role = typeof request.data?.role === "string" ? request.data.role : "";
    const dryRun = request.data?.dryRun === true;

    if (!dryRun) validate(subject, body);

    let q: FirebaseFirestore.Query = db.collection("users");
    if (role && role !== "all") q = q.where("role", "==", role);

    const snap = await q.get();
    const recipients = snap.docs
      .filter((d) => {
        const email = d.get("email") as string | undefined;
        if (!email) return false;
        if (d.get("is_banned") === true) return false;
        if (d.get("email_opt_out") === true) return false;
        if (d.get("role") === "admin") return false; // don't spam ourselves
        return true;
      })
      .map((d) => ({uid: d.id, email: d.get("email") as string}));

    if (dryRun) {
      return {
        ok: true,
        dryRun: true,
        recipients: recipients.length,
        skipped: snap.size - recipients.length,
      };
    }

    let sent = 0;
    let failed = 0;

    for (let i = 0; i < recipients.length; i += BULK_CHUNK) {
      const chunk = recipients.slice(i, i + BULK_CHUNK);
      await Promise.all(
        chunk.map(async (r) => {
          try {
            await sendMail({
              to: r.email,
              subject,
              body,
              html: html || undefined,
              unsubscribeUrl: unsubscribeUrlFor(r.uid),
            });
            sent++;
          } catch (e) {
            failed++;
            logger.warn("sendBulkEmail: recipient failed", {uid: r.uid, e});
          }
        })
      );
    }

    await audit(actor, "send_bulk_email", role || "all", {
      subject,
      sent,
      failed,
    });

    logger.info("sendBulkEmail", {actor, role, sent, failed});
    return {ok: true, sent, failed};
  }
);

/**
 * The unsubscribe link's destination. Public by necessity — it is clicked from
 * an inbox, with no session.
 *
 * The uid alone proves nothing (anyone could put someone else's uid in the URL),
 * so the link carries an HMAC over the uid. Without a valid signature this does
 * nothing.
 */
export const unsubscribe = onRequest(async (req, res) => {
  const uid = String(req.query.uid ?? "");
  const token = String(req.query.token ?? "");

  const page = (title: string, message: string) =>
    `<!doctype html><html><head><meta charset="utf-8">
     <meta name="viewport" content="width=device-width,initial-scale=1">
     <title>${title}</title></head>
     <body style="margin:0;background:#f0f9ff;display:grid;place-items:center;
                  min-height:100vh;font:16px/1.6 -apple-system,BlinkMacSystemFont,
                  'Segoe UI',system-ui,sans-serif;color:#0f172a">
       <div style="background:#fff;padding:32px;border-radius:18px;max-width:420px;
                   text-align:center">
         <div style="font-weight:800;color:#0284c7;margin-bottom:14px">EduLinky</div>
         <h1 style="font-size:20px;margin:0 0 8px">${title}</h1>
         <p style="margin:0;color:#475569">${message}</p>
       </div>
     </body></html>`;

  if (!uid || !verifyUnsubscribeToken(uid, token)) {
    res.status(400).send(page("Invalid link", "This unsubscribe link is not valid."));
    return;
  }

  try {
    await db.collection("users").doc(uid).update({email_opt_out: true});
  } catch (e) {
    logger.error("unsubscribe failed", {uid, e});
    res.status(500).send(page("Something went wrong", "Please try again later."));
    return;
  }

  logger.info("unsubscribe", {uid});
  res.status(200).send(
    page(
      "You're unsubscribed",
      "You will no longer receive announcement emails from EduLinky. " +
        "Account and security emails will still be sent."
    )
  );
});
