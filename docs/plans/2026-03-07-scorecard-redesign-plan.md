# Scorecard Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rewrite `HabitsScorecardView` as a beautiful free-form daily-behavior rater, completely decoupled from Supabase habits.

**Architecture:** Single-file rewrite of `HabitsScorecardView.swift`. The `ScorecardEntry` model and UserDefaults persistence are unchanged. No new files, no schema changes. The view is broken into private sub-structs inside the same file.

**Tech Stack:** SwiftUI, `ScorecardEntry` (UserDefaults persistence), existing `HabitWizardView` sheet for "Replace it" flow.

---

## Context: What exists today

`HabitStack/Views/FourLaws/HabitsScorecardView.swift` contains:
- `loadHabitsIfNeeded()` — fetches from Supabase and injects them as entries. **Delete this entirely.**
- `FlowLayout` — unused now. **Delete.**
- `LegendItem` — stand-alone legend row. **Delete** (buttons are self-labelling).
- `ScorecardSummaryBar` / `SummaryCell` — keep concept, rewrite to be inline/compact (no card).
- `ScorecardEntryRow` — keep concept, make rows tighter.
- `AddBehaviorField` — keep, minor copy tweak.
- `onContinue` parameter — keep (used in onboarding).
- `onReplace` / `showReplaceWizard` state — keep.

`HabitStack/Models/ScorecardEntry.swift` — **no changes**.

---

## Task 1: Strip dead code from the view

**Files:**
- Modify: `HabitStack/Views/FourLaws/HabitsScorecardView.swift`

**Step 1: Delete `loadHabitsIfNeeded()`**

Remove the entire `loadHabitsIfNeeded()` method (lines ~130–161 in current file) and its `.task { await loadHabitsIfNeeded() }` call site. Also remove `@State private var isLoading = false`.

The `.onAppear { entries = ScorecardEntry.load() }` stays.

**Step 2: Delete `FlowLayout`**

Remove the entire `FlowLayout: Layout` struct (bottom of file, ~40 lines).

**Step 3: Delete `LegendItem` struct and its usage**

Remove the `LegendItem` struct and the `HStack(spacing: 16)` legend block from the body.

**Step 4: Build — confirm no regressions**

The view should still compile. It will look slightly broken (no legend, no loading) but functional.

---

## Task 2: Compact entry row

**Files:**
- Modify: `HabitStack/Views/FourLaws/HabitsScorecardView.swift` — `ScorecardEntryRow` struct

**Goal:** Reduce row height. Current padding is `.padding(.vertical, 10)` with 34×34 buttons. Target: 8pt vertical, 30×30 buttons.

**Step 1: Tighten `ScorecardEntryRow` body**

Replace the existing `ScorecardEntryRow` body with:

```swift
var body: some View {
    HStack(spacing: 10) {
        Rectangle()
            .fill(ratingColor.opacity(0.7))
            .frame(width: 3)
            .padding(.vertical, 6)

        VStack(alignment: .leading, spacing: 2) {
            Text(entry.behavior)
                .font(.subheadline)
                .foregroundStyle(Color("Stone950"))
                .frame(maxWidth: .infinity, alignment: .leading)
            if entry.rating == .negative {
                Button { onReplace() } label: {
                    Label("Replace it", systemImage: "arrow.right")
                        .font(.caption.bold())
                        .foregroundStyle(Color("Teal"))
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }

        HStack(spacing: 3) {
            ForEach(ScorecardEntry.Rating.allCases, id: \.self) { rating in
                Button {
                    withAnimation(.spring(duration: 0.2)) {
                        onRatingChanged(entry.rating == rating ? nil : rating)
                    }
                } label: {
                    Text(rating.rawValue)
                        .font(.caption.bold())
                        .frame(width: 30, height: 30)
                        .background(entry.rating == rating ? buttonColor(rating) : Color("Stone100"))
                        .foregroundStyle(entry.rating == rating ? .white : Color("Stone500"))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
            }
        }
    }
    .padding(.trailing, 12)
    .padding(.vertical, 8)
    .background(rowTint)
    .swipeActions(edge: .trailing) {
        Button(role: .destructive, action: onDelete) {
            Label("Delete", systemImage: "trash")
        }
    }
}
```

Change font from `.body` to `.subheadline` on the behavior text. This alone shrinks rows significantly.

---

## Task 3: Inline summary + suggestion chips

**Files:**
- Modify: `HabitStack/Views/FourLaws/HabitsScorecardView.swift`

**Step 1: Replace `ScorecardSummaryBar` with an inline one-liner**

Delete the existing `ScorecardSummaryBar` and `SummaryCell` structs. Replace the usage in the body with a simple inline view:

```swift
// Inline summary — shown when entries exist
if !entries.isEmpty {
    HStack(spacing: 16) {
        Label("\(positiveCount)", systemImage: "plus")
            .font(.caption.bold()).foregroundStyle(Color("Teal"))
        Label("\(neutralCount)", systemImage: "equal")
            .font(.caption.bold()).foregroundStyle(Color("Stone500"))
        Label("\(negativeCount)", systemImage: "minus")
            .font(.caption.bold()).foregroundStyle(.red.opacity(0.7))
        Spacer()
        if unratedCount > 0 {
            Text("\(unratedCount) unrated")
                .font(.caption).foregroundStyle(Color("Stone500").opacity(0.6))
        }
    }
    .padding(.horizontal, 16)
    .padding(.top, 4)
}
```

