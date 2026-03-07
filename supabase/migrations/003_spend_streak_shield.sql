-- Migration 003: spend_streak_shield RPC
-- Allows a user to spend one streak shield to retroactively mark yesterday
-- as 'skipped' for all active-streak habits, preserving their streaks.

CREATE OR REPLACE FUNCTION public.spend_streak_shield(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_yesterday date := (current_date - interval '1 day')::date;
BEGIN
  -- Guard: user must have at least one shield available
  IF (SELECT streak_shields FROM profiles WHERE id = p_user_id) < 1 THEN
    RAISE EXCEPTION 'no_shields';
  END IF;

  -- Decrement shield count
  UPDATE profiles
  SET streak_shields = streak_shields - 1
  WHERE id = p_user_id;

  -- Insert 'skipped' logs for yesterday for all qualifying habits
  INSERT INTO habit_logs (habit_id, user_id, logged_at, status)
  SELECT
    h.id,
    p_user_id,
    v_yesterday::timestamptz,
    'skipped'
  FROM habits h
  JOIN streaks s ON s.habit_id = h.id
  WHERE h.user_id = p_user_id
    AND h.archived_at IS NULL
    AND s.current_streak > 0
    AND NOT EXISTS (
      SELECT 1
      FROM habit_logs hl
      WHERE hl.habit_id = h.id
        AND hl.logged_at::date = v_yesterday
    );
END;
$$;

GRANT EXECUTE ON FUNCTION public.spend_streak_shield(uuid) TO authenticated;
