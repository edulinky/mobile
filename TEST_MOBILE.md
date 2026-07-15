# EduLink Mobile — Test Cases

Manual QA checklist for the Flutter app (`mobile/`), organized by implementation
phase. PLAN.md is the *implementation* doc (what/how); this is the *verification*
doc (what to test). Add a new section here whenever a phase lands.

**Legend:** ⬜ not tested · ✅ pass · ❌ fail (note the bug) · ⏭️ blocked/deferred

**Firebase console** (project `edulinky-86123`, account `edlinky001@gmail.com`):
- Auth users → Authentication → Users
- User docs → Firestore Database → `users` collection
- A user's role claim → Authentication → Users → (⋮) → not shown in UI; verify via
  the app landing on the correct role home, or the Admin SDK.

---

## Phase 1 — Infrastructure & Firebase wiring

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 1.1 | App boots against Firebase | `cd mobile && flutter run` | App launches to the splash screen, no Firebase init crash in logs | ⬜ |
| 1.2 | `health` function reachable | (covered once an authed screen calls it; for now) `firebase functions:log --only health --account edlinky001@gmail.com` after a call | Returns `{status:"ok", ...}` | ⬜ |

---

## Phase 2 — Auth & Role System

**Prerequisite:** deploy first —
`firebase deploy --only functions:completeRegistration,functions:setRole,firestore:rules --account edlinky001@gmail.com`

### Registration (happy path)

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 2.1 | Register **Student** | Splash → Get Started → step1 (name/email/pw/confirm) → step2 pick **Student** → step3 fill name/city/subject → Create account | Lands on `/student/discover`. Firebase: new Auth user + `users/{uid}` doc with `role:"student"`, `verified_status:"not_required"`, `sub_status:"free"` | ⬜ |
| 2.2 | Register **Teacher** | Same, pick **Teacher** at step2 | Lands on `/cert-upload` → can reach `/pending`. Doc has `role:"teacher"`, `verified_status:"pending"` | ⬜ |
| 2.3 | Register **Institution** | Same, pick **Institution** | Lands on `/institution/paywall`. Doc has `role:"institution"` | ⬜ |
| 2.4 | Doc field sanity | Inspect any `users/{uid}` after register | Contains: `uid, role, email, display_name, primary_subject, geo_location{lat,lng,geohash,city,place_id}, sub_status, verified_status, is_banned:false, avg_rating:0, total_reviews:0, featured:false, created_at` | ⬜ |

### City picker — Places API (New) via App-Check proxy (register step-3)

**Prereqs:** deploy `placesAutocomplete`+`placeDetails`; App Check registered for the iOS app; the launch's **debug token** added in Firebase console → App Check → Manage debug tokens (per simulator). Key restriction: Application **None** + API **Places API (New)**. Run plainly: `flutter run -d <deviceId>` (no `--dart-define`).

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 2.G1 | Open picker | step3 → tap the City field | Full-screen "Select your city" search opens, keyboard focused | ⬜ |
| 2.G2 | Autocomplete | Type ≥2 chars of a city (e.g. "Lond") | Debounced city suggestions appear (city-level only, no street addresses) | ⬜ |
| 2.G3 | Select | Tap a suggestion | Returns to step3; City field shows the chosen city (e.g. "London, United Kingdom") | ⬜ |
| 2.G4 | Mandatory | Leave city empty → Create account | Blocked with snackbar "Please select your city." | ⬜ |
| 2.G5 | Geo stored | Complete registration with a city | `users/{uid}.geo_location` has `{lat, lng, geohash, city, place_id}` in Firestore | ⬜ |
| 2.G6 | App Check enforced | Call from an app without a registered App Check token | Rejected (permission-denied) — confirms only the attested app can reach the proxy | ⬜ |
| 2.G7 | Cold start tolerated | After an idle period, type a city | Suggestions still arrive; the *first* search may lag ~1–3s (function scales to zero — accepted for now). Subsequent searches are fast | ⬜ |

### Photo cropper (register step-3 avatar) — pure-Dart, no upload yet

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 2.C1 | Open cropper | step3 → tap avatar circle → pick a photo | Full-screen "Adjust photo" cropper opens with a fixed circular frame | ⬜ |
| 2.C2 | Reposition | Drag the image around inside the frame | Image pans L/R/U/D; the circular frame stays fixed | ⬜ |
| 2.C3 | Zoom | Pinch to zoom in/out | Image scales under the fixed frame | ⬜ |
| 2.C4 | Confirm | Tap **Done** | Returns to step3; avatar circle shows the cropped result | ⬜ |
| 2.C5 | Cancel | Reopen cropper → tap ✕ | Returns to step3 with the previous avatar unchanged | ⬜ |

---

## Phase 3 — Profile System

### Avatar & certificate upload (Storage)

**Prereq:** deploy `storage` rules + `submitCertification`.

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 3.1 | Avatar uploads | Register with a cropped photo | Storage has `avatars/{uid}/profile.jpg`; `users/{uid}.photo_url` holds its download URL | ⬜ |
| 3.2 | Avatar optional | Register without picking a photo | Registration succeeds; no `photo_url` field | ⬜ |
| 3.3 | Upload failure is non-fatal | (force by killing network right after account creation) | Snackbar "account is ready, but the photo could not be uploaded"; user still lands on their role home, account intact | ⬜ |
| 3.4 | Teacher cert submits | Register as teacher → cert-upload → pick file(s) → Submit for review | Storage has `certs/{uid}/…`; `users/{uid}` gains `cert_paths` (array) + `cert_submitted_at`, `verified_status:"pending"`; lands on `/pending` | ⬜ |
| 3.4a | **Multiple files** | Select 3 documents at once (or add them one at a time) | All 3 listed with name + size; all 3 upload; `cert_paths` has 3 entries | ⬜ |
| 3.4b | **PDF accepted** | Select a `.pdf` certificate | Uploads (contentType `application/pdf`) — this is the common case and `image_picker` could not do it | ⬜ |
| 3.4c | Remove before submit | Add 3 files → tap ✕ on one → Submit | Only the remaining 2 upload | ⬜ |
| 3.4d | Max 5 | Try to add a 6th document | Blocked with "You can upload at most 5 documents."; server also rejects >5 | ⬜ |
| 3.4e | Oversize skipped | Select a file >10 MB | Skipped with a snackbar naming it; others still added; Storage rules also reject it | ⬜ |
| 3.5 | Cert is unreadable by clients | Try to read `certs/{uid}/…` via the client SDK (even as its owner) | **Denied** — certs are write-only from the app | ⬜ |
| 3.6 | Cert path can't be forged | Call `submitCertification` with any `certPaths` entry under **another** uid | Rejected `invalid-argument` — **every** path is checked, not just the first | ⬜ |
| 3.7 | Non-teacher blocked | Call `submitCertification` as a student | Rejected `permission-denied` | ⬜ |
| 3.8 | Oversize/non-image rejected | Attempt an avatar >5 MB or a non-image | Denied by Storage rules | ⬜ |

