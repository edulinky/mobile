# EduLink Platform — Full MVP (Phase 1) Implementation Plan

## Context

EduLink is a greenfield Tinder-style education recruitment platform connecting Students, Teachers, and Institutions. The requirements document defines a swipe-based discovery engine, RBAC via Firebase Custom Claims, real-time messaging gated on mutual matches, RevenueCat subscription tiers, and an Admin moderation panel.

**Architecture split:**
- **Mobile app (Flutter)** — Student, Teacher, Institution users (iOS & Android)
- **Admin web app (Next.js 14)** — Admin panel only, browser-based
- **Backend (Firebase + Cloud Functions)** — all server-side logic lives in Cloud Functions (Node.js/TypeScript); no standalone server required

**Why Firebase + Cloud Functions (not a standalone Express server):**
- Firestore handles the database, real-time listeners (chat, matches), and security rules
- Cloud Functions replace Express — same Node.js logic, but serverless: scale to zero at idle, scale up automatically under load, pay only for what runs
- Firebase Auth handles login, tokens, and Custom Claims (role system)
- Firebase Storage handles photos and certificates
- FCM (Firebase Cloud Messaging) handles push notifications
- The only things that need Cloud Functions are: swipe quota enforcement, setting Custom Claims on registration, RevenueCat webhook, mutual-swipe → match creation, and admin actions

---

## Cross-cutting conventions (apply to every phase)

### Localization — no hard-coded user-facing text
The app ships English-only today but **must be translatable without a rewrite**. Infrastructure: `flutter_localizations` + `intl`, `generate: true`, ARB files in `mobile/lib/l10n/`, `l10n.yaml`, and a `context.l10n` extension (`core/extensions/l10n_extension.dart`).

**Rule:** every string a user can read comes from the ARB — labels, hints, buttons, snackbars, error messages, empty states. No string literal in a `Text(...)`, `labelText:`, `hintText:`, or snackbar. Add the key to `lib/l10n/app_en.arb`, run `flutter gen-l10n`, use `context.l10n.myKey`. Interpolation goes through ARB placeholders (`"msgResetEmailSent": "Password reset email sent to {email}."`), never Dart `$interpolation` inside a literal — a translator must be able to move the placeholder.

To add a language later: drop in `app_xx.arb` and add the locale to `supportedLocales`. Nothing else changes.

> Guard: `grep -rn --include="*.dart" -E "(Text\(|labelText:|hintText:|_snack\()\s*'[A-Z]" mobile/lib | grep -v l10n` should return **zero** hits.

### Currency — USD now, multi-currency ready
Prices are **USD only** today, but nothing hard-codes that.

- **Storage:** every priced amount is stored *next to its currency code* — `users/{uid}.currency` (`"USD"`, set by `completeRegistration`) alongside `hourly_rate`. A bare number is never written, so an old row can never become ambiguous when a second currency appears.
- **Display:** all formatting goes through `core/money/currency.dart` — the `Currency` enum (code + symbol, `Currency.supported`, `Currency.fromCode` with a safe fallback) and `Money.format()/perHour()`, which use `intl`'s `NumberFormat.currency` and are **locale-aware** (`1,234.50` in en-US → `1.234,50` in de-DE). No literal `$` anywhere in the UI; the symbol comes from the profile's currency.
- **The picker is already built and shipped** — `core/widgets/currency_picker_field.dart` (`CurrencyPickerField`), rendered from `Currency.supported` next to the hourly rate in the teacher Bio tab. With one supported currency it shows a single locked option ("More currencies coming soon"), which makes the currency of a price *visible* rather than an unstated assumption. `currencyProvider` reads the user's stored `users/{uid}.currency` (falling back to USD).
- **To add a currency later:** add the enum value and list it in `Currency.supported`. **That is the whole change** — the picker unlocks itself, the symbol follows, and no call site moves.

---

## Monorepo Structure

```
edulink/
├── mobile/                    # Flutter app (Student / Teacher / Institution)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/               # MaterialApp, routing (go_router)
│   │   ├── features/
│   │   │   ├── auth/          # Login, register, role selector screens
│   │   │   ├── discover/      # Swipe stack screen + card widgets
│   │   │   ├── matches/       # Match list screen
│   │   │   ├── messages/      # Chat thread screen
│   │   │   ├── profile/       # Own profile edit + public view
│   │   │   ├── jobs/          # Job card list + detail (Institution)
│   │   │   └── settings/      # Subscription, account settings
│   │   ├── core/
│   │   │   ├── firebase/      # Firebase init, Auth, Firestore, Storage helpers
│   │   │   ├── theme/         # Sky Blue ColorScheme, text styles, radius tokens
│   │   │   └── widgets/       # Shared: GlassCard, BadgeChip, StarRating, VideoEmbed
│   │   └── providers/         # Riverpod providers: auth, swipe, matches, messages
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── admin/                     # Next.js 14 web app (Admin only)
│   └── src/
│       ├── app/
│       │   ├── login/page.tsx
│       │   ├── verifications/page.tsx
│       │   ├── reviews/page.tsx
│       │   └── users/page.tsx
│       ├── components/        # VerificationQueue, ReviewQueue, UserTable
│       ├── lib/               # firebase/{client,auth,firestore}, api.ts
│       └── styles/            # globals.css, tokens.css
│
├── functions/                 # Firebase Cloud Functions (Node.js/TypeScript)
│   └── src/
│       ├── auth/              # onRegister trigger: set Custom Claims, write user doc
│       ├── swipe/             # getCandidates, recordSwipe, quota enforcement
│       ├── matches/           # createMatch (called internally on mutual swipe)
│       ├── payments/          # RevenueCat webhook: update sub_status + isPremium claim
│       ├── notifications/     # FCM push triggers on new match / new message
│       ├── admin/             # approveTeacher, banUser, approveReview
│       └── shared/            # Firebase Admin SDK init, shared types
│
├── firestore.rules
├── storage.rules
└── firebase.json
```

---

## Implementation Order (10 Phases)

### Phase 1 — Scaffold & Infrastructure
- Monorepo root with `mobile/`, `admin/`, `functions/` directories; shared `.gitignore`
- Firebase project: enable Firestore (Native mode), Auth (Email/Password), Storage, Messaging (FCM), Cloud Functions
- **Mobile:** add to `pubspec.yaml`: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `go_router`, `flutter_riverpod`, `dio`, `geoflutterfire_plus`
- **Admin:** `create-next-app` with App Router + TypeScript; install `firebase`, `axios`; create `tokens.css` with Sky Blue CSS vars
- **Functions:** `firebase init functions` (TypeScript); install `firebase-admin`, `firebase-functions`; deploy `/health` callable to verify setup

### Phase 2 — Auth & Role System
- `functions/src/auth/onRegister.ts` — `onCreate` Auth trigger: calls `admin.auth().setCustomUserClaims(uid, { role })`, writes `users/{uid}` doc to Firestore
- `functions/src/auth/setRole.ts` — callable function for changing role (admin only)
- Teacher cert upload: callable `submitCertification` sets `verified_status: "pending"` + `cert_url` on user doc
- **Mobile:** `AuthNotifier` (Riverpod `AsyncNotifier`) — wraps `firebase_auth`; after sign-in calls `user.getIdTokenResult(forceRefresh: true)` to read Custom Claims. 3-screen registration: credentials → role selector → display name
- **Admin:** Email/Password login; middleware checks Firebase session cookie; redirects non-admin to `/login`
- Mobile route guards via `go_router` redirect callbacks reading auth state from Riverpod

**Phase 2 (initial) ships Email/Password only.** Social + passwordless providers are deferred to Phase 2.5 below.

#### Phase 2.5 — Additional Auth Providers (Deferred)

