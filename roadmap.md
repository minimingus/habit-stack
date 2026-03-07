# HabitStack Roadmap

Ideas and improvements gathered through audits, user scenarios, and blueprint reviews.
Add new ideas here freely — break them down in tasks.md when ready to act.

---

## Behavioral / Psychology

- Habit difficulty progression: Level 1 → 2 → 3 unlocked after N consecutive days (requires `difficulty_level` DB column)
- "Temptation bundling" field in wizard: "I will [habit] WHILE [something I enjoy]" — store separately from craving
- Habit pairing suggestions: when creating a habit, suggest an existing habit to stack with
- "Implementation intention" prompt: "When [situation], I will [habit], because [reason]" — stronger than just a cue

## Retention & Engagement

- Weekly reflection push notification: fire Friday evening to prompt user to open app and reflect
- Comeback prompt after 5+ day absence: different tone from inactive-user notification — more personal
- Monthly summary: "You completed X habits Y times in [month]. Your best streak was Z days."
- Streak shield UI: show how shields are earned and spent (currently stored but never explained)

## Analytics & Insights

- Completion sound on habit check-off (subtle, satisfying audio feedback)
- Trend line: 4-week completion rate trend (is the user improving or declining?)
- Best time of day: which time slot has the highest completion rate for this user
- Habit correlation: "Users who complete morning run also tend to complete journaling"
- Predictive nudge: if user typically completes a habit at 8 AM and hasn't by 10 AM, send a reminder

## UX / Usability

- Quick-add flow: FAB → type name → done (single screen, skip wizard) for fast habit creation
- Swipe to complete: swipe right on habit card directly marks it done (no tap needed)
- Habit card reorder across groups: currently only within same time-of-day group
- Archive view: see and restore archived habits in Settings
- Search habits: when habit count is high, a search bar in Today view

## Identity & Four Laws

- Identity statement in habit wizard: "Who are you becoming?" field that auto-populates the identity vote statement
- Identity vote history: show how many votes cast per statement over time (trend)
- Four Laws score in Today header: a single "system health" percentage badge

## Technical / Infrastructure

- Offline mode: queue habit completions locally if no network, sync when reconnected
- iCloud backup: back up reflections and local preferences
- Widget: iOS home screen widget showing today's progress ring and habit count
- Apple Watch companion: quick check-off from wrist
- Push notifications via APNs: server-side streak-at-risk notifications (currently local only)
- Supabase Realtime: live sync across devices

## Freemium / Monetization

- Pro feature: habit templates library (pre-built habits for sleep, fitness, reading, etc.)
- Pro feature: AI-generated habit suggestions based on scorecard result
- Pro feature: CSV export of habit history
- Referral flow: "Share with a friend" → both get 7-day Pro trial

---

*Last updated: 2026-03-07*
