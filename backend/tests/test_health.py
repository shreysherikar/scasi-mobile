"""Smoke tests that don't require real GROQ_API_KEY / SUPABASE_* secrets —
they just confirm the app imports cleanly and the unauthenticated routes
respond. Auth-gated routes need a live Supabase project to test properly,
so they're out of scope for CI and are covered by manual testing instead.
"""
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json() == {"status": "ok"}


def test_root_serves_html():
    res = client.get("/")
    assert res.status_code == 200
    assert "Scasi API" in res.text


def test_chat_requires_auth():
    res = client.post("/chat/stream", json={"message": "hi"})
    assert res.status_code == 401


def test_emails_summarize_requires_auth():
    res = client.post("/emails/summarize", json={"subject": "hi", "body": "hi"})
    assert res.status_code == 401
