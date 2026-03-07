# Multiple Identities Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the single global identity statement with a per-habit identity carousel on the Identity tab, and make the Today completion toast show the specific habit's identity.

**Architecture:** No schema changes. Each `Habit` already has a `craving` field — that IS the identity statement. `identity_votes` already tracks completions per statement. We group habits by their `craving` string, display a paged TabView carousel on FourLawsView, remove the onboarding global identity step, and fix TodayViewModel to set `topIdentityStatement` from the just-completed habit's `craving` at toggle time rather than loading a global top vote.

**Tech Stack:** SwiftUI, `@Observable` ViewModels, Supabase (identity_votes table, habits table), UserDefaults (onboardingComplete key only).

---

## Context

### Key files
| File | Current role |
|------|-------------|
| `HabitStack/Views/FourLaws/FourLawsView.swift` | Shows single `IdentityHeroCard` + `EditIdentitySheet`. Both get replaced. |
| `HabitStack/ViewModels/TodayViewModel.swift` | `topIdentityStatement` loaded via `loadTopIdentity()` from top voted string globally. Needs to become per-completion. |
| `HabitStack/Views/Onboarding/OnboardingContainerView.swift` | Has `.identityStatement` step that saves `onboardingIdentityStatement` to UserDefaults. Step is removed. |
| `HabitStack/Views/Onboarding/IdentityStatementView.swift` | Only used by onboarding. Deleted. |

### Data model reminder
- `Habit.craving: String?` — the "why this matters to me" field set in WizardStepCravingView
- `IdentityVote` — Supabase row: `(id, habit_id, user_id, identity_statement, voted_at)`. Every habit completion writes a vote via the streak-calc edge function.
- `identity_votes` rows for a statement = evidence count displayed on the identity card.

---

## Task 1: Remove global identity onboarding step

**Files:**
- Modify: `HabitStack/Views/Onboarding/OnboardingContainerView.swift`
- Delete: `HabitStack/Views/Onboarding/IdentityStatementView.swift`
- Modify: `HabitStack/Assets.xcassets/` — no changes needed

**Step 1: Rewrite `OnboardingViewModel` in `OnboardingContainerView.swift`**

Replace the entire file with:

```swift
import SwiftUI
import Observation

@Observable
final class OnboardingViewModel {
    enum Step {
        case welcome
        case habitScorecard
        case notificationPermission
        case complete
    }

    var step: Step = .welcome

    func advance() {
        switch step {
        case .welcome: step = .habitScorecard
        case .habitScorecard: step = .notificationPermission
        case .notificationPermission: step = .complete
        case .complete: break
        }
    }

    func markComplete() {
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
    }
}

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        switch viewModel.step {
        case .welcome:
            WelcomeView(onStart: { viewModel.advance() })
        case .habitScorecard:
            ScorecardOnboardingView(onContinue: { viewModel.advance() })
        case .notificationPermission:
            NotificationPermissionView(onComplete: { viewModel.advance() })
        case .complete:
            ProgressView()
                .task {
                    viewModel.markComplete()
                    _ = try? await supabase.auth.refreshSession()
                }
        }
    }
}
```

**Step 2: Delete `IdentityStatementView.swift`**

This file is only referenced by `OnboardingContainerView`. Now that the step is removed, delete the file:

```bash
rm HabitStack/Views/Onboarding/IdentityStatementView.swift
```

Note: XcodeGen uses glob patterns so removing the file from disk is sufficient — no `.xcodeproj` edit needed. Run `~/.mint/bin/xcodegen generate` after if the project stops building.

**Step 3: Commit**

```bash
git add HabitStack/Views/Onboarding/OnboardingContainerView.swift
git rm HabitStack/Views/Onboarding/IdentityStatementView.swift
git commit -m "feat: remove global identity onboarding step"
```

**Verification:** Open app, complete onboarding — flow goes Welcome → Scorecard → Notifications → done. No identity text field appears.

---

## Task 2: Fix Today toast to use per-habit craving

**Files:**
- Modify: `HabitStack/ViewModels/TodayViewModel.swift`

**Context:** `topIdentityStatement: String?` is currently loaded once in `loadTopIdentity()` as the globally top-voted statement. The Today toast (`IdentityToastView`) uses this. We want it to show the *just-completed* habit's `craving` instead.

**Step 1: Remove `loadTopIdentity()` and its call site**

In `TodayViewModel.swift`:

Delete this entire method (lines 210–220):
```swift
private func loadTopIdentity(userId: UUID) async {
    let votes: [IdentityVote] = (try? await supabase
        .from("identity_votes")
        .select()
        .eq("user_id", value: userId.uuidString)
        .execute()
        .value) ?? []
    let grouped = Dictionary(grouping: votes, by: { $0.identityStatement })
    let top = grouped.max(by: { $0.value.count < $1.value.count })?.key
    await MainActor.run { self.topIdentityStatement = top }
}
```

Also delete its call site in `loadToday()`:
```swift
await loadTopIdentity(userId: userId)
```