Add these once the Email/Password flow is solid. All four resolve to the same `firebase_auth` `User` and the same `onRegister` → Custom Claims path, so the role system is unchanged — but **first-time social/passwordless sign-ins skip the 3-step registration**, so they need a "complete your profile" step to capture **role + display name** before landing in the app.

- **Apple Sign-In — required, not optional.** App Store Review Guideline 4.8 mandates Sign in with Apple for any app offering third-party sign-in (Google). Blocks iOS submission if missing.
  - Firebase console: enable **Apple** provider
  - Apple Developer: create a **Services ID**, enable "Sign in with Apple" on the App ID, generate the **key (.p8)** + Key ID + Team ID, configure the return URL
  - Flutter: `sign_in_with_apple` + `firebase_auth` `signInWithProvider(AppleAuthProvider())`; `Info.plist` / Xcode "Sign in with Apple" capability
  - Note: Apple only returns name/email on the **first** authorization — persist it immediately or it's lost
- **Google Sign-In**
  - Firebase console: enable **Google** provider (sets the OAuth client)
  - Flutter: `google_sign_in` + `firebase_auth`; Android needs the **SHA-1/SHA-256** fingerprints added in Firebase; iOS needs the reversed-client-id `CFBundleURLScheme` in `Info.plist`
- **Email link (passwordless)**
  - Firebase console: enable **Email link (passwordless sign-in)** under the Email/Password provider
  - Flutter: `sendSignInLinkToEmail` + `signInWithEmailLink`; requires deep-link handling (universal links / app links) to catch the return link and an `ActionCodeSettings` with the `eduLinky.com` domain
  - Depends on the custom domain + email being live
- **Cross-cutting work for all three:**
  - New-user detection (`userCredential.additionalUserInfo?.isNewUser`) → route to a **role + display-name capture screen** before the app shell; `onRegister` writes the `users/{uid}` doc + sets the role claim from that input
  - Account-linking strategy for same-email-different-provider collisions (`account-exists-with-different-credential`)
  - Update login/register screens with Apple/Google buttons (Apple button must follow Apple's HIG styling)
  - Admin panel stays **Email/Password only** — no social providers there

### Phase 3 — Profile System
- Full `users/{uid}` Firestore schema: uid, role, sub_status, geo_location (lat/lng/geohash/city), verified_status, cert_url, video_links, gallery, qualifications, experience, availability, avg_rating, total_reviews, is_banned, featured
- **Mobile:** Tabbed `ProfileEditScreen` — auto-saves on field change (debounced 800ms → Firestore `update`); gallery upload via `image_picker` + Firebase Storage → `gallery/{uid}/{uuid}.jpg`, max 6 photos; `VideoEmbedWidget` using `webview_flutter`; `ScheduleGrid` 7×12 time-slot toggle
- **Image reposition/crop before upload** — ✅ **DONE**: `core/widgets/photo_crop_screen.dart` (`PhotoCropScreen`) using pure-Dart `crop_your_image` with `interactive:true` + `fixCropRect:true` + `withCircleUi` — image pans/pinch-zooms inside a fixed circular frame; returns cropped bytes. **Pending:** reuse in profile-edit gallery/avatar.
- **Storage uploads (avatar + teacher certificate)** — ✅ **DONE.** `core/storage/storage_service.dart` (`StorageService`) + `features/profile/data/profile_repository.dart` (`ProfileRepository`).
  - `storage.rules` replaced the default-deny baseline: `avatars/{uid}/…` and `gallery/{uid}/…` are readable by any signed-in user and writable only by the owner (images, <5 MB); **`certs/{uid}/…` is write-only — `allow read: if false`**, because a certificate is a private identity document. Admins read it through a Cloud Function (Admin SDK bypasses rules).
  - Register step-3 uploads the cropped avatar **after** `completeRegistration` (the user must exist + be signed in for the rules to pass), then writes `photo_url` on the user doc. Failure is **non-fatal** — the account is already usable, so we snackbar and continue rather than strand the user.
  - `submitCertification` callable (`functions/src/auth/submitCertification.ts`): teacher-only; **accepts up to 5 documents** (`certPaths[]`) — a degree, a teaching qualification and a licence are commonly separate files. Rejects any path outside the caller's own `certs/{uid}/` folder (otherwise a teacher could claim someone else's document); verifies every object exists; sets `cert_paths` + `cert_submitted_at` + `verified_status:"pending"`. It can never set "approved" — that stays an admin action (Phase 8).
  - Picker is **`file_picker`** (not `image_picker`): the screen always advertised "PDF, JPG, PNG" but `image_picker` cannot select a PDF — a certificate is usually a PDF. Multi-select, 10 MB/file (checked client-side *and* in `storage.rules`), removable list before submit. Storage rules accept `image/*` **or** `application/pdf` under `certs/{uid}/`; still `allow read: if false`.
- **City via Google Places autocomplete (mandatory, city-level only)** — ✅ **DONE, App-Check-protected Cloud Function proxy + warm instance.** History: native `flutter_google_places_sdk` (broken iOS/legacy API) → direct `google_places_sdk_flutter` (worked but key-in-app felt unsafe) → **this** (key server-side, low latency, attested). Flow: `city_picker_screen.dart` → `PlacesService` (`core/places/places_service.dart`) → callables `placesAutocomplete`/`placeDetails` (`functions/src/places/`, `enforceAppCheck:true`, autocomplete `minInstances:1`) → **Places API (New)** HTTP, `(cities)`, session tokens. Register step-3 free-text field replaced with the tappable picker; **city is required**. `completeRegistration` computes geohash (`geofire-common`) and stores `geo_location` for Phase 4. **Key:** `functions/.env` (`PLACES_API_KEY`), restriction **Application None** + **API Places API (New)** + quota. **App Check** (`firebase_app_check` in `main.dart`): debug provider in dev (register the printed debug token per simulator), App Attest/Play Integrity in release. **Pending:** reuse picker in profile-edit.
  - **Key handling — DECIDED: native Places SDK** (`flutter_google_places_sdk`) for speed. The API key ships in the app but is locked down so extraction is inert: **application restriction** (Android package `com.edulinky.mobile` + release/debug SHA-1; iOS bundle ID `com.edulinky.mobile`) + **API restriction** (Places API only) + **session tokens** + **billing budget/quota cap**. This is the one intentional exception to "no keys in the app" — restricted Maps keys are the accepted practice; it is NOT a real secret.
  - **Setup [You]:** (1) enable **Places API** in Google Cloud for `edulinky-86123` (Blaze billing already on); (2) create an API key; (3) add application + API restrictions above; (4) set a billing budget alert + daily quota cap.
  - Key config lives in `android/app/src/main/AndroidManifest.xml` (meta-data) + iOS `AppDelegate`/`Info.plist` — NOT a true secret, but keep it in app config, not committed alongside real secrets.
  - Applies to register step-3 AND profile edit; `completeRegistration` updated to accept/store `geo_location` (lat/lng/geohash/city); make `geo_location` required in `users/` for roles that appear in discovery.
- **Profile edit on live Firestore** — ✅ **DONE for student + teacher Bio tab.** `features/profile/models/user_profile.dart` (`UserProfile`, `GeoLocation`), `ProfileRepository.watchMyProfile()/updateProfile()/setAvatar()/setCity()`, `myProfileProvider` (`StreamProvider<UserProfile>`). Screens read the live doc (no more "Alex Thompson"/"Sarah Johnson" mock), save name/about/subjects/avatar (+ teacher `hourly_rate`), and reuse the Places city picker.
  - City change goes through the new **`updateLocation`** callable (`functions/src/profile/updateLocation.ts`) and `geo_location` is now **client-immutable in `firestore.rules`** — the geohash must be derived from the coordinates server-side, or a user could hand-write a hash and surface in discovery for a city they aren't in. `cert_path` is locked the same way.
