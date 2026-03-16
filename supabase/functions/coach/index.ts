import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const FREE_DAILY_LIMIT = 5;
const PRO_DAILY_LIMIT = 50;

const SYSTEM_PROMPT = `You are an expert habit coach grounded in James Clear's Atomic Habits methodology.
Your role is to help users build lasting habits through consistency — not perfection.

Core philosophy:
- Consistency beats intensity. Showing up every day, even imperfectly, compounds into transformation.
- Progress over perfection: a 2-minute version of your habit still counts.
- Never miss twice — one missed day is an accident; two is the start of a new habit.
- Long-term consistency always outperforms short-term heroics.

Key principles you embody:
- Reinforce identity through repeated action: "Every time I show up, I vote for the person I want to become."
- Celebrate the act of showing up, not just the outcome
- Use habit stacking to anchor new behaviors: "After [CURRENT HABIT], I will [NEW HABIT]"
- Design the environment to make the consistent choice the easy choice
- Reframe slips as data, not failure — what made today hard? How do we remove that friction?

Tone guidelines:
- Be warm, steady, and encouraging — like a coach who believes in long-term progress
- Redirect perfectionism back to consistency: "Done is better than perfect"
- When users celebrate wins, acknowledge the streak/consistency, not just the result
- When users struggle, focus on the next small, doable action

Keep responses concise, practical, and grounded. Ask clarifying questions when needed.`;

serve(async (req) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
  const { data: { user }, error: authError } = await supabase.auth.getUser(
    authHeader.replace("Bearer ", "")
  );

  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  }

  // Get user plan
  const { data: profile } = await supabase
    .from("profiles")
    .select("plan")
    .eq("id", user.id)
    .single();

  const isPro = profile?.plan === "pro";
  const dailyLimit = isPro ? PRO_DAILY_LIMIT : FREE_DAILY_LIMIT;

  // Count today's messages
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const { count } = await supabase
    .from("coach_usage")
    .select("*", { count: "exact", head: true })
    .eq("user_id", user.id)
    .gte("created_at", today.toISOString());

  const usedToday = count ?? 0;
  if (usedToday >= dailyLimit) {
    return new Response(
      JSON.stringify({ error: "Rate limit reached", messagesRemainingToday: 0 }),
      { status: 402 }
    );
  }

  const { message, history } = await req.json();

  // Model routing: short non-question messages → Haiku, else Sonnet
  const wordCount = message.split(/\s+/).length;
  const hasQuestion = message.includes("?");
  const model = (wordCount < 15 && !hasQuestion)
    ? "claude-haiku-4-5-20251001"
    : "claude-sonnet-4-20250514";

  const messages = [
    ...(history ?? []).slice(-6),
    { role: "user", content: message }
  ];

  const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": ANTHROPIC_API_KEY,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json"
    },
    body: JSON.stringify({
      model,
      max_tokens: 1024,
      system: SYSTEM_PROMPT,
      messages
    })
  });

  const anthropicData = await anthropicRes.json();
  const reply = anthropicData.content?.[0]?.text ?? "";
  const inputTokens = anthropicData.usage?.input_tokens ?? 0;
  const outputTokens = anthropicData.usage?.output_tokens ?? 0;

  // Log usage
  await supabase.from("coach_usage").insert({
    user_id: user.id,
    model,
    input_tokens: inputTokens,
    output_tokens: outputTokens
  });

  return new Response(
    JSON.stringify({
      reply,
      messagesRemainingToday: dailyLimit - usedToday - 1
    }),
    { headers: { "Content-Type": "application/json" } }
  );
});
