from fastapi import APIRouter
from ..schemas import GoogleAuthRequest
from ..auth import verify_google_id_token, issue_backend_token

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/google")
def google_auth(body: GoogleAuthRequest):
    """Exchange a Google ID token (from the Flutter app's native Google Sign-In)
    for a Scasi backend session token. Stateless verification — no server-side
    OAuth code exchange needed since we only need identity, not a Gmail token
    (the app talks to Gmail directly with its own access token)."""
    payload = verify_google_id_token(body.idToken)
    token = issue_backend_token(
        email=payload["email"],
        name=payload.get("name"),
        picture=payload.get("picture"),
    )
    return {
        "token": token,
        "user": {"email": payload["email"], "name": payload.get("name"), "picture": payload.get("picture")},
    }