- **Teacher tabs — Gallery / Qualifications / Experience / Schedule / Videos** — ✅ **DONE, all on live Firestore.** Schema added to `users/{uid}`: `gallery` (Storage **paths**), `qualifications` (string[]), `experience` (`{title, institution, from, to}[]`), `availability` (`{Mon: ["Morning",…]}`), `video_links` (string[]).
  - **Gallery** stores **paths, not URLs** (`addGalleryPhoto`/`removeGalleryPhoto` in `functions/src/profile/gallery.ts`): the callable checks the path is under the caller's own `gallery/{uid}/`, so a user can't point their gallery at an arbitrary remote image shown to other users; it also enforces the **6-photo cap**, which rules can't (they can't count an array). Photos reuse `PhotoCropScreen`. The app resolves path → URL via the Storage SDK at render.
  - **Videos** go through `setVideoLinks` (`functions/src/profile/setVideoLinks.ts`): **https + YouTube/Vimeo hosts only, max 4**. Video links are embedded in a WebView shown to *other* users, so an arbitrary URL is a phishing surface.
  - `gallery` + `video_links` are therefore **client-immutable in `firestore.rules`** (alongside `geo_location` and `cert_path`). Qualifications/experience/availability are plain text rendered as text, so they stay direct client writes.
- **Public profile view** — ✅ **DONE, live Firestore.** `TeacherPublicProfileScreen` now takes a **uid** and streams `users/{uid}` via `userProfileProvider` (family) — the rules already allow any signed-in user to read a profile. Renders photo, name, city, rating, **Verified/Pending/Featured `BadgeChip`**, hourly rate (through `Money.perHour`, so it carries the profile's currency), subjects, about, gallery (paths → URLs), qualifications, experience, availability.
  - Route changed to **`/teacher/:uid/profile`** (was `/student/teacher-profile` taking a `TeacherCardModel` in `extra`) — keyed by uid so it loads fresh and is deep-linkable.
  - Reviews show the real empty state instead of the two invented review cards: a review cannot exist until the ratings system (Phase 8), so displaying fake ones would be a lie.
  - **Known gap until Phase 4:** the student discover deck is still mock (`mockTeachers`, uids `t1…t5`), so tapping a card opens "This profile is not available." That resolves the moment `getCandidates` returns real uids.

### Phase 4 — Discovery / Swipe Engine
✅ **DONE** (Job Cards in the teacher deck remain Phase 6).

**Quota model (from the requirements):** a free Student gets **20 right swipes / 24h — 15 "primary subject" + 5 "discovery"**. The two are **separate budgets**, so exhausting discovery must not eat the primary allowance. **Left swipes are free** — only expressions of interest are metered. Premium (`sub_status != "free"`) is unlimited. The Teacher quota is "to be defined by Admin", so limits are overridable at `config/quotas` (no client access, no redeploy needed); `functions/src/shared/quotas.ts` holds the defaults and the `bucketFor()` primary-vs-discovery rule.

**Deck ranking — people who already liked you come FIRST.**
Mutual consent is correct, but leaving it to chance is not: without this, both people must *independently* find each other in a distance-ordered deck, so the person who already said yes might be card 30 — or never surface at all before the swipe quota runs out. `getCandidates` runs `collectionGroup("sent").where("target_id","==",me).where("liked","==",true)` and sorts those to the front.
- **It leaks nothing.** They render as an ordinary card — no badge, no label. The viewer cannot tell "first because they liked me" from "first because they're nearby". *Naming* a liker would be a disclosure; *ordering* is not. The `likedMe` flag is stripped server-side before the batch is returned.
- The doc dictates who is discoverable and what creates a match; it says nothing about deck order (featured-first is our call too). It notifies on a one-sided swipe exactly once — **Teacher → Job Card → Institution** — and never for people. So no "someone liked you" notification: that would leak the like, and "see who liked you" is not in the doc's premium tiers either. It's the natural Phase 7 upsell if you ever want it.
- **The rules deliberately do NOT grant a collection-group rule on `sent`** — the same query from a client would reveal exactly who liked you. Admin SDK bypasses rules; clients are denied by default. Don't add one.

**Cloud Functions (`functions/src/swipe/`):**
- `getCandidates` — target role derived from *your* role (student→teacher, teacher→student). Geohash **bounding-box** query via `geofire-common` (`geohashQueryBounds`), then a true-distance filter, because a box over-selects at the corners. Excludes everyone in `swipes/{uid}/sent/`, yourself, banned users, and **unapproved teachers** (`verified_status != "approved"` are not discoverable). Sorts **featured first, then nearest**; returns 10. Needs the composite index in `firestore.indexes.json` (equality on `role`+`is_banned`, range on `geo_location.geohash`).
- `recordSwipe` — **one Firestore transaction** covering the quota check, the swipe write, and the match write. This is the point of the transaction: two swipes racing (double-tap, retry, second device) could each read "14 used" and both commit — a quota you can beat by tapping fast is not a quota. Re-swiping the same person is a no-op, not a second charge. On a **mutual** right-swipe it calls `createMatchInTx` (`matches/createMatch.ts`, deterministic `matchId = [a,b].sort().join("_")`) so the match and the swipe commit together or not at all.
- `getSwipeQuota` — remaining swipes for the banner.

**Firestore rules:** `swipes/`, `swipeQuotas/`, `matches/`, `config/` are all **server-write-only**. A client that could write its own swipe doc would bypass the quota transaction entirely — and could forge the *other* side of a mutual like to manufacture a match with someone who never swiped on them. `matches` is readable only by its two participants (it is the gate that unlocks chat).

**Mobile:**
- `discover_repository.dart` — `getTeacherCandidates`/`getStudentCandidates`/`recordSwipe`/`getQuota`.
- `swipe_controller.dart` — `SwipeController<T>`, **generic over the card type** because the engine is identical for both decks (the server picks *who* you see from your role). **Optimistic UI**: the card leaves immediately and the call runs after; if the server rejects it (quota exhausted) **the card is put back** — a user must not lose a profile they never spent a swipe on. Prefetches a new batch in the background at ≤3 cards left.
- Providers: `teacherDeckProvider` (student's deck) and `studentDeckProvider` (teacher's deck).
- `student_discover_screen.dart` + the teacher's **Students** tab are live; `QuotaBanner` shows real remaining swipes; the match overlay fires on a real mutual like and carries the real `matchId` into chat.
- **`mockTeachers` and `mockStudents` are deleted.**

### Phase 5 — Matching & Messaging
✅ **DONE** (teacher "job matches" wait for Phase 6).

**Schema:** `matches/{matchId}` gains `last_message`, `last_message_at`, `unread: {uid: n}`. Messages live at `matches/{matchId}/messages/{msgId}` — `{sender_id, text, created_at}`. Push tokens at `users/{uid}.fcm_tokens` (an array: one account, several devices).

**Firestore rules — chat is gated on the match.** Only the two people who *both* right-swiped can read or write a thread; the match doc IS the consent record, so that is what the rule checks (`inMatch()` reads `participants`). Three deliberate choices:
- **`is_banned` is re-checked on every send** (`notBanned()`), not just at sign-in. A Firebase ID token stays valid for up to an hour after an admin bans someone, so a token-only check would let a banned user keep messaging the person they were banned for harassing. One extra doc read is the right price.
- **`sender_id` must equal the caller** — you cannot forge the other side of a conversation.
- **History is immutable** (`allow update, delete: if false`) — nobody rewrites what was said, including the sender. Moderation is a Phase 8 server-side action.

**Cloud Functions:**
- `onNewMessage` (`notifications/onNewMessage.ts`, Firestore `onDocumentCreated`) — owns what the client must not: the match's `last_message`/`last_message_at` (which order the match list) and the recipient's `unread` counter, since `matches/` is server-write-only and a client could otherwise fake activity or clear someone else's badge. Then sends the FCM push. The push is **best-effort** — a failed notification must never fail the message. Dead tokens (uninstalled app, rotated token) are pruned from `fcm_tokens` on send failure, or they accumulate forever. The notification body is truncated to 120 chars: it shows on a lock screen.
- `markMatchRead` (callable) — clears **only the caller's own** unread counter.

**Mobile:**
- `matches/models/chat_models.dart` (`MatchThread`, `ChatMessage`), `matches/data/matches_repository.dart` (`matchesProvider`, `messagesProvider` family).
- `MatchesList` widget — shared by the student and teacher screens (a match is symmetric; nothing about it is role-specific). Matches with no messages render as a "new matches" avatar row; the rest as a conversation list with unread badges.
- `ChatScreen` streams `messages` live and sends via Firestore. **Sends are optimistic for free**: Firestore echoes the write from its local cache before the server acks, so the bubble appears instantly. A message whose `created_at` is still null shows no timestamp rather than a wrong one. On failure the text is put back in the field rather than lost.
- **The fake typing indicator and the canned auto-reply are gone** — they simulated a person who wasn't there.
- `core/notifications/push_service.dart` — requests permission, saves the FCM token on sign-in, follows `onTokenRefresh` (tokens rotate; saving once means pushes silently stop), and **removes the token on sign-out** so the next person to use the phone does not get the previous user's messages.

### Phase 5.5 — In-app Activity / Notifications
✅ **DONE.**

Push alone was not enough: a notification is ephemeral (dismissed, or never delivered because the user turned notifications off), so anything worth pushing is worth persisting where the user can find it. And **teacher verification had no surface at all** — an approval or rejection was completely silent; the teacher would just notice Discover started working, or never did.

**Schema:** `notifications/{uid}/items/{id}` — `{type, title, body, data, read, created_at}`. Types: `match`, `message`, `verification_approved`, `verification_rejected`, `job_application` (Phase 6).

**Rules:** server-write-only (`allow create: if false`). A client that could write here could fabricate *"you matched with X"* or *"you're verified"*. The owner may flip **only** `read` (`diff().affectedKeys().hasOnly(['read'])`) and may delete an item to dismiss it.

**Cloud Functions:**
- `shared/notify.ts` — one `notify()` helper writes the inbox item **and** sends the push, so the two surfaces can never drift apart. Push is best-effort; dead FCM tokens are pruned on send failure.
- `recordSwipe` — notifies **both** parties on a mutual match. Fired **after** the transaction commits: a transaction can be retried, and notifying inside it could send the same push several times.
- `onNewMessage` — notifies the recipient (inbox + push).
- **`onVerificationChanged`** (`onDocumentUpdated` on `users/{uid}`) — tells a teacher when their certificate is approved or rejected. A Firestore trigger rather than a call from the admin action, so it fires **however** `verified_status` changes — including a hand edit in the console, which is how approvals happen until Phase 8.
- `markNotificationsRead` (callable) — clears the badge.

**Mobile:** `features/notifications/` — repository + `NotificationsScreen` (one screen, all three roles). **Alerts is now a nav tab for students and teachers** (it previously existed only for institutions), sitting at index 1 for every role so tab order is consistent. Unread count drives a red badge on the nav icon; opening the inbox marks all read. Swipe an item to dismiss it.

> **Note — no "match request" notification, deliberately.** A match only exists once *both* sides right-swipe. Telling someone "X liked you" before they have liked back would leak who swiped them, which is a privacy decision (and typically a paid feature elsewhere).

### Phase 6 — Job Cards
✅ **DONE.** Institutions are now testable end-to-end.

**Schema:** `jobCards/{jobId}` — `{job_id, inst_id, institution_name, institution_logo_url, title, subject, description, contract_type, salary_min, salary_max, currency, video_url, geo_location{lat,lng,geohash,city}, status, applicant_count, created_at}`. `applications/{jobId}_{teacherId}` — `{job_id, teacher_id, inst_id, teacher_name, teacher_photo_url, job_title, status, created_at}`.

**The one-directional flow.** Teacher → Job Card is the *only* place a single swipe notifies anyone, and the spec says so explicitly: *"Teacher → Job Card: Right swipe triggers an Immediate Notification to the Institution."* No mutual swipe, no match. The asymmetry is deliberate — the counterparty is an organisation receiving a job application, not a person being swiped on. (Compare Student ↔ Teacher, which requires mutual consent.)

**Cloud Functions (`functions/src/jobs/`):**
- `upsertJobCard` / `setJobCardStatus` — the card **inherits the institution's verified city**; there is no location field in the UI. The geohash must be *derived* from that, never supplied, or a card could surface in a city it isn't in. `inst_id`, `status` and `applicant_count` are set server-side so they cannot be forged (an institution could otherwise inflate its applicant count, or post as somebody else). Editing checks the card is yours.
- `getJobCards` — geohash bounding box + true-distance filter, `status == "active"`, excludes jobs already applied to, and **only returns jobs in the subjects the teacher teaches** (stakeholder decision — the doc does not require this; FR3.2 asks for a *user-controlled* subject/distance filter, which is still unbuilt). A teacher with **no** subjects set is not filtered down to nothing — they see everything until they fill the field in. Same **verification gate** as student discovery: an unapproved teacher cannot reach institutions either.
  > Because the deck is now subject-filtered, the empty state has to say so — a teacher with one subject sees an empty deck easily, and "no jobs" reads as "this platform has no jobs" rather than "widen what you teach". It offers **Start over** and **Edit my subjects** (which reloads the deck on the way back).

**Subject matching — `shared/subjects.ts`.** Subjects are free text on both sides, so every comparison goes through `canonicalSubject()`: case, padding, punctuation, plus a table of the aliases people actually type (`maths`/`math` → `mathematics`, `ICT`/`computing` → `computer science`, `chinese` → `mandarin`, …). Without it "Mathematics" and "maths " are different subjects and a job card is invisible to exactly the teacher it was posted for.

**It is an alias table, not fuzzy matching, on purpose.** Edit-distance cuts both ways and both ways are bad: loose enough to be useful and a French teacher gets shown German jobs (short subject names are dense with near-neighbours); tight enough to be safe and it still misses `maths` → `mathematics`, which is six edits apart and the whole reason we are here. A table is predictable, testable, and when it is wrong it is wrong in a way you can see and fix in one line.

Two things use it now:
- `getJobCards` — which cards a teacher sees.
- **`bucketFor()` (quotas)** — a student whose primary subject was "Maths" swiping a teacher who wrote "Mathematics" had been silently spending from the 5-swipe *discovery* budget instead of the 15-swipe *primary* one. Same string-equality bug, just quieter, because nothing visibly disappeared.

**Job form: preset dropdown + "Other".** `SubjectDropdownField` — the institution picks from `kSubjectPresets` (the same list the profiles use) or types their own. The spelling here decides who the card reaches, so the common spelling is now the easy one; free text stays, because the list will never cover the long tail (IELTS, Music Theory, a local curriculum subject) and a form that refuses the real answer is worse than one that risks a typo.
- `applyToJob` — deterministic id `{jobId}_{teacherId}`, so applying twice is a no-op rather than a duplicate. Increments `applicant_count`, then notifies the institution (inbox + push).

**Rules:** `jobCards` readable by any signed-in user, **write: false**. `applications` are readable **only by the two parties** — who has applied for a job is confidential to the applicant and the institution — and written only by `applyToJob`.

**Mobile:** `features/jobs/` — `JobCard`/`JobApplication` models, `JobsRepository`. Institution **dashboard** lists its live cards with status + applicant counts; **create/edit** screen (no location field, by design); **detail** screen shows applicants, tapping through to a teacher's public profile, with Close/Reopen (a closed card leaves every teacher's deck). The institution's **Alerts** tab now uses the shared `NotificationsScreen`. The teacher's **Jobs** tab is live: a right-swipe applies, optimistically removing the card and restoring it if the server rejects.
**`mockJobCards`, `mockJobMatches` and `JobPostModel` are deleted.**

