# Habit Evolution + Weekly Reflection Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add progressive habit difficulty (Habit Evolution) and a weekly reflection sheet so users grow over time instead of staying static.

**Architecture:** Both features are fully local — Habit Evolution uses UserDefaults keyed by habit ID, Weekly Reflection stores answers in UserDefaults and triggers from TodayView on Monday mornings. No Supabase schema changes required.

**Tech Stack:** SwiftUI, `@Observable`, UserDefaults, existing `HabitService` + `StreakService`

---

## Overview of Changes

| Feature | New Files | Modified Files |
|---|---|---|
| Habit Evolution | `HabitLevelUpSheet.swift` | `HabitCardView.swift`, `HabitWizardViewModel.swift` |
| Weekly Reflection | `WeeklyReflectionView.swift` | `TodayView.swift`, `TodayViewModel.swift` |

---

## Feature 1 — Habit Evolution

Each habit has a **level** (1–3) stored in UserDefaults as `habitLevel_<id>`. Each level represents a harder version:

- Level 1 → tinyVersion (2-min rule, already saved)
- Level 2 → medium version (user-defined in wizard)
- Level 3 → full version (habit name / routine field)

After 7 consecutive days at the current level, a "Level Up?" sheet appears. User confirms → level badge advances, new description shown on card.

---

### Task 1: Add `mediumVersion` field to `HabitWizardViewModel`

**Files:**
- Modify: `HabitStack/ViewModels/HabitWizardViewModel.swift`
- Modify: `HabitStack/Views/HabitWizard/WizardStepRoutineView.swift`

**Step 1: Add the field**

In `HabitWizardViewModel.swift`, after `var tinyVersion: String = ""`:

```swift
var mediumVersion: String = ""
```

**Step 2: Load/save in `prefill(from habit:)` and `save()`**

In `prefill(from habit:)`, after the tinyVersion line:
```swift
let savedMedium = UserDefaults.standard.string(forKey: "habitMedium_\(habit.id.uuidString)") ?? ""
mediumVersion = savedMedium
```

In `save()`, after the duration block:
```swift
if !mediumVersion.trimmingCharacters(in: .whitespaces).isEmpty {
    UserDefaults.standard.set(mediumVersion, forKey: "habitMedium_\(habit.id.uuidString)")
} else {
    UserDefaults.standard.removeObject(forKey: "habitMedium_\(habit.id.uuidString)")
}
```

**Step 3: Add Medium Version field in WizardStepRoutineView**

In `WizardStepRoutineView.swift`, after the "2-Minute Version" `FormSection`, add:

```swift
FormSection(title: "Medium Version (Level 2)") {
    VStack(alignment: .leading, spacing: 6) {
        TextField("e.g. Run for 10 minutes", text: $viewModel.mediumVersion)
            .padding()
            .background(Color("Stone100"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        Text("Unlocked after 7 days at Level 1.")
            .font(.caption)
            .foregroundStyle(Color("Stone500"))
    }
}
```

**Step 4: Build check**

Open Xcode → Cmd+B. No new errors.

**Step 5: Commit**

```bash
git add HabitStack/ViewModels/HabitWizardViewModel.swift HabitStack/Views/HabitWizard/WizardStepRoutineView.swift
git commit -m "feat: add mediumVersion field to habit wizard (level 2 support)"
```

---

### Task 2: Create `HabitLevelUpSheet.swift`

**Files:**
- Create: `HabitStack/Views/Today/HabitLevelUpSheet.swift`

**Step 1: Write the file**

