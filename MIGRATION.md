# Supabase auth + real backend wiring — migration guide

This makes two things true that your resume already claims:
1. The Flutter app is actually paired with the FastAPI backend (chat + email
   AI actions now go through it, not straight to Groq from the phone).
2. Auth is Supabase-backed (Google Sign-In on-device → Supabase session →
   verified by the backend), with chat history in Supabase Postgres instead
   of SQLite.

## 1. Delete these files (no longer used)

- `app/lib/services/groq_service.dart` — replaced by `backend_api_service.dart`
- `app/lib/services/api_key_store.dart` — no more per-device Groq key; the
  key now lives server-side as `GROQ_API_KEY` on the backend only

## 2. Add these files (new, from this delivery)

- `backend/supabase/migrations/0001_init.sql`
- `app/lib/services/supabase_service.dart`
- `app/lib/services/backend_api_service.dart`

## 3. Replace these files with the versions in this delivery

Backend:
- `backend/requirements.txt`
- `backend/app/config.py`
- `backend/app/auth.py`
- `backend/app/db.py`
- `backend/app/main.py`
- `backend/app/schemas.py`
- `backend/app/routers/auth.py`
- `backend/app/routers/chat.py`
- `backend/render.yaml`

App:
- `app/pubspec.yaml`
- `app/lib/config/constants.dart`
- `app/lib/main.dart`
- `app/lib/services/auth_service.dart`
- `app/lib/services/email_actions_service.dart`
- `app/lib/screens/chat_screen.dart`
- `app/lib/screens/settings_screen.dart`

Everything else (inbox, email detail, classify_rules, gmail_service, models,
login_screen, home_screen) is untouched — I checked call sites and none of
them needed to change.

## 4. One-time setup (do this before running)

### Supabase project
1. Create a project at supabase.com.
2. SQL Editor → run `backend/supabase/migrations/0001_init.sql`.
3. Authentication → Providers → enable **Google**. You'll need a Google
   OAuth Client ID/Secret for this (next step covers getting the ID).
4. Project Settings → API → copy the **Project URL** and **anon public key**
   into `app/lib/config/constants.dart` (`kSupabaseUrl`, `kSupabaseAnonKey`).
5. Project Settings → API → copy the **service_role key** — this goes on
   the *backend* only, as the `SUPABASE_SERVICE_ROLE_KEY` env var. Never put
   it in the Flutter app.

### Google Cloud Console
1. APIs & Services → Credentials → create an OAuth Client ID of type
   **Web application** (this is new — separate from your existing
   Android/iOS client IDs, which you keep as-is for Gmail access).
2. Put this Web client ID into Supabase's Google provider settings (Client
   ID + Secret) so Supabase can validate tokens issued for it.
3. Put the same Web client ID into `kGoogleServerClientId` in
   `constants.dart` — it becomes `GoogleSignIn(serverClientId: ...)`, which
   is what makes the ID token's audience match what Supabase expects.

Because we use `signInWithIdToken` (native token exchange) rather than the
browser-based OAuth flow, there's no deep-link/URL-scheme setup needed on
Android/iOS for this part.

### Backend env vars
Set on your host (Render, etc.) or a local `.env` you load yourself:
```
GROQ_API_KEY=...
SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co
SUPABASE_SERVICE_ROLE_KEY=...
```
`JWT_SECRET`, `GOOGLE_CLIENT_ID`, and `DB_PATH` are gone — Supabase replaces
all three.

### Flutter
```
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   # emulator
# or your deployed Render URL once the backend is live
```

## 5. After it's working, update the README

The root `README.md`'s "Status" section currently says Supabase auth is
"planned as a follow-up" — once this is merged, that line is no longer true
and should say it's done, not planned.
