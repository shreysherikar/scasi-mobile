/// Gmail scopes requested at sign-in. Read-only is enough for inbox display,
/// summarize, and AI-drafted replies (drafts are shown in-app, not auto-sent).
const List<String> kGmailScopes = [
  'email',
  'profile',
  'https://www.googleapis.com/auth/gmail.readonly',
];

/// Groq's OpenAI-compatible endpoint — the same one Scasi-AI's backend uses.
const String kGroqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';

/// Same model Scasi's backend uses for reply/chat tasks.
const String kGroqModel = 'llama-3.3-70b-versatile';