### Profile edit — live Firestore (student + teacher Bio tab)

**Prereq:** deploy `functions:updateLocation` + `firestore:rules`.

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 3.9 | Loads real data | Sign in → Profile tab | Shows *your* name / about / subjects / city / photo from Firestore — **not** "Alex Thompson" or "Sarah Johnson" mock data | ⬜ |
| 3.10 | Empty profile | A user who registered without an about/subjects | Fields render empty (no crash), avatar shows the camera placeholder | ⬜ |
| 3.11 | Save name & about | Edit both → Save changes | Green "Saved" banner; `users/{uid}.display_name` + `.about` updated in Firestore | ⬜ |
| 3.12 | Save subjects | Toggle subject chips → Save | `users/{uid}.subjects` array matches the selected chips | ⬜ |
| 3.12a | **Add a custom subject** | Tap **+ Add subject** → type e.g. "Mandarin" → Add → Save | New chip appears **selected**; `subjects` contains "Mandarin" | ⬜ |
| 3.12b | Custom subject persists | Restart the app → Profile | The custom chip is still shown, alongside the presets | ⬜ |
| 3.12c | Deselect a custom subject | Tap the custom chip to deselect → Save | Removed from `subjects` (and it drops out of the chip list) | ⬜ |
| 3.12d | Duplicate is not created | Add "mathematics" (lowercase) when Mathematics is a preset | Selects the existing preset — no near-duplicate chip | ⬜ |
| 3.12e | Cap | Select 15 subjects, then try to add another | Blocked with "You can select up to 15 subjects." | ⬜ |
| 3.13 | Persists across restart | Save → kill app → reopen → Profile | Edited values are still shown (read from Firestore, not local state) | ⬜ |
| 3.14 | Change avatar | Tap avatar → pick → crop → Done → Save | New photo replaces `avatars/{uid}/profile.jpg`; `photo_url` updated; avatar shows the new image after save | ⬜ |
| 3.15 | Change city | Tap the City field → pick a new city | Saves **immediately** (no Save press needed); `geo_location` gains new `lat`/`lng`/**`geohash`**/`city` | ⬜ |
| 3.16 | Teacher hourly rate | Teacher → Bio tab → set rate → Save | `users/{uid}.hourly_rate` stored as a number | ⬜ |
### Teacher tabs — Gallery / Qualifications / Experience / Schedule / Videos

**Prereq:** deploy `functions:addGalleryPhoto,functions:removeGalleryPhoto,functions:setVideoLinks` + `firestore:rules` + `storage`.

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 3.21 | Gallery add | Gallery tab → tap an empty tile → pick → crop → Done | Photo appears in the grid; Storage has `gallery/{uid}/…`; `users/{uid}.gallery` array gains that **path** (not a URL) | ⬜ |
| 3.22 | Gallery persists | Kill app → reopen → Gallery tab | The photos are still there (loaded from the paths, resolved to URLs at render) | ⬜ |
| 3.23 | Gallery remove | Tap the ✕ on a photo | Disappears from the grid; removed from the `gallery` array **and** deleted from Storage | ⬜ |
| 3.24 | Gallery cap = 6 | Add a 7th photo | Blocked — only 6 tiles, and the server rejects a 7th with `failed-precondition` | ⬜ |
| 3.25 | Qualifications | Add/edit/delete rows → Save changes | "Saved" banner; `users/{uid}.qualifications` = the non-empty rows, in order | ⬜ |
| 3.26 | Experience | Fill title/institution/from/to → Save | `users/{uid}.experience` = array of `{title, institution, from, to}`; blank cards are dropped | ⬜ |
| 3.27 | Schedule | Toggle day×slot cells → Save | `users/{uid}.availability` = `{Mon: [Morning, ...], ...}`; cleared days disappear from the map | ⬜ |
| 3.28 | Schedule reload | Kill app → reopen → Schedule | The same cells are still highlighted | ⬜ |
| 3.29 | Videos (valid) | Paste a `https://youtube.com/watch?v=…` or Vimeo link → Save | "Saved"; `users/{uid}.video_links` holds the link | ⬜ |
| 3.30 | Videos (rejected) | Paste `https://evil.example.com/x` → Save | **Rejected** with "Only https YouTube or Vimeo links are allowed" — the link is never stored | ⬜ |
| 3.31 | Videos cap = 4 | Try to add a 5th | The "add" button is hidden at 4; the server also rejects >4 | ⬜ |

### Public profile view (`/teacher/:uid/profile`)