**Step 2: Set `topIdentityStatement` from completed habit's `craving` in `toggleHabit`**

In `toggleHabit`, find this existing block (around line 125–133):

```swift
if newStatus == .done {
    self.lastCompletedHabitName = habitName
    self.showXPToastRotated()
    self.checkMilestone(for: habitId, habitName: habitName, streaks: allStreaks)
    self.scheduleRetentionNotifications(
        habits: self.habitGroups.values.flatMap { $0 }.map { $0 },
        streaks: allStreaks
    )
}
```

Replace with:

```swift
if newStatus == .done {
    self.lastCompletedHabitName = habitName
    // Set identity to THIS habit's craving for the toast
    let completedHabit = self.habitGroups.values.flatMap { $0 }.first { $0.habit.id == habitId }
    self.topIdentityStatement = completedHabit?.habit.craving
    self.showXPToastRotated()
    self.checkMilestone(for: habitId, habitName: habitName, streaks: allStreaks)
    self.scheduleRetentionNotifications(
        habits: self.habitGroups.values.flatMap { $0 }.map { $0 },
        streaks: allStreaks
    )
}
```

**Step 3: Commit**

```bash
git add HabitStack/ViewModels/TodayViewModel.swift
git commit -m "feat: identity toast shows completed habit's own craving"
```

**Verification:** Add two habits — one with craving "reads every day", one with craving "exercises consistently". Complete the reading habit → toast says "I am becoming someone who reads every day". Complete the exercise habit → toast says "exercises consistently". Habit with no craving set → no identity toast (XP toast only).

---

## Task 3: Replace IdentityHeroCard with IdentityCarousel in FourLawsView

**Files:**
- Modify: `HabitStack/Views/FourLaws/FourLawsView.swift`

**Context:** `FourLawsView` currently has:
- `@State private var identityStatement: String`
- `@State private var showEditIdentity: Bool`
- `IdentityHeroCard(statement:votes:onEdit:)` in body
- `.sheet(isPresented: $showEditIdentity) { EditIdentitySheet(statement: $identityStatement) }`
- `IdentityHeroCard` private struct
- `EditIdentitySheet` private struct

We delete all of that and replace with `IdentityCarousel` + `IdentityCard` private structs. The `editingHabit` state already exists for editing via wizard — we reuse it for tapping habits on the carousel card.

**Step 1: Update FourLawsView state and body**

In `FourLawsView`:

**Remove these two state vars:**
```swift
@State private var showEditIdentity = false
@State private var identityStatement: String = ""
```

**Replace the `IdentityHeroCard` line in body:**
```swift
// OLD:
IdentityHeroCard(
    statement: identityStatement,
    votes: totalVotes,
    onEdit: { showEditIdentity = true }
)
.padding(.horizontal, 16)
```
with:
```swift
IdentityCarousel(
    habits: habits,
    votes: allVotes,
    onHabitTap: { habit in editingHabit = habit }
)
.padding(.horizontal, 16)
```

**Remove the EditIdentitySheet sheet modifier** (the `.sheet(isPresented: $showEditIdentity) { ... }` block).

**Update the `load()` function** — change `votesResult` from fetching just count to fetching all votes and storing them:

Change:
```swift
async let votesResult: [IdentityVote] = (try? await supabase
    .from("identity_votes")
    .select()
    .eq("user_id", value: userId.uuidString)
    .execute()
    .value) ?? []

let (loadedHabits, loadedVotes) = await (habitsResult, votesResult)
habits = loadedHabits
totalVotes = loadedVotes.count

// Identity statement: onboarding entry takes priority, fall back to top vote
if let saved = UserDefaults.standard.string(forKey: "onboardingIdentityStatement"), !saved.isEmpty {
    identityStatement = saved
} else {
    let grouped = Dictionary(grouping: loadedVotes, by: { $0.identityStatement })
    identityStatement = grouped.max(by: { $0.value.count < $1.value.count })?.key ?? ""
}
```

to:
```swift
async let votesResult: [IdentityVote] = (try? await supabase
    .from("identity_votes")
    .select()
    .eq("user_id", value: userId.uuidString)
    .execute()
    .value) ?? []

let (loadedHabits, loadedVotes) = await (habitsResult, votesResult)
habits = loadedHabits
allVotes = loadedVotes
```

**Add `@State private var allVotes: [IdentityVote] = []`** in place of `identityStatement` and `totalVotes`.

Also remove `@State private var totalVotes: Int = 0` — it's no longer needed.

**Step 2: Add `IdentityCarousel` and `IdentityCard` private structs**

Delete the `IdentityHeroCard` struct and `EditIdentitySheet` struct entirely. Replace them with:

