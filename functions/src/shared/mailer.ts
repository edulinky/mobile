import * as crypto from "crypto";
import sanitizeHtml from "sanitize-html";
import {logger} from "firebase-functions/v2";

const RESEND_API_KEY = process.env.RESEND_API_KEY ?? "";
const MAIL_FROM = process.env.MAIL_FROM ?? "EduLinky <noreply@edulinky.com>";
// We send FROM a no-reply address (no mailbox needed — sending and receiving are
// independent), but a reply must go somewhere a human reads. Without this, a
// user answering an admin's email about their account is talking into the void.
const MAIL_REPLY_TO = process.env.MAIL_REPLY_TO ?? "";
const UNSUBSCRIBE_SECRET = process.env.UNSUBSCRIBE_SECRET ?? "";
const APP_URL = process.env.APP_URL ?? "";

export interface Mail {
  to: string;
  subject: string;
  /** Plain-text fallback. Always sent — many clients prefer or force it. */
  body: string;
  /** Rich HTML from the admin's editor. Sanitised before it is ever sent. */
  html?: string;
  /** Marketing mail MUST carry an unsubscribe link. Transactional need not. */
  unsubscribeUrl?: string;
}

/**
 * What the rich-text editor is allowed to produce.
 *
 * Admins are trusted, but "trusted" is not "infallible" — a pasted fragment from
 * a website can carry a tracking pixel, a script tag, or styles that break the
 * layout in half the mail clients that receive it. An allowlist means the only
 * markup that can leave here is markup we chose.
 */
const SANITIZE_OPTIONS: sanitizeHtml.IOptions = {
  allowedTags: [
    "p", "br", "strong", "b", "em", "i", "u", "s",
    "h1", "h2", "h3",
    "ul", "ol", "li",
    "blockquote", "a", "code", "pre", "hr",
  ],
  allowedAttributes: {
    a: ["href", "title"],
  },
  // No javascript: or data: URIs.
  allowedSchemes: ["http", "https", "mailto"],
  transformTags: {
    // Links open outside the mail client, and never leak the referrer.
    a: sanitizeHtml.simpleTransform("a", {
      target: "_blank",
      rel: "noopener noreferrer",
    }),
  },
};

export function sanitizeEmailHtml(html: string): string {
  return sanitizeHtml(html, SANITIZE_OPTIONS);
}

/**
 * Signs an unsubscribe link so it cannot be forged.
 *
 * Without the HMAC, `?uid=<someone-else>` would let anyone unsubscribe any user
 * — a link in an email is public by definition, so the uid alone proves nothing.
 */
export function unsubscribeToken(uid: string): string {
  return crypto
    .createHmac("sha256", UNSUBSCRIBE_SECRET)
    .update(uid)
    .digest("hex");
}

export function verifyUnsubscribeToken(uid: string, token: string): boolean {
  if (!UNSUBSCRIBE_SECRET || !token) return false;
  const expected = unsubscribeToken(uid);
  // Constant-time compare: a plain === leaks the token byte by byte via timing.
  const a = Buffer.from(expected);
  const b = Buffer.from(token);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

export function unsubscribeUrlFor(uid: string): string {
  if (!APP_URL || !UNSUBSCRIBE_SECRET) return "";
  return `${APP_URL}/unsubscribe?uid=${encodeURIComponent(
    uid
  )}&token=${unsubscribeToken(uid)}`;
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function toHtml(mail: Mail): string {
  // A rich body is sanitised; a plain one is escaped and paragraphed.
  const content = mail.html ?
    sanitizeEmailHtml(mail.html) :
    escapeHtml(mail.body)
      .split(/\n{2,}/)
      .map((p) => `<p style="margin:0 0 16px">${p.replace(/\n/g, "<br>")}</p>`)
      .join("");

  const footer = mail.unsubscribeUrl ?
    `<hr style="border:none;border-top:1px solid #e2e8f0;margin:28px 0 14px">
     <p style="margin:0;font-size:12px;color:#94a3b8">
       You are receiving this because you have an EduLinky account.
       <a href="${mail.unsubscribeUrl}" style="color:#0284c7">Unsubscribe</a>.
     </p>` :
    "";

  return `<!doctype html><html><body style="margin:0;background:#f0f9ff;padding:24px">
    <div style="max-width:560px;margin:0 auto;background:#fff;border-radius:16px;
                padding:28px;font:15px/1.6 -apple-system,BlinkMacSystemFont,
                'Segoe UI',system-ui,sans-serif;color:#0f172a">
      <div style="font-weight:800;font-size:18px;color:#0284c7;margin-bottom:20px">
        EduLinky
      </div>
      ${content}
      ${footer}
    </div>
  </body></html>`;
}

/**
 * Sends one email via Resend.
 *
 * Throws on failure — the caller decides whether that is fatal. For a bulk send
 * one bad address must not abort the run, so `sendBulk` catches per-recipient.
 */
export async function sendMail(mail: Mail): Promise<void> {
  if (!RESEND_API_KEY) {
    throw new Error(
      "RESEND_API_KEY is not configured (functions/.env)."
    );
  }

  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: MAIL_FROM,
      to: [mail.to],
      subject: mail.subject,
      ...(MAIL_REPLY_TO ? {reply_to: MAIL_REPLY_TO} : {}),
      text: mail.body + (mail.unsubscribeUrl ?
        `\n\n---\nUnsubscribe: ${mail.unsubscribeUrl}` :
        ""),
      html: toHtml(mail),
      // Lets Gmail/Apple Mail show a native unsubscribe button, and is expected
      // by spam filters for bulk mail.
      ...(mail.unsubscribeUrl ?
        {headers: {"List-Unsubscribe": `<${mail.unsubscribeUrl}>`}} :
        {}),
    }),
  });

  if (!res.ok) {
    const body = await res.text();
    logger.error("sendMail failed", {status: res.status, body});
    throw new Error(`Email provider rejected the message (${res.status}).`);
  }
}
