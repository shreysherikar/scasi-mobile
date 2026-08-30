/// Gmail scopes requested at sign-in. Read-only is enough for inbox display,
/// summarize, and AI-drafted replies (drafts are shown in-app, not auto-sent).
const List<String> kGmailScopes = [
  'email',
  'profile',
  'https://www.googleapis.com/auth/gmail.readonly',
];

/// Supabase project URL + anon key — safe to ship in the app. Row Level
/// Security in Postgres (see backend/supabase/migrations) is what actually
/// protects the data, not secrecy of these values.
/// From: Supabase dashboard -> Project Settings -> API.
const String kSupabaseUrl = 'https://rrbsqxuwlchlvccwhwmz.supabase.co';
const String kSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJyYnNxeHV3bGNobHZjY3dod216Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4ODAwMzQ0NCwiZXhwIjoyMTAzNTc5NDQ0fQ.v8xgWzYkzC4UeMu3DwYKXbz30EJPD3StK6I7kE11rRk';

/// A Google Cloud OAuth client ID of type "Web application" (not the
/// Android/iOS client). Required as GoogleSignIn's serverClientId so the ID
/// token's audience matches what Supabase's Google provider expects.
/// From: Google Cloud Console -> APIs & Services -> Credentials.
const String kGoogleServerClientId = '211736943252-obd33i3cfrprqguq5lc6osvkdpu6apb9.apps.googleusercontent.com';

/// Base URL of the FastAPI backend in /backend. Override at build/run time
/// with --dart-define=API_BASE_URL=https://your-backend.example.com
const String kBackendBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://scasi-api.onrender.com/', // Android emulator -> host machine
);
