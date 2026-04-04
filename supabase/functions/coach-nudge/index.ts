import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { encode as base64url } from "https://deno.land/std@0.168.0/encoding/base64url.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const APNS_KEY_ID = Deno.env.get("APNS_KEY_ID")!;
const APNS_TEAM_ID = Deno.env.get("APNS_TEAM_ID")!;
const APNS_PRIVATE_KEY = Deno.env.get("APNS_PRIVATE_KEY")!;
const BUNDLE_ID = "com.tomerab.habitstack";

// Thresholds
const MIN_STREAK_BEFORE_NUDGE = 3;   // Only nudge if they had 3+ day streak
const DAYS_MISSED_THRESHOLD = 2;      // Nudge after 2 days of missing
const NUDGE_COOLDOWN_DAYS = 3;        // Max 1 nudge per 3 days per user
const MAX_NUDGES_PER_RUN = 50;        // Cap per cron run to control costs

// Templated nudge messages — personalized with habit name and streak
const NUDGE_TEMPLATES = [
  {
    title: "Your coach noticed something",
    body: (habit: string, streak: number) =>
      `You had a ${streak}-day ${habit} streak going. What got in the way?`,
  },
  {
    title: "Quick check-in",
    body: (habit: string, streak: number) =>
      `${habit} hasn't happened in a few days. Your ${streak}-day streak is worth protecting.`,
  },
  {
    title: "Still here for you",
    body: (habit: string, _streak: number) =>
      `Streaks reset. Habits don't. Ready to restart ${habit}?`,
  },
  {
    title: "One rep away",
    body: (habit: string, _streak: number) =>
      `A 2-minute version of ${habit} still counts. Consistency beats perfection.`,
  },
];

function pickTemplate(userId: string) {
  // Deterministic-ish selection based on user ID so they don't get the same one
  const hash = userId.split("").reduce((a, c) => a + c.charCodeAt(0), 0);
  return NUDGE_TEMPLATES[hash % NUDGE_TEMPLATES.length];
}

// Build JWT for APNs authentication
async function buildApnsJwt(): Promise<string> {
  const header = { alg: "ES256", kid: APNS_KEY_ID };
  const now = Math.floor(Date.now() / 1000);
  const claims = { iss: APNS_TEAM_ID, iat: now };

  const headerB64 = base64url(new TextEncoder().encode(JSON.stringify(header)));
  const claimsB64 = base64url(new TextEncoder().encode(JSON.stringify(claims)));
  const signingInput = `${headerB64}.${claimsB64}`;

  // Import the P8 private key
  const pemContents = APNS_PRIVATE_KEY
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
  const keyData = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    new TextEncoder().encode(signingInput)
  );

  const sigB64 = base64url(new Uint8Array(signature));
  return `${signingInput}.${sigB64}`;
}

async function sendPush(
  token: string,
  title: string,
  body: string,
  jwt: string,
  data: Record<string, string> = {}
): Promise<boolean> {
  const url = `https://api.push.apple.com/3/device/${token}`;

  try {
    const res = await fetch(url, {
      method: "POST",
      headers: {
        authorization: `bearer ${jwt}`,
        "apns-topic": BUNDLE_ID,
        "apns-push-type": "alert",
        "apns-priority": "5", // Low priority — not time-critical
        "content-type": "application/json",
      },
      body: JSON.stringify({
        aps: {
          alert: { title, body },
          sound: "default",
        },
        ...data,
      }),
    });
    return res.ok;
  } catch {
    return false;
  }
}

