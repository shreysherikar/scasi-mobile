import jwt
from jwt import PyJWKClient
from fastapi import Header, HTTPException

from .config import settings
from .db import upsert_user

_jwk_client: PyJWKClient | None = None


def _get_jwk_client() -> PyJWKClient:
    global _jwk_client
    if _jwk_client is None:
        if not settings.SUPABASE_URL:
            raise HTTPException(status_code=500, detail="Supabase is not configured on this backend")
        _jwk_client = PyJWKClient(settings.SUPABASE_JWKS_URL)
    return _jwk_client


def get_current_user(authorization: str = Header(None)) -> dict:
    """Verifies the Supabase session token the Flutter app sends after
    Supabase Auth's signInWithIdToken(Google) exchange.

    Supabase is now the identity provider — not this backend — so we only
    verify the token's signature/audience/expiry against Supabase's public
    keys. We no longer issue our own JWTs or verify Google ID tokens here.
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.removeprefix("Bearer ").strip()

    try:
        signing_key = _get_jwk_client().get_signing_key_from_jwt(token)
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=["ES256", "RS256"],
            audience="authenticated",
        )
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid Supabase session: {e}")

    user_id = payload["sub"]
    email = payload.get("email")
    metadata = payload.get("user_metadata") or {}
    name = metadata.get("full_name") or metadata.get("name")
    picture = metadata.get("avatar_url") or metadata.get("picture")

    # Keep our own users table (used for FK joins on chat_sessions) in sync.
    upsert_user(user_id, email, name, picture)

    return {"id": user_id, "email": email, "name": name, "picture": picture}
