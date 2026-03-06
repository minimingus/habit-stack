-- RPC function for atomic XP increment
create or replace function increment_xp(user_id_param uuid, xp_amount int)
returns void
language plpgsql
security definer
as $$
begin
  update profiles
  set xp_total = xp_total + xp_amount,
      level = greatest(1, floor((xp_total + xp_amount) / 100)::int + 1)
  where id = user_id_param;
end;
$$;