> The student discover deck is still **mock** until Phase 4, so tapping a card there opens "This profile is not available" (case 3.39). To test 3.34–3.38 now, navigate directly with a **real** teacher uid from Firestore.

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 3.34 | Renders a real teacher | Open `/teacher/<real-uid>/profile` | Shows that teacher's photo, name, city, rating, subjects, about — all from Firestore | ⬜ |
| 3.35 | Badges | View a teacher with `verified_status: approved` / `pending` / `featured: true` | Shows **Verified** / **Pending** / **Featured** chip respectively | ⬜ |
| 3.36 | Rate with currency | A teacher with an `hourly_rate` | Shows e.g. `$25/hr` — symbol from the profile's `currency`, not a literal | ⬜ |
| 3.37 | Rich sections | A teacher with gallery/qualifications/experience/availability filled | Each section renders; **empty sections are hidden entirely** (no blank headers) | ⬜ |
| 3.38 | Reviews empty state | Any teacher (no reviews exist yet) | "No reviews yet" — **not** invented review cards | ⬜ |
| 3.39 | Unknown uid | Open `/teacher/does-not-exist/profile` | "This profile is not available." with a back button — no crash | ⬜ |
| 3.40 | **Gallery opens full screen** | Tap any gallery thumbnail | Full-screen viewer opens **on the photo you tapped** (not photo 1) | ⬜ |
| 3.41 | **Swipe through** | Swipe left/right in the viewer | Moves through the gallery; the counter reads `2 / 5`; pinch zooms; ✕ closes | ⬜ |
| 3.42 | **Intro videos render** | A teacher with `video_links` set | An **Intro videos** section — YouTube links show a real thumbnail, Vimeo a placeholder tile, both with a play button | ⬜ |
| 3.43 | Video opens | Tap a video | Opens in the YouTube/Vimeo app or the browser (not a blank in-app WebView) | ⬜ |
| 3.44 | No videos → no section | A teacher with no videos | The section is hidden entirely — no empty header | ⬜ |

### Security (Phase 3 invariants)

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 3.32 | Can't inject a foreign gallery image | Call `addGalleryPhoto` with a path under **another** uid, or a remote URL | Rejected `invalid-argument` — gallery entries must be Storage paths in your own folder | ⬜ |
| 3.33 | Can't write gallery/video_links directly | Client write to own `users/{uid}.gallery` or `.video_links` | **Denied** by rules — they must go through the validating callables | ⬜ |

### Security (Phase 3 invariants)

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 3.18 | Can't fake location | Client write to own `users/{uid}.geo_location` (rules simulator) | **Denied** — geohash must be derived server-side by `updateLocation`, else a user could appear in a city they aren't in | ⬜ |
| 3.19 | Can't forge cert_path | Client write to own `users/{uid}.cert_path` | **Denied** — only `submitCertification` sets it | ⬜ |
| 3.20 | Editable fields still work | Client write to own `display_name`/`about`/`subjects`/`photo_url`/`hourly_rate` | **Allowed** (these are the genuinely user-owned fields) | ⬜ |

### Registration (validation & errors)

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 2.5 | Empty fields | step1 with blanks → Next | Snackbar "Please fill in your name, email, and password." (no advance) | ⬜ |
| 2.6 | Bad email | step1 email = `foo` → Next | Snackbar "Please enter a valid email address." | ⬜ |
| 2.7 | Short password | password `123` → Next | Snackbar "Password must be at least 6 characters." | ⬜ |
| 2.8 | Password mismatch | confirm ≠ password → Next | Snackbar "Passwords do not match." | ⬜ |
| 2.9 | Duplicate email | Register with an email that already exists | Snackbar with Firebase error (email already in use); **no** partial doc left behind | ⬜ |
| 2.10 | Rollback on failure | (hard to force manually) if `completeRegistration` fails after account creation | Account is deleted, snackbar "Could not finish setting up your account…", can retry | ⏭️ |

### Login

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 2.11 | Sign in (correct) | Log out → `/login` → correct email/pw → Sign in | Lands on the role's home screen | ⬜ |
| 2.12 | Sign in (wrong pw) | Wrong password | Snackbar with error, stays on login | ⬜ |
| 2.13 | Empty login | Blank fields → Sign in | Snackbar "Please enter your email and password." | ⬜ |
| 2.14 | Forgot password | Enter email → "Forgot password" | Snackbar "Password reset email sent to …"; reset email arrives | ⬜ |
| 2.15 | Forgot password (no email) | Tap "Forgot password" with empty email | Snackbar prompting to enter email first | ⬜ |
| 2.16 | Google button | Tap "Continue with Google" | Snackbar "Google sign-in is coming soon." (deferred to Phase 2.5) | ⬜ |

### Session & route guards

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 2.17 | Persist across restart | Sign in → fully close app → reopen | Skips splash/login, lands on role home (session persisted) | ⬜ |
| 2.18 | Sign out | From settings, sign out | Returns to splash `/`; cannot reach role screens | ⬜ |
| 2.19 | Guard: unauth deep link | While signed out, attempt to reach any role route (e.g. `/student/discover`) | Redirects back to `/` | ⬜ |
| 2.20 | Guard: entry bounce | While signed in, manually navigate to `/login` or `/` | Bounced to role home | ⬜ |

### Security (must-hold invariants)

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 2.21 | No self-elevation | As a signed-in student, attempt a client write setting `role:"admin"` on own `users/{uid}` (Firestore console rules simulator or a scratch call) | **Denied** by rules | ⬜ |
| 2.22 | Server-field lock | Attempt client update changing `verified_status`/`sub_status`/`is_banned` on own doc | **Denied** by rules | ⬜ |
| 2.23 | Re-register blocked | Call `completeRegistration` again for an already-registered user | Fails `already-exists` (role not reassigned) | ⬜ |
| 2.24 | Other users' docs | Read is allowed for any signed-in user; writing another uid's doc | Read OK; write **denied** | ⬜ |

---

---

## Phase 4 — Discovery / Swipe Engine

**Prereq:** `firebase deploy --only functions:getCandidates,functions:recordSwipe,functions:getSwipeQuota,firestore:rules,firestore:indexes --account edlinky001@gmail.com`
**Index:** the `users` composite index must finish building before discovery returns anything — check Firestore → Indexes.
**Fixture:** you need at least 2 **approved** teachers and 2 students with cities set. A teacher is only discoverable once `verified_status == "approved"` — set it by hand in the console until the admin panel exists (Phase 8).

