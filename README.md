# Scasi Mobile

A Flutter client for [Scasi AI](https://github.com/shreysherikar/Scasi-AI), backed by a
custom FastAPI backend — Google Sign-In, a real Gmail inbox, and AI-powered email
classification, summarization, reply drafting, and inbox triage, plus a streaming
conversational assistant.

## Structure

```
scasi-mobile/
├── app/       — Flutter client (Android/iOS)
└── backend/   — FastAPI backend (Google auth, Groq-powered AI, SQLite chat history)
```

## Tech stack

**App:** Flutter, Dart, Google Sign-In, Gmail REST API
**Backend:** Python, FastAPI, Groq (Llama/GPT-OSS via Groq's LPU inference), JWT auth, SQLite

## Features

- Google Sign-In with direct, on-device Gmail inbox access (no data leaves the
  device except to the user's own backend for AI processing)
- Keyword-based email classification (urgent / financial / meeting / social / etc.)
- LLM-powered email summarization and reply drafting
- One-tap AI inbox triage briefing
- Streaming conversational assistant with a visible multi-step agent trace
  (intent → step → token → done) and persisted chat history

## Running it

See `backend/README.md` and `app/README.md` for setup instructions for each half.
Short version: start the backend first (`uvicorn app.main:app`), then run the
Flutter app pointed at it via `--dart-define=API_BASE_URL=...`.

## Status

Actively being developed — Supabase-backed authentication and persistence are
planned as a follow-up to bring this fully in line with the original Scasi-AI
web backend's architecture.
