# Retention & UX Polish Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Ship 7 cohesive improvements: card redesign, hold-to-complete, opt-in notes, FAB simplification, perfect day/comeback/sound/achievement retention features, level perks, and archived habit recovery.

**Architecture:** All changes are client-side SwiftUI except one new Supabase RPC (`spend_streak_shield`). No schema changes. New files need XcodeGen regeneration after creation (`~/.mint/bin/xcodegen generate`).

**Tech Stack:** SwiftUI, `@Observable` ViewModels, Supabase Swift SDK, AudioToolbox (for completion sound), existing `HabitService`/`StreakService`/`HapticManager`.

---

## Task 1: HabitFrictionSheet — new mini-editor sheet

**Files:**
- Create: `HabitStack/Views/Today/HabitFrictionSheet.swift`

**Step 1: Create the file**

```swift
import SwiftUI

struct HabitFrictionSheet: View {
    let habit: Habit
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var tinyVersion: String
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date

    init(habit: Habit, onSave: @escaping () -> Void) {
        self.habit = habit
        self.onSave = onSave
        _tinyVersion = State(initialValue: habit.tinyVersion ?? "")
        _reminderEnabled = State(initialValue: habit.reminderEnabled)
        _reminderTime = State(initialValue: habit.reminderTime ?? Date())
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("What's the 2-minute version?")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color("Stone500"))
                    TextField("e.g. Just put on my shoes", text: $tinyVersion)
                        .padding(12)
                        .background(Color("Stone100"))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Enable daily reminder", isOn: $reminderEnabled)
                        .tint(Color("Teal"))
                    if reminderEnabled {
                        DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .tint(Color("Teal"))
                    }
                }
                .padding(12)
                .background(Color("Stone100"))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Spacer()
            }
            .padding(20)
            .background(Color("AppBackground").ignoresSafeArea())
            .navigationTitle("Set up \(habit.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color("Stone500"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("Teal"))
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() async {
        var updated = habit
        updated.tinyVersion = tinyVersion.trimmingCharacters(in: .whitespaces).isEmpty ? nil : tinyVersion.trimmingCharacters(in: .whitespaces)
        updated.reminderEnabled = reminderEnabled
        updated.reminderTime = reminderEnabled ? reminderTime : nil
        try? await HabitService.shared.updateHabit(updated)
        onSave()
        dismiss()
    }
}
```

**Step 2: Regenerate xcodeproj**

```bash
cd /Users/tomerab/dev/habit-stack && ~/.mint/bin/xcodegen generate
```

Expected: `✅ Done` with no errors.

**Step 3: Commit**

```bash
git add HabitStack/Views/Today/HabitFrictionSheet.swift project.yml HabitStack.xcodeproj
git commit -m "feat: add HabitFrictionSheet mini-editor"
```

---

## Task 2: HabitCardView — color dot, remove rating, friction chip, opt-in pencil note

**Files:**
- Modify: `HabitStack/Views/Today/HabitCardView.swift`

**Step 1: Replace emoji with color dot**

In `HabitCardView`, find the habit info `Button { showDetail = true }` label and replace the emoji row:

```swift
// REMOVE:
Text(habit.emoji)
    .font(.title3)

// ADD in the HStack at the same position — a colored letter dot:
ZStack {
    Circle()
        .fill(accentColor)
        .frame(width: 40, height: 40)
    Text(String(habit.name.prefix(1)).uppercased())
        .font(.headline.bold())
        .foregroundStyle(.white)
}
```

**Step 2: Remove rating state and rating UI**

Remove these `@State` declarations:
```swift
// REMOVE:
@State private var rating: ScorecardEntry.Rating? = nil
@State private var showRatingPicker = false
```

Remove the `ratingKey` computed property.

Remove the rating `Button { showRatingPicker = true }` from the right-side `VStack`.

Remove the `.confirmationDialog(...)` block for rating at the bottom of `body`.

Remove `setRating()` private function.

Remove `ratingBackground` and `ratingForeground` computed properties.

Remove from `.onAppear`:
```swift
// REMOVE:
if let raw = UserDefaults.standard.string(forKey: ratingKey) {
    rating = ScorecardEntry.Rating(rawValue: raw)
}
```

**Step 3: Add friction chip and sheet state**

Add state:
```swift
@State private var showFrictionSheet = false
```

In the habit info `VStack` (after the tiny version text), add:
```swift
if hasFriction {
    Button { showFrictionSheet = true } label: {
        Text("Needs setup")
            .font(.caption.bold())
            .foregroundStyle(.orange)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.12))
            .clipShape(Capsule())
    }
    .buttonStyle(.plain)
}
```

Remove the existing `hasFriction` use from the emoji row:
```swift
// REMOVE:
if hasFriction {
    Image(systemName: "exclamationmark.triangle.fill")
        .font(.caption2)
        .foregroundStyle(.orange)
}
```

