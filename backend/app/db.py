import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager

from .config import settings

_lock = threading.Lock()


def init_db():
    with _connect() as conn:
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS users (
                email TEXT PRIMARY KEY,
                name TEXT,
                picture TEXT,
                created_at REAL
            );

            CREATE TABLE IF NOT EXISTS chat_sessions (
                id TEXT PRIMARY KEY,
                user_email TEXT,
                title TEXT,
                created_at REAL,
                updated_at REAL
            );

            CREATE TABLE IF NOT EXISTS chat_messages (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                session_id TEXT,
                role TEXT,
                content TEXT,
                created_at REAL
            );
            """
        )


@contextmanager
def _connect():
    conn = sqlite3.connect(settings.DB_PATH)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def upsert_user(email: str, name: str | None, picture: str | None):
    with _lock, _connect() as conn:
        conn.execute(
            """
            INSERT INTO users (email, name, picture, created_at)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(email) DO UPDATE SET name=excluded.name, picture=excluded.picture
            """,
            (email, name, picture, time.time()),
        )


def ensure_session(session_id: str | None, user_email: str, first_message: str) -> str:
    sid = session_id or str(uuid.uuid4())
    with _lock, _connect() as conn:
        existing = conn.execute("SELECT id FROM chat_sessions WHERE id = ?", (sid,)).fetchone()
        now = time.time()
        if existing is None:
            title = (first_message[:60] + "…") if len(first_message) > 60 else first_message
            conn.execute(
                "INSERT INTO chat_sessions (id, user_email, title, created_at, updated_at) VALUES (?, ?, ?, ?, ?)",
                (sid, user_email, title, now, now),
            )
        else:
            conn.execute("UPDATE chat_sessions SET updated_at = ? WHERE id = ?", (now, sid))
    return sid


def save_message(session_id: str, role: str, content: str):
    with _lock, _connect() as conn:
        conn.execute(
            "INSERT INTO chat_messages (session_id, role, content, created_at) VALUES (?, ?, ?, ?)",
            (session_id, role, content, time.time()),
        )


def get_history(session_id: str, limit: int = 20) -> list[dict]:
    with _lock, _connect() as conn:
        rows = conn.execute(
            "SELECT role, content FROM chat_messages WHERE session_id = ? ORDER BY id ASC LIMIT ?",
            (session_id, limit),
        ).fetchall()
    return [{"role": r["role"], "content": r["content"]} for r in rows]


def list_sessions(user_email: str) -> list[dict]:
    with _lock, _connect() as conn:
        rows = conn.execute(
            "SELECT id, title, updated_at FROM chat_sessions WHERE user_email = ? ORDER BY updated_at DESC",
            (user_email,),
        ).fetchall()
    return [{"id": r["id"], "title": r["title"], "updatedAt": r["updated_at"]} for r in rows]
