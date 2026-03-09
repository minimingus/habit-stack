# Research: Old → New Habits Transition

**Roadmap item:** "Find a way to show the 'old habits' relationship to the new habits; today if a user takes the habit scorecard during onboarding, they are shown 'no habits' which is incorrect. What does the book say about the transition from existing to new, better habits?"

---

## 1. The Bug

### What happens today

The onboarding sequence is:

```
Welcome → ScorecardOnboarding → NotificationPermission → Complete → TodayView
```

`ScorecardOnboardingView` collects behaviors across 4 time periods (morning / afternoon / evening / night), then hands off to `HabitsScorecardView` for rating (+/=/–). All of this is stored in `UserDefaults` as `[ScorecardEntry]` objects.

Crucially, **no `Habit` rows are ever written to Supabase during onboarding**. The scorecard is purely a local behavior inventory. When the user taps "Continue →" in the scorecard, `OnboardingViewModel.advance()` moves to `.notificationPermission`, then `.complete`, which sets `onboardingComplete = true` and the app transitions to `MainTabView`.

`TodayView` then calls `loadToday()`, which queries `habits` in Supabase for the current user. On a fresh account the result is an empty array, so `totalHabits == 0` and the empty state fires:

```swift
// TodayView.swift:15–22
} else if viewModel.totalHabits == 0 {
    EmptyStateView(
        icon: "checkmark.circle",
        headline: "No habits yet",
        subtext: "Start with just one habit. Small beats ambitious.",
        cta: "Add Habit",
        onCTA: { showHabitWizard = true }
    )
}
```

The user just spent several minutes mapping their entire day — and the app greets them with a blank slate. The scorecard work is invisible from the Today tab. There is no connection drawn between "what I rated" and "what I could build."

### Why "no habits" feels wrong

The user performed meaningful work (behavior inventory). The app has that data (in `UserDefaults` via `ScorecardEntry.load()`). But Today acts as if the onboarding never happened. This creates a cognitive gap: the user's mental model is "I told the app what I do" but the app's state is "you have no habits." The framing is also off — "No habits yet" implies the user hasn't thought about habits at all, which is false.

---

## 2. The Existing "Replace It" Flow

The codebase already implements a behavior-replacement path, but it lives exclusively inside `HabitsScorecardView` (the Identity tab), not at the end of onboarding:

1. User rates a behavior **negative** (–) → `ScorecardEntryRow` shows a "Replace it" `Label("Replace it", systemImage: "arrow.right")` button inline under the behavior name.
2. Tap → `replacingBehavior` is set → `HabitWizardView(replacingBehavior: behavior)` sheet opens.
3. `HabitWizardViewModel.prefill(replacing:)` pre-fills the cue field: `"When I feel like \(behavior)"`.
4. `WizardStepCueView` shows a banner: *"Same cue, new routine. Keep what triggers it — change what you do."*
5. On wizard save, the scorecard entry is removed from the list.

This flow is sound. Its problem is **discoverability and timing**: it only surfaces for negatively-rated behaviors, it requires navigating to the Identity tab, and it is not shown at the natural moment of transition — right after the user finishes rating.

---

## 3. What Atomic Habits Says

### The Habit Scorecard (Chapter 4)
Clear's "Habits Scorecard" is a self-awareness exercise: write down everything you do each day, then mark each + / = / –. The explicit purpose is to make the unconscious conscious. It is **not** the endpoint — it is the diagnostic. The natural next step is design.

> "The purpose of the Habits Scorecard is simply to get a clearer picture of what actually happens each day."

The app's scorecard correctly implements this. The gap is the missing "what now?" bridge.

### The Golden Rule of Habit Change (Chapter 12)
Clear's central claim about breaking bad habits:

> "You can't eliminate a bad habit, you can only replace it."

The mechanism: **keep the same cue and reward; substitute only the routine**.

