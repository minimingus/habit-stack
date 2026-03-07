-- Migration: 004_spend_streak_shield.sql
-- Adds the spend_streak_shield RPC used when a Level 5+ user spends a shield
-- to protect their streak after missing a day.

CREATE OR REPLACE FUNCTION public.spend_streak_shield(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_yesterday date := (current_date - interval '1 day')::date;
BEGIN
  -- Atomically guard and decrement in one statement to prevent TOCTOU race.
  UPDATE public.profiles
  SET streak_shields = streak_shields - 1
  WHERE id = p_user_id
    AND streak_shields >= 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'no_shields'
      USING ERRCODE = 'P0001', HINT = 'no_shields';
  END IF;

  -- Insert 'skipped' logs for yesterday for all non-archived habits with an
  -- active streak that don't already have a log for that date.
  INSERT INTO public.habit_logs (habit_id, user_id, logged_at, status)
  SELECT
    h.id,
    p_user_id,
    (v_yesterday AT TIME ZONE 'UTC'),
    'skipped'
  FROM public.habits h
  JOIN public.streaks s ON s.habit_id = h.id
  WHERE h.user_id    = p_user_id
    AND h.archived_at IS NULL
    AND s.current_streak > 0
    AND NOT EXISTS (
      SELECT 1
      FROM public.habit_logs hl
      WHERE hl.habit_id    = h.id
        AND hl.user_id     = p_user_id
        AND hl.logged_at::date = v_yesterday
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.spend_streak_shield(uuid) TO authenticated;
