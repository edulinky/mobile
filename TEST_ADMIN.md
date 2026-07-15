# EduLinky Admin — Test Cases

Manual QA for the admin web app (`admin/`). PLAN.md is the *implementation* doc;
this is the *verification* doc. Companion to TEST_MOBILE.md.

**Legend:** ⬜ not tested · ✅ pass · ❌ fail (note the bug) · ⏭️ blocked/deferred

**Run:** `cd admin && npm run dev` → http://localhost:3001
**Sign in:** the account promoted with `scripts/make-admin.js`.

---

## Access control

> The UI hiding itself is a *convenience*, not a security boundary. Every admin
> action is a callable that re-checks `role === "admin"` on the ID token, and the
> Firestore rules gate `auditLog` on it too. Cases A.3/A.4 test the real gate.

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| A.1 | Admin signs in | Sign in with the admin account | Lands on Verifications | ⬜ |
| A.2 | Non-admin is refused | Sign in with a **student/teacher** account | "Not an admin" screen, no data, sign-out offered | ⬜ |
| A.3 | **Callables reject non-admins** | While signed in as a student, call `approveTeacher` directly | Rejected `permission-denied` — the server does not trust the UI | ⬜ |
| A.4 | Audit log is admin-only | Read `auditLog` from the mobile app / a non-admin client | **Denied** by rules | ⬜ |
| A.5 | Sign out | Click Sign out | Returns to the login form | ⬜ |
| A.6 | Fresh claim needed | Promote an account that is **already signed in** elsewhere | It is NOT admin until it signs out and back in (the role lives in the ID token) | ⬜ |

---

## Verifications

**Setup:** register a teacher in the app and upload a certificate at the
cert-upload step, so there is something real to review. (Seeded teachers have no
documents — "View documents" is correctly disabled for them.)

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| V.1 | Pending queue | Open Verifications | Every teacher with `verified_status: "pending"`, with name, email, city, document count | ⬜ |
| V.2 | **View documents** | Click "View documents" | Opens signed URLs to their certificates. Certificates are `allow read: if false` in Storage — this is the ONLY way to see them | ⬜ |
| V.3 | Links expire | Wait >15 min, reuse a document URL | **403 / expired** — the signed URL is short-lived by design | ⬜ |
| V.4 | Approve | Click Approve | Row leaves Pending; `verified_status: "approved"` in Firestore | ⬜ |
| V.5 | **Approval reaches the teacher** | Check the teacher's phone | Activity notification "You're verified" (+ push on a real device); their Discover tab now works | ⬜ |
| V.6 | Reject with a reason | Click Reject → type a reason → confirm | Modal is a **textarea**; confirm disabled while empty. `verified_status: "rejected"`, `rejection_reason` stored | ⬜ |
| V.7 | **Rejection reaches the teacher** | Check the teacher's phone | "Verification unsuccessful — you can submit a new one" | ⬜ |
| V.8 | Rejected teachers stay reachable | Rejected tab | They are listed, with the reason shown | ⬜ |
| V.9 | **Undo a mistaken rejection** | Rejected tab → Approve | Approved, and the teacher is notified. (Before this existed they were stranded unless they happened to re-submit) | ⬜ |
| V.10 | Revoke an approval | Approved tab → Reject | Back to rejected; they lose discovery access | ⬜ |
| V.11 | Re-submission returns them | Rejected teacher uploads new documents in the app | They reappear in **Pending** | ⬜ |
| V.12 | Empty state | No pending teachers | "Nothing to review. 🎉" | ⬜ |

---

