import time
from fastapi import Header, HTTPException
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests
import jwt

from .config import settings
from .db import upsert_user

_google_request = google_requests.Request()


def verify_google_id_token(token: str) -> dict:
    """Verifies a Google ID token and returns its payload (email, name, picture).

    Audience must match GOOGLE_CLIENT_ID — the Flutter app's GoogleSignIn must be
    configured with `serverClientId: <this same client id>` so tokens issued on
    Android/iOS carry the right audience.
    """
    try:
        payload = google_id_token.verify_oauth2_token(
            token, _google_request, audience=settings.GOOGLE_CLIENT_ID
        )
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Invalid Google ID token: {e}")

    email = payload.get("email")
    if not email:
        raise HTTPException(status_code=400, detail="Google account has no email")
    return payload


def issue_backend_token(email: str, name: str | None, picture: str | None) -> str:
    upsert_user(email, name, picture)
    payload = {
        "sub": email,
        "name": name,
        "picture": picture,
        "iat": int(time.time()),
        "exp": int(time.time()) + settings.JWT_EXPIRE_DAYS * 86400,
    }
    return jwt.encode(payload, settings.JWT_SECRET, algorithm="HS256")


def get_current_user(authorization: str = Header(None)) -> dict:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = authorization.removeprefix("Bearer ").strip()
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=["HS256"])
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Session expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid session token")
    return {"email": payload["sub"], "name": payload.get("name"), "picture": payload.get("picture")}