```swift
// MARK: - Identity Carousel

private struct IdentityCarousel: View {
    let habits: [Habit]
    let votes: [IdentityVote]
    let onHabitTap: (Habit) -> Void

    private struct IdentityGroup: Identifiable {
        let id: String  // the statement itself
        let statement: String
        let habits: [Habit]
        let evidenceCount: Int
    }

    private var groups: [IdentityGroup] {
        let withCraving = habits.filter { !($0.craving ?? "").isEmpty }
        let grouped = Dictionary(grouping: withCraving, by: { $0.craving! })
        return grouped.map { (key, value) in
            let count = votes.filter { $0.identityStatement == key }.count
            return IdentityGroup(id: key, statement: key, habits: value, evidenceCount: count)
        }
        .sorted { $0.evidenceCount > $1.evidenceCount }
    }

    var body: some View {
        if groups.isEmpty {
            emptyCard
        } else if groups.count == 1 {
            IdentityCard(group: groups[0], onHabitTap: onHabitTap)
        } else {
            TabView {
                ForEach(groups) { group in
                    IdentityCard(group: group, onHabitTap: onHabitTap)
                        .padding(.bottom, 24) // room for page dots
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 240)
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 12) {
            Text("I am becoming")
                .font(.caption.bold())
                .foregroundStyle(Color("Teal"))
                .textCase(.uppercase)
                .kerning(0.8)
            Text("Who do you want to become?")
                .font(.title3.bold())
                .foregroundStyle(Color("Stone500"))
                .multilineTextAlignment(.center)
            Text("Add a \"Why\" to any habit in the wizard to build your identity here.")
                .font(.caption)
                .foregroundStyle(Color("Stone500").opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct IdentityCard: View {
    struct Group: Identifiable {
        let id: String
        let statement: String
        let habits: [Habit]
        let evidenceCount: Int
    }
    // Use IdentityCarousel.IdentityGroup — passed directly
    let group: IdentityCarousel.IdentityGroup
    let onHabitTap: (Habit) -> Void

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("I am becoming")
                    .font(.caption.bold())
                    .foregroundStyle(Color("Teal"))
                    .textCase(.uppercase)
                    .kerning(0.8)
                Text("someone who \(group.statement.lowercased())")
                    .font(.title3.bold())
                    .foregroundStyle(Color("Stone950"))
                    .multilineTextAlignment(.center)
            }

            // Habit chips
            HStack(spacing: 8) {
                ForEach(group.habits) { habit in
                    Button { onHabitTap(habit) } label: {
                        Label(habit.name, systemImage: "")
                            .labelStyle(.titleAndIcon)
                    }
                    // simpler: just text + emoji
                }
            }
            // Actually use a flow-style wrap for >2 habits — but keep simple: just HStack with wrap via LazyVGrid
            .lineLimit(1)

            if group.evidenceCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color("Teal"))
                    Text("\(group.evidenceCount) completion\(group.evidenceCount == 1 ? "" : "s") as evidence")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone950"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color("TealLight"))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color("TealLight"), Color("TealLight").opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
```

> **Note on habit chips:** Keep them simple — `Text("\(habit.emoji) \(habit.name)")` as tappable capsule chips. Don't use `Label` with `systemImage: ""`. Here is the clean chip button:
>
> ```swift
> ForEach(group.habits) { habit in
>     Button { onHabitTap(habit) } label: {
>         Text("\(habit.emoji) \(habit.name)")
>             .font(.caption.bold())
>             .padding(.horizontal, 10)
>             .padding(.vertical, 5)
>             .background(Color("CardBackground").opacity(0.7))
>             .foregroundStyle(Color("Stone950"))
>             .clipShape(Capsule())
>             .overlay(Capsule().strokeBorder(Color("Teal").opacity(0.3), lineWidth: 1))
>     }
>     .buttonStyle(.plain)
> }
> ```

**Step 3: Clean up the `load()` function identity statement derivation**

In `load()` also remove the line `identityStatement = ...` and the `UserDefaults.standard.string(forKey: "onboardingIdentityStatement")` lookup — both are gone now.

**Step 4: Commit**

```bash
git add HabitStack/Views/FourLaws/FourLawsView.swift
git commit -m "feat: replace single identity hero card with per-habit identity carousel"
```

**Verification:**
1. Identity tab with no habits with craving set → shows empty state card
2. Add a habit with craving "reads every day" → one carousel card appears: "I am becoming someone who reads every day" with habit chip
3. Add a second habit with craving "exercises consistently" → two cards, swipeable. Page dots appear at bottom.
4. Two habits with the *same* craving → grouped on one card with two chips
5. Complete any habit → its identity card updates evidence count
6. Tap a habit chip → wizard opens for that habit

---

## Verification Checklist (end-to-end)

- [ ] Onboarding: flow skips identity statement step entirely
- [ ] Today: complete a habit with craving set → toast shows that habit's identity
- [ ] Today: complete a habit with no craving → no identity toast (XP only)
- [ ] Identity tab, no cravings set → empty state card
- [ ] Identity tab, 1 identity → single card, no page dots
- [ ] Identity tab, 2+ identities → paged carousel, swipeable, dots visible
- [ ] Tap habit chip on carousel → habit wizard opens
- [ ] Evidence count increments after completing a habit (Supabase vote recorded)
