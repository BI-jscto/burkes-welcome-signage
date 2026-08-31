import base64, io, json, os
from PIL import Image

BASE = r"C:/Users/nseamon/Burkes Intelligence & Engineering/Burkes Intelligence - Burkes_Intelligence_Main/Operations/Visitor Welcome Screens"

# --- IP logo: inline SVG as data URI (vector, crisp) ---
with open(os.path.join(BASE, "IP Logo.svg"), "r", encoding="utf-8") as f:
    ip_svg = f.read()
ip_uri = "data:image/svg+xml;base64," + base64.b64encode(ip_svg.encode("utf-8")).decode()

# --- Burkes logo: downscale, embed as PNG data URI ---
b = Image.open(os.path.join(BASE, "burkes_mechanical_logo.png")).convert("RGBA")
# trim transparent margins
bbox = b.getbbox()
if bbox: b = b.crop(bbox)
w = 1400
b = b.resize((w, round(b.height * w / b.width)), Image.LANCZOS)
buf = io.BytesIO(); b.save(buf, "PNG")
burkes_uri = "data:image/png;base64," + base64.b64encode(buf.getvalue()).decode()

# --- GAT logo: white-bg raster; trim near-white margins, downscale, embed ---
import numpy as np
g = Image.open(os.path.join(BASE, "GAT_Logo_4k.png")).convert("RGB")
ga = np.asarray(g)
gmask = ~((ga[:,:,0]>235)&(ga[:,:,1]>235)&(ga[:,:,2]>235))
gys, gxs = np.where(gmask)
pad = 12
g = g.crop((max(gxs.min()-pad,0), max(gys.min()-pad,0),
            min(gxs.max()+pad, g.width), min(gys.max()+pad, g.height)))
gw = 1500
g = g.resize((gw, round(g.height * gw / g.width)), Image.LANCZOS)
gbuf = io.BytesIO(); g.save(gbuf, "PNG")
gat_uri = "data:image/png;base64," + base64.b64encode(gbuf.getvalue()).decode()

# --- Embedded schedule (drives display offline today) ---
schedule = {
  "_note": "Embedded fallback schedule baked into the page for offline/USB use. When hosted, an external schedule.json overrides this.",
  "visits": [
    {
      "company": "International Paper",
      "domain": "internationalpaper.com",
      "visitorName": "",
      "subline": "PINE HILL",
      "theme": "light",
      "accentColor": "#006963",
      "startsAt": "2026-07-09T00:00:00Z",
      "expiresAt": "2026-07-10T05:00:00Z"
    },
    {
      "company": "GAT Finishing Systems",
      "domain": "gatfinishing.com",
      "visitorName": "",
      "subline": "",
      "theme": "light",
      "bg": "#ffffff",
      "accentColor": "#004888",
      "startsAt": "2026-07-23T00:00:00Z",
      "expiresAt": "2026-07-24T05:00:00Z"
    }
  ]
}

with open(os.path.join(BASE, "_build", "welcome-display.template.html"), "r", encoding="utf-8") as f:
    tpl = f.read()

out = (tpl
       .replace("__IP_LOGO__", ip_uri)
       .replace("__GAT_LOGO__", gat_uri)
       .replace("__BURKES_LOGO__", burkes_uri)
       .replace("__SCHEDULE_JSON__", json.dumps(schedule, ensure_ascii=False)))

outpath = os.path.join(BASE, "welcome-display.html")
with open(outpath, "w", encoding="utf-8") as f:
    f.write(out)

# Also write the external schedule.json (for future hosted use)
with open(os.path.join(BASE, "schedule.json"), "w", encoding="utf-8") as f:
    json.dump(schedule, f, ensure_ascii=False, indent=2)

print("wrote", outpath, round(os.path.getsize(outpath)/1024), "KB")
print("burkes uri KB:", round(len(burkes_uri)/1024), " ip uri KB:", round(len(ip_uri)/1024))
