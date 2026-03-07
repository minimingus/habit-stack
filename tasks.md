# HabitStack Tasks

Status: `[ ] pending` · `[~] in progress` · `[x] complete` · `[-] won't do`

---

## Phase 1 — Foundation (Bootstrap + Backend)

- [x] Xcode project with XcodeGen (`project.yml`)
- [x] SPM dependencies: Supabase, RevenueCat, PostHog
- [x] Asset catalog colors: Teal, TealLight, Stone950, Stone500, Stone100
- [x] Secrets.plist pattern (git-ignored)
- [x] Supabase schema: habits, habit_logs, streaks, profiles, identity_votes, coach_usage, device_tokens
- [x] RLS policies (owner-only access)
- [x] Auth trigger: auto-create profile on signup (idempotent, with ON CONFLICT)
- [x] Edge function: coach (rate-limited, model-routed, Anthropic API)
- [x] Edge function: streak-calc (XP + streak webhook)
- [x] Edge function: revenuecat-webhook (plan sync)
- [x] increment_xp RPC function

## Phase 2 — Auth & Onboarding

- [x] AuthView: sign in + sign up buttons
- [x] SignUpView
- [x] Onboarding flow: Welcome → Scorecard Gate → Questions → Result → Wizard → Notifications
- [x] Scorecard: 4 questions, dimension scoring, tie-break logic
- [x] ScorecardResultView: animated ring, dimension bars, habit template pre-fill
- [x] Back navigation in scorecard questions
- [x] NotificationPermissionView
- [x] Profile saved to Supabase on completion

## Phase 3 — Core Habit Tracking

- [x] HabitWizard: 4-step sheet (Cue → Craving → Routine → Reward)
- [x] Emoji picker grid in wizard step 1
- [x] Color picker in wizard step 1
- [x] Cue suggestions + custom field
- [x] Identity framing in craving step ("I am becoming the type of person who...")
- [x] 2-minute rule field (tinyVersion)
- [x] Time of day + frequency pickers
- [x] Reminder toggle + time picker
- [x] Anchor habit (habit stacking) picker
- [x] Free tier: 5-habit limit enforced in HabitService
- [x] TodayView: habits grouped by time of day
- [x] Progress ring with % and momentum message
- [x] HabitCardView: check button, streak badge, anchor label, tiny version
- [x] Confetti animation on completion
- [x] Long press context menu (Edit / Archive)
- [x] Swipe actions: Edit (leading), Archive (trailing)
- [x] Drag to reorder within time-of-day group
- [x] Friction indicator: warning when no reminder + no tiny version
- [x] HabitDetailView: streak stats, 7-day completion rate, Four Laws breakdown, identity card
- [x] Optimistic completion toggle
- [x] Skeleton loading state

## Phase 4 — Streaks & XP

- [x] Streak tracking (current + longest)
- [x] StreakBadge in habit cards
- [x] XP / Level system (XPHeaderView)
- [x] Streak shields display
- [x] XP toast on completion
- [x] Identity toast (alternates with XP toast)
- [x] Milestone celebration modal at 7 / 14 / 21 / 30 / 66 / 100 days
- [x] Streak milestone progress bar in AnalyticsView
- [x] "Next milestone" indicator in StreakBarView

## Phase 5 — Analytics

- [x] Heatmap: 5-week Canvas grid (done/skipped/none)
- [x] Heatmap legend
- [x] Cell tap → detail sheet
- [x] Habit picker (select which habit to inspect)
- [x] StreakBarView: current + best + next milestone
- [x] Weekly consistency score card (avg % across all habits, 7 days)
- [x] Strongest / weakest habit insight cards
- [x] Day-of-week bar chart
- [x] Free tier: 7-day history limit
- [x] Pull-to-refresh

## Phase 6 — Identity & Four Laws Tab

- [x] Identity Hero Card (top identity statement)
- [x] Habit System Health: Four Laws score bars per law
- [x] Identity votes list (top 3 with vote counts)
- [x] Manual vote button
- [x] Identity empty state
- [x] Identity statement in Today header (XPHeaderView)

## Phase 7 — AI Coach

- [x] Chat UI with message bubbles
- [x] Quick suggestion chips
- [x] Usage bar (X/Y messages today)
- [x] Persistent conversation (UserDefaults, 50-message cap)
- [x] Daily limit reset
- [x] Clear conversation button
- [x] Rate limit → Paywall sheet
- [x] Free: 5 messages/day · Pro: 50 messages/day

## Phase 8 — Retention & Notifications

- [x] Never Miss Twice banner (majority of habits missed yesterday)
- [x] EOD recovery notification at 9 PM (if habits incomplete)
- [x] Streak-at-risk notification at 8 PM
- [x] Inactive user reminder (5 days from last open)
- [x] Miss-2-days encouragement notification at 9 AM
- [x] Smart reminder content (streak count or tiny version in body)
- [x] Weekly reflection sheet (triggered every 7 days)
- [x] Reflection snooze ("Remind me in 4 hours")
- [ ] Weekly reflection push notification (fire Friday evening)

## Phase 9 — Paywall & Settings

- [x] PaywallView: monthly + annual options, restore purchases
- [x] SettingsView: email, plan badge, sign out
- [x] AdminSpendView (coach usage / cost)
- [x] RevenueCat integration: plan sync via webhook

## Backlog (from roadmap)

- [ ] Completion sound on habit check-off
- [ ] Habit difficulty progression (Level 1 → 2 → 3, requires DB column)
- [ ] Weekly reflection push notification
- [ ] Quick-add flow (name only, skip wizard)
- [ ] Archive view (see + restore archived habits)
- [ ] Trend line in analytics (4-week completion rate)
- [ ] Monthly summary screen or notification
- [ ] iOS home screen widget
- [ ] Habit templates library (Pro feature)
- [ ] CSV export (Pro feature)
- [ ] Offline mode with sync queue
- [-] Apple Watch companion (out of scope for now)
- [-] Habit correlation / predictive nudge (requires ML, out of scope)
