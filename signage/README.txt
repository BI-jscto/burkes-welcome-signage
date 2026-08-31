BURKES VISITOR WELCOME DISPLAY  —  RingCentral Rooms (Digital Signage) pilot
============================================================================

WHAT'S IN THIS FOLDER
  welcome.html         The display page. Renders the "BURKES WELCOMES" screen
                       live from schedule.json (white house style, brand-color
                       accents + corner brackets). Self-refreshes every 30s.
  schedule.json        The visitor list. THIS is the only file you edit to add
                       or change a visitor. (See "UPDATING" below.)
  logos/               Visitor logos (clayco, gat, rj, isat, ip). Referenced by
                       schedule.json. Local so the screen works with no internet.
  signage-server.ps1   Tiny local web server (no install needed) that serves this
                       folder at http://localhost:8080/.
  README.txt           This file.


ONE-TIME SETUP ON A THINKCENTRE
  1. Copy this whole folder to:  C:\signage\
  2. Register the server to start at boot (run PowerShell AS ADMIN, once):
       $a = New-ScheduledTaskAction -Execute "powershell.exe" `
         -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\signage\signage-server.ps1"
       $t = New-ScheduledTaskTrigger -AtStartup
       $p = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
       Register-ScheduledTask -TaskName "SignageServer" -Action $a -Trigger $t -Principal $p
       Start-ScheduledTask -TaskName "SignageServer"
     Verify: open http://localhost:8080/welcome.html in a browser — you should
     see the Clayco pilot screen.
  3. RingCentral Admin Portal:
       Meetings -> Rooms -> Add Room -> Room Type = "Digital Signage Only" (Windows)
       In that room's Digital Signage settings, add content of type URL / web page:
            http://localhost:8080/welcome.html
       Set Operation Time = always-on (24/7). The PAGE owns hours + overnight black.
  4. On the ThinkCentre: install the RingCentral Rooms app, sign in, and pair it
     to that Digital Signage room with the activation code from the portal.
     It then shows the URL fullscreen on the Vizio (HDMI-1).

  (Each Digital Signage Only room needs a RingCentral Rooms license — 8 screens = 8.
   Confirm licensing + that the server task runs on boot with TUSCOM.)


UPDATING THE DISPLAY EACH TIME  ***  the important part  ***
  To add or change a visitor you edit ONE file: schedule.json.
  Add an object to the "visitors" list:

      {
        "company": "Acme Steel",              <- required
        "logo": "logos/acme.png",             <- optional (drop the file in logos/)
        "brandColor": "#0057B8",              <- optional (their brand color)
        "note": "Plant tour, 2 pm",           <- optional
        "start": "2026-09-10T08:00:00",       <- local time, no timezone
        "end":   "2026-09-10T16:00:00"
      }

  Save the file. The screen reloads it within 30 seconds — no image to make,
  no thumb drive, no RingCentral change. If the visitor has no logo, leave "logo"
  out and the big company name shows instead. Overlapping visitors rotate every 12s.

  GETTING THE EDIT TO ALL 8 SCREENS (pick one):
    * Simplest now:  keep C:\signage on each PC in a OneDrive-synced folder, so
      editing schedule.json once syncs to all eight.
    * Central option: host schedule.json in Azure Blob (static website) and set
      CONFIG.scheduleUrl in welcome.html to that URL — then you edit one file and
      every screen reads it. (Keep welcome.html + logos local so screens survive an
      internet outage.) New logos still need to reach each PC's logos\ folder.
    * Automated (goal): Power Automate writes schedule.json from a visitor email,
      so no one hand-edits at all.


BEFORE PRODUCTION (checklist)
  [ ] Replace the wide-window Clayco pilot row in schedule.json with real visits.
  [ ] Remove DEMO_SCHEDULE + its fallback branch in welcome.html (marked in the file).
  [ ] Confirm operating hours in welcome.html CONFIG.hours (default Mon-Fri 06:00-17:00).
  [ ] Test ONE screen end to end before rolling to the other seven.
  [ ] Decide overnight: black screen (burns backlight) vs. cutting the panels via CEC.
