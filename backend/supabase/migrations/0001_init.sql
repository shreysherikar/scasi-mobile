-- Run this against your Supabase project (SQL Editor, or `supabase db push`
-- if you set up the CLI). Creates the tables that replace backend/app/db.py's
-- old SQLite schema, keyed on Supabase's own auth.users instead of email.

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  name text,
  picture text,
  created_at timestamptz not null default now()
);

create table if not exists public.chat_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.chat_messages (
  id bigint generated always as identity primary key,
  session_id uuid not null references public.chat_sessions(id) on delete cascade,
  role text not null,
  content text not null,
  created_at timestamptz not null default now()
);

create index if not exists chat_sessions_user_id_idx on public.chat_sessions (user_id);
create index if not exists chat_messages_session_id_idx on public.chat_messages (session_id);

-- Row Level Security. Our FastAPI backend writes with the service-role key,
-- which bypasses RLS entirely — these policies exist so that if the Flutter
-- app ever reads Supabase directly with the user's own session token
-- (instead of going through the backend), a user can only ever see their
-- own rows.
alter table public.users enable row level security;
alter table public.chat_sessions enable row level security;
alter table public.chat_messages enable row level security;

create policy "Users can view own profile" on public.users
  for select using (auth.uid() = id);

create policy "Users can view own chat sessions" on public.chat_sessions
  for select using (auth.uid() = user_id);

create policy "Users can view own chat messages" on public.chat_messages
  for select using (
    exists (
      select 1 from public.chat_sessions s
      where s.id = chat_messages.session_id and s.user_id = auth.uid()
    )
  );
