import json
import re
from groq import Groq, BadRequestError

from .config import settings

_client = Groq(api_key=settings.GROQ_API_KEY) if settings.GROQ_API_KEY else None


def _require_client() -> Groq:
    if _client is None:
        raise RuntimeError("GROQ_API_KEY is not configured on the server")
    return _client


def generate_json(system_prompt: str, user_prompt: str, temperature: float = 0.4, max_tokens: int = 1024) -> dict:
    """Calls Groq in JSON mode. GPT-OSS occasionally emits output that fails
    Groq's own json_object validation (empty or malformed) on the first try,
    especially for larger/nested schemas like the triage briefing — so we
    retry once before giving up, rather than surfacing a raw 500."""
    client = _require_client()

    attempts = [temperature, min(temperature + 0.15, 1.0)]
    last_error: Exception | None = None

    for attempt_temp in attempts:
        try:
            completion = client.chat.completions.create(
                model=settings.GROQ_MODEL,
                temperature=attempt_temp,
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
        except (BadRequestError, json.JSONDecodeError) as e:
            last_error = e
            continue

    raise RuntimeError(
        f"Groq failed to return valid JSON after {len(attempts)} attempts: {last_error}"
    )


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