> **Still gated on Phase 7:** the doc says *"Institution Premium Only"* for recruiting. Job-card posting is currently open to any institution — the paywall screen exists but is inert until RevenueCat lands.

### Phase 7 — Monetization & Payments (RevenueCat)

The doc's monetization rules (FR-3.1 – FR-3.3) and what each one costs us:

| Requirement | Where it lives | Status |
|---|---|---|
| **FR-3.1** Free Student: 20 right swipes / 24h — **15 primary + 5 discovery** | `shared/quotas.ts` + `recordSwipe` | ✅ **Done.** Two *separate* budgets, so burning the 5 discovery swipes cannot eat the 15 primary ones. Rolling 24h window. **Left swipes are not metered** — only expressions of interest are. Which bucket a swipe draws from is decided by `bucketFor()` → `canonicalSubject()`, so "Maths" vs "Mathematics" doesn't silently charge the scarcer budget. |
| **FR-3.2** Free Teacher: "limited swipes, **to be defined by Admin**" | `config/quotas` + admin **Quotas** screen | ✅ **Done.** `limitsForRole()` reads an override from `config/quotas` **without a redeploy** — that indirection exists *because* the doc leaves the number to the admin. `getQuotas` / `setQuotas` (admin-only, audited) drive a **Quotas** screen in the panel. One setting **per role**, not per user: it moves every free user in that role on their next swipe. `config/*` stays unreadable and unwritable to clients — a client that could write it would grant itself unlimited swipes — hence the callables. |
| **FR-3.3** Premium Student / Teacher: **unlimited swipes** | `recordSwipe` | ⚠️ **Logic done, unreachable.** The quota is skipped when `sub_status != "free"` — but **nothing can set `sub_status`**, so today nobody can be premium. That is exactly what this phase unblocks. |
| **FR-3.3** Premium Teacher: **"Featured" badge** | `setFeatured` (admin) | ❌ **Missing the link.** `featured` exists and boosts discovery, but it is *admin-granted only* — it is not tied to the subscription. **A premium teacher must get it automatically, and lose it when they lapse**, or the perk they paid for depends on an admin remembering. |
| **FR-3.3** Institution: **mandatory subscription** to access the dashboard or post Job Cards | `upsertJobCard`, rules, paywall screen | ❌ **Not enforced.** Any institution can post today. The paywall screen exists but is inert. This is the one place where money gates a *feature*, not a *limit* — and the doc is explicit ("Mandatory Subscription required"). |

