import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const XP_PER_COMPLETION = 10;
const MILESTONE_XP = 50;
const MILESTONES = [7, 14, 30, 100];

function daysBetween(a: Date, b: Date): number {
  const msPerDay = 86400000;
  const aDay = Math.floor(a.getTime() / msPerDay);
  const bDay = Math.floor(b.getTime() / msPerDay);
  return Math.abs(aDay - bDay);
}

serve(async (req) => {
  const payload = await req.json();
  const record = payload.record;

  if (!record || record.status !== "done") {
    return new Response("ok", { status: 200 });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const habitId = record.habit_id;
  const userId = record.user_id;

  // Fetch all done logs for this habit, ordered by date
  const { data: logs } = await supabase
    .from("habit_logs")
    .select("logged_at")
    .eq("habit_id", habitId)
    .eq("status", "done")
    .order("logged_at", { ascending: false });

  if (!logs || logs.length === 0) {
    return new Response("ok", { status: 200 });
  }

  // Calculate current streak
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  let currentStreak = 0;
  let longestStreak = 0;
  let tempStreak = 1;
  let expectedDate = new Date(logs[0].logged_at);
  expectedDate.setHours(0, 0, 0, 0);

  // Start streak if logged today or yesterday
  const diff = daysBetween(today, expectedDate);
  if (diff <= 1) {
    currentStreak = 1;
  }

  for (let i = 1; i < logs.length; i++) {
    const prevDate = new Date(logs[i].logged_at);
    prevDate.setHours(0, 0, 0, 0);
    const gap = daysBetween(expectedDate, prevDate);

    if (gap === 1) {
      tempStreak++;
      if (i < logs.length && currentStreak > 0) currentStreak++;
    } else {
      longestStreak = Math.max(longestStreak, tempStreak);
      tempStreak = 1;
      if (currentStreak > 0 && gap > 1) currentStreak = 0; // broken
    }
    expectedDate = prevDate;
  }
  longestStreak = Math.max(longestStreak, tempStreak);

  // Upsert streak
  await supabase.from("streaks").upsert({
    habit_id: habitId,
    user_id: userId,
    current_streak: currentStreak,
    longest_streak: longestStreak,
    last_logged_date: new Date(logs[0].logged_at).toISOString().split("T")[0]
  });

  // Award XP
  let xpGain = XP_PER_COMPLETION;
  if (MILESTONES.includes(currentStreak)) {
    xpGain += MILESTONE_XP;
  }

  await supabase.rpc("increment_xp", { user_id_param: userId, xp_amount: xpGain });

  return new Response("ok", { status: 200 });
});
