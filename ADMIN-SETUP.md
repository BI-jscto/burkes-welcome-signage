# Admin form — one-time setup

The **Add Visitor** form is at `https://YOUR-SITE.netlify.app/admin.html`. Someone fills it
out, enters the shared password, and clicks **Add visitor** — a serverless function commits
the change to `schedule.json` in GitHub, Netlify redeploys, and the screens update in ~30–60s.
No one touches GitHub or JSON.

For this to work you set up two things **once**: a GitHub token and four Netlify settings.

---

## 1. Create a GitHub token (lets the form save to the repo)

1. GitHub → your profile menu → **Settings** → **Developer settings** (bottom left) →
   **Personal access tokens** → **Fine-grained tokens** → **Generate new token**.
2. **Token name:** `burkes-signage-admin`. **Expiration:** 1 year (set a reminder to renew).
3. **Resource owner:** the account/org that owns the `burkes-welcome-signage` repo.
4. **Repository access:** **Only select repositories** → pick **burkes-welcome-signage**.
5. **Permissions:** expand **Repository permissions** → find **Contents** → set to
   **Read and write**. (Leave everything else as No access.)
6. **Generate token** and **copy it** (it starts with `github_pat_…`). You won't see it again.

> Treat this token like a password. It goes only into Netlify (next step) — never into the
> page, never emailed around.

## 2. Add four settings in Netlify

Netlify → your site → **Site configuration** → **Environment variables** → **Add a variable**
(add each of these):

| Key | Value |
|-----|-------|
| `GITHUB_TOKEN` | the `github_pat_…` token you just copied |
| `GITHUB_REPO` | `owner/burkes-welcome-signage` (your GitHub org/user + repo name) |
| `GITHUB_BRANCH` | `main` |
| `EDIT_PASSWORD` | a password you choose — this is what people type in the form |

## 3. Redeploy so the settings and new files take effect

Netlify → **Deploys** → **Trigger deploy** → **Clear cache and deploy site**.

## 4. Test it

1. Go to `https://YOUR-SITE.netlify.app/admin.html`.
2. Enter the **EDIT_PASSWORD**, add a test visitor with a short time window, click **Add visitor**.
3. You should see “Added.” Check GitHub — there's a new commit on `schedule.json`. Remove the
   test entry with its **Remove** button.

---

## Who gets what
- **The form + password** → give to whoever schedules visitors (they only need the URL + password).
- **The GitHub token** → stays in Netlify only. If it ever leaks or someone leaves, delete it in
  GitHub and generate a new one, then update `GITHUB_TOKEN` in Netlify.
- **New company logos** → still come to Nick to crop/clean and add to `logos/`; then they appear
  in the form's Logo dropdown.

## If the form says…
- **“Wrong password.”** → the value typed doesn't match `EDIT_PASSWORD` in Netlify.
- **“Server not configured…”** → `GITHUB_TOKEN` or `GITHUB_REPO` is missing/misspelled in Netlify.
- **“Save failed (GitHub 403/404)…”** → the token lacks **Contents: Read and write**, or
  `GITHUB_REPO` is wrong.
