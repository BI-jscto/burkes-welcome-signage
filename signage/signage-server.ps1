# ============================================================
#  Burkes Visitor Welcome Display - local static server
#  Serves this folder on http://localhost:8080/ with no
#  dependencies (uses .NET HttpListener, built into Windows).
#  RingCentral Digital Signage points at:
#     http://localhost:8080/welcome.html
#
#  Run at boot via a Scheduled Task set to "highest privileges"
#  (see README.txt) so the URL is up before RingCentral loads it.
# ============================================================

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$prefix = "http://localhost:8080/"

$types = @{
  ".html"="text/html; charset=utf-8"; ".htm"="text/html; charset=utf-8"
  ".json"="application/json; charset=utf-8"; ".js"="text/javascript"
  ".css"="text/css"; ".png"="image/png"; ".jpg"="image/jpeg"; ".jpeg"="image/jpeg"
  ".svg"="image/svg+xml"; ".gif"="image/gif"; ".ico"="image/x-icon"
  ".webp"="image/webp"; ".woff2"="font/woff2"; ".mp4"="video/mp4"
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Serving '$root' at $prefix  (Ctrl+C to stop)"

while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $rel = [System.Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart("/"))
    if ([string]::IsNullOrWhiteSpace($rel)) { $rel = "welcome.html" }
    $path = Join-Path $root $rel

    # keep requests inside the served folder
    $full = [System.IO.Path]::GetFullPath($path)
    if (-not $full.StartsWith([System.IO.Path]::GetFullPath($root))) {
      $ctx.Response.StatusCode = 403; $ctx.Response.Close(); continue
    }

    if (Test-Path $full -PathType Leaf) {
      $ext = [System.IO.Path]::GetExtension($full).ToLower()
      $ct = $types[$ext]; if (-not $ct) { $ct = "application/octet-stream" }
      $bytes = [System.IO.File]::ReadAllBytes($full)
      $ctx.Response.ContentType = $ct
      $ctx.Response.Headers.Add("Cache-Control", "no-store")
      $ctx.Response.ContentLength64 = $bytes.Length
      $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $ctx.Response.StatusCode = 404
    }
    $ctx.Response.Close()
  } catch {
    try { $ctx.Response.StatusCode = 500; $ctx.Response.Close() } catch {}
  }
}
