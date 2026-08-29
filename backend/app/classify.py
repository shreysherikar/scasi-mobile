"""Same keyword rule engine as the Flutter app's classify_rules.dart, itself
ported from the real backend's src/agents/nlp/index.ts classify() method.
Exposed server-side too so the backend's /docs page demonstrates the same logic."""

RULES = [
    ("urgent", 0.92, 90, "Urgent keywords detected",
     ["urgent", "asap", "immediately", "action required", "critical", "emergency", "respond now"]),
    ("financial", 0.88, 75, "Financial keywords detected",
     ["invoice", "payment due", "billing statement", "receipt", "bank transfer", "bank account",
      "transaction alert", "refund", "overdue", "amount due", "payslip", "salary credit"]),
    ("action_required", 0.85, 70, "Action request detected",
     ["action required", "please review", "your approval", "please confirm", "follow up on",
      "kindly assist", "approval needed", "your response is needed"]),
    ("meeting", 0.87, 65, "Meeting/scheduling keywords detected",
     ["meeting", "interview", "schedule", "calendar invite", "zoom", "google meet", "teams call",
      "appointment", "standup", "sync"]),
    ("social", 0.90, 20, "Social network email detected",
     ["linkedin", "twitter", "instagram", "facebook", "github notification", "mentioned you",
      "connection request", "started following", "noreply@", "social notification"]),
    ("promotional", 0.91, 15, "Promotional keywords detected",
     ["unsubscribe", "sale", "% off", "deal", "offer", "discount", "coupon", "promo",
      "limited time", "shop now", "buy now", "free trial", "upgrade now"]),
    ("newsletter", 0.83, 25, "Newsletter or digest email",
     ["newsletter", "digest", "weekly update", "monthly report", "announcement", "release notes",
      "changelog", "alert", "no-reply", "noreply"]),
    ("spam", 0.80, 5, "Spam-like keywords detected",
     ["congratulations", "you have won", "click here to claim", "verify your account now",
      "suspicious", "out of office auto-reply"]),
    ("personal", 0.75, 55, "Personal email signals detected",
     ["hey", "hi there", "dear friend", "hope you are", "miss you", "family", "mom", "dad",
      "brother", "sister"]),
]


def classify_email(subject: str, snippet: str, sender: str = "") -> dict:
    text = f"{subject} {snippet} {sender}".lower()
    for category, confidence, priority, reason, keywords in RULES:
        if any(k in text for k in keywords):
            return {"category": category, "confidence": confidence, "priority": priority, "reason": reason}
    return {"category": "fyi", "confidence": 0.60, "priority": 30, "reason": "General informational email"}


# --- Lightweight intent router for the visible chat trace ---
# Not the full multi-agent orchestrator (no tool-calling/RAG) — a small,
# honest classifier that picks a workflow label so the SSE stream can show
# a real "step" event before the model starts answering.

WORKFLOWS = [
    ("draft_reply", ["reply", "draft", "respond to", "write back", "compose"]),
    ("summarize_help", ["summarize", "summary", "tl;dr", "recap"]),
    ("triage_help", ["triage", "prioritize", "what's urgent", "sort my inbox", "important emails"]),
    ("schedule_help", ["schedule", "meeting", "calendar", "reschedule"]),
]


def route_intent(message: str) -> dict:
    text = message.lower()
    for workflow, keywords in WORKFLOWS:
        if any(k in text for k in keywords):
            return {"workflow": workflow, "reasoning": f"Message matches the '{workflow}' pattern"}
    return {"workflow": "general_qa", "reasoning": "General question or conversation"}