#### Stripe or RevenueCat? (the doc says "Stripe/RevenueCat" — they are not alternatives)

**RevenueCat is not a payment processor.** It sits *on top of* Apple's StoreKit and Google Play Billing: Apple and Google take the money, RevenueCat tells us — reliably, via one webhook — who is subscribed right now. The hard part of mobile subscriptions is not taking a payment, it is *knowing the current state*: renewals happen while the app is closed, receipts differ per platform, and there are grace periods, billing retries, refunds, upgrades and family sharing to track. RevenueCat does that twice over (iOS + Android) and hands us a boolean.

**Apple leaves us no choice for the in-app tiers.** Guideline 3.1.1 *requires* in-app purchase for digital content consumed in the app. Unlimited swipes and a Featured badge are exactly that, so charging for them with Stripe inside the iOS app gets the app **rejected** — and you cannot link out to a web checkout to dodge it either. The 15–30% cut is the cost of being on the store.

| Tier | Bought where | Rails | Cut |
|---|---|---|---|
| **Student / Teacher premium** | Inside the mobile app | **RevenueCat** (IAP) — mandatory, Guideline 3.1.1 | 15–30% |
| **Institution subscription** | *If* on a **web** dashboard | **Stripe** — legitimate, and the money is worth chasing | ~3% |

> **Decide before the paywall is built:** institutions are businesses buying a recruiting tool — the highest-value subscription we have, and the one where Apple's cut hurts most. If they subscribe on the **web** (sign up and pay on the site; their app account is simply already premium), Stripe is allowed and we keep ~97%. What we may **not** do is put a Subscribe button in the iOS app that opens a Stripe checkout. It has to genuinely be a web product, bought on the web.
>
> The current `InstitutionPaywallScreen` is *in the app*, so as written it commits us to IAP for institutions too. Moving that flow to the web is a product decision, not a code one — make it now, not after the screen ships.

RevenueCat also gives us **Offerings** (the monthly / yearly prices change in their dashboard, not in an app release) and **Restore Purchases**, which Apple rejects apps for omitting. Free up to ~$2.5k/month of tracked revenue, so it costs nothing until it works. The alternative — StoreKit 2 + Play Billing + our own receipt-validation server — is real, but its failure mode is "a paying customer isn't premium", which is the worst bug a subscription app can have.

#### Student & Teacher premium — ✅ **code done, awaiting dashboard setup**

**`functions/src/payments/revenuecatWebhook.ts`** — the single writer of `sub_status`. HTTPS (not callable): RevenueCat is calling us, so there is no Firebase auth context.
- **Grant** on `INITIAL_PURCHASE`, `RENEWAL`, `UNCANCELLATION`, `PRODUCT_CHANGE`, `NON_RENEWING_PURCHASE`, `SUBSCRIPTION_EXTENDED`. **Revoke** on `EXPIRATION`, `SUBSCRIPTION_PAUSED`, `REFUND`, `TRANSFER`.
- **`CANCELLATION` does neither, deliberately.** In the stores, "cancelled" means *auto-renew off* — the subscriber keeps what they paid for until the period ends, and only then does `EXPIRATION` fire. Downgrading on cancellation takes away time they have already paid for: a refund request and a one-star review.
- Writes `sub_status`, `sub_expires_at`, `sub_product_id`, sets the `isPremium` claim, and **for teachers flips `featured`** — FR-3.3's paid perk, which must ride the subscription rather than an admin's memory.
- **Authenticated with a shared secret** (`REVENUECAT_WEBHOOK_SECRET`, `Authorization: Bearer …`), compared in **constant time**, and it **fails closed** if the secret is unset. An unauthenticated endpoint that grants premium grants it to anyone who finds the URL. Returns **5xx on failure so RevenueCat retries** — a dropped `RENEWAL` means a paying customer silently loses premium, the worst bug this system can have.

**Mobile:** `core/purchases/purchase_service.dart` (configure / identify / purchase / restore), `features/premium/` (paywall + upgrade card).
- **`Purchases.logIn(uid)` on every sign-in.** The RevenueCat `app_user_id` **must be** the Firebase uid — it is the only thing tying money taken by Apple to an account of ours. Get it wrong and purchases land on an anonymous id belonging to nobody. `logOut()` on sign-out, so the next person on the phone does not inherit a subscription.
- **No hard-coded prices.** The paywall renders the store's own localised `priceString` from the Offering. A `$4.99` typed into the app is wrong in every other currency and stale the first time you run a promotion. (The prototype had four hard-coded price cards in *three* places; they are gone.)
- **The UI reads `sub_status` from Firestore, not from the RevenueCat SDK cache** (`isPremiumProvider`). The server enforces the quota, so the server is what the UI must agree with — otherwise the app promises unlimited swipes that `recordSwipe` then refuses.
- **Force token refresh after a purchase**, or the `isPremium` claim lags up to an hour and the user pays and sees nothing change.
- **Restore Purchases** on the paywall — Apple rejects subscription apps without it — plus the subscription terms, and Terms/Privacy links (Guideline 3.1.2).
- The teacher's Featured card is **no longer a switch**: it was a local bool pretending the teacher could toggle a perk only the server can grant. It now shows the real `featured` state.