Add sheet after existing sheets:
```swift
.sheet(isPresented: $showFrictionSheet) {
    HabitFrictionSheet(habit: habit) {
        // parent refreshes via onEdit path — no action needed here
    }
}
```

**Step 4: Replace auto-note trigger with opt-in pencil icon**

Find both places that say:
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
    showNote = true
}
```
Remove both of them (one in `onComplete:`, one in quantified button).

In the right-side `VStack(alignment: .trailing, spacing: 6)`, after the HStack with timer and streak badge, add:
```swift
if habitWithStatus.isCompleted {
    Button { showNote = true } label: {
        Image(systemName: "pencil.circle")
            .font(.title3)
            .foregroundStyle(Color("Stone500").opacity(0.6))
    }
    .buttonStyle(.plain)
    .transition(.opacity)
    .animation(.easeInOut(duration: 0.3), value: habitWithStatus.isCompleted)
}
```

**Step 5: Build check**

Open Xcode and build (`Cmd+B`). Fix any "use of unresolved identifier" errors from removed rating properties.

**Step 6: Commit**

```bash
git add HabitStack/Views/Today/HabitCardView.swift
git commit -m "feat: card — color dot, remove rating, friction chip, opt-in note"
```

---

## Task 3: HabitCardView — swipe right = complete

**Files:**
- Modify: `HabitStack/Views/Today/HabitCardView.swift`

**Step 1: Replace leading swipe action**

Find:
```swift
.swipeActions(edge: .leading, allowsFullSwipe: false) {
    Button(action: onEdit) { Label("Edit", systemImage: "pencil") }.tint(Color("Teal"))
}
```

Replace with:
```swift
.swipeActions(edge: .leading, allowsFullSwipe: true) {
    if habitWithStatus.isCompleted {
        Button {
            onToggle()
        } label: {
            Label("Undo", systemImage: "xmark")
        }
        .tint(Color("Stone500"))
    } else {
        Button {
            onToggle()
        } label: {
            Label("Done", systemImage: "checkmark")
        }
        .tint(Color("Teal"))
    }
}
```

**Step 2: Build check**

Build (`Cmd+B`). Confirm no errors.

**Step 3: Commit**

```bash
git add HabitStack/Views/Today/HabitCardView.swift
git commit -m "feat: swipe right on habit card to complete/uncomplete"
```

---

## Task 4: HoldCompleteButton — hold-to-fill ring + completion sound

**Files:**
- Modify: `HabitStack/Views/Today/HoldCompleteButton.swift`

**Step 1: Rewrite HoldCompleteButton**

Replace the entire file content:

```swift
import SwiftUI
import AudioToolbox

struct HoldCompleteButton: View {
    let isCompleted: Bool
    let accentColor: Color
    let onComplete: () -> Void
    let onUncomplete: () -> Void

    @State private var progress: Double = 0
    @State private var isPressed = false
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            // Base fill
            Circle()
                .fill(isCompleted ? accentColor : Color("Stone100"))
                .frame(width: 56, height: 56)

            // Border
            Circle()
                .strokeBorder(accentColor.opacity(isCompleted ? 0 : 0.35), lineWidth: 2)
                .frame(width: 56, height: 56)

