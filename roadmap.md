# HabitStack Roadmap

Ideas and improvements gathered through audits, user scenarios, and blueprint reviews.
Status: ✅ Done · 🔄 In Progress · ⬜ Planned

---

## Session: 2026-03-10 — Bug Fixes & UX Improvements

| Status | Feature | Notes |
|--------|---------|-------|
| ✅ | Multiple reminders per habit | Wizard Step 4 allows adding up to 2 extra reminder times; stored in UserDefaults; each scheduled independently |
| ✅ | Fix "Custom" frequency | CustomDayPicker (S M T W T F S) in wizard; stored in UserDefaults; TodayViewModel filters by isScheduledToday |
| ✅ | "Crushing it" / mood feedback response | WeekMood enum (crushing/good/tough/rough) with SF Symbol, ReflectionResponseView with contextual message |
| ✅ | Hold-to-complete increments count by 1 | Hold gesture adds 1 to currentCount for quantified habits; auto-completes at target |
| ⬜ | Old habits → new habits transition | Scorecard "no habits" bug: after onboarding scorecard, Today shows no habits (wizard creates one but page is empty); surface old/bad habits as candidates for replacement; Atomic Habits: replace the old routine, keep the same cue+reward |

---

## Session: 2026-03-09 — UX Polish & New Features

| Status | Feature | Notes |
|--------|---------|-------|
| ✅ | Wrapping chip grid in wizard | ChipGrid Layout replaces horizontal scroll; SuggestionChip component |
| ✅ | Input-aware suggestion chips | Chips filter as user types across all 4 wizard steps |
| ✅ | Template library deduplication | Already-active habits hidden from Quick Pick and template library |
| ✅ | Hold-to-complete for count habits | HoldCompleteButton extended with backgroundProgress + centerLabel |
| ✅ | Weekly reflection timing fix | No longer fires immediately after onboarding |
| ✅ | Remove emoji picker | Removed broken emoji grid from wizard Step 1 |
| ✅ | Habit pause with streak protection | pause_until DB column; PauseHabitSheet (1d/3d/1w/2w); skipped logs on resume |
| ✅ | What's New walkthrough system | WhatsNewRegistry + WhatsNewSheet; one-line to add future features |

---

## Suggested Improvements — Simple (Next Up)

| Status | Feature | Notes |
|--------|---------|-------|
| ✅ | Home screen widget | Progress ring + incomplete count. WidgetKit, no server calls needed |
| ✅ | Streak safe on edit callout | One-time banner in wizard header: "{N}-day streak is safe — editing never resets it." |
| ✅ | Compact card mode | Settings toggle to shrink habit cards to single row (no subtitle, smaller button) |
| ⬜ | Batch time-group complete | Long-press time-of-day header ("Morning") → confirm → marks all habits in group done |
| ✅ | Streak share card | After milestone sheet, offer Share button → ImageRenderer card (name, streak, identity) |

---

## Suggested Improvements — Medium

| Status | Feature | Notes |
|--------|---------|-------|
| ⬜ | Siri Shortcuts | AppIntents: "Hey Siri, log my morning run" — completion without unlocking |
| ✅ | Habit insight cards in Analytics | Best day of week, current vs longest streak delta, "on track for X-day milestone" countdown |
| ✅ | Environment design prompt | One-time tip after habit creation: "To make this obvious: [cue-derived tip]" |
| ⬜ | Habit difficulty log | After completing, optionally rate 1–3 (easy/medium/hard); surfaces as effort trend in Analytics |

---

## Suggested Improvements — Deeper (Plan First)

| Status | Feature | Notes |
|--------|---------|-------|
| ⬜ | Accountability partner | Read-only progress share link; one person sees your streak, can't modify |
| ⬜ | Habit levels | Level 1→2→3 unlocked after N consecutive days; requires difficulty_level DB column |
| ⬜ | Temptation bundling | "I will [habit] WHILE [something I enjoy]" field in wizard — store separately from craving |

---

## Behavioral / Psychology

| Status | Feature | Notes |
|--------|---------|-------|
| ⬜ | Habit pairing suggestions | When creating a habit, suggest an existing one to stack with |
| ⬜ | Implementation intention prompt | "When [situation], I will [habit], because [reason]" — stronger than just a cue |

---

## Retention & Engagement

| Status | Feature | Notes |
|--------|---------|-------|
| ⬜ | Weekly reflection push notification | Fire Friday evening to prompt user to reflect |
| ⬜ | Comeback prompt after 5+ day absence | Different tone from inactive-user notification |
| ⬜ | Monthly summary | "You completed X habits Y times. Your best streak was Z days." |
| ⬜ | Streak shield UI | Explain how shields are earned and spent (currently stored but never surfaced) |

---

## Analytics & Insights

| Status | Feature | Notes |
|--------|---------|-------|
| ⬜ | 4-week completion trend line | Is the user improving or declining? |
| ✅ | Predictive nudge | If user typically completes at 8 AM and hasn't by 10 AM, send a reminder |
| ⬜ | Habit correlation | "Users who complete morning run also tend to complete journaling" |

---

## Technical / Infrastructure

| Status | Feature | Notes |
|--------|---------|-------|
| ⬜ | Offline mode | Queue completions locally, sync when reconnected |
| ⬜ | Apple Watch companion | Quick check-off from wrist |
| ⬜ | Push notifications via APNs | Server-side streak-at-risk notifications (currently local only) |
| ⬜ | Supabase Realtime | Live sync across devices |
| ⬜ | iCloud backup | Back up reflections and local preferences |

---

## Freemium / Monetization

| Status | Feature | Notes |
|--------|---------|-------|
| ⬜ | CSV export of habit history | Pro feature |
| ⬜ | AI-generated habit suggestions | Based on scorecard result — Pro feature |
| ⬜ | Referral flow | "Share with a friend" → both get 7-day Pro trial |

---

*Last updated: 2026-03-09*