> **TODO [You] — the dashboard half.** The code ships without it and behaves as "subscriptions unavailable", so nothing is blocked.
> 1. **App Store Connect / Play Console:** create **two** auto-renewing subscription products — **Monthly** and **Yearly** (yearly priced a little below 12× monthly) — in one subscription group. Fill in the **paid-apps agreement + banking details**, or products stay in "Missing Metadata" and RevenueCat returns an empty offering.
> 2. **RevenueCat:** create the project, add the iOS + Android apps, import the two products, create **one entitlement called `premium`** (both tiers unlock it — the app never asks *which* package was bought), and put both packages in the **current Offering**.
> 3. **Webhook:** Integrations → Webhooks → URL `https://us-central1-edulinky-86123.cloudfunctions.net/revenuecatWebhook`, Authorization header `Bearer <REVENUECAT_WEBHOOK_SECRET from functions/.env>`. Send a test event and check the function log.
> 4. **Keys:** put the RevenueCat **public SDK keys** in `mobile/dart_defines.json` as `REVENUECAT_IOS_KEY` / `REVENUECAT_ANDROID_KEY` (the file is gitignored — no keys in the repo).
> 5. **Sandbox test:** an App Store Connect sandbox account → buy → confirm `sub_status: "premium"` on the user doc, `featured: true` for a teacher, and the quota banner disappearing.
> 6. **Terms & Privacy pages** must exist at `edulinky.com/terms` and `/privacy` — the paywall links to them, and Apple checks.

#### Institution — still open
Institution gate: `upsertJobCard` re-checks `sub_status`, and the rules check `request.auth.token.isPremium`. **Decide the Stripe-on-web question above first** — it changes where the paywall lives.

**Non-negotiables when this is built:**
- **The server is the only source of truth about who paid.** The webhook writes `sub_status`; the client never does — a client that could set its own subscription state is a client that gets unlimited swipes for free. The Firestore rules already lock `sub_status` against client writes.
- **Verify the webhook.** RevenueCat signs its calls (`Authorization` header); an unauthenticated HTTPS endpoint that grants premium is an endpoint that grants premium *to anyone who finds it*.
- **The custom claim needs a token refresh.** `isPremium` lives in the ID token, so a fresh purchase does not unlock rules-gated writes until the client force-refreshes — do it right after a successful purchase, or the user pays and nothing happens.
- **Downgrade must actually downgrade.** Expiry has to revoke `featured` and put the quota back. A subscription you can cancel while keeping the perks is a subscription nobody renews.
- **Restore purchases** — Apple rejects apps without it (Guideline 3.1.1) when a subscription can be bought.

### Phase 8 — Admin Panel (Next.js Web App)
✅ **DONE.** (The review moderation queue landed with Phase 9.)

**Why before payments:** teacher approvals were still hand-edits in the Firestore console, and `banUser` did not exist at all. RevenueCat needs App Store Connect products and external keys; this needed nothing.

**Bootstrap — the first admin is created out-of-band, on purpose.** `scripts/make-admin.js <email>` sets the claim with the service-account key. `admin` is deliberately **not** in `APP_ROLES`, so it can never be chosen at registration, and `setRole` is itself admin-only. An account that can approve teachers, ban users and read identity documents must not be self-service. (The admin must sign out and back in — the role lives in the ID token.)

**Cloud Functions (`functions/src/admin/adminActions.ts`):**
- `approveTeacher` / `rejectTeacher` — flip `verified_status`. They do **not** notify: `onVerificationChanged` (a Firestore trigger) does, so an approval made any other way still reaches the teacher.
- **`banUser` — sets `is_banned` AND calls `auth.revokeRefreshTokens(uid)` + `updateUser({disabled: true})`.** This is the gap flagged back in Phase 5: an ID token stays valid for up to an hour, so the flag *alone* leaves a banned user able to keep messaging the person they were banned for harassing. The rules also re-read `is_banned` on every message send. **Both halves are required; neither is sufficient.** Admins cannot be banned, and you cannot ban yourself.
- `setFeatured` — the discovery boost (a paid perk, admin-granted).
- **`getCertificateUrls`** — certificates are `allow read: if false` in Storage: *nobody* can read them via a client SDK, including their owner. An admin reviewing a verification must actually see the document, so this mints **15-minute signed URLs** server-side. It is the only way in, and it is audited.
- Every action writes `auditLog/{id}` — actor, action, target, details. **Rules: admin-read, server-write, no update, no delete.** An audit log you can edit is not an audit log.

**Admin app (`admin/`, Next.js 15 + Firebase JS SDK, port 3001):** login → **Verifications** queue (view documents, approve, reject with a reason) → **Users** (filter, feature/unfeature, ban/unban with a reason) → **Audit log**. The UI gate is a *convenience*: hiding it stops an accident, not an attacker. The real gate is server-side — every callable re-checks `role === "admin"` on the ID token.

**Setup [You]:** `cp admin/.env.local.example admin/.env.local` and fill in the Firebase **web** config (console → Project settings → Your apps → Web). Those values are not secrets: they identify the project, they do not grant access.

### Phase 8.5 — Admin email (Resend)
✅ **DONE.**

**Per-user email** (`sendUserEmail`) — transactional: an admin writing to one person about their account. No unsubscribe link; opt-out does not apply.

**Bulk email** (`sendBulkEmail`) — announcements, and treated as such:
- **Opt-out is enforced server-side** (`email_opt_out`), not in the UI. Banned users and admins are skipped too.
- **Every message carries a signed unsubscribe link** + a `List-Unsubscribe` header. Bulk mail without a working unsubscribe is a legal problem (GDPR/CAN-SPAM), not just rude — and it is how a sending domain gets blacklisted.
- **`dryRun` returns the recipient count before anything sends.** The admin UI shows the real number and refuses to compose at zero — an "email everyone" button with no preview is one misclick from a very bad day.
- One bad address never aborts the run; failures are counted.

**`unsubscribe`** (public HTTP fn) — the link is clicked from an inbox with no session, so it is public by necessity. The uid alone proves nothing (anyone could substitute another uid), so the link carries an **HMAC over the uid**, verified with a constant-time compare.

**Config** (`functions/.env`): `RESEND_API_KEY`, `MAIL_FROM`, `MAIL_REPLY_TO`, `UNSUBSCRIBE_SECRET`, `APP_URL`. Sending domain **eduLinky.com is verified in Resend** (SPF/DKIM via the GoDaddy integration).

> **TODO [You]:**
> 1. **Rotate the Resend API key** — the original was pasted into a chat transcript.
> 2. **Mailbox.** `MAIL_REPLY_TO` is currently **empty**, so replies to admin emails bounce. GoDaddy has retired free forwarding; the plan is a **Namecheap Private Email** mailbox (possibly moving the domain there). When it exists: set `MAIL_REPLY_TO` and redeploy — one line.
> 3. **DMARC.** TXT at `_dmarc` → `v=DMARC1; p=none; rua=mailto:...`. Rejects nothing at `p=none`, and it is the single biggest factor in staying out of spam folders.

### Phase 9 — Reviews & Ratings
✅ **DONE.** The `0.0 (0)` that sat on every teacher profile since Phase 3 is now real.

**Who may review whom.** Only **teachers** are reviewed (the spec puts Reviews & Ratings under Teacher Profiles; nobody rates a student), and only by someone they have **matched** with. The match is the price of admission: without it, any signed-in account could one-star a teacher it has never met, which is how a ratings system becomes a weapon and how a competitor's profile gets buried. A **blocked** match does not count either — otherwise "block them, then one-star them" is a two-tap revenge combo.

**Nothing is published on submit.** A review lands as `pending` and an admin releases it (`approveReview`). This is the highest-risk user content in the app — written text about a named person, permanent, on their public profile — and taking it down after the fact is far more expensive than holding it for a look. Editing an approved review sends it **back** to `pending`, or "post something bland, get approved, edit it into abuse" is an open door.