```swift
import SwiftUI

struct HabitLevelUpSheet: View {
    let habitName: String
    let currentLevel: Int
    let nextDescription: String
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("Level \(currentLevel + 1)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Color("Teal"))

                Text("Ready to level up?")
                    .font(.title2.bold())

                Text("You've built the habit of \"\(habitName)\" for 7 days. Time to raise the bar.")
                    .font(.subheadline)
                    .foregroundStyle(Color("Stone500"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Next challenge")
                    .font(.caption.bold())
                    .foregroundStyle(Color("Stone500"))
                    .textCase(.uppercase)
                    .kerning(0.5)

                Text(nextDescription)
                    .font(.body.bold())
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color("TealLight"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    Text("Level Up")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Teal"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    onDismiss()
                    dismiss()
                } label: {
                    Text("Not yet")
                        .foregroundStyle(Color("Stone500"))
                }
                .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .presentationDetents([.medium])
    }
}
```

**Step 2: Run `~/.mint/bin/xcodegen generate` to pick up new file**

```bash
cd /Users/tomerab/dev/habit-stack && ~/.mint/bin/xcodegen generate
```

**Step 3: Build check**

Cmd+B in Xcode.

**Step 4: Commit**

```bash
git add HabitStack/Views/Today/HabitLevelUpSheet.swift HabitStack.xcodeproj/project.pbxproj
git commit -m "feat: add HabitLevelUpSheet for habit level-up prompt"
```

---

### Task 3: Wire Habit Evolution into `HabitCardView`

**Files:**
- Modify: `HabitStack/Views/Today/HabitCardView.swift`

**Step 1: Add state variables (after existing `@State` declarations)**

```swift
@State private var habitLevel: Int = 1
@State private var showLevelUp = false
```

**Step 2: Add computed helpers (after existing private vars)**

```swift
private var levelKey: String { "habitLevel_\(habit.id.uuidString)" }
private var levelUpShownKey: String { "habitLevelUpShown_\(habit.id.uuidString)_\(currentLevelUpStreak)" }
private var currentLevelUpStreak: Int { (habitLevel - 1) * 7 } // 7 days per level

private func levelDescription(for level: Int) -> String {
    switch level {
    case 1: return habit.tinyVersion ?? habit.name
    case 2:
        return UserDefaults.standard.string(forKey: "habitMedium_\(habit.id.uuidString)") ?? habit.name
    default: return habit.name
    }
}
```

**Step 3: Add level badge to the right-side VStack**

In the `VStack(alignment: .trailing, spacing: 6)` section, after the streak badge HStack, add:

```swift
// Level badge (only if level > 1)
if habitLevel > 1 {
    Text("Lv \(habitLevel)")
        .font(.caption2.bold())
        .foregroundStyle(Color("Teal"))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color("TealLight"))
        .clipShape(Capsule())
}
```

**Step 4: Check for level-up eligibility in onAppear**

In `.onAppear`, add after existing load lines:

```swift
habitLevel = max(1, UserDefaults.standard.integer(forKey: levelKey) == 0
    ? 1
    : UserDefaults.standard.integer(forKey: levelKey))
// Trigger level-up if streak >= 7*currentLevel and not yet prompted
if let streak, streak.currentStreak >= habitLevel * 7,
   habitLevel < 3,
   !UserDefaults.standard.bool(forKey: levelUpShownKey) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        showLevelUp = true
    }
}
```

**Step 5: Add the sheet modifier** (after existing `.sheet(isPresented: $showTimer)`)

```swift
.sheet(isPresented: $showLevelUp) {
    HabitLevelUpSheet(
        habitName: habit.name,
        currentLevel: habitLevel,
        nextDescription: levelDescription(for: habitLevel + 1),
        onConfirm: {
            habitLevel = min(3, habitLevel + 1)
            UserDefaults.standard.set(habitLevel, forKey: levelKey)
            UserDefaults.standard.set(true, forKey: levelUpShownKey)
            HapticManager.notification(.success)
        },
        onDismiss: {
            UserDefaults.standard.set(true, forKey: levelUpShownKey)
        }
    )
}
```

**Step 6: Also show current level description on card** — in the habit info VStack, after the tinyVersion line:

