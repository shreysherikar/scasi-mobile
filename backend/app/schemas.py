from pydantic import BaseModel
from typing import Optional, List


class GoogleAuthRequest(BaseModel):
    idToken: str


class ClassifyRequest(BaseModel):
    subject: str = ""
    snippet: str = ""
    sender: str = ""


class SummarizeRequest(BaseModel):
    subject: str = ""
    sender: Optional[str] = None
    date: Optional[str] = None
    body: str = ""


class ReplyRequest(BaseModel):
    subject: str = ""
    body: str = ""
    tone: str = "professional"
    senderFirstName: Optional[str] = None


class EmailBrief(BaseModel):
    sender: Optional[str] = None
    subject: Optional[str] = None
    snippet: Optional[str] = None


class TriageRequest(BaseModel):
    emails: List[EmailBrief]


class ChatRequest(BaseModel):
    message: str
    sessionId: Optional[str] = None