| Component | Old Habit | New Habit |
|-----------|-----------|-----------|
| Cue       | Same      | Same      |
| Routine   | Bad       | Good      |
| Reward    | Same      | Same      |

The app already captures this in the "Replace it" banner copy: *"Same cue, new routine."* The insight needs to be brought earlier, into the moment right after rating.

### Habit Stacking (Chapter 5)
Implementation intention formula: *"After I [CURRENT HABIT], I will [NEW HABIT]."*

This is directly relevant to positive (+) behaviors: rather than replacing them, the user can **stack** a new habit onto an existing cue. The `anchorHabitId` field in `HabitWizardViewModel` supports this but is never surfaced from the scorecard.

For example: User rates "Morning coffee" as positive. The natural next action is not "Replace it" but "Stack after it" — e.g., *"While I wait for the coffee to brew, I will read for 2 minutes."*

### Identity-Based Habits (Chapters 1–3)
Clear argues that lasting change comes from identity first, behavior second:

> "The most effective way to change your habits is to focus not on what you want to achieve, but on who you wish to become."

The scorecard rating is implicitly an identity statement. A negative (–) rating is the user saying: *"I don't want to be the person who does this."* The app should reflect that back and bridge it to the wizard's craving step, which asks "Why does this matter to me?"

### The First Step Is Never the Habit (Chapter 1)
Clear emphasizes that habits are not about single actions but about systems and environment:

> "You do not rise to the level of your goals. You fall to the level of your systems."

The scorecard reveals the current system. The wizard designs the new one. The transition between them needs to be explicit.

---

## 4. Design Space

### Option A — Post-Scorecard "Design One Habit" Prompt (Low effort)

After the user taps "Continue →" in the onboarding scorecard, before advancing to `NotificationPermission`, show an interstitial:

- Pull the **first negatively-rated behavior** from `ScorecardEntry.load()`.
- Show: *"You rated [Behavior] as a habit to change. Want to replace it with something better?"*
- Two CTAs: **"Replace it →"** (opens wizard with `replacingBehavior` pre-filled) and **"I'll do this later"** (advances to notifications).

This reuses the existing replace flow with zero new architecture. The wizard save completes normally; onboarding then advances.

**Pro:** Minimal code, high impact, directly guided.
**Con:** Only addresses negative behaviors; skips positive-behavior stacking; forces one-habit creation.

---

### Option B — Post-Onboarding Empty State Context-Awareness (Medium effort)

When `totalHabits == 0` AND `ScorecardEntry.load()` is non-empty (user has done the scorecard), show a **different** empty state:

```
icon: clipboard or chart
headline: "Your habit inventory is ready"
subtext: "You mapped [N] daily behaviors. Pick one to replace or build on."
cta: "Review my behaviors →"
onCTA: { navigate to Identity tab, open scorecard sheet }
```

This acknowledges the work done in onboarding and provides a clear next action. The empty state would read `ScorecardEntry.load().count` to detect the scorecard-complete state.

**Pro:** No change to onboarding flow; Today tab becomes contextually smart.
**Con:** Still requires the user to navigate away from Today; doesn't create the habit.

---

### Option C — "Positive Habit → Stack It" in Scorecard (Medium effort)

The existing scorecard only shows "Replace it" for negative behaviors. Add a parallel CTA for **positive** behaviors:

- Positive (+) row: show **"Stack on it →"** button (below behavior name, same animation as "Replace it").
- Opens wizard with `anchorHabitId` pre-set to a new "anchor" concept (or just pre-fills cue with `"After I \(behavior)"`).

This implements Clear's habit stacking principle and doubles the conversion surface from the scorecard.

**Pro:** Book-accurate; covers the majority of behaviors (most are positive/neutral); builds on existing infrastructure.
**Con:** Neutral behaviors are still unaddressed; "Stack on it" copy may need explanation.

---

### Option D — Onboarding Wizard Step After Scorecard (High effort)