### Candidates

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 4.1 | Student sees teachers | Sign in as a student → Discover | Real teacher cards (name/photo/subjects/distance from Firestore) — no "Sarah Johnson" | ⬜ |
| 4.2 | Teacher sees students | Sign in as a teacher → Discover → **Students** tab | Real student cards | ⬜ |
| 4.3 | Unapproved teachers hidden | Set a teacher to `verified_status: "pending"` | That teacher does **not** appear in any student's deck | ⬜ |
| 4.4 | Banned users hidden | Set a user `is_banned: true` | Never appears as a candidate | ⬜ |
| 4.5 | Never see yourself | Any deck | Your own profile is never a card | ⬜ |
| 4.6 | Distance is real | Compare a card's "km away" to the two cities | Roughly correct (great-circle distance) | ⬜ |
| 4.7 | Featured first | Set a teacher `featured: true` | They sort to the front of the deck | ⬜ |
| 4.7a | **Likers come first** | Student right-swipes Teacher. Then open the **Teacher's** deck | That student is **card #1** — a pending like is one swipe from a match, so it leads the deck | ⬜ |
| 4.7b | Ranking precedence | A liker who is far away vs. a featured profile nearby | The **liker** wins (liked-me → featured → nearest) | ⬜ |
| 4.7c | **No leak** | Inspect the `getCandidates` response payload | **No `likedMe` field** — it is stripped server-side. The card shows no badge; the viewer cannot tell why it came first | ⬜ |
| 4.7d | Client can't ask who liked them | From the client, run `collectionGroup('sent').where('target_id','==',myUid)` | **Denied** — no collection-group rule exists on `sent`, deliberately | ⬜ |
| 4.8 | No city set | A user with no `geo_location` opens Discover | Clean error, "Set your city before discovering" — no crash | ⬜ |
| 4.9 | Already-swiped never resurface | Swipe someone → reopen Discover / restart the app | They do **not** come back | ⬜ |
| 4.10 | Background top-up | Swipe until ≤3 cards remain | More cards are fetched with no spinner and no interruption | ⬜ |

### Quota (free student: 15 primary + 5 discovery per 24h)

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 4.11 | Banner shows real remaining | Open Discover | Banner = actual remaining right-swipes, decrements on each **right** swipe | ⬜ |
| 4.12 | Left swipes are free | Swipe left several times | Banner does **not** move — only interest is metered | ⬜ |
| 4.13 | Primary bucket | Right-swipe a teacher who teaches your `primary_subject` | `swipeQuotas/{uid}.primary_used` increments (not `discovery_used`) | ⬜ |
| 4.14 | Discovery bucket | Right-swipe a teacher who does **not** teach your primary subject | `discovery_used` increments | ⬜ |
| 4.15 | Buckets are separate | Exhaust all 5 discovery swipes | You can **still** right-swipe primary-subject teachers (15 intact) | ⬜ |
| 4.16 | Limit enforced | Exhaust a bucket → right-swipe again | Rejected `resource-exhausted`; snackbar shown; **the card comes back** (not silently consumed) | ⬜ |
| 4.17 | 24h reset | Set `window_start` >24h in the past → swipe | Counters reset to 0 and the swipe succeeds | ⬜ |
| 4.18 | Premium unlimited | Set `sub_status: "premium"` → Discover | No banner; unlimited right-swipes | ⬜ |
| 4.19 | **Race safety** | Double-tap the like button rapidly at your limit boundary | Never exceeds the limit — the transaction serializes it | ⬜ |
| 4.20 | Re-swipe is a no-op | Force `recordSwipe` twice for the same target | Second returns `alreadySwiped`, quota charged **once** | ⬜ |

### Match

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 4.21 | Mutual like → match | Student right-swipes Teacher (sim A); Teacher right-swipes that Student (sim B) | Match overlay appears on the **second** swipe; `matches/{a_b}` created with both `participants` | ⬜ |
| 4.22 | One-sided ≠ match | Only one side right-swipes | **No** match doc, no overlay | ⬜ |
| 4.23 | Deterministic id | Inspect the match doc | `matchId == [uidA, uidB].sort().join("_")` — same from either direction, never two docs for one pair | ⬜ |
| 4.24 | Overlay → chat | Tap "Send message" on the overlay | Opens chat carrying the **real** matchId | ⬜ |

### Security (Phase 4 invariants)

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 4.25 | Can't write own swipe | Client write to `swipes/{me}/sent/{someone}` | **Denied** — else the quota transaction is bypassed entirely | ⬜ |
| 4.26 | Can't forge a match | Client write to `swipes/{otherUid}/sent/{me}` (faking *their* like) or directly to `matches/` | **Denied** — otherwise you could manufacture a match with someone who never swiped on you | ⬜ |
| 4.27 | Can't edit own quota | Client write to `swipeQuotas/{me}` | **Denied** | ⬜ |
| 4.28 | Matches are private | Read `matches/{id}` you are not a participant in | **Denied** — a match is the gate that unlocks chat | ⬜ |
| 4.29 | Config locked | Read/write `config/quotas` from the client | **Denied** (server-only) | ⬜ |

---

## Phase 5 — Matching & Messaging

**Prereq:** `firebase deploy --only functions:onNewMessage,functions:markMatchRead,firestore:rules --account edlinky001@gmail.com`
**Setup:** you need a real match — student right-swipes teacher (sim A), teacher right-swipes that student (sim B).

