from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse

from .db import init_db
from .routers import auth, emails, chat

app = FastAPI(
    title="Scasi API",
    description=(
        "Backend for Scasi — an AI-powered email & productivity assistant. "
        "Handles Google identity verification, session issuance, and AI features "
        "(classification, summarization, reply drafting, inbox triage, and a "
        "streaming conversational agent) backed by Groq's Llama 3.3 70B."
    ),
    version="1.0.0",
    contact={"name": "Shreya Sherikar", "url": "https://github.com/shreysherikar"},
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(emails.router)
app.include_router(chat.router)


@app.on_event("startup")
def _startup():
    init_db()


@app.get("/health", tags=["meta"])
def health():
    return {"status": "ok"}


@app.get("/", response_class=HTMLResponse, tags=["meta"])
def root():
    return """
    <html>
      <head><title>Scasi API</title></head>
      <body style="font-family: -apple-system, sans-serif; max-width: 640px; margin: 80px auto; color: #1a1a2e;">
        <h1>🟢 Scasi API is running</h1>
        <p>This is the backend for the Scasi Flutter app — Google auth, AI classification,
        summarization, reply drafting, inbox triage, and a streaming chat agent, powered by Groq.</p>
        <p><a href="/docs">→ Interactive API docs (Swagger UI)</a></p>
        <p><a href="/redoc">→ Reference docs (ReDoc)</a></p>
      </body>
    </html>
    """
