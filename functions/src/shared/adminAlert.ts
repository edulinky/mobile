import {logger} from "firebase-functions/v2";
import {db} from "./admin";
import {notify, NotificationType} from "./notify";
import {sendMail} from "./mailer";

export interface AdminAlert {
  /** Email subject. Prefix it so a mailbox filter can sort the queue. */
  subject: string;
  /** Plain-text body. The panel link is appended. */
  body: string;
  /** Short line for the in-app inbox. */
  title: string;
  /** The queue this belongs to, e.g. "/reports" — appended to ADMIN_URL. */
  panelPath: string;
  type: NotificationType;
  data?: Record<string, string>;
}

/**
 * Tells every admin that something needs a human.
 *
 * **Email is the channel that actually reaches them.** Admins work in the web
 * panel, not the mobile app: they have no FCM token and never open the in-app
 * inbox. The in-app notification is written anyway (it costs one document, and an
 * admin who does use the app should see it), but the email is the one that makes
 * the queue get worked.
 *
 * Best-effort, always: an alert that fails must never fail the thing that
 * triggered it. A teacher's certificate submission does not get rolled back
 * because Resend was down, and a report is not lost because an admin's mailbox
 * bounced — the row is already in the queue either way.
 */
export async function alertAdmins(alert: AdminAlert): Promise<void> {
  try {
    const admins = await db
      .collection("users")
      .where("role", "==", "admin")
      .get();

    const panelUrl = process.env.ADMIN_URL ?? "";
    const link = panelUrl ? `\n\nOpen the queue: ${panelUrl}${alert.panelPath}\n` : "";

    await Promise.all(
      admins.docs.flatMap((a) => {
        const email = a.get("email") as string | undefined;

        const tasks: Promise<unknown>[] = [
          notify({
            uid: a.id,
            type: alert.type,
            title: alert.title,
            body: alert.body.split("\n")[0],
            data: alert.data ?? {},
          }).catch((e) =>
            logger.error("alertAdmins: in-app notify failed", {admin: a.id, e})
          ),
        ];

        if (email) {
          tasks.push(
            sendMail({
              to: email,
              subject: alert.subject,
              body: alert.body + link,
            }).catch((e) =>
              logger.error("alertAdmins: email failed", {admin: a.id, e})
            )
          );
        }

        return tasks;
      })
    );
  } catch (e) {
    logger.error("alertAdmins: failed", {subject: alert.subject, e});
  }
}