### Matches list

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 5.1 | New match appears | Complete a mutual swipe | Both users see the other in **NEW MATCHES** (avatar row) — no mock "Sarah/James/Aisha" | ⬜ |
| 5.2 | Empty state | A user with no matches | "No matches yet — keep swiping…" | ⬜ |
| 5.3 | Moves to Messages | Send the first message | The match moves out of NEW MATCHES into the **MESSAGES** list, showing the last message | ⬜ |
| 5.4 | Ordering | Have two matches; message the older one | It jumps to the top (ordered by `last_message_at`) | ⬜ |
| 5.5 | Unread badge | A sends a message; check B's match list | B shows an unread count badge; `matches/{id}.unread.{B}` increments | ⬜ |
| 5.6 | Badge clears | B opens the thread | Badge disappears; `unread.{B}` back to 0 (via `markMatchRead`) | ⬜ |

### Chat

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 5.7 | Real-time delivery | Both sims in the same thread; A sends | Message appears on **B within a second**, no refresh | ⬜ |
| 5.8 | Optimistic send | A sends | A's bubble appears **instantly** (Firestore local cache), before the server acks | ⬜ |
| 5.9 | Persists | Kill and reopen the app → thread | The history is still there (loaded from Firestore, not memory) | ⬜ |
| 5.10 | Empty thread | Open a brand-new match | "You matched! Say hello." — **no fake typing indicator, no canned auto-reply** | ⬜ |
| 5.11 | Send failure | Turn off the network → send | Snackbar, and **the text is restored to the input** (not lost) | ⬜ |
| 5.12 | Own vs other | Look at both sides | Own messages right-aligned/blue; received left/white — from `sender_id`, not position | ⬜ |

### Push (FCM)

> Simulators cannot receive real APNs pushes. Test on a **physical device**, or verify server-side that `onNewMessage` ran and `fcm_tokens` is populated.

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 5.13 | Token saved | Sign in | `users/{uid}.fcm_tokens` contains a token | ⬜ |
| 5.14 | Push on message | A messages B while B is backgrounded (real device) | B gets a notification titled with A's name, body = the message (truncated at 120 chars) | ⬜ |
| 5.15 | Token removed on sign-out | Sign out | That device's token is **removed** from `fcm_tokens` — the next user of the phone must not get the previous user's messages | ⬜ |
| 5.16 | Dead tokens pruned | Uninstall the app, then message that user | The stale token is removed from `fcm_tokens` after the failed send | ⬜ |

### Security (Phase 5 invariants)

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 5.17 | **No chat without a match** | Read/write `matches/{someId}/messages` for a match you're not in | **Denied** — the match is the consent record that gates chat | ⬜ |
| 5.18 | Can't forge a sender | Write a message with `sender_id` = the other person | **Denied** — you can only send as yourself | ⬜ |
| 5.19 | History is immutable | Try to edit or delete a message you sent | **Denied** — nobody rewrites what was said | ⬜ |
| 5.20 | **Banned user can't message** | Set `is_banned: true` on a user with a live session → they send | **Denied** — the rule re-reads `is_banned` on every send, because their ID token stays valid for up to an hour after the ban | ⬜ |
| 5.21 | Can't fake activity | Client write to `matches/{id}.last_message` or `.unread` | **Denied** — server-owned; else you could float yourself to the top of someone's list or clear their badge | ⬜ |
| 5.22 | Oversized message | Send >2000 chars | **Denied** by rules | ⬜ |

---

## Phase 5.5 — In-app Activity / Notifications

**Prereq:** deploy `functions` + `firestore:rules` + `firestore:indexes` (a new composite index on `items` must finish building).

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 5.23 | Alerts tab exists | Sign in as student, then teacher | A new **Activity** tab (bell) sits second in the bottom nav for both | ⬜ |
| 5.24 | Empty state | New account → Activity | "Nothing here yet" | ⬜ |
| 5.25 | Match notifies **both** | Complete a mutual swipe | **Both** users get an "It's a match!" item naming the other person | ⬜ |
| 5.26 | Message notifies recipient | A messages B | B gets an item titled with A's name; **A does not** | ⬜ |
| 5.27 | Unread badge | Receive a notification | Red badge with the count on the Activity nav icon; unread rows are tinted | ⬜ |
| 5.28 | Badge clears | Open Activity | Badge disappears; rows go white (all marked read) | ⬜ |
| 5.29 | **Verification approved** | Set a teacher's `verified_status` to `"approved"` in the console | Teacher gets "You're verified — you can now discover students" (push + inbox). **This previously had no surface at all** | ⬜ |
| 5.30 | **Verification rejected** | Set it to `"rejected"` | Teacher gets "Verification unsuccessful — you can submit a new one" | ⬜ |
| 5.31 | Dismiss | Swipe a notification left | It's deleted and does not come back | ⬜ |
| 5.32 | Tap a match/message | Tap the item | Opens the Matches list | ⬜ |

### Security (Phase 5.5 invariants)

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 5.33 | Can't fabricate a notification | Client write to `notifications/{me}/items` | **Denied** — else anyone could fake "you're verified" or "you matched with X" | ⬜ |
| 5.34 | Can't read another's inbox | Read `notifications/{otherUid}/items` | **Denied** | ⬜ |
| 5.35 | Owner may only flip `read` | Client update changing `title` or `type` on own item | **Denied**; changing only `read` is **allowed** | ⬜ |

---

## Phase 6 — Job Cards

**Prereq:** deploy functions + rules + indexes (four new indexes must finish building).
**Setup:** an **institution** account (register one, or use the seed script), plus an **approved** teacher.

### Institution

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 6.1 | Empty dashboard | New institution → Dashboard | "No job cards yet" — no mock listings | ⬜ |
| 6.2 | Post a job | Tap **Post a job** → fill title/subject/description/salary/contract → Post | Card appears on the dashboard; `jobCards/{id}` created with `inst_id` = you, `status: "active"` | ⬜ |
| 6.3 | **No location field** | Look at the create form | There is none — the card inherits your institution's verified city (shown as a note). The geohash is derived from it server-side | ⬜ |
| 6.4 | Salary carries currency | Enter 1200–1800 | Shows `$1,200 – $1,800`; `currency` stored on the card | ⬜ |
| 6.5 | Edit | Open a card → Edit → change the title → Save | Updated in place, no duplicate card | ⬜ |
| 6.6 | Close | Open a card → **Close** | `status: "closed"`; the card **disappears from every teacher's deck** | ⬜ |
| 6.7 | Reopen | **Reopen** | Back to `active`, visible to teachers again | ⬜ |
| 6.8 | No city set | An institution with no `geo_location` posts a job | Rejected: "Set your institution's city before posting a job" | ⬜ |

