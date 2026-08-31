@echo off
REM ============================================================
REM  Burkes Visitor Welcome Display - kiosk launcher (STARTER)
REM  Target: the Lenovo ThinkCentre behind each Vizio screen.
REM  Double-click to test now, or set to auto-start (notes below).
REM  Edit DISPLAY_URL once the page is hosted.
REM  Full spec: Visitor-Welcome-Display-BRIEF.md (Task 2).
REM ============================================================

REM --- The one URL every screen points at (replace when hosted) ---
set "DISPLAY_URL=https://REPLACE-WITH-HOSTED-URL/welcome-display.html"

REM --- Single-TV test WITHOUT a backend: uncomment to force a welcome ---
REM set "DISPLAY_URL=https://REPLACE-WITH-HOSTED-URL/welcome-display.html?company=Accelevation&domain=accelevation.com&color=E8822A"

REM --- Locate Microsoft Edge (falls back to 64-bit path) ---
set "EDGE=%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
if not exist "%EDGE%" set "EDGE=%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
if not exist "%EDGE%" (
  echo Microsoft Edge not found. Point EDGE in this script at your browser.
  pause
  exit /b 1
)

REM --- Launch full-screen kiosk; relaunch if it closes (basic self-heal) ---
:loop
"%EDGE%" --kiosk "%DISPLAY_URL%" --edge-kiosk-type=fullscreen ^
  --no-first-run --no-default-browser-check --disable-features=Translate ^
  --overscroll-history-navigation=0 --disable-pinch
timeout /t 3 /nobreak >nul
goto loop

REM ============================================================
REM  NOTES
REM  - Exit kiosk while testing: Alt+F4  (or Ctrl+W)
REM  - Auto-start on login: Win+R -> shell:startup -> drop a
REM    shortcut to this .bat there.
REM  - Hardened, self-healing boot + lockdown (assigned access,
REM    input disable, allow-list) belongs in Task Scheduler /
REM    Windows kiosk mode -- see BRIEF Task 2. This .bat is the
REM    quick starter for the one-TV pilot, not the final lockdown.
REM ============================================================
