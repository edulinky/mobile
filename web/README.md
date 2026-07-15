# EduLinky — marketing & legal site

A **standalone static site** (plain HTML/CSS, one tiny inline script). No build
step, no framework, no dependencies. Deliberately separate from `admin/` so the
public site and the admin panel share nothing — **there is no link to the admin
dashboard anywhere on this site, by design.**

```
web/
  index.html        landing page (hero, how it works, roles, pricing, safety, FAQ)
  privacy/index.html  Privacy Policy   → /privacy
  terms/index.html    Terms & Conditions → /terms
  styles.css        shared styles (mirrors the app's "sky" theme, light + dark)
```

The pages live in folders (`privacy/index.html`, `terms/index.html`) so the URLs
resolve cleanly as `/privacy` and `/terms` on any static host — **which is exactly
what the app's paywall links to** (`edulinky.com/terms`, `edulinky.com/privacy`).

## Local preview

```
cd web && python3 -m http.server 8080   # then open http://localhost:8080
```

## Hosting (Render, alongside the admin dashboard)

Deploy as a **Static Site**, separate from the admin **Web Service**:

- New → Static Site → this repo
- **Root Directory:** `web`
- **Build Command:** *(leave empty)*
- **Publish Directory:** `.`
- **Build Filter (Included Paths):** `web/**`
- Point the apex domain **edulinky.com** at this static site. Host the admin panel
  on a **separate subdomain** (e.g. `admin.edulinky.com`) — never linked from here.

Any static host works identically (Netlify, Cloudflare Pages, Firebase Hosting,
an S3 bucket). The clean `/privacy` and `/terms` URLs work out of the box because
of the folder structure.

## ⚠️ Before you publish — fill these in

The legal pages are **solid drafts, not legal advice.** Have a qualified lawyer
review them for your operating market (Vietnam first, plus GDPR/CCPA if you serve
those users). Search both legal files for `[BRACKETS]` and replace:

- `[COMPANY LEGAL NAME]` — your registered entity
- `[REGISTERED ADDRESS]`
- `[MINIMUM AGE]` — **a real product + legal decision.** An education app that
  matches students with teachers and opens private chat needs a deliberate age
  policy (and possibly parental-consent handling). Do not ship the default blank.
- `[GOVERNING JURISDICTION]` — for the Terms

Also confirm the email addresses referenced across the site actually exist and are
monitored: `support@`, `privacy@`, `hello@`, `sales@` `@edulinky.com`. They can all
forward to one inbox for now.

## Notes

- **Pricing** on the landing page is *indicative* and marked as such — the real
  price is set by the App Store / Google Play in the buyer's local currency. If you
  change the plan structure, update the `.toggle` buttons and the plan cards in
  `index.html`.
- The site is theme-aware (light/dark via `prefers-color-scheme`) and responsive.
- Fonts load from Google Fonts. If you'd rather self-host Inter (no external
  request), drop the `<link>` tags and add the font files locally.