### Teacher

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 6.9 | Jobs deck is live | Teacher → Discover → **Jobs** tab | Real job cards from nearby institutions — no "Lekki, Lagos" mock | ⬜ |
| 6.10 | **Apply = right swipe** | Right-swipe a job card | "Applied to X at Y" snackbar; card leaves the deck; `applications/{jobId}_{uid}` created | ⬜ |
| 6.11 | **No match is created** | Check `matches/` after applying | **No match doc.** A job application is one-directional — the spec's only such flow | ⬜ |
| 6.12 | Institution notified immediately | Check the institution's Activity | "New application — X applied to *title*" (inbox + push), with **no** action needed from the teacher's side | ⬜ |
| 6.13 | Pass a job | Left-swipe | Card leaves; **no** application; institution not notified | ⬜ |
| 6.14 | Applied jobs don't resurface | Reopen the Jobs tab | Jobs you applied to are gone | ⬜ |
| 6.15 | Apply twice is a no-op | Force `applyToJob` twice for the same job | Second returns `alreadyApplied`; `applicant_count` incremented **once** | ⬜ |
| 6.16 | Unapproved teacher blocked | A `pending` teacher opens Jobs | "Verification pending" — cannot see or apply to jobs either | ⬜ |
| 6.17 | Closed jobs hidden | Institution closes a card | It vanishes from the teacher's deck | ⬜ |
| 6.17b | **Empty deck says the right thing** | Swipe through every job | "No more jobs right now" + why the deck is subject-filtered — **not** the Students copy ("check back tomorrow for new matches"): a job is not a person and there is no match to wait for | ⬜ |
| 6.17c | **Start over** | Tap Start over on the empty Jobs deck | The jobs you **skipped** come back | ⬜ |
| 6.17d | Applications stay gone | Start over after applying to one | The applied job does **not** come back — it is already with the institution | ⬜ |
| 6.17e | **Only my subjects** | Teacher teaches *Mandarin*; institutions post *Mandarin* and *English* jobs | Only the **Mandarin** card is in the deck | ⬜ |
| 6.17f | Case/spacing doesn't matter | Teacher: `mathematics`; job card: `Mathematics ` | The card **is** shown — subjects are compared canonicalized, or a card is invisible to exactly the teacher it was posted for | ⬜ |
| 6.17f2 | **Aliases match** | Teacher: `Maths`; job card: `Mathematics` (also try `ICT` vs `Computer Science`, `Chinese` vs `Mandarin`) | The card **is** shown — `canonicalSubject()` maps the common spellings onto one | ⬜ |
| 6.17f3 | Aliases don't over-match | Teacher: `French`; job card: `German` | The card is **not** shown — this is an alias table, not fuzzy distance; near-spellings must not bleed into each other | ⬜ |
| 6.17f4 | **Subject dropdown on the job form** | Institution → Post a job → Subject | A dropdown of the preset subjects **plus "Other (type your own)"**; picking Other reveals a text field | ⬜ |
| 6.17f5 | Editing keeps the choice | Edit a card saved as `Mathematics` | The dropdown lands on **Mathematics**, not Other | ⬜ |
| 6.17f6 | Custom subject survives | Post a card with Other → `IELTS`; reopen it | The dropdown shows **Other** with `IELTS` in the field | ⬜ |
| 6.17g | No subjects set → see everything | A teacher with an empty Subjects list | All nearby jobs — an empty deck with no explanation reads as "there are no jobs", not "tell us what you teach" | ⬜ |
| 6.17h | **Edit my subjects** | Empty deck → Edit my subjects → add a subject → back | The profile opens, and the deck **reloads** on return with the newly-matching jobs | ⬜ |

### Applicants

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 6.18 | Applicant list | Institution → open the job card | The teacher who applied is listed with name + photo; `applicant_count` matches | ⬜ |
| 6.19 | Tap through | Tap an applicant | Opens that teacher's public profile | ⬜ |

### Security (Phase 6 invariants)

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 6.20 | Can't write a job card directly | Client write to `jobCards/{id}` | **Denied** — else `inst_id`, `status`, `applicant_count` and the geohash are all forgeable | ⬜ |
| 6.21 | Can't edit someone else's card | Call `upsertJobCard` with another institution's `jobId` | Rejected `permission-denied` | ⬜ |
| 6.22 | Can't fake a location | (implicit) A job's geohash always comes from the institution's own city | A card can never claim to be in a city the institution isn't in | ⬜ |
| 6.23 | **Applications are confidential** | Read `applications/{id}` as a third party | **Denied** — only the applicant and the institution may see who applied | ⬜ |
| 6.24 | Non-teacher can't apply | Call `applyToJob` as a student | Rejected `permission-denied` | ⬜ |
| 6.25 | Can't inflate applicant count | Client write to `jobCards/{id}.applicant_count` | **Denied** | ⬜ |

---

## Phase 7 — Premium (Student & Teacher)