            // Hold progress ring (only when not completed)
            if !isCompleted {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 56, height: 56)
                    .animation(.linear(duration: 0.02), value: progress)
            }

            // Checkmark
            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(isCompleted ? .white : accentColor.opacity(0.3))
                .scaleEffect(isCompleted ? 1 : 0.8)
                .animation(.spring(duration: 0.3), value: isCompleted)
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(duration: 0.15), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isCompleted { return }
                    if !isPressed {
                        isPressed = true
                        HapticManager.impact(.light)
                        startHoldTimer()
                    }
                }
                .onEnded { _ in
                    if isCompleted {
                        // Single tap to uncomplete
                        HapticManager.impact(.medium)
                        onUncomplete()
                        return
                    }
                    isPressed = false
                    if progress >= 1.0 { return } // already fired
                    cancelHoldTimer()
                    withAnimation(.spring(duration: 0.3)) { progress = 0 }
                }
        )
    }

    private func startHoldTimer() {
        timer?.invalidate()
        let interval = 0.02
        let step = interval / 0.6
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            Task { @MainActor in
                progress = min(1.0, progress + step)
                if progress >= 1.0 {
                    t.invalidate()
                    timer = nil
                    isPressed = false
                    HapticManager.impact(.medium)
                    AudioServicesPlaySystemSound(1104)
                    onComplete()
                    withAnimation(.spring(duration: 0.3)) { progress = 0 }
                }
            }
        }
    }

    private func cancelHoldTimer() {
        timer?.invalidate()
        timer = nil
    }
}
```

**Step 2: Build check**

Build (`Cmd+B`). Confirm `AudioToolbox` resolves (it's a system framework, no SPM needed).

**Step 3: Commit**

```bash
git add HabitStack/Views/Today/HoldCompleteButton.swift
git commit -m "feat: hold-to-complete fill ring with completion sound"
```

---

## Task 5: FAB simplification + "See all templates" in wizard

**Files:**
- Modify: `HabitStack/Views/Today/TodayView.swift`
- Modify: `HabitStack/Views/HabitWizard/WizardStepCueView.swift`

**Step 1: Remove FAB dialog in TodayView**

Find and remove:
```swift
@State private var showAddOptions = false
```

Find the FAB `Button`:
```swift
Button {
    showAddOptions = true
} label: { ... }
.confirmationDialog("Add Habit", isPresented: $showAddOptions) {
    Button("Browse Templates") { showTemplateLibrary = true }
    Button("Create Personal") { showHabitWizard = true }
    Button("Cancel", role: .cancel) {}
}
```

Replace with:
```swift
Button {
    showHabitWizard = true
} label: {
    Image(systemName: "plus")
        .font(.title2.bold())
        .foregroundStyle(.white)
        .frame(width: 56, height: 56)
        .background(Color("Teal"))
        .clipShape(Circle())
        .shadow(radius: 4, y: 2)
}
.padding(.trailing, 24)
.padding(.bottom, 24)
```

Also remove `showTemplateLibrary` state and its `.sheet` if Browse Templates is no longer reachable from the FAB. Keep the sheet — it will be triggered from inside the wizard in step 2.

**Step 2: Add "See all templates →" in WizardStepCueView**

In `WizardStepCueView`, the Quick Pick section has a horizontal `ScrollView`. Add a new `@State` for the template library sheet and a binding for the parent to pass through:

Add at the top of `WizardStepCueView`:
```swift
@State private var showTemplateLibrary = false
```

After the closing `}` of the Quick Pick horizontal `ScrollView` but still inside the Quick Pick `VStack(alignment: .leading, spacing: 8)`, add:
```swift
Button {
    showTemplateLibrary = true
} label: {
    Text("See all templates →")
        .font(.caption.bold())
        .foregroundStyle(Color("Teal"))
}
.buttonStyle(.plain)
.padding(.horizontal, 24)
```

Add a sheet modifier on the outer `ScrollView` of `WizardStepCueView` (append after existing modifiers on the ScrollView):
```swift
.sheet(isPresented: $showTemplateLibrary) {
    HabitTemplateLibraryView { template in
        viewModel.prefill(from: template)
        showTemplateLibrary = false
    }
}
```

**Step 3: Build check**

Build (`Cmd+B`).

**Step 4: Commit**

```bash
git add HabitStack/Views/Today/TodayView.swift HabitStack/Views/HabitWizard/WizardStepCueView.swift
git commit -m "feat: FAB direct to wizard, see all templates inside step 1"
```

---

## Task 6: TodayViewModel — perfect day detection + comeback state

**Files:**
- Modify: `HabitStack/ViewModels/TodayViewModel.swift`

**Step 1: Add NeverMissTwiceState enum and new properties**

After the `import Foundation` line, add:

```swift
enum NeverMissTwiceState {
    case warning, comeback, dismissed
}
```

Inside the `TodayViewModel` class, add new properties:
```swift
var neverMissTwiceState: NeverMissTwiceState = .dismissed
var isPerfectDay = false
```

**Step 2: Add perfect day detection in toggleHabit**

In `toggleHabit`, inside the `await MainActor.run` block after `self.checkMilestone(...)`, add:
```swift
self.checkPerfectDay()
self.checkComeback()
```

**Step 3: Add helper methods**

Add at the bottom of the private helpers section:

```swift
private func checkPerfectDay() {
    guard completedHabits == totalHabits, totalHabits > 0 else { return }
    let dateKey = "perfectDay_\(todayDateString)"
    guard !UserDefaults.standard.bool(forKey: dateKey) else { return }
    UserDefaults.standard.set(true, forKey: dateKey)
    UserDefaults.standard.set(true, forKey: "achievement_perfectDay")
    isPerfectDay = true
    // Show milestone view reusing existing showMilestone flag with special sentinel
    milestoneStreak = 0  // 0 = perfect day signal
    milestoneHabitName = "Perfect Day"
    showMilestone = true
    HapticManager.notification(.success)
}

private func checkComeback() {
    guard neverMissTwiceState == .warning, completedHabits == 1 else { return }
    withAnimation { neverMissTwiceState = .comeback }
    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        withAnimation { self.neverMissTwiceState = .dismissed }
    }
}

private var todayDateString: String {
    String(ISO8601DateFormatter().string(from: Date()).prefix(10))
}
```

**Step 4: Wire neverMissTwiceState into existing showNeverMissTwice logic**

In `checkNeverMissTwice`, replace the last two lines:
```swift
// REMOVE:
neverMissTwiceCount = missedCount
showNeverMissTwice = missedCount > streaks.count / 2

