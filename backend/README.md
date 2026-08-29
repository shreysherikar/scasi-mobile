# Scasi API

Real FastAPI backend for the Scasi Flutter app: Google identity verification,
session issuance, and Groq-backed AI features (classify, summarize, reply,
triage, streaming chat with persisted history).

## Why FastAPI over the original Next.js backend

- One process, one language, no build step quirks — `uvicorn app.main:app` is
  the entire deploy story.
- Auto-generated interactive docs at `/docs` — genuinely useful for a live
  demo, not just a nicety: you can literally show judges a request/response
  round-trip without opening the app.
- No serverless function cold-start/timeout edge cases to debug mid-demo.

## Local run

```bash
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env            # fill in GROQ_API_KEY and GOOGLE_CLIENT_ID
export $(cat .env | xargs)      # or use a tool like `direnv`/`python-dotenv`
uvicorn app.main:app --reload
```

Visit `http://localhost:8000/docs` — you should see the full interactive API.

`GOOGLE_CLIENT_ID` must be the **same Web application OAuth client ID** your
Flutter app's `GoogleSignIn` uses as `serverClientId` (see the Flutter app's
README) — that's what makes the ID token's audience verifiable here.

## Deploy to Render (recommended)

1. Push this folder to a GitHub repo (or a subfolder of your existing one).
2. On [render.com](https://render.com) → New → Blueprint → point at the repo.
   `render.yaml` here is already configured; Render will prompt you for
   `GROQ_API_KEY` and `GOOGLE_CLIENT_ID` as secrets.
3. Once deployed, your API is live at `https://scasi-api-xxxx.onrender.com`.
   Test it: `curl https://scasi-api-xxxx.onrender.com/health`.

Render's free tier spins down after inactivity and takes ~30s to wake up on
the first request — hit `/health` a minute before you go on stage so it's warm.

## Demo-day fallback: run it locally + tunnel

If the hosted deploy misbehaves right before judging, this is a 30-second
escape hatch that removes cloud hosting from the equation entirely:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
# in a second terminal:
ngrok http 8000
```

`ngrok` prints a public HTTPS URL (e.g. `https://a1b2c3.ngrok-free.app`) —
point the Flutter app's `API_BASE_URL` at that instead of your Render URL and
you're demoing off your own laptop, immune to any hosting flakiness.

## API surface

| Endpoint | Auth | Purpose |
|---|---|---|
| `POST /auth/google` | — | Exchange a Google ID token for a Scasi session token |
| `POST /emails/classify` | Bearer | Free rule-based category (no LLM call) |
| `POST /emails/summarize` | Bearer | LLM summary (structured JSON) |
| `POST /emails/reply` | Bearer | LLM-drafted reply |
| `POST /emails/triage` | Bearer | LLM inbox briefing across multiple emails |
| `POST /chat/stream` | Bearer | SSE: `intent` → `step` → `token`×N → `step` → `done` |
| `GET /chat/sessions` | Bearer | List a user's past chat sessions |
| `GET /chat/history/{id}` | Bearer | Full message history for one session |
| `GET /health` | — | Liveness check |

All AI prompts are copied verbatim from the real Scasi-AI TypeScript backend
(`app/prompts.py` — see the comments citing exact source files), not
reinvented, so behavior matches what's already documented on the resume/repo.

## Persistence note

Chat history is SQLite (`scasi.db`), created automatically on first run.
On Render's free tier the filesystem is ephemeral (wiped on redeploy/restart),
which is fine for a demo. For anything longer-lived, attach a Render Persistent
Disk (Settings → Disks) mounted at the working directory, or point `DB_PATH`
at a mounted volume.