```swift
if habitLevel == 2,
   let medium = UserDefaults.standard.string(forKey: "habitMedium_\(habit.id.uuidString)"),
   !medium.isEmpty {
    Text("Lv 2: \(medium)")
        .font(.caption)
        .foregroundStyle(Color("Teal"))
}
```

**Step 7: Build check** — Cmd+B

**Step 8: Commit**

```bash
git add HabitStack/Views/Today/HabitCardView.swift
git commit -m "feat: habit evolution — level badge, level-up sheet trigger after 7-day streak"
```

---

## Feature 2 — Weekly Reflection

A sheet shown **once per week** (Monday, or 7+ days since last) with three questions and last-week completion stats per habit.

---

### Task 4: Create `WeeklyReflectionView.swift`

**Files:**
- Create: `HabitStack/Views/Today/WeeklyReflectionView.swift`

**Step 1: Write the file**

```swift
import SwiftUI

struct WeeklyReflectionView: View {
    let habitNames: [String]
    let completionRates: [String: Double] // name → 0.0–1.0
    let onDismiss: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var easiest: String = ""
    @State private var hardest: String = ""
    @State private var adjustment: String = ""

    private static let adjustmentSuggestions = [
        "Start earlier",
        "Make it shorter",
        "Add a cue",
        "Pair with a reward",
        "Remove friction",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // Last week stats
                    if !completionRates.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Last 7 Days")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color("Stone500"))

                            ForEach(completionRates.sorted(by: { $0.value > $1.value }), id: \.key) { name, rate in
                                HStack(spacing: 10) {
                                    Text(name)
                                        .font(.subheadline)
                                        .foregroundStyle(Color("Stone950"))
                                        .lineLimit(1)
                                    Spacer()
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color("Stone100"))
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color("Teal"))
                                                .frame(width: geo.size.width * rate)
                                        }
                                    }
                                    .frame(width: 80, height: 8)
                                    Text("\(Int(rate * 100))%")
                                        .font(.caption.bold())
                                        .foregroundStyle(Color("Stone500"))
                                        .frame(width: 32, alignment: .trailing)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color("Stone100"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Q1
                    questionSection(
                        label: "Which habit felt easiest?",
                        options: habitNames,
                        selection: $easiest
                    )

                    // Q2
                    questionSection(
                        label: "Which habit was hardest?",
                        options: habitNames,
                        selection: $hardest
                    )

                    // Q3
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What will you adjust?")
                            .font(.subheadline.bold())

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Self.adjustmentSuggestions, id: \.self) { s in
                                    Button {
                                        adjustment = s
                                    } label: {
                                        Text(s)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 7)
                                            .background(adjustment == s ? Color("Teal") : Color("Stone100"))
                                            .foregroundStyle(adjustment == s ? .white : Color("Stone950"))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        TextField("Or a personal note…", text: $adjustment)
                            .padding()
                            .background(Color("Stone100"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(20)
            }
            .navigationTitle("Weekly Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        save()
                        onDismiss()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func questionSection(label: String, options: [String], selection: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.subheadline.bold())

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { name in
                        Button {
                            selection.wrappedValue = name
                        } label: {
                            Text(name)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(selection.wrappedValue == name ? Color("Teal") : Color("Stone100"))
                                .foregroundStyle(selection.wrappedValue == name ? .white : Color("Stone950"))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func save() {
        let dateStr = String(ISO8601DateFormatter().string(from: Date()).prefix(10))
        UserDefaults.standard.set(dateStr, forKey: "lastWeeklyReflectionDate")
        let entry = "Easiest: \(easiest) | Hardest: \(hardest) | Adjust: \(adjustment)"
        UserDefaults.standard.set(entry, forKey: "weeklyReflection_\(dateStr)")
    }
}
```

**Step 2: Run xcodegen**

```bash
cd /Users/tomerab/dev/habit-stack && ~/.mint/bin/xcodegen generate
```

**Step 3: Build check** — Cmd+B

**Step 4: Commit**