**`functions/src/reviews/`:**
- `submitReview.ts` — callable. Validates rating (integer 1–5), target is a teacher, reviewer is not banned, and the match exists and is not blocked. One review per pair (`{targetId}_{reviewerId}`), so a resubmission **edits** rather than stacks.
- `moderateReview.ts` — `approveReview` / `rejectReview` (admin-only, audited). A rejected review is kept, not deleted: the reviewer sees why, and it is evidence if the same person keeps trying.
- **`onReviewWritten.ts` — the aggregate lives here, not in `approveReview`.** Same reasoning as `onVerificationChanged`: a status changed any other way (console edit, an author pulling their approved review back into moderation, a deletion) must still keep `avg_rating` honest. It applies a **delta** inside a transaction — O(1), and it cannot lose a concurrent increment the way a re-sum would. `rating_sum` is carried on the user doc because an average alone cannot update itself from a delta; it is server-owned and never shown.
- Notifies the teacher **only when a review goes live**. A pending review is not news — it may never be published, and naming the reviewer before an admin has looked invites exactly the retaliation moderation exists to prevent.

**Rules.** `reviews` is server-write-only; readable when `status == "approved"`, plus your own in any state (so the app can say "awaiting approval" rather than appear to have swallowed it), plus admins. A list query only succeeds if *every* document it could return is readable, so the profile must filter on `status == "approved"` — which means **pending and rejected reviews cannot be enumerated**. `avg_rating` / `total_reviews` / `rating_sum` are now locked on the user doc: a self-writable rating is not a rating, and until this phase a client could simply have written itself a 5.0 with 200 reviews.

**Mobile (`features/reviews/`)** — `ReviewsSection` on the public profile: published reviews, your own (with its state), and a star + comment sheet. **Admin (`/reviews`)** — Pending / Approved / Rejected queue.

### Admin alerts — `shared/adminAlert.ts`

Every queue that needs a human now emails **every admin**: a **teacher submitting certificates**, a **report**, and a **review awaiting moderation**. Until this, only reports alerted anyone; a pending teacher just sat there — unable to discover, be discovered, or do anything but wait — until somebody remembered to open the panel.

**Email is the channel, deliberately.** Admins work in the web panel: they have no FCM token and never open the mobile inbox. The in-app notification is still written (it costs one document) but it is not what makes the queue get worked.

Alerts are **best effort** — a failing mailbox must never roll back the thing that triggered it. The teacher's submission, the report and the review are all already in the queue; the email only makes someone look sooner.

> The review alert fires on the **transition into `pending`** — a new review, or an approved one whose author has edited it (which pulls it back off the profile) — not on every write, so an already-pending review does not re-alert.

### Marketing & legal site — `web/`
Standalone **static site** (HTML/CSS, one inline script — no framework, no build), separate from `admin/` so nothing is shared between the public site and the admin panel. **No link to the admin dashboard anywhere, by design.**
- `index.html` (hero + app mockup, how-it-works, roles, **pricing with a billing-period toggle**, safety, FAQ), `privacy/index.html` → `/privacy`, `terms/index.html` → `/terms`. Folder-per-page so the clean URLs the paywall links to (`edulinky.com/terms`, `/privacy`) resolve on any static host.
- **The Terms page carries the App Store Guideline 1.2 EULA clause** — zero tolerance for objectionable content/abusive users + the 24-hour action commitment — which was an outstanding store-compliance item. It also states EduLinky is a *platform*, not an employer/agency (matters for job cards), and the store-billed auto-renew/cancel terms.
- Host on **Netlify** as a static site at the apex domain; admin panel as a **separate Netlify site**. See `web/README.md`.
- **Before publish [You]:** the legal pages are drafts — a lawyer must review them, and the `[BRACKETED]` placeholders (legal entity, address, **minimum age**, governing jurisdiction) must be filled. Confirm the `support@`/`privacy@`/`hello@`/`sales@` addresses exist.

### Hosting — both sites are FREE Netlify static sites from this one repo

Everything lives in one **private** monorepo (`edulinky/mobile`, `main`). The admin is a pure client-side Firebase app — no API routes, server actions, or server-only imports — so it builds to a **static export** (`output: "export"` in `admin/next.config.ts` → `admin/out/`). That means **both** the landing page and the admin deploy as **free Netlify static sites** — always-on, no cold starts, no server bill. (Landing is already live on Netlify.)

| | Landing (`web/`) | Admin (`admin/`) |
|---|---|---|
| Host | Netlify (static) | Netlify (static) |
| Base directory | `web` | `admin` |
| Build command | *(empty)* | `npm run build` |
| Publish directory | `web` | `admin/out` |
| Env vars | none | `NEXT_PUBLIC_FIREBASE_*` (the web config — not secrets) |
| Domain | apex `edulinky.com` | separate site / subdomain |

- **Clean URLs both work out of the box.** `web/` uses folder-index pages; Next's static export emits a real `reports.html` per route, which Netlify serves at `/reports` (no `trailingSlash`, deliberately — it would break the `usePathname` active-nav check).
- **Firebase authorized domains:** add the admin's Netlify domain under Firebase → Auth → Settings → Authorized domains, or the admin's **Google sign-in** popup throws `auth/unauthorized-domain`.
- **No link from the landing page to the admin**, by design — a separate site nobody discovers from the marketing site.
- After the admin is deployed, set `ADMIN_URL` in `functions/.env` to the admin's URL and redeploy `reportUser` + the alert functions, so the "new report / new review / new signup" emails link to the live queue.

### Phase 10 — Polish & Deployment
- **Mobile:** `flutter build appbundle` (Android) + `flutter build ipa` (iOS); submit to Play Store / App Store
- **Admin web:** Netlify static site (static export), base dir `admin/`, build `npm run build`, publish `admin/out`, set `NEXT_PUBLIC_FIREBASE_*`, add the Netlify domain to Firebase authorized domains — free, no cold starts
- **Marketing/legal site:** Netlify static site, base dir `web/`, publish `web`, apex domain (admin as a separate site) — already live
- **Functions:** `firebase deploy --only functions` from monorepo root
- Register RevenueCat webhook URL (Cloud Function HTTPS endpoint) in RevenueCat dashboard
- `firebase deploy --only firestore:rules,storage:rules`

---

## Firestore Security Rules (Key Patterns)

```js
// Helpers
function isOwner(uid) { return request.auth.uid == uid; }
function hasRole(role) { return request.auth.token.role == role; }
function isPremium() { return request.auth.token.isPremium == true; }
function matchExists(matchId) {
  let m = get(/databases/$(database)/documents/matches/$(matchId)).data;
  return m.userA_id == request.auth.uid || m.userB_id == request.auth.uid;
}

// Users: block self-elevation of role/sub_status/verified_status
// Matches: created only by Cloud Functions (Admin SDK bypasses rules); allow false on client
// Messages: only participants can read/write; enforce senderId == auth.uid; text <= 2000 chars
// Swipes & Quotas: write if false (Cloud Functions only)
// JobCards: create only if isPremium() && hasRole("institution")
// Reviews: create only if hasRole("student") && status == "pending"; update only by Cloud Function
```

---

## Critical Files

| File | Why Critical |
|------|-------------|
| `functions/src/swipe/recordSwipe.ts` | Quota transaction logic, geohash query, mutual-swipe detection |
| `functions/src/payments/revenuecatWebhook.ts` | RevenueCat webhook — source of truth for subscription state |
| `functions/src/auth/onRegister.ts` | Sets Custom Claims on signup — root of the entire role system |
| `firestore.rules` | `matchExists()` helper + messages sub-collection rule = most important security boundary |
| `mobile/lib/features/discover/widgets/swipe_card.dart` | Flutter GestureDetector + AnimationController swipe with optimistic UI |
| `mobile/lib/core/firebase/` | Firebase init shared across all Flutter features |
| `admin/src/app/` | Next.js Admin panel — the only web-facing user interface |