## Users

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| U.1 | Role filter | Click Students / Teachers / Institutions / Admins | List filters; counts on each tab are correct | ⬜ |
| U.2 | Search | Type a name or email | Filters within the selected role | ⬜ |
| U.3 | Badges | Look at a pending / verified / rejected / banned user | Correct badge on each | ⬜ |
| U.4 | Feature | Click Feature on a teacher | `featured: true`; they now sort to the **front** of students' decks | ⬜ |
| U.5 | Unfeature | Click again | `featured: false` | ⬜ |
| U.6 | **Ban** | Ban a user with a reason | `is_banned: true`, `ban_reason` stored, auth account **disabled** | ⬜ |
| U.7 | **Ban kills the live session** | Ban a user who is signed in on a phone, then have them send a chat message | **Denied.** This is the whole point: an ID token stays valid up to an hour, so `is_banned` alone would let them keep messaging the person they were banned for harassing | ⬜ |
| U.8 | Banned user disappears | Check another user's deck | The banned user is no longer a candidate | ⬜ |
| U.9 | Unban | Click Unban | `is_banned: false`, auth account re-enabled, they can sign in again | ⬜ |
| U.10 | Admins cannot be banned | Look at an admin row | No Ban button; the callable also rejects it | ⬜ |
| U.11 | Cannot ban yourself | Force `banUser` with your own uid | Rejected `failed-precondition` | ⬜ |

---

## Email

**Prereq:** `RESEND_API_KEY` set; eduLinky.com verified in Resend.
**Note:** `MAIL_REPLY_TO` is currently empty — replies bounce until a mailbox exists.

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| E.1 | Email one user | Users → Email → subject + body → Send | Arrives from `EduLinky <noreply@edulinky.com>`, branded, **in the inbox not spam** | ⬜ |
| E.2 | Transactional has no unsubscribe | Look at that email | **No** unsubscribe link — it is about their account, not marketing | ⬜ |
| E.3 | **Recipient preview** | Email page → pick an audience | Shows the real recipient count **before** you can compose; "Compose" disabled at 0 | ⬜ |
| E.4 | Audience filter | Switch between Everyone / Students / Teachers / Institutions | Counts change accordingly | ⬜ |
| E.5 | Bulk send | Compose → Send | Reports `sent` / `failed`. **Send to test accounts only** | ⬜ |
| E.6 | **Bulk carries an unsubscribe link** | Open a bulk email | Footer has an Unsubscribe link; Gmail also shows its native unsubscribe button (List-Unsubscribe header) | ⬜ |
| E.7 | **Unsubscribe works** | Click the link | "You're unsubscribed" page; `email_opt_out: true` on that user | ⬜ |
| E.8 | Opt-out is honoured | Send a bulk email again | That user is **skipped**, and the skipped count goes up | ⬜ |
| E.9 | **Unsubscribe cannot be forged** | Edit the URL: keep the token, change `uid` to someone else | **"Invalid link"** — the token is an HMAC over the uid. Without this, anyone could unsubscribe anybody | ⬜ |
| E.10 | Banned users are skipped | Ban a user → bulk send | They receive nothing | ⬜ |
| E.11 | Admins are skipped | Bulk send | Admin accounts are not emailed | ⬜ |
| E.12 | Empty fields blocked | Try to send with a blank subject or body | Send button disabled; the callable also rejects it | ⬜ |

---

## Quotas

> Free-tier right swipes per rolling 24h. **One setting per role, not per user.**
> FR-3.1 fixes the student at 15 primary + 5 discovery; FR-3.2 leaves the teacher
> "to be defined by Admin" — this screen is that dial.

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| Q.1 | Shows what is enforced | Open **Quotas** | Teacher and Student rows with their **effective** values (the built-in defaults if nothing was ever saved) — not an empty form | ⬜ |
| Q.2 | Save | Set Teacher to 5 / 2 → Save | "Saved"; `config/quotas.teacher == {primary: 5, discovery: 2}` | ⬜ |
| Q.3 | **Takes effect immediately** | As a free teacher, swipe | The banner shows the new total, and the 6th primary swipe is refused — **no redeploy, no re-login** | ⬜ |
| Q.4 | Premium is unaffected | Set the quota to 0 → swipe as a premium user | Unlimited — premium skips the quota check entirely | ⬜ |
| Q.5 | Budgets stay separate | Spend all the discovery swipes | The primary-subject swipes are **still** available — one budget cannot eat the other | ⬜ |
| Q.6 | Passes are free | Left-swipe repeatedly at quota 0 | Never refused — only expressions of interest are metered | ⬜ |
| Q.7 | Garbage rejected | Save `-1`, `1.5`, or `99999` | Rejected `invalid-argument` (whole number, 0–1000) | ⬜ |
| Q.8 | Audited | Save a change | `set_quotas` in the audit log, with **before and after** — changing what every free user may do must be attributable | ⬜ |
| Q.9 | **Admin-only** | Call `setQuotas` as a teacher | Rejected `permission-denied` — a client that could write `config/quotas` would grant itself unlimited swipes | ⬜ |
| Q.10 | Config is unreadable to clients | Read `config/quotas` from the app | **Denied** by rules — the panel goes through `getQuotas` for exactly this reason | ⬜ |

