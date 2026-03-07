# HabitStack — Retention & UX Polish Design

**Date:** 2026-03-07
**Status:** Approved

---

## Overview

Seven cohesive improvements across retention, daily engagement, and UX friction reduction. No new backend schema required except one RPC for streak shield spending.

---

## Section 1: Habit Card Redesign

### 1a. Emoji → Colored Identity Dot
- Replace `Text(habit.emoji).font(.title3)` in `HabitCardView` with a 40×40 filled circle using `habit.color`, containing the first letter of the habit name in white `.headline` font.
- Emoji retained as 56pt hero in `HabitDetailView` only.
- Fixes emoji baseline jitter and mixed rendering across glyph types.

### 1b. Remove Rating Dot
- Remove the rating badge (`·` / `+` / `=` / `-`) and its `.confirmationDialog` from `HabitCardView` entirely.
- Rating ownership stays in the Scorecard tab.
- Card right side: `[timer chip] [streak badge]` only.

### 1c. Swipe Right = Complete
- Replace leading swipe action (currently Edit) with Complete/Uncomplete.
- Complete: teal background, checkmark icon. Uncomplete: Stone background, xmark icon.
- Edit moves to context menu only (already present there).

### 1d. Friction Warning → Mini-Editor
- Replace dead `⚠️` triangle with a tappable `"Needs setup"` orange capsule chip.
- Chip condition: `!habit.reminderEnabled && (habit.tinyVersion ?? "").isEmpty`
- Tapping opens a `.sheet` with two fields only: "2-minute version" text field + reminder toggle + time picker.
- On save: calls `HabitService.updateHabit()`, sheet dismisses.
- No full wizard needed.

**Files:** `HabitCardView.swift`, new `HabitFrictionSheet.swift`

---

## Section 2: Hold-to-Complete

Revert `HoldCompleteButton` from tap-to-complete back to press-and-hold with a fill ring.

### Behaviour
- Press and hold: circular progress ring fills over 0.6 seconds.
- Driven by a `Timer.scheduledTimer(withTimeInterval: 0.02)` incrementing `progress` by `0.02/0.6`.
- Ring: `Circle().trim(from: 0, to: progress).stroke(accentColor, lineWidth: 3)` layered over the base circle.
- At `progress >= 1.0`: fire `.medium` haptic, call `onComplete()`, invalidate timer.
- Release before 100%: invalidate timer, spring `progress` back to 0.
- Uncomplete: single tap (deliberate undo, not accident-prone).
- `isPressed` scale effect (0.92) retained for press feedback.

**Files:** `HoldCompleteButton.swift`

---

## Section 3: Completion Note — Opt-In

Remove the automatic 0.4s note sheet trigger.

### Behaviour
- Remove both `DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showNote = true }` calls from `HabitCardView` (binary and quantified completion paths).
- After completion, a pencil icon button fades in on the card's right side (below streak badge) with `.transition(.opacity).animation(.easeInOut(duration: 0.3))`.
- Icon visible only when `habitWithStatus.isCompleted`.
- Tapping it sets `showNote = true`, opening `CompletionNoteSheet` as before.
- Icon does not auto-dismiss; stays until habit is uncompleted.

**Files:** `HabitCardView.swift`

---

## Section 4: FAB Simplification

Remove the confirmation dialog from the FAB.

### Behaviour
- FAB tap → directly open `HabitWizardView` (no `confirmationDialog`).
- Remove `showAddOptions` state and `.confirmationDialog` block.
- Inside `WizardStepCueView`, add a `"See all templates →"` button at the end of the Quick Pick horizontal scroll row. Tapping it opens `HabitTemplateLibraryView` as a sheet from within the wizard.
- `HabitTemplateLibraryView` sheet: on template select, dismiss library, prefill wizard fields.

**Files:** `TodayView.swift`, `WizardStepCueView.swift`

---

## Section 5: Retention Features

### 5a. Perfect Day Celebration
- In `TodayViewModel.toggleHabit()`: after a successful completion, if `completedHabits == totalHabits && totalHabits > 0`, check `UserDefaults` key `"perfectDay_\(todayDateString)"`.
- If not yet fired today: set the key, set `showMilestone = true` with a new `.perfectDay` milestone type.
- `MilestoneCelebrationView` gets a new variant for perfect day: title "Perfect Day", subtitle "Every habit. Every day. That's identity.", gold confetti tint, +25 bonus XP awarded via existing `increment_xp` RPC.

### 5b. Streak Calendar
- New `StreakCalendarView` card in `AnalyticsView`, inserted above `HeatmapView`.
- Shows current month as a grid of day squares (7 columns).
- Per day: fetch from existing `habit_logs` — if all habits logged `done` = filled teal; any done = half-filled (teal opacity 0.4); none = Stone100.
- Data computed in `AnalyticsViewModel` as `[Date: CalendarDayStatus]` enum (`.full`, `.partial`, `.empty`).
- No new Supabase query — reuses logs already fetched for heatmap.

### 5c. Comeback Celebration
- In `TodayView`, observe `viewModel.showNeverMissTwice`.
- When banner is visible and `viewModel.completedHabits` transitions from 0 → 1: swap banner content to comeback variant: teal background, "You're back. Streak lives on." text, auto-dismiss after 3 seconds.
- Implemented via a new `viewModel.neverMissTwiceState: NeverMissTwiceState` enum (`.warning`, `.comeback`, `.dismissed`).

