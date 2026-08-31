# Burkes Visitor Welcome — RingCentral signage (GitHub → Netlify)

A self-refreshing welcome page for the shop TVs. RingCentral points at **one URL that
never changes**; the page re-reads `schedule.json` every 30 seconds, so **editing
`schedule.json` on GitHub updates every screen within ~30s** — no URL change, no
RingCentral change, no USB.

## Files
- `welcome.html` — the display page (edit rarely)
- `schedule.json` — **the file you edit to change who's shown** (see "Updating")
- `logos/` — visitor logos referenced by `schedule.json`
- `_headers`, `netlify.toml` — Netlify config (leave alone)

---

## One-time setup

### 1. Put these files in a GitHub repo
Easiest (no git needed):
1. Sign in at https://github.com → **New repository** → name it e.g. `burkes-welcome-signage` → **Create**.
2. On the new repo page → **uploading an existing file** → drag in `welcome.html`,
   `schedule.json`, `_headers`, `netlify.toml`, and the whole `logos` folder → **Commit**.

### 2. Connect Netlify to the repo
1. Sign in at https://app.netlify.com (you can "Sign in with GitHub").
2. **Add new site → Import an existing project → GitHub** → pick the repo.
3. Leave build command empty; publish directory `.` → **Deploy**.
4. Netlify gives you a URL like `https://YOUR-SITE.netlify.app`.
   Your page is at **`https://YOUR-SITE.netlify.app/welcome.html`**.
   (Optional: Site settings → change the site name to something tidy.)

### 3. Point RingCentral at it
RingCentral Admin Portal → **Meetings → Rooms → Rooms List → [room] → Display Settings**:
- **URL** = `https://YOUR-SITE.netlify.app/welcome.html`
- **Operation Time** = **always-on** (leave it — the page owns the schedule via each
  visitor's `start`/`end`, which is more precise than RingCentral's day-of-week timer).
- Do this for each of the rooms (all 8 use the same URL).

### 4. Set the display device to Central Time
The on/off window uses the display device's own clock, so make sure the Rooms device is
set to **Central Time**. Then `06:00`/`17:00` = 6am/5pm CT.

---

## Updating (the whole point)
To change who's shown, edit **`schedule.json`** on GitHub:
1. Open `schedule.json` in the repo → click the **pencil (Edit)** icon.
2. Change or add a visitor, then **Commit changes**.
3. Netlify auto-deploys in ~30–60s; the screens refresh within ~30s after that.

A visitor block:
```json
{
  "company": "Acme Steel",
  "logo": "logos/acme.png",
  "brandColor": "#0057B8",
  "note": "Plant tour, 2 pm",
  "start": "2026-09-10T08:00:00",
  "end":   "2026-09-10T16:00:00"
}
```
- `company` is required; the rest are optional (no `logo` → the big name shows instead).
- New logo? Upload the image into `logos/` in the repo and reference it by that path.
- Times are **local to the display device** (Central Time), no timezone suffix.
- Before/after the window, or when no visitor is active, the screen goes **black**.

Currently loaded: **Clayco, Thursday 9/3, 6:00am–5:00pm** (no-tagline logo).

---

## Notes
- The site is **public** (anyone with the link can view it). It's a lobby welcome screen,
  so low-stakes — just don't put anything sensitive in `note`.
- **Internet-dependent:** if the plant loses internet, the screens can't reach Netlify and
  hold their last state.
- `welcome.html` still contains a `DEMO_SCHEDULE` block used only if `schedule.json` can't
  be reached; it's harmless to leave.
