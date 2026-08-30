# Scasi Mobile

![CI](https://github.com/shreysherikar/scasi-mobile/actions/workflows/ci.yml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)

A Flutter client for [Scasi AI](https://github.com/shreysherikar/Scasi-AI), backed by a
custom FastAPI backend — Supabase-authenticated Google Sign-In, a real Gmail inbox, and
AI-powered email classification, summarization, reply drafting, and inbox triage, plus a
streaming conversational assistant with persisted chat history.

**Live backend:** https://scasi-api.onrender.com ([API docs](https://scasi-api.onrender.com/docs))

## Structure

```
scasi-mobile/
├── app/       — Flutter client (Android/iOS)
└── backend/   — FastAPI backend (Supabase auth + Postgres, Groq-powered AI)
```

## Tech stack

**App:** Flutter, Dart, Google Sign-In, Supabase (auth session), Gmail REST API
**Backend:** Python, FastAPI, Groq (Llama/GPT-OSS via Groq's LPU inference), Supabase
(Postgres + JWT-based auth verification via JWKS)
**Infra:** Render (backend hosting), GitHub Actions (CI)

## Features

- Google Sign-In on-device for Gmail access, exchanged for a Supabase session; the
  Flutter app never talks to Gmail's or Google's servers on the backend's behalf, and
  the backend never sees a Google token — only the Supabase-issued session JWT
- Keyword-based email classification (urgent / financial / meeting / social / etc.),
  running entirely on-device
- LLM-powered email summarization, reply drafting, and inbox triage — proxied through
  the FastAPI backend, which holds the Groq API key server-side
- Streaming conversational assistant with a visible multi-step agent trace
  (intent → step → token → done), backed by the FastAPI backend and persisted to
  Supabase Postgres (row-level security scoped per user)

## Auth & data flow

1. Flutter does native Google Sign-In (Gmail scope) → gets a Google ID token.
2. That ID token is exchanged with Supabase (`signInWithIdToken`) for a Supabase
   session — Supabase is the identity provider, not this backend.
3. The Supabase session token is sent as a Bearer token on every request to the
   FastAPI backend, which verifies it against Supabase's public keys (JWKS) — no
   shared secret, no custom JWT issuance.
4. Chat history and user profiles live in Supabase Postgres
   (`backend/supabase/migrations/0001_init.sql`), written server-side with the
   service-role key and protected by RLS policies scoped to `auth.uid()`.

## Running it

The app points at the live backend above by default — clone, configure the app-side
values below, and run.

1. Create a Supabase project, run `backend/supabase/migrations/0001_init.sql`, and
   enable Google as an auth provider — only needed if you're running your **own**
   backend instance instead of the hosted one above.
2. Set `kSupabaseUrl`, `kSupabaseAnonKey`, and `kGoogleServerClientId` in
   `app/lib/config/constants.dart`, then:
   ```
   cd app
   flutter pub get
   flutter run
   ```
   To point at a different backend (e.g. one you're running locally), pass
   `--dart-define=API_BASE_URL=http://10.0.2.2:8000` (Android emulator) or your own URL.

### Running the backend yourself (optional)

```
cd backend
cp .env.example .env   # fill in GROQ_API_KEY, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Testing

- Backend: `cd backend && pip install -r requirements.txt -r requirements-dev.txt && pytest`
- App: `cd app && flutter analyze && flutter test`

Both run automatically on every push via GitHub Actions (see the badge above).

## Deployment notes

The backend is hosted on Render's free tier, which sleeps after ~15 minutes of
inactivity — the first request after a period of idle time can take 30–60 seconds
to wake it back up. This is expected behavior, not a bug.

## Status

Supabase-backed authentication and persistence are implemented — the app and backend
are fully paired, matching the original Scasi-AI web backend's architecture, and the
backend is deployed and publicly reachable.

## License

MIT — see [LICENSE](LICENSE).