### 5d. Sound Design
- On hold-complete success in `HoldCompleteButton.onEnded` (when `progress >= 1.0`): call `AudioServicesPlaySystemSound(1104)` (the standard iOS keyboard click — short, satisfying).
- Import `AudioToolbox`.
- Respects silent mode automatically via system sound APIs.

### 5e. Achievement Gallery
- New `AchievementsView` embedded as a section at the bottom of `AnalyticsView`.
- Achievements defined as a static array of `Achievement` structs: `{ id, name, description, emoji, milestoneKey }`.
- Milestone keys: `"milestone_7"`, `"milestone_14"`, `"milestone_21"`, `"milestone_30"`, `"milestone_66"`, `"milestone_100"`, `"perfectDay"`.
- Keys stored in `UserDefaults` as `Bool` when milestone fires.
- Gallery: 3-column grid. Earned = full color + name. Locked = greyed out + unlock condition.

**Files:** `TodayViewModel.swift`, `MilestoneCelebrationView.swift`, `AnalyticsView.swift`, `AnalyticsViewModel.swift`, `HoldCompleteButton.swift`, new `StreakCalendarView.swift`, new `AchievementsView.swift`

---

## Section 6: Level Perks

### L5 — Streak Freeze (Spendable Shields)
- `NeverMissTwiceBanner` gains a "Use Shield" button, visible when `profile.level >= 5 && profile.streakShields > 0`.
- Tapping calls a new Supabase RPC `spend_streak_shield(habit_id)` that: decrements `profiles.streak_shields` by 1, inserts a `skipped` log for yesterday for all habits with active streaks, preserves streak counts.
- On success: banner flips to comeback variant (5c).
- New migration: `supabase/migrations/003_spend_streak_shield.sql`.

### L10 — Habit Insights Upgrade
- `HabitInsightsCard` in `AnalyticsView`: if `profile.level >= 10`, show a third metric "Best time of day" — computed from which `time_of_day` group has highest completion rate in `AnalyticsViewModel`.
- If `profile.level < 10`: show a lock badge overlay on the card with "Unlock at Level 10".

**Files:** `NeverMissTwiceBanner.swift`, `TodayViewModel.swift`, `AnalyticsView.swift`, `AnalyticsViewModel.swift`, new `supabase/migrations/003_spend_streak_shield.sql`

---

## Section 7: Archived Habit Recovery

- New `ArchivedHabitsView`: fetches `habits` where `archived_at IS NOT NULL` for current user, ordered by `archived_at DESC`.
- Each row: color dot + habit name + archive date.
- Trailing swipe: "Restore" → calls `HabitService.restoreHabit(_ habitId: UUID)` which sets `archived_at = null`.
- Accessible via `NavigationLink` in `SettingsView` under a new "Data" section (above Developer).
- `HabitService` gains `func restoreHabit(_ habitId: UUID) async throws`.

**Files:** `SettingsView.swift`, `HabitService.swift`, new `ArchivedHabitsView.swift`

---

## Files Changed Summary

| File | Change |
|------|--------|
| `HabitCardView.swift` | Color dot, remove rating, swipe complete, pencil note, friction chip |
| `HoldCompleteButton.swift` | Hold-to-fill ring, sound on complete |
| `TodayView.swift` | FAB direct to wizard, no dialog |
| `TodayViewModel.swift` | Perfect day detection, comeback state enum, shield spend |
| `WizardStepCueView.swift` | "See all templates" link |
| `MilestoneCelebrationView.swift` | Perfect day variant |
| `AnalyticsView.swift` | Streak calendar card, achievements section, L10 insights gate |
| `AnalyticsViewModel.swift` | Calendar data, best time of day computation |
| `NeverMissTwiceBanner.swift` | Comeback variant, Use Shield button |
| `SettingsView.swift` | Archived habits link |
| `HabitService.swift` | `restoreHabit()` method |
| `supabase/migrations/003_spend_streak_shield.sql` | RPC for shield spending |
| new `HabitFrictionSheet.swift` | Mini two-field editor |
| new `StreakCalendarView.swift` | Monthly chain calendar |
| new `AchievementsView.swift` | Achievement gallery grid |
| new `ArchivedHabitsView.swift` | Restore archived habits |

---

## Verification

1. Card: emoji gone from row, colored letter dot shows; rating dot gone; swipe right completes with haptic
2. Hold circle: fill ring animates on press, fires at 100%, cancels cleanly on early release
3. Note: no auto-sheet after completion; pencil icon appears; tapping opens note sheet
4. FAB: single tap opens wizard; "See all templates" inside wizard step 1 works
5. Perfect day: complete all habits → gold celebration fires once per day
6. Streak calendar: month grid shows full/partial/empty days correctly
7. Comeback: miss yesterday, open app → orange banner; complete first habit → banner flips teal
8. Sound: completion plays subtle click; silent mode = no sound
9. Achievements: complete a 7-day streak → badge fills in gallery
10. L5: NeverMissTwiceBanner shows "Use Shield" when level >= 5 and shields > 0
11. L10: insights card locked below L10, unlocked at L10 with best-time metric
12. Archived: archive a habit, go to Settings → Archived → restore → appears in Today
