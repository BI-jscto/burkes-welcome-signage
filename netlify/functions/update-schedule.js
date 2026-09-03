/* Netlify Function: safely update schedule.json in the GitHub repo.
   The form (admin.html) POSTs here. The GitHub token lives ONLY in this
   function's environment (never in the page). Requires these Netlify
   environment variables:
     GITHUB_TOKEN   fine-grained token with Contents: Read and write on the repo
     GITHUB_REPO    "owner/repo"  e.g. "BI-jscto/burkes-welcome-signage"
     GITHUB_BRANCH  optional, defaults to "main"
     EDIT_PASSWORD  the shared password the form must send
*/
function resp(code, obj) {
  return { statusCode: code, headers: { "Content-Type": "application/json" }, body: JSON.stringify(obj) };
}
function clean(v) {
  const out = { company: String(v.company || "").trim() };
  if (v.logo) out.logo = String(v.logo);
  if (v.brandColor) out.brandColor = String(v.brandColor);
  out.note = v.note ? String(v.note) : "";
  if (v.start) out.start = String(v.start);
  if (v.end) out.end = String(v.end);
  return out;
}

exports.handler = async (event) => {
  if (event.httpMethod !== "POST") return resp(405, { error: "Method not allowed" });

  let body;
  try { body = JSON.parse(event.body || "{}"); }
  catch { return resp(400, { error: "Bad request body" }); }

  const { password, action, visitor, match } = body;
  if (!process.env.EDIT_PASSWORD || password !== process.env.EDIT_PASSWORD)
    return resp(401, { error: "Wrong password." });

  const token  = process.env.GITHUB_TOKEN;
  const repo   = process.env.GITHUB_REPO;
  const branch = process.env.GITHUB_BRANCH || "main";
  if (!token || !repo)
    return resp(500, { error: "Server not configured: set GITHUB_TOKEN and GITHUB_REPO in Netlify." });

  const api = `https://api.github.com/repos/${repo}/contents/schedule.json`;
  const gh = (url, opts = {}) => fetch(url, {
    ...opts,
    headers: {
      "Authorization": `Bearer ${token}`,
      "Accept": "application/vnd.github+json",
      "User-Agent": "burkes-signage-admin",
      ...(opts.headers || {})
    }
  });

  // 1) read the current file (need its sha to commit)
  let cur;
  try {
    const r = await gh(`${api}?ref=${encodeURIComponent(branch)}`);
    if (!r.ok) return resp(502, { error: `Could not read schedule.json (GitHub ${r.status}).` });
    cur = await r.json();
  } catch (e) {
    return resp(502, { error: "Could not reach GitHub to read the schedule." });
  }

  let data;
  try { data = JSON.parse(Buffer.from(cur.content, "base64").toString("utf8")); }
  catch { data = {}; }
  if (!Array.isArray(data.visitors)) data.visitors = [];

  // 2) apply the change
  let msg;
  if (action === "add") {
    if (!visitor || !String(visitor.company || "").trim())
      return resp(400, { error: "Company is required." });
    data.visitors.push(clean(visitor));
    msg = `signage: add ${clean(visitor).company}`;
  } else if (action === "remove") {
    if (!match) return resp(400, { error: "Nothing specified to remove." });
    const before = data.visitors.length;
    data.visitors = data.visitors.filter(v =>
      !(v.company === match.company && v.start === match.start && v.end === match.end));
    if (data.visitors.length === before) return resp(404, { error: "That visitor was not found (it may have already changed)." });
    msg = `signage: remove ${match.company}`;
  } else {
    return resp(400, { error: "Unknown action." });
  }

  // 3) commit it back
  const newContent = JSON.stringify(data, null, 2) + "\n";
  try {
    const r = await gh(api, {
      method: "PUT",
      body: JSON.stringify({
        message: msg,
        content: Buffer.from(newContent, "utf8").toString("base64"),
        sha: cur.sha,
        branch
      })
    });
    if (!r.ok) {
      const t = await r.text();
      return resp(502, { error: `Save failed (GitHub ${r.status}). ${t.slice(0, 160)}` });
    }
  } catch (e) {
    return resp(502, { error: "Could not reach GitHub to save." });
  }

  return resp(200, { ok: true, visitors: data.visitors });
};
