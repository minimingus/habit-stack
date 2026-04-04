# Better You — Launch Content Drafts

Ready-to-post content for launch day. Copy, paste, ship.

---

## 1. Reddit: r/getdisciplined

**Title:** I tracked what actually changed when I focused on identity instead of goals for 90 days

**Body:**

For years I set goals like "work out 4x/week" and "read 20 books this year." I'd go hard for 2-3 weeks, then fall off.

What changed was reframing the question. Instead of "what do I want to achieve?" I started asking "who do I want to become?"

I picked three traits: disciplined, focused, healthier. Then I asked: what would a disciplined person do today? Not next month. Today.

The shift sounds small but it changes everything:
- Goals feel distant. Identity feels present.
- Goals let you quit after achieving them. Identity is ongoing.
- Goals create pass/fail. Identity creates direction.

I started with 3 tiny habits aligned to those traits. Morning walk (healthier). 10 minutes reading (focused). Making my bed (disciplined). The point wasn't doing hard things. It was showing up consistently.

90 days in:
- I haven't missed the morning walk in 67 days
- I've read 11 books without a "20 books" goal
- The habits feel automatic now, not effortful

The compound effect is real but it's slow. Week 1 feels pointless. Week 3 you notice patterns. By week 8 other people start commenting.

If you're stuck in the goal-fail-guilt cycle, try this: pick who you want to be, then ask what that person does daily. Start with something you can't fail at. Build from there.

---

## 2. Reddit: r/productivity

**Title:** I built an AI habit coach that actually knows what you're working on (instead of giving generic advice)

**Body:**

I got frustrated with AI productivity tools because they all give the same generic advice. "Try the Pomodoro technique!" "Have you considered journaling?" They don't know anything about you.

So I built an iOS habit tracker with a built-in AI coach that has full context on:
- What habits you're tracking
- Your current streaks
- Which habits you're struggling with
- Your identity goals (who you want to become)

The difference is real. Instead of "try to be more consistent," you get "You've completed Morning Walk 12 days straight but Meditation has a 3-day gap. What's making meditation harder this week?"

It's called Better You. Free for up to 5 habits and 5 coach messages/day.

The identity-based approach is the core differentiator. During onboarding, you pick traits like "focused" or "healthier," and the app suggests habits aligned to those traits. You swipe right to adopt them (yes, like a dating app for habits).

Technical stack for anyone curious: SwiftUI, Supabase backend, Claude API for the coach (via edge function with rate limiting), RevenueCat for subscriptions, PostHog for analytics.

Would love feedback from anyone who tries it.

---

## 3. Product Hunt

**Tagline:** Build habits based on who you want to become, not to-do lists

**Description:**

Better You is a habit tracker that starts with identity, not tasks.

Most habit apps ask "what do you want to do?" We ask "who do you want to become?" Pick your future self traits, swipe to adopt aligned habits, and track your consistency with an AI coach that actually knows your journey.

**Key features:**
- Identity-first onboarding — choose who you want to become
- Swipe-to-adopt — browse personalized habit suggestions like a dating app
- AI Coach — context-aware advice based on your real habits and streaks
- Streak milestones at 7, 14, 21, 30, and 66 days
- Weekly reflections to course-correct
- Share cards for milestone celebrations

**Free:** 5 habits, 5 coach messages/day, full streak tracking
**Pro:** Unlimited habits, 50 coach messages/day, full analytics ($7.99/mo or $59.99/yr with 7-day free trial)

**Maker Comment:**

Hey PH! I'm Tomer, and I built Better You because I kept failing at habits the same way — set a goal, go hard, burn out, feel guilty, repeat.

The breakthrough was shifting from "what do I want to achieve" to "who do I want to become." When you tie habits to identity, showing up daily stops feeling like discipline and starts feeling like self-expression.

The AI coach is what I'm most proud of. Unlike generic AI assistants, it knows your actual habits, streaks, and goals. So when you ask "why can't I stick with meditation?" it can say "You've done Morning Walk for 14 days straight — what makes that one easier? Can we apply that to meditation?"

I built this as a solo dev using SwiftUI + Claude API. Happy to answer any technical or product questions.

Try it free: [App Store link]

---

