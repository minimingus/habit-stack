-- Track proactive coach nudge notifications for cooldown and analytics
create table coach_nudges (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  habit_id uuid not null references habits(id) on delete cascade,
  habit_name text not null,
  streak_at_nudge int not null default 0,
  template_index int not null default 0,
  sent_at timestamptz not null default now()
);

-- Index for cooldown lookups (find recent nudges per user)
create index idx_coach_nudges_user_sent on coach_nudges(user_id, sent_at desc);

-- RLS: service role only (edge function writes, users don't need direct access)
alter table coach_nudges enable row level security;

-- Allow service role to insert (edge function uses service role key)
-- No user-facing policy needed — this table is server-side only