**Prereq:** RevenueCat products + entitlement `premium` + webhook configured, and
`REVENUECAT_IOS_KEY` in `dart_defines.json`. Buy with an **App Store sandbox
account** — never a real card. Without the keys the paywall correctly says
"Subscriptions aren't available right now".

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 7.1 | Paywall opens | Settings → Upgrade to Premium | The paywall, with the **four real plans and store prices** — not hard-coded `$4.99` | ⬜ |
| 7.2 | Prices are the store's | Change a price in App Store Connect | The app shows the new price with **no app release** | ⬜ |
| 7.3 | Teacher sees the badge perk | Open the paywall as a teacher | "Featured badge" is listed; a student does **not** see it | ⬜ |
| 7.4 | **Purchase** | Buy any plan (sandbox) | Payment sheet → success; `users/{uid}.sub_status == "premium"`; webhook logged | ⬜ |
| 7.5 | **Quota disappears** | Swipe after buying | No swipe limit; the quota banner is gone — `recordSwipe` skips the check | ⬜ |
| 7.6 | **Teacher gets Featured** | Buy as a teacher | `featured: true` on the user doc; the Featured card in Settings shows **active** — no admin involved | ⬜ |
| 7.7 | Cancelling is not cancelled | Tap Cancel on the payment sheet | Returns quietly to the paywall — **no error snackbar**; the user just changed their mind | ⬜ |
| 7.8 | **Restore** | Delete + reinstall → Restore purchases | Premium comes back without paying again (**Apple rejects apps without this**) | ⬜ |
| 7.9 | Nothing to restore | Restore on a fresh account | "No previous purchase found" — not an error | ⬜ |
| 7.10 | Manage/cancel is findable | Settings as a premium user | Says the subscription is managed in the store's account settings — **an app cannot cancel it**, and a user who can't find "cancel" charges back | ⬜ |
| 7.11 | Terms are stated | The paywall | Renewal terms in words + Terms and Privacy links (Guideline 3.1.2) | ⬜ |
| 7.12 | **Purchase follows the account** | Buy on account A, sign out, sign in as B | B is **not** premium — `Purchases.logOut()` on sign-out; the next person on the phone must not inherit a subscription | ⬜ |
| 7.13 | Cancellation keeps access | Cancel in the store settings | **Still premium until the period ends** (`CANCELLATION` means auto-renew off, not access off) — only `EXPIRATION` downgrades | ⬜ |
| 7.14 | **Expiry downgrades** | Let a sandbox subscription expire | `sub_status: "free"`, quota back, and a teacher's `featured` **removed** — a sub you can cancel while keeping the perks is one nobody renews | ⬜ |
| 7.15 | No keys → no crash | Run without `REVENUECAT_IOS_KEY` | App works; the paywall says subscriptions are unavailable | ⬜ |

### Security (Phase 7 invariants)

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 7.20 | **Client cannot self-promote** | Client write `sub_status: "premium"` on your own user doc | **Denied** by rules — otherwise unlimited swipes are free | ⬜ |
| 7.21 | **Webhook rejects strangers** | POST to the webhook URL with no/wrong `Authorization` | **401** — an unauthenticated endpoint that grants premium grants it to anyone who finds the URL | ⬜ |
| 7.22 | Fails closed | Unset `REVENUECAT_WEBHOOK_SECRET` | **500**, and nobody is granted premium — a misconfiguration must never mean "everybody is premium" | ⬜ |
| 7.23 | Retries on failure | Force an error inside the handler | Returns 5xx so RevenueCat **retries** — a dropped `RENEWAL` silently un-premiums a paying customer | ⬜ |
| 7.24 | Client cannot self-feature | Client write `featured: true` | **Denied** — it is a paid perk, granted only by the webhook | ⬜ |

---

## Safety — Report & Block (App Store Guideline 1.2)

Apple and Google both refuse an app with user-generated content that cannot flag
abuse and block people. These are release-blocking.

### Report

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| S.1 | Reachable from Discover | Discover → `⋯` on the top card | Action sheet: Report / Block / Cancel | ⬜ |
| S.2 | Reachable from a profile | Open anyone's profile → `⋯` top-right | Same action sheet | ⬜ |
| S.3 | Reasons | Report → the reason sheet | 7 reasons, scrollable, no overflow | ⬜ |
| S.4 | Submit | Pick a reason → Report | "Thanks, our team will review this." | ⬜ |
| S.5 | **Admin is emailed** | Check the admin mailbox | `[Report] <name> — <reason>` arrives; the report is in the admin panel's **Reports** queue | ⬜ |
| S.6 | No flooding | Report the same person for the same reason twice | The second is a no-op (one report per reporter/target/reason) | ⬜ |
| S.7 | A new reason still lands | Report the same person for a *different* reason | A second report is created | ⬜ |

### Block

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| S.8 | Block from Discover | `⋯` → Block → confirm | The card disappears from the deck immediately | ⬜ |
| S.9 | Stays gone | Refresh / Search wider | They do **not** come back | ⬜ |
| S.10 | Symmetric | Sign in as the blocked user | The blocker is gone from *their* deck too | ⬜ |
| S.11 | **Match disappears** | Block someone you matched and chatted with | The thread vanishes from **both** users' Matches lists | ⬜ |
| S.12 | **Chat is dead, not hidden** | Force a message send into that thread | **Denied** by the rules, in both directions | ⬜ |
| S.13 | History is kept | Firestore console → `matches/{id}/messages` | The messages are still there — they are the evidence if a report follows | ⬜ |
| S.14 | Unblock | Settings → Blocked users → Unblock | They can appear in the deck again | ⬜ |
| S.15 | **Unblock restores the thread** | Unblock someone you had matched with | The match reappears in both lists **with its history** | ⬜ |
| S.16 | Only the blocker can lift it | A blocked B, then B unblocks A (if B had also blocked) | Each side only controls its own block; A's block stands | ⬜ |
| S.17 | Blocked list | Settings → Blocked users | Photo + name per person, with Unblock; empty state when none | ⬜ |
| S.18 | **The blocked party is never told** | As the blocked user, look for any signal | Nothing says "you were blocked" or by whom — that is information a harasser wants | ⬜ |

---

## Phase 9 — Reviews & Ratings

