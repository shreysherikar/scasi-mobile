from datetime import datetime
from fastapi import APIRouter, Depends

from ..schemas import ClassifyRequest, SummarizeRequest, ReplyRequest, TriageRequest
from ..classify import classify_email
from ..prompts import SUMMARIZE_SYSTEM_PROMPT, REPLY_SYSTEM_PROMPT, triage_system_prompt
from ..groq_client import generate_json
from ..auth import get_current_user

router = APIRouter(prefix="/emails", tags=["emails"])


@router.post("/classify")
def classify(body: ClassifyRequest, user=Depends(get_current_user)):
    """Free, instant, no LLM call — same keyword rule engine as the original
    Scasi-AI backend's nlpAgent.classify()."""
    return classify_email(body.subject, body.snippet, body.sender)


@router.post("/summarize")
def summarize(body: SummarizeRequest, user=Depends(get_current_user)):
    user_prompt = "\n".join(
        filter(
            None,
            [
                f"Subject: {body.subject}",
                f"From: {body.sender}" if body.sender else None,
                f"Received: {body.date}" if body.date else None,
                "",
                f"Body:\n{body.body[:3000]}",
            ],
        )
    )
    return generate_json(SUMMARIZE_SYSTEM_PROMPT, user_prompt, temperature=0.4, max_tokens=512)


@router.post("/reply")
def reply(body: ReplyRequest, user=Depends(get_current_user)):
    lines = [f"Tone: {body.tone}", f"Subject: {body.subject}"]
    if body.senderFirstName:
        lines.append(f"Sender's first name: {body.senderFirstName}")
    lines += ["", f"Email Content:\n{body.body[:3000]}", ""]
    lines.append(
        f'Draft a reply. Open with "Dear {body.senderFirstName}," — never use placeholder text like [name] or [sender].'
        if body.senderFirstName
        else "Draft a reply:"
    )
    result = generate_json(REPLY_SYSTEM_PROMPT, "\n".join(lines), temperature=0.7, max_tokens=1024)
    return {"reply": result.get("reply", "")}


@router.post("/triage")
def triage(body: TriageRequest, user=Depends(get_current_user)):
    time_str = datetime.now().strftime("%A, %B %d, %Y at %I:%M %p")
    blob = "\n---\n".join(
        f"From: {e.sender or 'Unknown'}\nSubject: {e.subject or ''}\nSnippet: {e.snippet or ''}"
        for e in body.emails[:30]
    )
    return generate_json(
        triage_system_prompt(time_str),
        f"Analyze these emails:\n\n{blob}",
        temperature=0.2,
        max_tokens=2000,
    )
