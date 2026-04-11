# EduLink Platform — Full MVP (Phase 1) Implementation Plan

## Context

EduLink is a greenfield Tinder-style education recruitment platform connecting Students, Teachers, and Institutions. The requirements document defines a swipe-based discovery engine, RBAC via Firebase Custom Claims, real-time messaging gated on mutual matches, Stripe/RevenueCat subscription tiers, and an Admin moderation panel.

**Architecture split:**
- **Mobile app (Flutter)** — Student, Teacher, Institution users (iOS & Android)
- **Admin web app (Next.js 14)** — Admin panel only, browser-based
- **Backend (Node.js/Express)** — shared API for both clients
- **Firebase** — shared Auth, Firestore, Storage

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
│   │   │   ├── api/           # Dio HTTP client → Express backend
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
├── server/                    # Node.js / Express (shared backend)
│   └── src/
│       ├── routes/            # auth, users, swipe, matches, jobs, payments, admin, reviews
│       ├── controllers/       # auth, swipe, match, payment, admin, review
│       ├── middleware/        # verifyToken, requireRole, requirePremium, rateLimiter, errorHandler
│       ├── services/          # auth, swipe, match, payment, notification, admin
│       └── models/            # Typed Firestore interfaces
│
├── firestore.rules
├── storage.rules
└── firebase.json
```

---

## Implementation Order (10 Phases)

### Phase 1 — Scaffold & Infrastructure
- Monorepo root with `mobile/`, `admin/`, `server/` directories; shared `.gitignore`
- Firebase project: enable Firestore (Native), Auth (Email/Password), Storage, Messaging (FCM)
- **Mobile:** `flutter create mobile`; add to `pubspec.yaml`: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `go_router`, `flutter_riverpod`, `dio`, `google_maps_flutter`, `geoflutterfire_plus`
- **Admin:** `create-next-app` with App Router + TypeScript; install `firebase`, `axios`; create `tokens.css` with Sky Blue CSS vars
- **Server:** Express with `helmet`, `cors`, `express.json()`, `/health` route; Firebase Admin SDK init

### Phase 2 — Auth & Role System
- `server/src/middleware/verifyToken.ts` — decode `Authorization: Bearer <idToken>` via `admin.auth().verifyIdToken()`
- `server/src/services/auth.service.ts` — `setUserRole(uid, role)` calls `admin.auth().setCustomUserClaims(uid, { role })`
- `POST /auth/register` — creates Firebase Auth user, sets custom claim, writes `users/{uid}` doc
- **Mobile:** `AuthNotifier` (Riverpod `AsyncNotifier`) — wraps `firebase_auth`; after sign-in call `user.getIdTokenResult(forceRefresh: true)` to get the custom claim. 3-screen registration flow: credentials → `RoleSelector` widget (glassmorphism cards) → display name. Calls Express backend for registration (not Firebase directly).
- **Admin:** Email/Password login page; `middleware.ts` checks Firebase session cookie; redirects non-admin to `/login`
- Teacher cert upload: `POST /users/:uid/certification` sets `verified_status: "pending"` + `cert_url`
- Mobile route guards via `go_router` redirect callbacks reading auth state from Riverpod

### Phase 3 — Profile System
- Full `users/{uid}` Firestore schema: uid, role, sub_status, geo_location (lat/lng/geohash/city), verified_status, cert_url, video_links, gallery, qualifications, experience, availability, avg_rating, total_reviews, is_banned, featured
- **Mobile:** Tabbed `ProfileEditScreen` — auto-saves on field change (debounced 800ms → `PATCH /users/:uid`); gallery upload via `image_picker` + Firebase Storage → `gallery/{uid}/{uuid}.jpg`, max 6 photos; `VideoEmbedWidget` using `webview_flutter` for YouTube/TikTok/Vimeo; `ScheduleGrid` widget — 7×12 time-slot toggle
- Public profile view screen — Verified/Pending/Featured `BadgeChip` widgets

### Phase 4 — Discovery / Swipe Engine
**Backend (`swipe.service.ts`):**
- `getCandidates(user, filters)` — role-based target collection; Geohash bounding box via `geofire-common`; exclude already-swiped profiles from `swipes/{uid}/sent/` sub-collection; return batch of 10
- `recordSwipe(uid, targetId, direction, targetType)` — **Firestore transaction** on `swipeQuotas/{uid}` (prevents race conditions); enforce 15+5 free quota; write to `swipes/{uid}/sent/{targetId}`; check mutual right swipe → call `match.service.ts`
- `GET /swipe/candidates`, `POST /swipe`

**Mobile (Flutter):**
- `SwipeNotifier` (Riverpod) — pre-loads 10 cards, refetches in background when 3 remain
- `SwipeCard` widget — `GestureDetector` with `onPanUpdate`/`onPanEnd`; card offset driven by `AnimationController`; LIKE/PASS stamp `Opacity` interpolated from drag delta. **Optimistic UI** — animate immediately, call `POST /swipe` in background via Dio
- `SwipeStack` widget — top 3 cards in a `Stack` with `Transform.scale(0.95/0.90)` for deck illusion
- `QuotaBanner` widget — circular progress indicator with remaining swipes count

### Phase 5 — Matching & Messaging
- `match.service.ts` `createMatch(a, b)` — deterministic `matchId = [a,b].sort().join("_")`; writes `matches/{matchId}`; writes notifications for both users; sends FCM push notification via `firebase_messaging`
- **Mobile:** `MatchesNotifier` (Riverpod) — Firestore `snapshots()` stream on matches where user is participant
- Messages: `matches/{matchId}/messages/{msgId}` sub-collection; `MessagesNotifier` streams `snapshots()` ordered by timestamp; load last 50 on mount
- `ChatScreen` — `ListView` auto-scrolls to bottom; own messages Sky Blue, received messages glassmorphism `Container`
- FCM push notifications for new messages when app is backgrounded (`firebase_messaging` `onBackgroundMessage`)

### Phase 6 — Job Cards
- `jobCards/{jobId}` schema: inst_id, title, subject, description, location, salary_range, contract_type, video_url, status, createdAt
- Institution dashboard screen (requires `role == "institution" && isPremium`) with `JobCardForm` widget
- Teacher swipe queue merges `users` (students) + `jobCards` documents from backend
- Teacher right swipe on Job Card → `notifyInstitution()` writes Firestore notification + FCM push to Institution

### Phase 7 — Payments (RevenueCat)
- Use **RevenueCat** (`purchases_flutter` package) rather than direct Stripe — handles iOS App Store + Google Play billing natively, which is required for in-app purchases on mobile
- Configure RevenueCat dashboard: link App Store Connect + Google Play; create Offerings for Monthly, 3m, 6m, 1yr tiers
- `Purchases.purchasePackage(package)` in Flutter — RevenueCat handles the native payment sheet
- RevenueCat webhook → `POST /payments/revenuecat-webhook` on Express: on `INITIAL_PURCHASE` / `RENEWAL`: update Firestore `sub_status → "premium"` + set `isPremium: true` Custom Claim; on `EXPIRATION` / `CANCELLATION`: revert
- `requirePremium.ts` middleware — checks `req.user.isPremium` from decoded token
- Institution paywall: full-screen `PaywallScreen` shown when `role == "institution" && !isPremium`

### Phase 8 — Admin Panel (Next.js Web App)
- Admin claim set manually via one-time script (`setCustomUserClaims(uid, { role: "admin" })`)
- `GET /admin/verifications` — query `verified_status === "pending"`; approve/reject endpoints
- `GET /admin/reviews/pending`; approve/reject updates `avg_rating` + `total_reviews` on teacher doc
- `POST /admin/users/:uid/ban` — sets `is_banned: true`, calls `admin.auth().revokeRefreshTokens(uid)`
- `is_banned` check in `verifyToken.ts` (Firestore read, cached 60s)
- Audit log: write `auditLog/{logId}` on every Admin action
- **Admin web app deployed separately** to Vercel (root dir `admin/`)

### Phase 9 — Reviews & Ratings
- `POST /reviews` — validate match exists between student and teacher, write with `status: "pending"`
- Only `status === "approved"` reviews visible on public profile
- `avg_rating` / `total_reviews` are denormalized on the user document (updated on Admin approval)

### Phase 10 — Polish & Deployment
- **Mobile:** `flutter build appbundle` (Android) + `flutter build ipa` (iOS); submit to Play Store / App Store
- **Admin web:** Vercel deployment, root dir `admin/`, set `NEXT_PUBLIC_*` env vars
- **Server:** Render deployment, root dir `server/`, start command `npm run start`
- Register RevenueCat webhook URL in RevenueCat dashboard
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
// Matches: created only by backend (Admin SDK bypasses rules); allow false
// Messages: only participants can read/write; enforce senderId == auth.uid; text <= 2000 chars
// Swipes & Quotas: write if false (backend only)
// JobCards: create only if isPremium() && hasRole("institution")
// Reviews: create only if hasRole("student") && status == "pending"; update only by Admin
```