serve(async (req) => {
  // Verify this is called by cron or admin (check for service role key or secret header)
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.includes(SUPABASE_SERVICE_ROLE_KEY)) {
    return new Response("Unauthorized", { status: 401 });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const now = new Date();
  const todayStr = now.toISOString().split("T")[0];

  // Find at-risk users: had a streak >= MIN_STREAK_BEFORE_NUDGE
  // but last_logged_date is DAYS_MISSED_THRESHOLD+ days ago
  const cutoffDate = new Date(now);
  cutoffDate.setDate(cutoffDate.getDate() - DAYS_MISSED_THRESHOLD);
  const cutoffStr = cutoffDate.toISOString().split("T")[0];

  const { data: atRiskStreaks, error: streakError } = await supabase
    .from("streaks")
    .select(`
      habit_id,
      user_id,
      current_streak,
      longest_streak,
      last_logged_date
    `)
    .gte("longest_streak", MIN_STREAK_BEFORE_NUDGE) // Had a meaningful streak
    .lte("last_logged_date", cutoffStr);             // Haven't logged recently

  if (streakError || !atRiskStreaks?.length) {
    return new Response(
      JSON.stringify({ nudged: 0, reason: streakError?.message ?? "no at-risk users" }),
      { headers: { "Content-Type": "application/json" } }
    );
  }

  // Get habit names for personalization
  const habitIds = atRiskStreaks.map((s) => s.habit_id);
  const { data: habits } = await supabase
    .from("habits")
    .select("id, name, emoji")
    .in("id", habitIds)
    .is("archived_at", null); // Don't nudge archived habits

  const habitMap = new Map((habits ?? []).map((h) => [h.id, h]));

  // Get device tokens for these users
  const userIds = [...new Set(atRiskStreaks.map((s) => s.user_id))];
  const { data: tokens } = await supabase
    .from("device_tokens")
    .select("user_id, token")
    .in("user_id", userIds);

  const tokenMap = new Map<string, string>();
  for (const t of tokens ?? []) {
    tokenMap.set(t.user_id, t.token);
  }

  // Check nudge cooldown — skip users nudged within NUDGE_COOLDOWN_DAYS
  const cooldownDate = new Date(now);
  cooldownDate.setDate(cooldownDate.getDate() - NUDGE_COOLDOWN_DAYS);

  const { data: recentNudges } = await supabase
    .from("coach_nudges")
    .select("user_id")
    .gte("sent_at", cooldownDate.toISOString());

  const recentlyNudgedUsers = new Set((recentNudges ?? []).map((n) => n.user_id));

  // Build APNs JWT once for all pushes
  let jwt: string;
  try {
    jwt = await buildApnsJwt();
  } catch (e) {
    return new Response(
      JSON.stringify({ error: "Failed to build APNs JWT", detail: String(e) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  // Send nudges
  let nudgedCount = 0;
  const nudgeRecords: Array<{
    user_id: string;
    habit_id: string;
    habit_name: string;
    streak_at_nudge: number;
    template_index: number;
    sent_at: string;
  }> = [];

  // Group by user — pick the most impactful habit to nudge about
  // (highest previous streak that's now at risk)
  const userBestStreak = new Map<
    string,
    { habit_id: string; streak: number; habit_name: string; emoji: string }
  >();

  for (const streak of atRiskStreaks) {
    const habit = habitMap.get(streak.habit_id);
    if (!habit) continue;

    const userId = streak.user_id;
    const existing = userBestStreak.get(userId);
    const streakValue = streak.longest_streak;

    if (!existing || streakValue > existing.streak) {
      userBestStreak.set(userId, {
        habit_id: streak.habit_id,
        streak: streakValue,
        habit_name: habit.name,
        emoji: habit.emoji,
      });
    }
  }

  for (const [userId, best] of userBestStreak) {
    if (nudgedCount >= MAX_NUDGES_PER_RUN) break;
    if (recentlyNudgedUsers.has(userId)) continue;

    const token = tokenMap.get(userId);
    if (!token) continue;

    const template = pickTemplate(userId);
    const title = template.title;
    const body = template.body(`${best.emoji} ${best.habit_name}`, best.streak);

    const sent = await sendPush(token, title, body, jwt, {
      type: "coach_nudge",
      habit_id: best.habit_id,
    });

    if (sent) {
      nudgedCount++;
      const templateIndex = NUDGE_TEMPLATES.indexOf(template);
      nudgeRecords.push({
        user_id: userId,
        habit_id: best.habit_id,
        habit_name: best.habit_name,
        streak_at_nudge: best.streak,
        template_index: templateIndex,
        sent_at: now.toISOString(),
      });
    }
  }

  // Record nudges for cooldown tracking and analytics
  if (nudgeRecords.length > 0) {
    await supabase.from("coach_nudges").insert(nudgeRecords);
  }

  return new Response(
    JSON.stringify({
      nudged: nudgedCount,
      at_risk_users: userBestStreak.size,
      skipped_cooldown: recentlyNudgedUsers.size,
      date: todayStr,
    }),
    { headers: { "Content-Type": "application/json" } }
  );
});
