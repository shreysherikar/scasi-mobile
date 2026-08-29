import json
import re
from groq import Groq

from .config import settings

_client = Groq(api_key=settings.GROQ_API_KEY) if settings.GROQ_API_KEY else None


def _require_client() -> Groq:
    if _client is None:
        raise RuntimeError("GROQ_API_KEY is not configured on the server")
    return _client


def generate_json(system_prompt: str, user_prompt: str, temperature: float = 0.4, max_tokens: int = 1024) -> dict:
    client = _require_client()
    completion = client.chat.completions.create(
        model=settings.GROQ_MODEL,
        temperature=temperature,
        max_tokens=max_tokens,
        response_format={"type": "json_object"},
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    )
    content = completion.choices[0].message.content or "{}"
    cleaned = re.sub(r"^```(?:json)?\s*|\s*```$", "", content.strip())
    return json.loads(cleaned)


def stream_chat(messages: list[dict], temperature: float = 0.6):
    """Yields text deltas from a streaming Groq chat completion."""
    client = _require_client()
    stream = client.chat.completions.create(
        model=settings.GROQ_MODEL,
        temperature=temperature,
        messages=messages,
        stream=True,
    )
    for chunk in stream:
        delta = chunk.choices[0].delta.content if chunk.choices else None
        if delta:
            yield delta