// ADD:
neverMissTwiceCount = missedCount
let shouldShow = missedCount > 0 && missedCount > streaks.count / 2
showNeverMissTwice = shouldShow
neverMissTwiceState = shouldShow ? .warning : .dismissed
```

Also store achievement key for streak milestones. In `checkMilestone`, after `UserDefaults.standard.set(true, forKey: key)` add:
```swift
UserDefaults.standard.set(true, forKey: "achievement_milestone_\(count)")
```

**Step 5: Build check**

Build (`Cmd+B`).

**Step 6: Commit**

```bash
git add HabitStack/ViewModels/TodayViewModel.swift
git commit -m "feat: perfect day detection, comeback state, achievement keys"
```

---

## Task 7: MilestoneCelebrationView — perfect day variant

**Files:**
- Modify: `HabitStack/Views/Today/MilestoneCelebrationView.swift`
- Modify: `HabitStack/Views/Today/TodayView.swift`

**Step 1: Add perfect day variant to MilestoneCelebrationView**

`streakDays == 0` is the perfect day sentinel (set in Task 6). Update `milestoneName`, `milestoneEmoji`, and the body copy:

In `milestoneName`, add at the top of the switch:
```swift
case 0: return "Perfect Day"
```

In `milestoneEmoji`, add:
```swift
case 0: return "⭐"
```

In `body`, replace the static subtitle `Text`:
```swift
// REMOVE:
Text("Every rep makes you more of the person you want to become.")

// ADD:
if streakDays == 0 {
    Text("Every habit. Every day. That's identity.")
        .font(.body)
        .foregroundStyle(Color("Stone500"))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
        .padding(.top, 24)
} else {
    Text("Every rep makes you more of the person you want to become.")
        .font(.body)
        .foregroundStyle(Color("Stone500"))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
        .padding(.top, 24)
}
```

**Step 2: Build check**

Build (`Cmd+B`).

**Step 3: Commit**

```bash
git add HabitStack/Views/Today/MilestoneCelebrationView.swift
git commit -m "feat: perfect day variant in MilestoneCelebrationView"
```

---

## Task 8: NeverMissTwiceBanner — comeback variant + Use Shield button

**Files:**
- Modify: `HabitStack/Views/Today/NeverMissTwiceBanner.swift`
- Modify: `HabitStack/Views/Today/TodayView.swift`

**Step 1: Rewrite NeverMissTwiceBanner to accept state**

Replace the entire file:

```swift
import SwiftUI

struct NeverMissTwiceBanner: View {
    var state: NeverMissTwiceState = .warning
    var missedCount: Int = 0
    var profile: Profile?
    let onDismiss: () -> Void
    let onUseShield: () -> Void

    var body: some View {
        switch state {
        case .warning:
            warningBanner
        case .comeback:
            comebackBanner
        case .dismissed:
            EmptyView()
        }
    }

