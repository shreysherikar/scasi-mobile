from fastapi import APIRouter, Depends

from ..auth import get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])


@router.get("/me")
def me(user=Depends(get_current_user)):
    """The app calls this once right after Supabase sign-in to confirm the
    backend accepted the session and to warm the `users` row. There's no
    more POST /auth/google — Supabase itself verifies Google and issues the
    session token now; this backend only verifies Supabase's signature."""
    return {"user": user}
