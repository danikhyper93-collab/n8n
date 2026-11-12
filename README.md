# n8n on Render (Free Tier) + Supabase Postgres

Minimal setup to run the official **n8n** web UI and workflow editor (`n8nio/n8n:2.47.5`) on Render's free web service tier backed by an external Supabase PostgreSQL database.

## Files

- `Dockerfile` — Pins `n8nio/n8n:2.47.5`, adds `entrypoint.sh`, exposes `5678`, and preserves the official `tini` + `/docker-entrypoint.sh` startup.
- `entrypoint.sh` — Auto-sets `N8N_HOST` and `N8N_WEBHOOK_URL` from Render's `RENDER_EXTERNAL_URL` so only one deploy is needed.
- `render.yaml` — Render Blueprint defining the Docker web service, `/healthz` health check, and environment variables.
- `.env.example` — Reference list of all environment variables.
- `.gitignore` — Keeps local `.env` files and `.n8n/` data out of git.

---

## Setup Steps

### 1. Create a Supabase Project

1. Go to [Supabase](https://supabase.com/) and create a new project.
2. Open **Project Settings → Database** (or click **Connect** at the top of the dashboard).
3. Switch to **Session pooler** (port `5432`) so it uses an IPv4 endpoint (Render free services cannot reach Supabase's IPv6-only direct DB host).
4. Copy these three values:
   - **Host**: e.g. `aws-0-ap-south-1.pooler.supabase.com`
   - **User**: `postgres.<project-ref>`
   - **Password**: your database password
5. *(Recommended)* Open the **SQL Editor** in Supabase and create the `n8n` schema in advance:
   ```sql
   CREATE SCHEMA IF NOT EXISTS n8n;
   ```

### 2. Generate an Encryption Key

Run this command locally once and save the output somewhere safe:

```bash
openssl rand -hex 24
```

> **Important:** Never change `N8N_ENCRYPTION_KEY` after creating credentials in n8n. Changing it makes all saved credentials unreadable.

### 3. Push This Repo to GitHub

1. Initialize git, commit all files (`Dockerfile`, `entrypoint.sh`, `render.yaml`, `.env.example`, `.gitignore`, `README.md`), and push to a GitHub repository.
2. Make sure no real `.env` or secret values are committed.

### 4. Deploy on Render via Blueprint

1. Open the [Render Dashboard](https://dashboard.render.com/).
2. Click **New +** → **Blueprint**.
3. Connect and select your GitHub repository.
4. Fill in the 4 prompted secret environment variables (`sync: false` in `render.yaml`):
   - `DB_POSTGRESDB_HOST` — Supabase Session pooler host
   - `DB_POSTGRESDB_USER` — `postgres.<project-ref>`
   - `DB_POSTGRESDB_PASSWORD` — Supabase DB password
   - `N8N_ENCRYPTION_KEY` — the 48-character hex string generated in Step 2
5. Click **Apply** and wait for the Docker build and deploy to turn **Live**.

### 5. Create Your n8n Owner Account

1. Open your Render service URL (`https://<service>.onrender.com`).
2. Complete the initial owner account setup form.

### 6. Keep It Awake with UptimeRobot (Free)

Render's free tier sleeps after 15 minutes of inactivity. Scheduled triggers and incoming webhooks only run while the instance is awake.

1. Create a free account at [UptimeRobot](https://uptimerobot.com/).
2. Click **Add New Monitor**:
   - **Monitor Type**: `HTTP(s)`
   - **URL**: `https://<service>.onrender.com/healthz`
   - **Monitoring Interval**: `5 minutes`
3. Save the monitor.

### 7. Connect Google Drive, Sheets, and YouTube (Optional)

1. Go to [Google Cloud Console](https://console.cloud.google.com/) and create a new project.
2. Go to **APIs & Services → Library** and enable:
   - **Google Drive API**
   - **Google Sheets API**
   - **YouTube Data API v3**
3. Go to **Google Auth Platform** (or **APIs & Services → OAuth consent screen**):
   - Set app name and support email, choose **External**, and save.
   - Under **Audience / Test users**, add your own Google email address.
4. Go to **Clients** (or **Credentials → Create Credentials → OAuth client ID**):
   - Application type: **Web application**
   - Authorized redirect URI:
     ```text
     https://<service>.onrender.com/rest/oauth2-credential/callback
     ```
5. Copy the **Client ID** and **Client Secret**, open n8n → **Credentials → Add Credential**, pick Google Drive / Google Sheets / YouTube OAuth2, paste the values, and sign in.

---

## Known Limits

- **512 MB RAM**: Render's free tier has 512 MB RAM (`NODE_OPTIONS=--max-old-space-size=384` is set to prevent OOM crashes). Avoid processing huge files or heavy concurrent workflows.
- **Sleep after 15 min idle**: Without a 5-minute `/healthz` ping (or if Render restarts the container), schedules and webhooks pause until the next request wakes the service (cold start ~30–60s).
- **Ephemeral disk**: Workflows, credentials, and execution metadata live in Supabase Postgres, but local filesystem binary data (`/home/node/.n8n`) is wiped on container restart or redeploy.
- **Unverified Google Cloud App**: While your Google OAuth app is in **Testing** mode (unverified), API-uploaded YouTube videos may be forced to **Private**, and refresh tokens can expire after 7 days unless the app is published/verified.