    private var warningBanner: some View {
        HStack(spacing: 12) {
            Text("💪").font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("You missed yesterday. That's okay.")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color("Stone950"))
                Text(missedCount > 1
                     ? "\(missedCount) habits missed yesterday — never miss twice."
                     : "Rule: Never miss twice. Start again today.")
                    .font(.caption)
                    .foregroundStyle(Color("Stone500"))
            }
            Spacer()
            VStack(spacing: 6) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(Color("Stone500"))
                        .padding(6)
                        .background(Color("Stone100"))
                        .clipShape(Circle())
                }
                if let profile, profile.level >= 5, profile.streakShields > 0 {
                    Button(action: onUseShield) {
                        HStack(spacing: 3) {
                            Image(systemName: "shield.fill")
                            Text("Use Shield")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(Color("Teal"))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color("TealLight"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color("Teal").opacity(0.3), lineWidth: 1))
    }

    private var comebackBanner: some View {
        HStack(spacing: 12) {
            Text("🔥").font(.title2)
            Text("You're back. Streak lives on.")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(14)
        .background(Color("Teal"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

**Step 2: Update TodayView to use new NeverMissTwiceBanner API**

Find the `NeverMissTwiceBanner(...)` call in `TodayView` and update it:

```swift
// REMOVE old call:
NeverMissTwiceBanner(missedCount: viewModel.neverMissTwiceCount) {
    viewModel.showNeverMissTwice = false
    viewModel.neverMissTwiceDismissed = true
}

// ADD:
NeverMissTwiceBanner(
    state: viewModel.neverMissTwiceState,
    missedCount: viewModel.neverMissTwiceCount,
    profile: viewModel.profile,
    onDismiss: {
        viewModel.showNeverMissTwice = false
        viewModel.neverMissTwiceDismissed = true
        viewModel.neverMissTwiceState = .dismissed
    },
    onUseShield: {
        Task { await viewModel.spendStreakShield() }
    }
)
```

Also update the banner visibility condition from `viewModel.showNeverMissTwice` to:
```swift
if viewModel.neverMissTwiceState != .dismissed {
```

**Step 3: Add spendStreakShield to TodayViewModel**

In `TodayViewModel.swift`, add:
```swift
func spendStreakShield() async {
    guard let userId else { return }
    // Call Supabase RPC (defined in Task 13)
    try? await supabase.rpc("spend_streak_shield", params: ["p_user_id": userId.uuidString]).execute()
    // Reload to pick up new streaks + shield count
    await loadToday()
    await MainActor.run {
        neverMissTwiceState = .comeback
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { self.neverMissTwiceState = .dismissed }
        }
    }
}
```

**Step 4: Build check**

Build (`Cmd+B`).

**Step 5: Commit**

```bash
git add HabitStack/Views/Today/NeverMissTwiceBanner.swift HabitStack/Views/Today/TodayView.swift HabitStack/ViewModels/TodayViewModel.swift
git commit -m "feat: comeback banner variant + Use Shield button"
```

---

## Task 9: Supabase migration — spend_streak_shield RPC

**Files:**
- Create: `supabase/migrations/003_spend_streak_shield.sql`

**Step 1: Create the migration**

```sql
-- RPC: spend_streak_shield
-- Decrements streak_shields by 1 for the user,
-- inserts a 'skipped' log for yesterday for every habit that has an active streak,
-- so streak counts are preserved.

create or replace function spend_streak_shield(p_user_id uuid)
returns void
language plpgsql
security definer
as $$
declare
    yesterday date := current_date - interval '1 day';
    habit_rec record;
begin
    -- Guard: user must have at least 1 shield
    if (select streak_shields from profiles where id = p_user_id) < 1 then
        raise exception 'No streak shields available';
    end if;

    -- Decrement shield
    update profiles
    set streak_shields = streak_shields - 1
    where id = p_user_id;

    -- Insert skipped log for yesterday for each habit with an active streak
    for habit_rec in
        select h.id as habit_id
        from habits h
        join streaks s on s.habit_id = h.id
        where h.user_id = p_user_id
          and h.archived_at is null
          and s.current_streak > 0
          and s.last_logged_date < current_date  -- missed today or yesterday
    loop
        -- Only insert if no log already exists for yesterday
        if not exists (
            select 1 from habit_logs
            where habit_id = habit_rec.habit_id
              and user_id = p_user_id
              and logged_at::date = yesterday
        ) then
            insert into habit_logs (habit_id, user_id, logged_at, status)
            values (habit_rec.habit_id, p_user_id, yesterday::timestamptz, 'skipped');
        end if;
    end loop;
end;
$$;

-- Grant execute to authenticated users
grant execute on function spend_streak_shield(uuid) to authenticated;
```

**Step 2: Apply migration**

```bash
cd /Users/tomerab/dev/habit-stack && supabase db push
```

Expected: migration applied with no errors.

**Step 3: Commit**

```bash
git add supabase/migrations/003_spend_streak_shield.sql
git commit -m "feat: add spend_streak_shield Supabase RPC"
```

---

## Task 10: AnalyticsViewModel — calendar data + best time of day

**Files:**
- Modify: `HabitStack/ViewModels/AnalyticsViewModel.swift`

**Step 1: Add CalendarDayStatus enum**

After the `import Foundation` line, add:
```swift
enum CalendarDayStatus {
    case full, partial, empty
}
```

**Step 2: Add allHabitsLogs for calendar computation**

Add a new property:
```swift
var calendarData: [Date: CalendarDayStatus] = [:]
```

**Step 3: Add calendar computation method**

Add after `loadAllHabitsStats`:
```swift
private func loadCalendarData(userId: UUID) async {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) else { return }
    let formatter = ISO8601DateFormatter()

    // Fetch all habit logs for this month
    let allLogs: [HabitLog] = (try? await supabase
        .from("habit_logs")
        .select()
        .eq("user_id", value: userId.uuidString)
        .gte("logged_at", value: formatter.string(from: monthStart))
        .lte("logged_at", value: formatter.string(from: today))
        .execute()
        .value) ?? []

    let habitCount = habits.count
    guard habitCount > 0 else { return }

    // Group done logs by day
    var donePerDay: [Date: Int] = [:]
    for log in allLogs where log.status == .done {
        let day = calendar.startOfDay(for: log.loggedAt)
        donePerDay[day, default: 0] += 1
    }

    // Build status per day for current month
    var result: [Date: CalendarDayStatus] = [:]
    var current = monthStart
    while current <= today {
        let done = donePerDay[current] ?? 0
        if done == 0 {
            result[current] = .empty
        } else if done >= habitCount {
            result[current] = .full
        } else {
            result[current] = .partial
        }
        current = calendar.date(byAdding: .day, value: 1, to: current)!
    }

    await MainActor.run { self.calendarData = result }
}
```

**Step 4: Add best time of day computation**

Add property:
```swift
var bestTimeOfDay: Habit.TimeOfDay? = nil
```

Add method (call after `loadAllHabitsStats`):
```swift
private func computeBestTimeOfDay(userId: UUID) async {
    guard !habits.isEmpty else { return }
    let formatter = ISO8601DateFormatter()
    let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

    let allLogs: [HabitLog] = (try? await supabase
        .from("habit_logs")
        .select()
        .eq("user_id", value: userId.uuidString)
        .gte("logged_at", value: formatter.string(from: weekAgo))
        .eq("status", value: "done")
        .execute()
        .value) ?? []

    var countByTimeOfDay: [Habit.TimeOfDay: Int] = [:]
    for log in allLogs {
        guard let habit = habits.first(where: { $0.id == log.habitId }) else { continue }
        countByTimeOfDay[habit.timeOfDay, default: 0] += 1
    }

    let best = countByTimeOfDay.max(by: { $0.value < $1.value })?.key
    await MainActor.run { self.bestTimeOfDay = best }
}
```

**Step 5: Call both in load()**

In `load()`, after `await loadAllHabitsStats(userId: userId)`, add:
```swift
await loadCalendarData(userId: userId)
await computeBestTimeOfDay(userId: userId)
```

**Step 6: Build check**

Build (`Cmd+B`).

**Step 7: Commit**

```bash
git add HabitStack/ViewModels/AnalyticsViewModel.swift
git commit -m "feat: analytics — calendar data + best time of day computation"
```

---

## Task 11: StreakCalendarView — new file

**Files:**
- Create: `HabitStack/Views/Analytics/StreakCalendarView.swift`

**Step 1: Create file**

```swift
import SwiftUI

struct StreakCalendarView: View {
    let calendarData: [Date: CalendarDayStatus]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    private var monthDays: [Date?] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
              let range = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }

        // Pad start: weekday of monthStart (Mon=0)
        let firstWeekday = (calendar.component(.weekday, from: monthStart) + 5) % 7
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        return days
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Month")
                .font(.headline)
                .foregroundStyle(Color("Stone950"))

            // Day labels
            HStack(spacing: 4) {
                ForEach(dayLabels, id: \.self) { label in
                    Text(label)
                        .font(.caption2.bold())
                        .foregroundStyle(Color("Stone500"))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(monthDays.indices, id: \.self) { index in
                    if let date = monthDays[index] {
                        let status = calendarData[date] ?? .empty
                        RoundedRectangle(cornerRadius: 4)
                            .fill(cellColor(status))
                            .frame(height: 28)
                            .overlay(
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.caption2)
                                    .foregroundStyle(status == .empty ? Color("Stone500") : .white)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.clear)
                            .frame(height: 28)
                    }
                }
            }

            // Legend
            HStack(spacing: 12) {
                Spacer()
                legendItem(color: Color("Stone100"), label: "None")
                legendItem(color: Color("Teal").opacity(0.4), label: "Partial")
                legendItem(color: Color("Teal"), label: "All done")
            }
            .font(.caption2)
            .foregroundStyle(Color("Stone500"))
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private func cellColor(_ status: CalendarDayStatus) -> Color {
        switch status {
        case .full: return Color("Teal")
        case .partial: return Color("Teal").opacity(0.4)
        case .empty: return Color("Stone100")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
        }
    }
}
```

**Step 2: Regenerate xcodeproj**

```bash
cd /Users/tomerab/dev/habit-stack && ~/.mint/bin/xcodegen generate
```

**Step 3: Commit**

```bash
git add HabitStack/Views/Analytics/StreakCalendarView.swift project.yml HabitStack.xcodeproj
git commit -m "feat: StreakCalendarView — monthly habit chain calendar"
```

---

## Task 12: AchievementsView — new file

**Files:**
- Create: `HabitStack/Views/Analytics/AchievementsView.swift`

**Step 1: Create file**

```swift
import SwiftUI

struct Achievement: Identifiable {
    let id: String
    let name: String
    let description: String
    let emoji: String

    var isEarned: Bool {
        UserDefaults.standard.bool(forKey: "achievement_\(id)")
    }
}

struct AchievementsView: View {
    private static let all: [Achievement] = [
        Achievement(id: "milestone_7",   name: "Week Warrior",       description: "7-day streak",   emoji: "🔥"),
        Achievement(id: "milestone_14",  name: "Two Weeks Strong",   description: "14-day streak",  emoji: "⚡"),
        Achievement(id: "milestone_21",  name: "Habit Forming",      description: "21-day streak",  emoji: "🌱"),
        Achievement(id: "milestone_30",  name: "Month Champion",     description: "30-day streak",  emoji: "🏆"),
        Achievement(id: "milestone_66",  name: "Automatic",          description: "66-day streak",  emoji: "🧠"),
        Achievement(id: "milestone_100", name: "Centurion",          description: "100-day streak", emoji: "💯"),
        Achievement(id: "perfectDay",    name: "Perfect Day",        description: "All habits in one day", emoji: "⭐"),
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
                .foregroundStyle(Color("Stone950"))

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Self.all) { achievement in
                    VStack(spacing: 6) {
                        Text(achievement.emoji)
                            .font(.title)
                            .opacity(achievement.isEarned ? 1.0 : 0.25)
                        Text(achievement.name)
                            .font(.caption.bold())
                            .foregroundStyle(achievement.isEarned ? Color("Stone950") : Color("Stone500"))
                            .multilineTextAlignment(.center)
                        Text(achievement.description)
                            .font(.caption2)
                            .foregroundStyle(Color("Stone500"))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(achievement.isEarned ? Color("TealLight").opacity(0.4) : Color("Stone100").opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
```

**Step 2: Regenerate xcodeproj**

```bash
cd /Users/tomerab/dev/habit-stack && ~/.mint/bin/xcodegen generate
```

**Step 3: Commit**

```bash
git add HabitStack/Views/Analytics/AchievementsView.swift project.yml HabitStack.xcodeproj
git commit -m "feat: AchievementsView — achievement gallery"
```

---

## Task 13: AnalyticsView — wire in calendar, achievements, L10 gate

**Files:**
- Modify: `HabitStack/Views/Analytics/AnalyticsView.swift`

**Step 1: Add StreakCalendarView above HeatmapView**

In `AnalyticsView.body`, find the heatmap section:
```swift
VStack(alignment: .leading, spacing: 8) {
    HeatmapView(...)
    HeatmapLegend()
}
.padding(.horizontal, 16)
```

Replace with:
```swift
VStack(alignment: .leading, spacing: 16) {
    StreakCalendarView(calendarData: viewModel.calendarData)

    VStack(alignment: .leading, spacing: 8) {
        HeatmapView(
            cells: viewModel.heatmapData(),
            onTap: { cell in
                selectedCell = cell
                showCellSheet = true
            }
        )
        HeatmapLegend()
    }
}
.padding(.horizontal, 16)
```

**Step 2: Gate HabitInsightsCard with L10 perk**

The `HabitInsightsCard` is inside `AnalyticsView` as a private struct. Add a `profile` parameter and lock overlay:

First, pass profile to AnalyticsView. Add state:
```swift
@State private var profile: Profile?
```

In `.task { await viewModel.load() }`, also load the profile:
```swift
.task {
    await viewModel.load()
    if let userId = try? await supabase.auth.session.user.id {
        let profiles: [Profile] = (try? await supabase
            .from("profiles").select()
            .eq("id", value: userId.uuidString)
            .limit(1).execute().value) ?? []
        profile = profiles.first
    }
}
```

Replace the `HabitInsightsCard(...)` call:
```swift
// REMOVE:
HabitInsightsCard(
    strongest: viewModel.strongestHabit,
    weakest: viewModel.weakestHabit
)
.padding(.horizontal, 16)

// ADD:
ZStack(alignment: .topTrailing) {
    HabitInsightsCard(
        strongest: viewModel.strongestHabit,
        weakest: viewModel.weakestHabit,
        bestTimeOfDay: (profile?.level ?? 0) >= 10 ? viewModel.bestTimeOfDay : nil
    )
    if (profile?.level ?? 0) < 10 {
        Label("Unlock at Level 10", systemImage: "lock.fill")
            .font(.caption.bold())
            .foregroundStyle(Color("Stone500"))
            .padding(6)
            .background(.regularMaterial)
            .clipShape(Capsule())
            .padding(10)
    }
}
.padding(.horizontal, 16)
```

Update `HabitInsightsCard` struct to accept the new parameter:
```swift
// In HabitInsightsCard:
let bestTimeOfDay: Habit.TimeOfDay?

// In body, after the weakest InsightPill:
if let tod = bestTimeOfDay {
    InsightPill(
        label: "Best time",
        emoji: tod == .morning ? "🌅" : tod == .evening ? "🌙" : "☀️",
        name: tod.displayName,
        rate: -1,  // -1 = don't show percentage
        color: .purple
    )
}
```

Update `InsightPill` to handle `rate == -1` (no percentage shown):
```swift
// In InsightPill body, replace:
Text("\(Int(rate * 100))% this week")
// with:
if rate >= 0 {
    Text("\(Int(rate * 100))% this week")
        .font(.caption)
        .foregroundStyle(Color("Stone500"))
}
```

**Step 3: Add AchievementsView at bottom of scroll**

Just before the closing `}` of the `VStack(alignment: .leading, spacing: 20)`, add:
```swift
AchievementsView()
    .padding(.horizontal, 16)
```

**Step 4: Build check**

Build (`Cmd+B`).

**Step 5: Commit**

```bash
git add HabitStack/Views/Analytics/AnalyticsView.swift
git commit -m "feat: analytics — streak calendar, achievements gallery, L10 insights gate"
```

---

## Task 14: HabitService + ArchivedHabitsView + SettingsView

**Files:**
- Modify: `HabitStack/Services/HabitService.swift`
- Create: `HabitStack/Views/Settings/ArchivedHabitsView.swift`
- Modify: `HabitStack/Views/Settings/SettingsView.swift`

**Step 1: Add restoreHabit to HabitService**

At the end of `HabitService`, add:
```swift
func restoreHabit(_ habitId: UUID) async throws {
    try await supabase
        .from("habits")
        .update(["archived_at": String?.none as Any])
        .eq("id", value: habitId.uuidString)
        .execute()
}

func fetchArchivedHabits(userId: UUID) async throws -> [Habit] {
    try await supabase
        .from("habits")
        .select()
        .eq("user_id", value: userId.uuidString)
        .not("archived_at", operator: .is, value: "null")
        .order("archived_at", ascending: false)
        .execute()
        .value
}
```

**Step 2: Create ArchivedHabitsView**

```swift
import SwiftUI

struct ArchivedHabitsView: View {
    @State private var habits: [Habit] = []
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if habits.isEmpty {
                EmptyStateView(
                    icon: "archivebox",
                    headline: "No archived habits",
                    subtext: "Habits you archive will appear here."
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(habits) { habit in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: habit.color))
                                    .frame(width: 36, height: 36)
                                Text(String(habit.name.prefix(1)).uppercased())
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(habit.name)
                                    .font(.subheadline)
                                    .foregroundStyle(Color("Stone950"))
                                if let archivedAt = habit.archivedAt {
                                    Text("Archived \(archivedAt.formatted(.dateTime.month().day().year()))")
                                        .font(.caption)
                                        .foregroundStyle(Color("Stone500"))
                                }
                            }
                            Spacer()
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                Task { await restore(habit) }
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(Color("Teal"))
                        }
                    }
                }
            }
        }
        .navigationTitle("Archived Habits")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        guard let userId = try? await supabase.auth.session.user.id else { return }
        isLoading = true
        habits = (try? await HabitService.shared.fetchArchivedHabits(userId: userId)) ?? []
        isLoading = false
    }

    private func restore(_ habit: Habit) async {
        try? await HabitService.shared.restoreHabit(habit.id)
        withAnimation { habits.removeAll { $0.id == habit.id } }
    }
}
```

Note: `habit.archivedAt` requires the `Habit` model to expose this field. Check `HabitStack/Models/Habit.swift` — if `archivedAt` is already a property (it's in the schema as `archived_at`), use it directly. If not, add `var archivedAt: Date?` with `CodingKeys` mapping `"archived_at"`.

**Step 3: Add Data section to SettingsView**

In `SettingsView.body` List, add before the existing Developer section:
```swift
Section("Data") {
    NavigationLink("Archived Habits") {
        ArchivedHabitsView()
    }
}
```

**Step 4: Regenerate xcodeproj**

```bash
cd /Users/tomerab/dev/habit-stack && ~/.mint/bin/xcodegen generate
```

**Step 5: Build check**

Build (`Cmd+B`). Fix any `archivedAt` missing field errors in `Habit.swift` if needed.

**Step 6: Commit**

```bash
git add HabitStack/Services/HabitService.swift HabitStack/Views/Settings/ArchivedHabitsView.swift HabitStack/Views/Settings/SettingsView.swift project.yml HabitStack.xcodeproj
git commit -m "feat: archived habit recovery — restore from Settings"
```

---

## Verification Checklist

Run through these manually on simulator after all tasks complete:

1. **Color dot** — open Today, confirm habits show colored letter circle instead of emoji; emoji still visible in HabitDetailView
2. **No rating dot** — confirm `·` badge gone from all cards; no confirmation dialog appears
3. **Needs setup chip** — create a habit with no tiny version and no reminder; confirm orange chip appears; tap → mini-editor opens; save tiny version → chip disappears
4. **Swipe right complete** — swipe habit card right → teal "Done" action → completes; swipe again → grey "Undo" → uncompletes
5. **Hold-to-complete** — press and hold circle → ring fills over ~0.6s → haptic + sound fires at 100%; release early → ring springs back to 0; tap completed habit → uncompletes
6. **Opt-in note** — complete a habit → no auto-sheet; pencil icon fades in; tap pencil → note sheet opens
7. **FAB** — tap `+` → wizard opens immediately (no dialog); inside step 1, tap "See all templates →" → library opens; select template → wizard prefills
8. **Perfect day** — complete all habits → gold "Perfect Day" milestone fires once; close and re-complete → does not fire again same day
9. **Streak calendar** — Analytics tab → month grid shows filled/partial/empty squares correctly
10. **Comeback banner** — set `lastLoggedDate` to 2 days ago in DB; open app → orange banner; complete first habit → banner flips teal, auto-dismisses
11. **Sound** — on hold-complete success, a soft click plays; toggle silent mode → no sound
12. **Achievements** — Analytics tab → achievement grid shows; after 7-day streak milestone, badge becomes full-color
13. **L5 Use Shield** — with a level 5 profile and 1+ shields, orange banner shows "Use Shield" button; tap → streak preserved, banner flips to comeback
14. **L10 insights** — below L10: lock badge on insights card; at L10+: "Best time" pill appears
15. **Archived recovery** — archive a habit; Settings → Data → Archived Habits → habit appears; swipe Restore → disappears from list; Today view shows it again