A review is **held for moderation**: it is invisible and does not count toward the
rating until an admin approves it (admin side: **TEST_ADMIN.md § Reviews**).

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 9.1 | Section exists | Open a **teacher's** profile | A **Reviews** section (students have none — nobody rates a student) | ⬜ |
| 9.2 | Empty state | A teacher with no reviews | "No reviews yet" | ⬜ |
| 9.3 | **Match required** | Open the profile of a teacher you have *not* matched with | **No** "Write a review" button | ⬜ |
| 9.4 | Button appears on match | Match with a teacher → open their profile | "Write a review" | ⬜ |
| 9.4b | **Reachable from the chat** | Open the thread → tap the name/photo in the header | Their profile opens — after matching, the chat is the only place the other person appears, so this is the only route to it | ⬜ |
| 9.4c | Bottom bar knows you're matched | Open the profile of someone you have matched with | A single **Send message** button (→ the thread), **not** Pass / Connect — those are the swipe deck's verbs and mean nothing once you are connected | ⬜ |
| 9.4d | Not matched → deck verbs | Open a profile from the Discover deck (info icon) | Pass / Connect, as before | ⬜ |
| 9.4e | Own profile | Open your own profile (e.g. from a review notification) | **No** bottom bar at all | ⬜ |
| 9.5 | Compose | Tap it | Sheet: star picker, optional comment, "Reviews are checked by our team before they appear." | ⬜ |
| 9.6 | Rating is mandatory | Leave the stars empty | Submit is disabled | ⬜ |
| 9.7 | Submit | 4 stars + a comment → Submit | Snackbar: "your review will appear once it's approved"; `reviews/{teacherId}_{myUid}` written with `status: "pending"` | ⬜ |
| 9.8 | **Pending is invisible to others** | As the teacher (or anyone else), open that profile | The review is **not** listed, and the rating is unchanged | ⬜ |
| 9.9 | Author sees their own | As the reviewer, reopen the profile | "Your review" card + "Awaiting approval — only you can see this." | ⬜ |
| 9.10 | Edit | Tap Edit → change to 5 stars → Submit | The same doc is updated (no second review), back to `pending` | ⬜ |
| 9.11 | **Approval publishes it** | Admin approves it | It appears in the list for everyone, and the teacher's header rating updates | ⬜ |
| 9.12 | Average is right | Approve a 4 and a 5 for the same teacher | Header shows `4.5 (2)` | ⬜ |
| 9.13 | **Teacher is notified** | After approval | The teacher gets an activity item + push: "You have a new review" — tapping it opens their public profile | ⬜ |
| 9.14 | Rejection is explained | Admin rejects with a reason | The reviewer's own card shows "This review wasn't published: <reason>" and can be edited and resubmitted | ⬜ |
| 9.15 | **Rejecting a published review un-counts it** | Approve a review, then reject it | It disappears from the profile and the rating/count drop back | ⬜ |
| 9.16 | Editing an approved review pulls it back | Reviewer edits an approved review | It leaves the profile (back to `pending`) and the rating drops until re-approved | ⬜ |

### Security (Phase 9 invariants)

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| 9.20 | **Can't write a review directly** | Client write to `reviews/{id}` | **Denied** — else anyone could self-approve, forge a reviewer name, or rate a stranger | ⬜ |
| 9.21 | **Can't rate a stranger** | Call `submitReview` for a teacher you never matched with | Rejected `failed-precondition` — a match is the price of admission | ⬜ |
| 9.22 | **A block kills the right to review** | Block a matched teacher, then call `submitReview` | Rejected — otherwise "block, then one-star them" is a two-tap revenge combo | ⬜ |
| 9.23 | Students can't be rated | Call `submitReview` targeting a student | Rejected `failed-precondition` | ⬜ |
| 9.24 | Rating bounds | Call `submitReview` with `rating: 0`, `6`, or `4.5` | Rejected `invalid-argument` (integer 1–5) | ⬜ |
| 9.25 | **Can't set your own rating** | Client write `avg_rating: 5.0` / `total_reviews: 200` / `rating_sum` on your user doc | **Denied** — the aggregate is owned by the `onReviewWritten` trigger | ⬜ |
| 9.26 | **Can't read pending reviews of someone else** | Query `reviews` where `target_id == <a teacher>` with no status filter | **Denied** — a list only succeeds if every doc is readable, so pending/rejected reviews cannot be enumerated | ⬜ |
| 9.27 | Banned users can't review | Ban a user → call `submitReview` | Rejected `permission-denied` | ⬜ |

---

## Cross-cutting — Localization & Currency

| # | Test | Steps | Expected | Status |
|---|------|-------|----------|--------|
| X.1 | No hard-coded text | `grep -rn --include="*.dart" -E "(Text\(\|labelText:\|hintText:\|_snack\()\s*'[A-Z]" mobile/lib \| grep -v l10n` | **Zero** hits — every user-facing string comes from the ARB | ⬜ |
| X.2 | Strings render | Walk the app (auth → register → profile → tabs) | No missing/blank labels, no raw keys shown | ⬜ |
| X.3 | Currency stored | Register a new user | `users/{uid}.currency == "USD"` | ⬜ |
| X.4 | Rate shows currency | Teacher → Bio → Hourly rate | Field is prefixed with the symbol from the selected currency (`$`), not a literal | ⬜ |
| X.5 | Legacy doc safe | A user doc with no `currency` field | Falls back to USD, no crash | ⬜ |
| X.6 | Currency picker renders | Teacher → Bio, next to Hourly rate | A **Currency** dropdown showing `USD ($)`, disabled, helper text "More currencies coming soon" | ⬜ |
| X.7 | Currency saves | Teacher → Bio → Save changes | `users/{uid}.currency == "USD"` written alongside `hourly_rate` (they always travel together) | ⬜ |

---

## Deferred / not yet testable (tracked here so we don't forget)

- ⏭️ Profile photo upload (picked at step3 but not uploaded) — **Phase 3** (Storage)
- ⏭️ Teacher certificate upload (screen routes to `/pending` without uploading) — **Phase 3**
- ⏭️ Teacher `pending → approved` gating on login — needs Admin approval — **Phase 8**
- ⏭️ Google / Apple / passwordless sign-in — **Phase 2.5**