**Step 2: Add suggestion chips**

Add a new private constant and view section. Place this **above** the entry list, below the summary:

```swift
// In the view struct, add this constant:
private let suggestions = [
    "Morning coffee", "Check phone", "Snooze alarm", "Brush teeth",
    "Breakfast", "Exercise", "Meditate", "Read", "Watch TV",
    "Scroll social media", "Take vitamins", "Journal",
    "Evening walk", "Drink water", "Late-night snacking",
]
```

```swift
// In body, between summary and entry list:
ScrollView(.horizontal, showsIndicators: false) {
    HStack(spacing: 8) {
        ForEach(suggestions, id: \.self) { suggestion in
            let alreadyAdded = entries.contains { $0.behavior == suggestion }
            Button {
                if !alreadyAdded {
                    withAnimation {
                        entries.append(ScorecardEntry(id: UUID(), behavior: suggestion, rating: nil))
                        ScorecardEntry.save(entries)
                        HapticManager.impact(.light)
                    }
                }
            } label: {
                Text(suggestion)
                    .font(.subheadline)
                    .foregroundStyle(alreadyAdded ? Color("Stone500").opacity(0.5) : Color("Stone950"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(alreadyAdded ? Color("Stone100").opacity(0.5) : Color("Stone100"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(alreadyAdded)
        }
    }
    .padding(.horizontal, 16)
}
```

---

## Task 4: New main body with framing text + empty state

**Files:**
- Modify: `HabitStack/Views/FourLaws/HabitsScorecardView.swift` — the `body` property of `HabitsScorecardView`

**Step 1: Replace the entire body's `ScrollView` content**

The new body VStack order inside the ScrollView:

```
1. Framing text (always visible)
2. Inline summary (if entries non-empty)
3. Suggestion chips (always visible)
4. Entry list card (if entries non-empty) OR empty prompt (if empty)
5. Spacer(minLength: 80)
```

**Framing text:**
```swift
Text("Notice what you actually do every day. Rate each behavior honestly.")
    .font(.subheadline)
    .foregroundStyle(Color("Stone500"))
    .padding(.horizontal, 16)
    .padding(.top, 4)
```

**Empty prompt (replaces current empty state):**
```swift
if entries.isEmpty {
    Text("Start with your morning — what's the first thing you actually do?")
        .font(.subheadline)
        .foregroundStyle(Color("Stone500").opacity(0.7))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .padding(.top, 32)
}
```

**Entry list** (keep existing card style — white background, rounded, shadow):
```swift
if !entries.isEmpty {
    VStack(spacing: 0) {
        ForEach(entries) { entry in
            ScorecardEntryRow(
                entry: entry,
                onRatingChanged: { setRating($0, for: entry.id) },
                onDelete: { deleteEntry(id: entry.id) },
                onReplace: { replacingBehavior = entry.behavior; showReplaceWizard = true }
            )
            if entry.id != entries.last?.id {
                Divider().padding(.leading, 16)
            }
        }
    }
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    .padding(.horizontal, 16)
}
```

**Step 2: Remove `.task { await loadHabitsIfNeeded() }` if still present**

Confirm it's gone. The only data-loading call should be `.onAppear { entries = ScorecardEntry.load() }`.

---

## Task 5: Input bar copy tweak

**Files:**
- Modify: `HabitStack/Views/FourLaws/HabitsScorecardView.swift` — `AddBehaviorField`

**Step 1:** Change placeholder text:
```swift
// Before:
TextField("Add a personal behavior…", text: $text)
// After:
TextField("Add a behavior…", text: $text)
```

---

## Verification

After all tasks:

1. Open app → Identity tab → "Habits Scorecard"
2. **Empty state:** See framing text + suggestion chips + empty prompt. No habits from Today view appear.
3. **Tap a chip** ("Morning coffee") → entry appears instantly in the list, chip grays out
4. **Tap another chip** → second entry appears
5. **Type in input bar** → custom behavior added on tap `+`
6. **Rate an entry `–`** → red strip appears on left, "Replace it" label fades in below text, row tints red faintly
7. **Tap "Replace it"** → wizard sheet opens with cue pre-filled "When I feel like [behavior]" and teal replacement banner
8. **Rate an entry `+`** → teal strip, TealLight tint
9. **Summary line** shows correct counts
10. **Swipe to delete** → entry removed
11. **Kill and reopen app** → ratings persist (UserDefaults)
12. **No Supabase call** — no spinner, no delay on open

---

## Notes

- `FlowLayout` is now deleted. It was only used internally and is no longer needed.
- `LegendItem` is deleted. The +/=/– buttons act as their own legend.
- `ScorecardSummaryBar`/`SummaryCell` are deleted and replaced by the inline HStack.
- `loadHabitsIfNeeded()` is deleted. Scorecard is fully local.
- All other view state (`replacingBehavior`, `showReplaceWizard`, `onContinue`, toolbar) is unchanged.
