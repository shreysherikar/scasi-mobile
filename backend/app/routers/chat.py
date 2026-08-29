import json
from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse

from ..schemas import ChatRequest
from ..auth import get_current_user
from ..classify import route_intent
from ..prompts import CHAT_SYSTEM_PROMPT
from ..groq_client import stream_chat
from ..db import ensure_session, save_message, get_history, list_sessions

router = APIRouter(prefix="/chat", tags=["chat"])


def _sse(event: str, data: dict) -> str:
    return f"event: {event}\ndata: {json.dumps(data)}\n\n"


@router.post("/stream")
def chat_stream(body: ChatRequest, user=Depends(get_current_user)):
    def event_source():
        session_id = ensure_session(body.sessionId, user["id"], body.message)

        try:
            # Step 1 — intent routing (visible in the UI as a status line).
            intent = route_intent(body.message)
            yield _sse("intent", intent)
            yield _sse("step", {"agentName": "Responder", "status": "running"})

            history = get_history(session_id, limit=12)
            messages = [{"role": "system", "content": CHAT_SYSTEM_PROMPT}, *history,
                        {"role": "user", "content": body.message}]

            save_message(session_id, "user", body.message)

            full_response = ""
            for delta in stream_chat(messages):
                full_response += delta
                yield _sse("token", {"text": delta})

            save_message(session_id, "assistant", full_response)

            yield _sse("step", {"agentName": "Responder", "status": "done"})
            yield _sse("done", {"sessionId": session_id})
        except Exception as e:
            yield _sse("error", {"message": str(e)})

    return StreamingResponse(event_source(), media_type="text/event-stream")


@router.get("/sessions")
def sessions(user=Depends(get_current_user)):
    return {"sessions": list_sessions(user["id"])}


@router.get("/history/{session_id}")
def history(session_id: str, user=Depends(get_current_user)):
    return {"messages": get_history(session_id, limit=200)}
