import os


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
