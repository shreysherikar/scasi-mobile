import time
import uuid
from typing import Optional

from supabase import create_client, Client

from .config import settings

_client: Optional[Client] = None


def get_client() -> Client:
    """Server-side Supabase client using the service-role key — bypasses RLS,
    which is fine because every caller into this module has already been
    authenticated by get_current_user() in auth.py."""
    global _client
    if _client is None:
        if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
            raise RuntimeError("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are not set")
        _client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)
    return _client


def upsert_user(user_id: str, email: str | None, name: str | None, picture: str | None):
    get_client().table("users").upsert(
        {"id": user_id, "email": email, "name": name, "picture": picture}
    ).execute()


def ensure_session(session_id: str | None, user_id: str, first_message: str) -> str:
    client = get_client()
    sid = session_id or str(uuid.uuid4())

    existing = client.table("chat_sessions").select("id").eq("id", sid).execute()
    if not existing.data:
        title = (first_message[:60] + "…") if len(first_message) > 60 else first_message
        client.table("chat_sessions").insert(
            {"id": sid, "user_id": user_id, "title": title}
        ).execute()
    else:
        client.table("chat_sessions").update(
            {"updated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
        ).eq("id", sid).execute()

    return sid


def save_message(session_id: str, role: str, content: str):
    get_client().table("chat_messages").insert(
        {"session_id": session_id, "role": role, "content": content}
    ).execute()


def get_history(session_id: str, limit: int = 20) -> list[dict]:
    res = (
        get_client()
        .table("chat_messages")
        .select("role, content")
        .eq("session_id", session_id)
        .order("id")
        .limit(limit)
        .execute()
    )
    return [{"role": r["role"], "content": r["content"]} for r in (res.data or [])]


def list_sessions(user_id: str) -> list[dict]:
    res = (
        get_client()
        .table("chat_sessions")
        .select("id, title, updated_at")
        .eq("user_id", user_id)
        .order("updated_at", desc=True)
        .execute()
    )
    return [{"id": r["id"], "title": r["title"], "updatedAt": r["updated_at"]} for r in (res.data or [])]