## 4. Hacker News — Show HN

**Title:** Show HN: Better You – iOS habit tracker with a context-aware AI coach

**Body:**

I built an iOS habit tracker where the AI coach has full context on your habits, streaks, and identity goals.

Most AI integrations in consumer apps are "paste your question, get a generic response." I wanted the coach to actually know what you're working on. So the coach system prompt includes your active habits, current streaks, completion rates, and the identity traits you selected during onboarding.

The difference: instead of "try starting small," you get "Your Morning Walk streak is at 14 days but Meditation dropped off 3 days ago — what changed?"

Tech stack:
- SwiftUI (iOS 17+, @Observable pattern)
- Supabase (auth, Postgres, edge functions)
- Claude API via Supabase edge function (rate-limited per user tier)
- RevenueCat (subscriptions)
- PostHog (analytics, 22 events across the full funnel)

The edge function handles context assembly — it fetches the user's habits, streaks, and profile, then builds a system prompt with that context before calling Claude. Free users get 5 messages/day, Pro gets 50.

Interesting design decisions:
1. Identity-first onboarding: users pick "who they want to become" (e.g., Focused, Healthier) before selecting habits. This frames habit selection as self-expression, not task management.
2. Swipe-to-adopt: habits are presented as cards you swipe right to adopt or left to skip. Lower friction than form-based habit creation.
3. Hold-to-complete: marking a habit done requires a press-and-hold gesture. Adds a moment of intentionality vs. accidental taps.

Free tier: 5 habits, 5 coach messages/day. Pro: $7.99/mo.

Source: https://github.com/minimingus/habit-stack (happy to open-source the edge functions if there's interest)

---

## 5. Twitter/X — Launch Thread

**Tweet 1 (Launch):**
I just launched Better You — an iOS habit tracker with an AI coach that actually knows your habits.

Most habit apps track tasks. We track identity.

Pick who you want to become. Swipe to adopt habits. Get coaching that knows your streaks, struggles, and goals.

Free on the App Store. [link]

**Tweet 2:**
The core insight: "I want to run 3x/week" fails because goals have an endpoint.

"I'm becoming a runner" works because identity is ongoing.

Better You starts with "Who do you want to become?" and builds habits around that answer.

**Tweet 3:**
The AI coach is what makes this different.

It knows:
- Your active habits
- Current streaks
- Where you're struggling
- Your identity goals

So instead of generic advice, you get: "You've done Morning Walk for 14 days — what makes that easier than Meditation?"

**Tweet 4:**
Built as a solo dev:
- SwiftUI + @Observable
- Supabase backend
- Claude API for coaching
- RevenueCat subscriptions
- PostHog analytics

Shipping > perfecting. 0 to App Store in [X] weeks.

**Tweet 5:**
Free: 5 habits, 5 coach messages/day, streaks, weekly reflections.

Pro ($7.99/mo): Unlimited everything.

7-day free trial. No credit card until you decide.

Try it: [App Store link]

---

## 6. IndieHackers — Launch Post

**Title:** Launched Better You — AI-powered habit tracker. $0 MRR, Day 1.

**Body:**

Just launched on the App Store. Here's the honest state of things:

**What it is:** An iOS habit tracker that starts with identity ("who do you want to become?") instead of tasks ("what do you want to do?"). Includes an AI coach with full context on your habits and streaks.

**The bet:** Most habit apps are glorified checklists. The ones that work long-term connect actions to identity. Our AI coach adds personalized guidance that generic tools can't match.

**Business model:**
- Free: 5 habits, 5 coach messages/day
- Pro: $7.99/mo or $59.99/yr (7-day free trial)
- Variable cost: Claude API calls (~$0.01-0.03 per coach conversation)

**Current numbers:**
- MRR: $0
- Downloads: TBD
- Cost to build: ~$99 (Apple Developer) + time
- Monthly costs: ~$25 (Supabase) + API usage

I'll post monthly updates here with real numbers. Following the build-in-public playbook.

Questions I'm wrestling with:
1. Is $7.99/mo too high for a new app with no reviews?
2. How aggressive should free tier limits be?
3. Reddit vs. paid acquisition — where to invest first $500?

Would love input from anyone who's launched a subscription iOS app.