---

## Critical Files

| File | Why Critical |
|------|-------------|
| `server/src/services/swipe.service.ts` | Quota transaction logic, geohash query, mutual-swipe detection |
| `server/src/services/payment.service.ts` | RevenueCat webhook — source of truth for subscription state |
| `server/src/middleware/verifyToken.ts` | Root trust anchor for all backend authorization |
| `firestore.rules` | `matchExists()` helper + messages sub-collection rule = most important security boundary |
| `mobile/lib/features/discover/widgets/swipe_card.dart` | Flutter GestureDetector + AnimationController swipe with optimistic UI |
| `mobile/lib/core/firebase/` | Firebase init shared across all Flutter features |
| `admin/src/app/` | Next.js Admin panel — the only web-facing user interface |

---

## Verification (End-to-End Test Scenarios)

1. **Match & Chat:** Register Teacher → upload cert → Admin approves → Student swipes right → Teacher swipes right → match created → both notified → chat unlocked → messages appear in real-time → non-participant blocked by Firestore rule
2. **Quota enforcement:** Free Student hits 15+5 limit → `429` returned → upgrade via Stripe test card `4242...` → webhook fires → `sub_status` flips → unlimited swipes restored
3. **Institution flow:** Register Institution → paywall shown → subscribe → Job Card created → Teacher sees it in swipe stack → right swipe → Institution notified
4. **Review moderation:** Student submits review → `status: "pending"` → not visible on profile → Admin approves → visible → `avg_rating` updated
5. **Security spot-checks:** Teacher token cannot call admin endpoints (`403`); client SDK cannot write to `matches/` directly; client SDK cannot set `role: "admin"` on own user doc; non-participant cannot read another match's messages
