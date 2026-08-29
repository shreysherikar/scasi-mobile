import os
from dotenv import load_dotenv

# Loads backend/.env into the process environment when running locally
# (uvicorn, pytest, etc.). In production (Render), env vars are injected
# directly by the platform, so this is a no-op if no .env file exists.
load_dotenv()


class Settings:
    GROQ_API_KEY: str = os.environ.get("GROQ_API_KEY", "")
    GROQ_MODEL: str = os.environ.get("GROQ_MODEL", "openai/gpt-oss-120b")

    # Supabase is now the identity provider and database. SUPABASE_URL and
    # SUPABASE_SERVICE_ROLE_KEY come from Project Settings -> API in the
    # Supabase dashboard. The service role key bypasses RLS, so it must
    # never be shipped to the Flutter app — server-side only.
    SUPABASE_URL: str = os.environ.get("SUPABASE_URL", "")
    SUPABASE_SERVICE_ROLE_KEY: str = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")

    # Used to verify the Supabase-issued JWTs the app sends us. Supabase
    # publishes its signing keys here — no shared secret needed.
    SUPABASE_JWKS_URL: str = os.environ.get(
        "SUPABASE_JWKS_URL",
        f"{os.environ.get('SUPABASE_URL', '').rstrip('/')}/auth/v1/.well-known/jwks.json",
    )


settings = Settings()

if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
    # Loud on purpose: a silently-empty Supabase config surfaces later as a
    # confusing 401 on every request instead of a clear startup warning.
    print(
        "[config] WARNING: SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are not set. "
        "Create backend/.env from backend/.env.example and fill in your "
        "Supabase project's values, or every request will fail auth."
    )
