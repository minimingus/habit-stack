-- profiles (auto-created by auth trigger)
create table profiles (
  id uuid primary key references auth.users on delete cascade,
  name text,
  xp_total int not null default 0,
  level int not null default 1,
  streak_shields int not null default 0,
  plan text not null default 'free' check (plan in ('free','pro')),
  scorecard_result jsonb,
  created_at timestamptz not null default now()
);

-- habits
create table habits (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  emoji text not null default '✅',
  color text not null default '#0D9488',
  cue text, craving text, routine text, reward text,
  tiny_version text,
  anchor_habit_id uuid references habits(id) on delete set null,
  frequency text not null default 'daily' check (frequency in ('daily','weekdays','weekends','custom')),
  time_of_day text not null default 'all-day' check (time_of_day in ('morning','afternoon','evening','all-day')),
  reminder_enabled bool not null default false,
  reminder_time timestamptz,
  archived_at timestamptz,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

-- habit_logs
create table habit_logs (
  id uuid primary key default gen_random_uuid(),
  habit_id uuid not null references habits(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  logged_at timestamptz not null default now(),
  status text not null check (status in ('done','skipped','missed')),
  note text, mood int
);

-- streaks
create table streaks (
  habit_id uuid primary key references habits(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  current_streak int not null default 0,
  longest_streak int not null default 0,
  last_logged_date date
);

-- identity_votes
create table identity_votes (
  id uuid primary key default gen_random_uuid(),
  habit_id uuid not null references habits(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  identity_statement text not null,
  voted_at timestamptz not null default now()
);

-- coach_usage
create table coach_usage (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  model text not null,
  input_tokens int not null default 0,
  output_tokens int not null default 0,
  created_at timestamptz not null default now()
);

-- device_tokens
create table device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  token text not null unique,
  platform text not null default 'ios',
  created_at timestamptz not null default now()
);

-- RLS: enable on all tables
alter table profiles enable row level security;
alter table habits enable row level security;
alter table habit_logs enable row level security;
alter table streaks enable row level security;
alter table identity_votes enable row level security;
alter table coach_usage enable row level security;
alter table device_tokens enable row level security;

-- RLS policies (owner-only)
create policy "users manage own profile" on profiles for all using (auth.uid() = id);
create policy "users manage own habits" on habits for all using (auth.uid() = user_id);
create policy "users manage own logs" on habit_logs for all using (auth.uid() = user_id);
create policy "users manage own streaks" on streaks for all using (auth.uid() = user_id);
create policy "users manage own votes" on identity_votes for all using (auth.uid() = user_id);
create policy "users manage own coach_usage" on coach_usage for all using (auth.uid() = user_id);
create policy "users manage own device_tokens" on device_tokens for all using (auth.uid() = user_id);

-- Auto-create profile on signup
create or replace function handle_new_user() returns trigger language plpgsql security definer as $$
begin
  insert into profiles (id) values (new.id);
  return new;
end;
$$;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();