---

## Verification (End-to-End Test Scenarios)

1. **Match & Chat:** Register Teacher → upload cert → Admin approves → Student swipes right → Teacher swipes right → match created → both notified via FCM → chat unlocked → messages appear in real-time → non-participant blocked by Firestore rule
2. **Quota enforcement:** Free Student hits swipe limit → quota transaction returns error → upgrade via RevenueCat → webhook fires → `sub_status` flips → unlimited swipes restored
3. **Institution flow:** Register Institution → paywall shown → subscribe → Job Card created → Teacher sees it in swipe stack → right swipe → Institution notified via FCM
4. **Review moderation:** Student submits review → `status: "pending"` → not visible on profile → Admin approves via callable → visible → `avg_rating` updated
5. **Security spot-checks:** Teacher token cannot call admin callables (`permission-denied`); client SDK cannot write to `matches/` directly; client SDK cannot set `role: "admin"` on own user doc; non-participant cannot read another match's messages

---

## Current State (as of this checklist)

The `mobile/` Flutter app is a **UI-only prototype**: all role screens, theme, l10n, routing, and shared widgets exist, but there is **no backend and no Firebase wiring**.

- ❌ No Firebase packages in `mobile/pubspec.yaml`; no `firebase_options.dart`; no `core/firebase/`
- ❌ No `functions/`, `admin/`, `firebase.json`, `firestore.rules`, `storage.rules`
- ❌ No `providers/` — screens hold local state and read **hardcoded mock data** (e.g. `mockTeachers`)
- ❌ Auth is fake — login just calls `context.go('/student/discover')`, no real sign-in
- ⚠️ The `mobile_app/` directory is empty and unused — real code is in `mobile/`. Delete `mobile_app/` to avoid confusion.

**Assets secured:** domain `eduLinky.com` and `edlinky001@gmail.com` (register the Firebase/Google Cloud project under this account). Neither is required to start backend work; they matter later for admin hosting, RevenueCat webhook URL, store listings, and custom-domain email.

---

## Phase 1 & 2 — Execution Checklist (Next Up)

Legend: **[You]** = interactive step requiring your login/console access · **[Me]** = I can do it in-repo.

### Step 0 — Housekeeping [Me] ✅ DONE
- [x] Remove the empty `mobile_app/` directory
- [x] `.gitignore` updated: added `functions/lib/` + `mobile/lib/firebase_options.dart` (the rest was already covered)

### Step 1 — Create the Firebase project [You]
Run these locally and follow the prompts (the `!` prefix in the prompt runs them in this session so I see the output):
- [ ] `npm i -g firebase-tools` (if not installed)
- [ ] `firebase login` → sign in as **edlinky001@gmail.com**
- [ ] Create the project (console is easiest): https://console.firebase.google.com → **Add project** → name `edulinky` → note the **Project ID** (e.g. `edulinky` or `edulinky-xxxxx`)
- [ ] In the Firebase console, enable: **Authentication → Email/Password**, **Firestore → Native mode**, **Storage**, **Cloud Messaging**, and upgrade to **Blaze** plan (required for Cloud Functions)
- [ ] Paste the final **Project ID** back to me

### Step 2 — Wire Firebase into the Flutter app [You + Me]  (project: `edulinky-86123`)
- [ ] **[You]** `dart pub global activate flutterfire_cli` (once)
- [x] **[Me]** Added to `mobile/pubspec.yaml`: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `cloud_functions`
- [ ] **[You]** From `mobile/`, run `flutterfire configure --project=edulinky-86123` → select iOS + Android → generates `lib/firebase_options.dart` + registers app IDs (bundle id `com.edulinky.mobile`)
- [x] **[Me]** `main.dart` → `WidgetsFlutterBinding.ensureInitialized()` + `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` (needs the file above to compile)
- [x] **[Me]** Created `core/firebase/firebase_refs.dart` (`Fb` — auth/firestore/storage/functions singletons)
- [ ] **[You]** From `mobile/`, `flutter pub get` then `flutter run` to confirm the app boots against Firebase

### Step 3 — Scaffold Cloud Functions + rules [You + Me] — scaffold done by hand (no `firebase init` needed)
- [x] **[Me]** Created `firebase.json`, `.firebaserc` (→ `edulinky-86123`), `firestore.rules` + `firestore.indexes.json`, `storage.rules` (both rules default-deny)
- [x] **[Me]** Created `functions/` (TS, 2nd-gen): `package.json`, `tsconfig.json`, `.gitignore`, `.env.example`, `src/{index,health}.ts`, `src/shared/admin.ts` — `npm run build` passes
- [ ] **[You]** `cd functions && npm install` (done once locally; already run during scaffolding — re-run if you re-clone)
- [ ] **[You]** From repo root, `firebase deploy --only functions:health` → confirm it deploys and returns OK
- [ ] **[You]** Optionally deploy rules: `firebase deploy --only firestore:rules,storage:rules`

### Step 4 — Phase 2 Auth & Role System [Me done; You to deploy + test]
- [x] **[Me]** `functions/src/auth/completeRegistration.ts` — callable (not an onCreate trigger, so the UI-chosen role can be passed): `setCustomUserClaims(uid,{role})` + writes `users/{uid}`; idempotent/anti-elevation; teachers get `verified_status:"pending"`
- [x] **[Me]** `functions/src/auth/setRole.ts` — admin-only callable to change role
- [x] **[Me]** `functions/src/shared/roles.ts` — shared role allow-list (`student`/`teacher`/`institution`; excludes `admin`)
- [x] **[Me]** `submitCertification` — landed in Phase 3 (see below)
- [x] **[Me]** Mobile auth layer: `AuthRepository` (firebase_auth + callable wrapper, force-refreshes token), `authStateProvider` (Riverpod `StreamProvider<AppUser?>` resolving the role claim), `AppUser` model
- [x] **[Me]** Replaced fake login/register nav with real `signInWithEmailAndPassword` / `createUserWithEmailAndPassword` + `completeRegistration`; step1 input validation; step3 rollback-on-failure; forgot-password wired
- [x] **[Me]** `go_router` converted to `goRouterProvider` with an auth+role redirect guard (signed-out → `/`; signed-in bounces entry screens → role home)
- [x] **[Me]** `firestore.rules` `users/` rule: server-only create, owner update blocked from changing `role`/`sub_status`/`verified_status`/`is_banned`/`uid`
- [x] **[Me]** Verified: `functions` build ✓, `flutter analyze` clean ✓, unit tests pass ✓
- [ ] **[You]** Deploy: `firebase deploy --only functions:completeRegistration,functions:setRole,firestore:rules --account edlinky001@gmail.com`
- [ ] **[You]** Test end-to-end — see **[TEST_MOBILE.md](TEST_MOBILE.md) § Phase 2** for the full case list (register each role, validation, login, guards, security invariants)

> NOTE: the DEV role picker was removed from the splash screen (the redirect guard made it dead — it bounced unauthenticated navigation back to `/`). Register a real account to test.

### Phase 1–2 Definition of Done
- [ ] Fresh install → register a new account → Firebase Auth user created → `users/{uid}` doc written with correct `role` → app routes to the role's home
- [ ] Sign out / sign back in → lands on correct role home from real auth state (no mock nav)
- [ ] `health` callable reachable from the app
- [ ] Client SDK **cannot** set `role: "admin"` on its own user doc (rules reject)

### Blocking dependency
Everything past Step 0 needs the **Firebase Project ID from Step 1**. That's the single thing gating backend work — create the project and hand me the ID, and I can execute all the **[Me]** items.
