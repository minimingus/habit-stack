# Better You — Post-Launch Roadmap (Wave 6+)

Focus: Retention, churn reduction, and deepening user value. Consistent MRR requires users who stay and pay, not just users who start.

## The Problem

Industry data (2025-2026):
- 52% of habit tracker users churn within 30 days
- 44% churn after missing streaks (motivation cliff)
- Weekly plans retain only 6.7% of users after 12 months
- Annual plans retain 36% — 5x better

Our weekly plan ($2.99/wk) is optimized for conversion, but it's a churn risk. We need two strategies:
1. Upgrade weekly users to monthly/annual (stickier)
2. Make the app so valuable they don't want to leave

## Wave 6: Retention Engine (Weeks 2-4 Post-Launch)

### 6.1 Proactive Coach Outreach (HIGH PRIORITY)
**What:** Push notification from the AI coach when it detects slipping patterns.
- "You haven't done Morning Walk in 3 days. What's getting in the way?"
- "Your meditation streak was going strong — want to talk about restarting?"

**Why:** The coach waiting for users to ask is passive. Proactive outreach transforms the coach from a tool into a relationship. This is the #1 retention lever because it uses our unique moat (context-aware AI) to prevent churn at the moment of drop-off.

**How:** Edge function that runs daily, checks for users with 2+ day gaps on previously consistent habits, sends a personalized push via Supabase + APNs. Rate-limit to 1 proactive message per 3 days to avoid notification fatigue.

### 6.2 Weekly-to-Monthly Upgrade Nudge
**What:** After 4 weeks on a weekly plan, show in-app card: "You've been building habits for a month. Switch to monthly and save 33%."

**Why:** Weekly plans churn 5x faster than annual. Moving users to monthly/annual is the single biggest MRR stabilizer. After 4 weeks, the user has demonstrated intent — they're likely to stay if given a reason.

**How:** Track subscription start date in UserDefaults. Show upgrade card in TodayView. PostHog event: `plan_upgrade_nudge_shown`, `plan_upgrade_completed`.

### 6.3 Monthly Progress Report
**What:** Push notification + in-app card on the 1st of each month: "January recap: 78% completion, 2 milestones, strongest habit: Morning Walk."

**Why:** Makes accumulated data feel valuable. Users who see their progress are 2x more likely to continue (Nir Eyal, Hooked). Also creates a shareable moment.

**How:** Edge function that calculates monthly stats and sends push. In-app: new MonthlyRecapView accessible from analytics tab.

## Wave 7: Habit Evolution (Weeks 4-8 Post-Launch)

### 7.1 Habit Difficulty Progression
**What:** After 14 consecutive days, prompt: "You've mastered 2-minute meditation. Ready to try 5 minutes?"

**Why:** 39% of users churn from habit fatigue / repetitive structures. Progressive difficulty keeps the challenge fresh. This is the core of behavior change science — gradual escalation.

**How:** Track consecutive completions. Show progression prompt in HabitCardView. Let user accept or stay at current level. PostHog: `habit_progression_offered`, `habit_progression_accepted`.

### 7.2 Habit Stacking Suggestions
**What:** "You always do Morning Walk at 7:30 AM. Stack Reading right after — people who stack are 3x more consistent."

**Why:** Habit stacking (cue → routine → reward chains) is the most effective behavior change technique. The AI coach can suggest stacks based on actual completion timing data.

**How:** Analyze completion timestamps. Identify adjacent habits. Coach suggests stacks proactively.

### 7.3 Smart Streak Recovery
**What:** Instead of "streak broken," offer: "You missed yesterday. Complete today and tomorrow to recover your streak."

**Why:** 44% of users churn after missing a streak. Punishing lapses kills retention. Recovery gives users a path back instead of a cliff.

**How:** Add streak_shield or grace_day logic. Show recovery prompt in NeverMissTwiceBanner (already exists — extend it).

## Wave 8: Social & Data (Month 3+)

### 8.1 Accountability Partners
**What:** Pair with a friend. See each other's completion rates (not streaks — less pressure).

**Why:** Social accountability is the #1 retention driver in fitness apps. We have zero social features.

**How:** Supabase shared table. Simple invite flow via share card. Privacy-first: opt-in, completion rates only, no habit names unless shared.

### 8.2 Data Export & Year-in-Review
**What:** Pro users can export CSV of all habit data. Year-end: "Your 2026 in habits" summary.

**Why:** Data lock-in creates switching cost. Users with 6+ months of data won't leave for a competitor. Year-in-review creates a shareable viral moment.

## Priority Order

1. **6.1 Proactive coach** — highest retention impact, uses our moat
2. **6.2 Weekly upgrade nudge** — directly stabilizes MRR
3. **7.3 Smart streak recovery** — prevents the #1 churn trigger
4. **6.3 Monthly progress report** — reinforces value, low effort
5. **7.1 Habit progression** — prevents fatigue churn
6. **7.2 Habit stacking** — deepens behavior change value
7. **8.1 Accountability partners** — social retention (higher effort)
8. **8.2 Data export** — lock-in (lower priority)

## Retention Targets

| Metric | Launch | Month 3 Target | Month 6 Target |
|--------|--------|---------------|----------------|
| D1 Retention | ? | 60% | 65% |
| D7 Retention | ? | 40% | 50% |
| D30 Retention | ? | 25% | 35% |
| Monthly churn (weekly plan) | ? | <30% | <20% |
| Monthly churn (annual plan) | ? | <5% | <3% |
| Weekly → Monthly upgrade rate | — | 15% | 25% |