---

## Admin alerts (email)

> Admins live in the **web panel**: no FCM token, and they never open the mobile
> inbox. Email is the only channel that actually reaches them, so every queue that
> needs a human sends one. All alerts are **best effort** — a failed email never
> fails the action that triggered it (`alertAdmins`).

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| N.1 | **Teacher signup** | A teacher submits certificates | Every admin gets `[Verification] <name> submitted documents`, with a link to the queue | ⬜ |
| N.2 | **New report** | A user reports someone | `[Report] <name> — <reason>`, with the details and the 24-hour SLA note | ⬜ |
| N.3 | **New review** | A student submits a review | `[Review] <teacher> — N★`, with the comment | ⬜ |
| N.4 | Edit pulls it back | A reviewer edits an **approved** review | A fresh alert — the review has left the profile and needs re-approving | ⬜ |
| N.5 | No spam on re-write | Nothing else changes on an already-pending review | **No** second alert (only the *transition* into pending alerts) | ⬜ |
| N.6 | Every admin is told | With two admin accounts | Both are emailed | ⬜ |
| N.7 | Link works | Click the link in any alert | Opens the right queue in the panel (`ADMIN_URL` — **currently `localhost:3001`; update it when the panel is deployed**) | ⬜ |
| N.8 | Failure is contained | (Code review) Resend down / a bad admin address | The teacher's submission, the report and the review still succeed — the row is in the queue either way | ⬜ |

---

## Reviews

> Reviews are the only user-written text published on a named person's public
> profile — permanent, and visible to everyone. They are held back until an admin
> releases them. Mobile side: **TEST_MOBILE.md § Phase 9**.

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| R.1 | Queue | A user submits a review → open **Reviews** | It is in **Pending**, oldest first, with stars, the comment, the teacher and the reviewer | ⬜ |
| R.2 | **Approve publishes it** | Approve | It moves to **Approved**, appears on the teacher's profile in the app, and their `avg_rating` / `total_reviews` update | ⬜ |
| R.3 | Average is recomputed, not overwritten | Approve a 4, then a 5, for the same teacher | `avg_rating: 4.5`, `total_reviews: 2` | ⬜ |
| R.4 | Reject needs a reason | Reject → leave the box empty | The confirm button stays disabled | ⬜ |
| R.5 | Reject | Reject with a reason | Moves to **Rejected**; the reviewer sees the reason in the app and can edit and resubmit | ⬜ |
| R.6 | **Rejecting a published review un-counts it** | Approve a review, then reject it | It leaves the teacher's profile and the rating/count drop back — the aggregate follows the status, always | ⬜ |
| R.7 | Console edits still work | Change a review's `status` by hand in the Firestore console | The rating still updates — the `onReviewWritten` trigger owns the aggregate, not the button | ⬜ |
| R.8 | Audited | Approve / reject | `approve_review` / `reject_review` in the audit log, with the reason | ⬜ |
| R.9 | Teacher is notified on approval only | Approve one, reject one | The teacher is notified about the approved one and **not** the rejected one — nobody needs "someone tried to one-star you" | ⬜ |

---

## Audit log

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| L.1 | Actions are recorded | Approve, reject, ban, feature, email, view documents, moderate a review | Each appears with actor, target, action, timestamp | ⬜ |
| L.2 | **Certificate views are audited** | View a teacher's documents | `view_certificates` entry — looking at someone's identity documents is itself an action worth recording | ⬜ |
| L.3 | Reasons are captured | Reject / ban with a reason | The reason is in the entry's details | ⬜ |
| L.4 | **Append-only** | Try to edit or delete an entry from any client | **Denied.** An audit log you can edit is not an audit log — including for the admin who wrote it | ⬜ |