Add a new `OnboardingViewModel.Step` between `.habitScorecard` and `.notificationPermission`:

```
.habitScorecard → .firstHabit → .notificationPermission
```

`firstHabitStep` shows a stripped-down wizard (just cue + name, no 4-step flow) pre-populated from the top negatively-rated scorecard entry, or from a recommended template if no negative entries exist.

This is the strongest UX because it guarantees at least one habit is created before the user ever sees TodayView.

**Pro:** Solves the empty-state bug permanently; user lands in Today with something.
**Con:** Adds friction to onboarding; not all users want to create a habit immediately; increases complexity of the onboarding flow significantly.

---

## 5. Atomic Habits Quotes Relevant to Copy/Framing

These can be used in UI copy for whatever solution is chosen:

| Principle | Quote | Suggested use |
|-----------|-------|---------------|
| Replace, don't eliminate | "You can't eliminate a bad habit, you can only replace it." | Interstitial between scorecard and wizard |
| Same cue, new routine | "Keep the cue and reward, change the routine." | Already in WizardStepCueView banner — could also appear on the scorecard "Replace it" row |
| Make it obvious | "Implementation intention: 'I will [behavior] at [time] in [location].'" | After creating first habit, suggest a specific time/place |
| Identity shift | "Every action you take is a vote for the type of person you wish to become." | Post-creation confirmation screen |
| Start small | "The Two-Minute Rule: downscale your habits until they can be done in two minutes or less." | Empty state or first-habit wizard intro |
| Awareness first | "The first step to changing bad habits is to be on the lookout for them." | Scorecard intro (already present, could be stronger) |

---

## 6. Data Available at Decision Point

When the user arrives at TodayView after onboarding, the app has access to:

| Data | Source | Available now? |
|------|--------|----------------|
| All scored behaviors | `ScorecardEntry.load()` → UserDefaults | ✅ Yes |
| Negative behaviors | `entries.filter { $0.rating == .negative }` | ✅ Yes |
| Positive behaviors | `entries.filter { $0.rating == .positive }` | ✅ Yes |
| Number of habits in DB | `viewModel.totalHabits` | ✅ Yes |
| Onboarding just completed | Could check `UserDefaults` first-launch flag | ⚠ Needs a `firstLaunchAfterOnboarding` flag |
| User identity preference | Nothing explicit | ❌ Not yet |

The simplest discriminator for "user just finished onboarding with scorecard data but no habits" is:

```swift
viewModel.totalHabits == 0 && !ScorecardEntry.load().isEmpty
```

---

## 7. Recommended Approach

A two-phase solution that's low-risk and respects the existing architecture:

**Phase 1 (Quick win, no onboarding changes):**
- Context-aware empty state in TodayView (Option B): when scorecard entries exist but no habits do, show a different headline and CTA that acknowledges the inventory and directs back to the scorecard's "Replace it" flow.

**Phase 2 (Stronger, deeper integration):**
- Add "Stack on it →" for positive behaviors in the scorecard (Option C) alongside the existing "Replace it" for negative ones. This makes the scorecard feel like the natural entry point for habit design rather than just a rating exercise.

Option D (mandatory wizard in onboarding) should be considered only after validating that users actually engage with the scorecard — if most users skip it, adding a mandatory wizard step based on scorecard data would be premature.

---

## 8. Files That Will Be Touched

| File | What changes |
|------|-------------|
| `Views/Today/TodayView.swift` | Context-aware empty state branch on `ScorecardEntry.load()` |
| `Views/FourLaws/HabitsScorecardView.swift` | "Stack on it →" CTA for positive entries + `ScorecardEntryRow` update |
| `Models/ScorecardEntry.swift` | Verify `load()` is accessible from TodayView (currently UserDefaults, no auth dependency) |
| `Views/Onboarding/OnboardingContainerView.swift` | Optional Phase 1.5: interstitial after scorecard before notifications |

No database schema changes are needed for any of the above phases.
