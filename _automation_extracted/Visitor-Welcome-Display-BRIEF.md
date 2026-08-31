# Visitor Welcome Display — Project Brief

Purpose: greet visiting companies on the shop-floor screens automatically. When a
visitor is scheduled, every screen shows "BURKES WELCOMES [company]" with the
visitor's logo and brand colors; between visits the screens show a Burkes standby
slide. Runs and updates remotely — no site visits for day-to-day operation.

This brief is the source of truth for the build. Companion files in this folder:
`welcome-display-remote-plan.pdf` / `.docx` (shareable overview + lockdown),
`welcome-kiosk.html` (early prototype — superseded by Task 1 below), and the
Accelevation slide PNG (brand reference).

---

## Hardware (confirmed on site)

- **8 screens.** Each is a **Vizio V4K50M-0809** (V-Series, SmartCast, firmware
  86.710.29.1-1). Important: **SmartCast has no web browser** — the display cannot
  run on the TV itself.
- **Behind each screen: a Lenovo ThinkCentre Tiny** (Windows mini-PC) driving the
  TV over **HDMI-1**. Each station has a keyboard + mouse on a pull-down tray.
- **The Lenovo is the device we target.** The TV is just a panel on HDMI-1.
- These mini-PCs may double as work machines — treat the welcome as a
  **non-destructive overlay** (comes up for the visit window, bows out after),
  not a permanent takeover, unless a station is confirmed dedicated.

### Vizio settings to set on each TV (one-time)
- **Input at Power On → Last Used TV Input** (returns to the Lenovo on power-up).
- **Auto Power Off → Off** (currently 10 min; would kill the display mid-visit).
- Power Mode → Quick Start (optional; faster wake, keeps CEC responsive).

---

## Architecture (remote model)

1. **Display page hosted once** in the cloud (Azure Static Web Apps or a Blob
   static website fits the Microsoft 365 stack). One URL used by all 8 PCs.
2. **`schedule.json` hosted alongside** (or in OneDrive/SharePoint). The page
   polls it every ~15s and shows whatever is active.
3. **Power Automate writes `schedule.json`** from a saved visitor email.
4. **Each Lenovo runs Edge in kiosk mode** pointed at the URL, autostart on login.
5. **Remote management** (Intune / RDP over the shop network / remote-access tool)
   for updates — so nothing requires a physical visit after initial setup.

---

## Display page spec (Task 1 — the centerpiece)

Single self-contained HTML file. Two states, driven entirely by data + clock:

- **Standby** — Burkes-branded holding screen (between visits).
- **Welcome** — "BURKES WELCOMES" eyebrow + company name; visitor logo; themed to
  the visitor's brand color; optional visitor name line.

### Brand tokens (from the Accelevation slide)
- Background charcoal `#141417`; accent orange `#E8822A`; text white/`#EAEDF0`.
- Motifs: orange corner registration brackets, faint blueprint grid, top/bottom
  accent bars, condensed industrial type.
- Burkes tagline available for standby: `SAFETY · QUALITY · PRODUCTIVITY`.
- **Per-visitor theming:** the welcome adopts the visitor's logo + brand color;
  standby stays Burkes orange.

### Data contract — `schedule.json`
```json
{
  "visits": [
    {
      "company": "Accelevation",
      "domain": "accelevation.com",
      "visitorName": "Marcus Reed — Procurement",
      "logoUrl": "",
      "accentColor": "#E8822A",
      "startsAt": "2026-07-15T13:00:00Z",
      "expiresAt": "2026-07-15T22:00:00Z"
    }
  ]
}
```
- Page selects the visit whose `[startsAt, expiresAt]` window contains "now".
  If none is active → **standby**. This gives "only on the day of the visit" in data.

### Logo + color resolution (in priority order)
1. Explicit `logoUrl` / `accentColor` if provided.
2. Else look up by `domain` via a logo API (Logo.dev or Brandfetch — both by-domain,
   free tiers, API key in config, **not committed**). Note: the old free Clearbit
   logo endpoint was shut down Dec 2025 — do not use it.
3. Else **monogram fallback** — company initials in a badge, in `accentColor`.
- Must degrade gracefully with **no network** (monogram path), for shop Wi-Fi gaps.

### Always-on hygiene
- Poll with cache-busting; smooth state transitions; subtle burn-in guard
  (slow drift) since panels run for long stretches; never show a blank/No-Signal
  state — always land on standby.

### Test affordance
- Support URL query params to force a welcome without a backend, e.g.
  `?company=Accelevation&domain=accelevation.com&color=E8822A` — for single-TV testing.

---

## Windows kiosk + launcher (Task 2)

- Launch Edge kiosk: `msedge --kiosk <URL> --edge-kiosk-type=fullscreen --no-first-run`.
- **Autostart** on login (Startup folder or Task Scheduler); **self-heal**
  (relaunch if closed). Optional **wake timer** (Task Scheduler) to power the PC
  on ahead of a scheduled visit.
- The launcher is also the natural host for the small agent that reads the
  schedule / triggers CEC.

## Lockdown & security (Task 2, cont.)
- **Windows assigned access / kiosk mode** locks the PC to the single browser app —
  no desktop, Start menu, or other apps. **Requires Windows Pro or Enterprise —
  VERIFY the edition on each machine** (Settings › System › About). Home lacks
  assigned access; upgrade or use a lighter lock.
- Locked browser (no address bar/tabs/downloads); **allow-list only the display URL**
  + its logo/schedule source.
- **Disable or remove the station keyboard/mouse** so there's nothing to browse with.
- **Isolated network segment / VLAN** so these PCs reach only what the display needs
  and nothing on the company network — set up by the shop's network admin. This is
  the primary control for "keep the shop floor off the company network."

## Optional: CEC power control (Task 3 — nice-to-have)
- Windows HDMI out has no usable native CEC → needs a **USB-CEC adapter**
  (Pulse-Eight, ~$50) per Lenovo.
- Use libcec / `cec-client` to send standby + image-view-on on the visit schedule:
  wake the panel before a visit, standby after. Without this, screens simply revert
  to standby between visits (panel stays on, or the TV's own timer goes dark).

## Power Automate flow (Task 4)
- Trigger: file created in the visitor folder (OneDrive/SharePoint).
- Steps: extract company + domain (structured template you fill in, or AI Builder) →
  optionally resolve logo/color → upsert the visit into `schedule.json` at the host
  or shared location. Include `startsAt` / `expiresAt` for the visit window.

---

## One-TV pilot test (Task 5)
On one station: set the two Vizio settings above; point Edge kiosk at the hosted URL
(or open the HTML locally); force a welcome via query string (use Accelevation);
verify standby ↔ welcome switching, logo vs. monogram fallback, color theming, and
clean exit. Optional: test CEC on/off if an adapter is fitted.

Needed on the test machine: a login (admin ideal for autostart/lockdown), Edge or
Chrome, internet if testing live logo lookup (else a logo PNG), and one real
visitor's company + domain.

---

## Open decisions (not blocking the display page build)
- Windows edition per machine (Pro?) — sets the kiosk-lockdown method.
- Network segmentation status — is there an isolated VLAN already?
- Hosting choice — Azure Static Web Apps vs Blob static website.
- Logo/color source — Logo.dev / Brandfetch API key, or a curated logo library for
  regular visitors.
- Where `schedule.json` lives and exactly how Power Automate writes to it.
