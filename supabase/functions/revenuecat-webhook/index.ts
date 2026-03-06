import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const REVENUECAT_WEBHOOK_SECRET = Deno.env.get("REVENUECAT_WEBHOOK_SECRET")!;

const PRO_EVENTS = new Set(["INITIAL_PURCHASE", "RENEWAL", "UNCANCELLATION"]);
const FREE_EVENTS = new Set(["CANCELLATION", "EXPIRATION", "BILLING_ISSUE"]);

serve(async (req) => {
  const authHeader = req.headers.get("Authorization");
  if (authHeader !== `Bearer ${REVENUECAT_WEBHOOK_SECRET}`) {
    return new Response("Unauthorized", { status: 401 });
  }

  const payload = await req.json();
  const event = payload.event;
  const appUserId = event?.app_user_id;

  if (!appUserId) {
    return new Response("Missing app_user_id", { status: 400 });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  let plan: string | null = null;
  if (PRO_EVENTS.has(event.type)) {
    plan = "pro";
  } else if (FREE_EVENTS.has(event.type)) {
    plan = "free";
  }

  if (plan) {
    await supabase
      .from("profiles")
      .update({ plan })
      .eq("id", appUserId);
  }

  return new Response("ok", { status: 200 });
});
