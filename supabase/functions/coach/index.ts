import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const FREE_DAILY_LIMIT = 5;
const PRO_DAILY_LIMIT = 50;

const SYSTEM_PROMPT = `You are an expert habit coach grounded in James Clear's Atomic Habits methodology.
Your role is to help users build better habits using the Four Laws of Behavior Change:
1. Make it Obvious (Cue)
2. Make it Attractive (Craving)
3. Make it Easy (Routine / 2-Minute Rule)
4. Make it Satisfying (Reward)

Key principles you embody:
- Focus on identity: "I am the type of person who..."
- Emphasize tiny habits and 1% improvements
- Use habit stacking: "After [CURRENT HABIT], I will [NEW HABIT]"
- Never miss twice rule
- Environment design over willpower
- Celebrate small wins

Keep responses concise, practical, and encouraging. Ask clarifying questions when needed.`;

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