```bash
git add HabitStack/Views/Today/WeeklyReflectionView.swift HabitStack.xcodeproj/project.pbxproj
git commit -m "feat: add WeeklyReflectionView with 3 questions + last-week stats"
```

---

### Task 5: Wire Weekly Reflection trigger into `TodayViewModel` + `TodayView`

**Files:**
- Modify: `HabitStack/ViewModels/TodayViewModel.swift`
- Modify: `HabitStack/Views/Today/TodayView.swift`

**Step 1: Add trigger state to `TodayViewModel`**

Add after `var topIdentityStatement: String?`:

```swift
var showWeeklyReflection = false
var weeklyReflectionHabitNames: [String] = []
var weeklyReflectionRates: [String: Double] = [:]
```

Add this private method:

```swift
func checkWeeklyReflection(habits: [HabitWithStatus]) {
    let key = "lastWeeklyReflectionDate"
    let lastStr = UserDefaults.standard.string(forKey: key) ?? ""
    let formatter = ISO8601DateFormatter()
    let calendar = Calendar.current

    var shouldShow = false
    if lastStr.isEmpty {
        // Never shown — show on Monday
        shouldShow = calendar.component(.weekday, from: Date()) == 2
    } else if let last = formatter.date(from: lastStr + "T00:00:00Z") {
        let days = calendar.dateComponents([.day], from: last, to: Date()).day ?? 0
        shouldShow = days >= 7
    }

    guard shouldShow else { return }

    weeklyReflectionHabitNames = habits.map { $0.habit.name }
    // Build completion rates from streaks (approximation: currentStreak / 7)
    weeklyReflectionRates = Dictionary(
        uniqueKeysWithValues: habits.map { h in
            let streak = streaks[h.habit.id]?.currentStreak ?? 0
            return (h.habit.name, min(1.0, Double(streak) / 7.0))
        }
    )
    showWeeklyReflection = true
}
```

**Step 2: Call it from `loadToday()` after habits load**

In `loadToday()`, inside the `await MainActor.run` block, after `checkNeverMissTwice`:

```swift
self.checkWeeklyReflection(habits: habits)
```

**Step 3: Show sheet in `TodayView`**

In `TodayView.swift`, add state:
```swift
// no new state needed — driven by viewModel.showWeeklyReflection
```

Add sheet after the milestone sheet:
```swift
.sheet(isPresented: $viewModel.showWeeklyReflection) {
    WeeklyReflectionView(
        habitNames: viewModel.weeklyReflectionHabitNames,
        completionRates: viewModel.weeklyReflectionRates,
        onDismiss: { viewModel.showWeeklyReflection = false }
    )
}
```

**Step 4: Build check** — Cmd+B

**Step 5: Smoke test**

To force the weekly reflection to appear: in Simulator, `UserDefaults.standard.removeObject(forKey: "lastWeeklyReflectionDate")` then set your device weekday to Monday (or set `lastStr` to a date 8 days ago) → loadToday() → sheet appears.

**Step 6: Commit**

```bash
git add HabitStack/ViewModels/TodayViewModel.swift HabitStack/Views/Today/TodayView.swift
git commit -m "feat: weekly reflection trigger — shows on Monday or 7+ days since last review"
```

---

## Verification Checklist

- [ ] Wizard Step 3 shows "Medium Version" field — can fill it in
- [ ] After saving, medium version appears in UserDefaults `habitMedium_<id>`
- [ ] Habit card at level 1: no level badge shown
- [ ] Habit card at level 2: shows "Lv 2" badge + medium description
- [ ] Level-up sheet appears when streak >= 7 and level < 3 (force by setting `habitLevel_<id>` to 1 and faking streak via Supabase)
- [ ] Weekly reflection sheet appears on first Monday or 7 days after last
- [ ] Completion rates bar chart renders per-habit
- [ ] Tapping a chip selects it (highlighted teal)
- [ ] "Done" saves date to UserDefaults, sheet doesn't reappear next load
