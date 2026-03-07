# Habits Scorecard Redesign

## Problem

The current scorecard auto-populates from Supabase habits (aspirational habits the user is building). That's wrong. The Atomic Habits scorecard exercise (Ch. 4) is about mapping **existing unconscious daily behaviors** — brushing teeth, checking phone, morning coffee, snoozing — and rating them honestly. The two lists should never be mixed.

## Goal

A beautiful, free-form list where the user writes their actual daily behaviors and rates each one +/=/–. No Supabase. No health dimensions. Just honesty about what you actually do.

## Design (Option B — Free-form beautiful list)

### Data

`ScorecardEntry` model and UserDefaults persistence are unchanged. No schema changes.

### Single file changed

`HabitStack/Views/FourLaws/HabitsScorecardView.swift` — complete rewrite of the view layer only.

### Layout

```
NavigationStack
  ScrollView
    ┌─ Framing text (1 line, caption) ─────────────────┐
    │  "Notice what you already do. Rate it honestly."  │
    └───────────────────────────────────────────────────┘

    [suggestion chips — horizontal scroll]
    ☕ Morning coffee  📱 Check phone  😴 Snooze  🦷 Brush teeth ...

    ┌─ Entry list (white card, rounded) ───────────────┐
    │ ▌ Brush teeth             [+] [=] [–]            │ ← 44pt row
    │ ▌ Check phone (–)         [+] [=] [–]            │
    │   → Replace it                                    │ ← shown on –
    │ ▌ Morning coffee          [+] [=] [–]            │
    └───────────────────────────────────────────────────┘

  SafeAreaInset (bottom)
    [ What do you actually do every day?    ] [+]
```

### Row design (compact)
- Height: ~44pt natural (no explicit height, but tight padding: 8pt vertical)
- Left: 3px color strip (teal positive, red negative, gray neutral, clear unrated)
- Behavior text: `.body`, Stone950, takes remaining width
- Rating: three 30×30 buttons (+/=/–) on trailing edge
- Selected state: filled background (teal/gray/red), white text
- Row tint: TealLight 20% on positive, red 4% on negative, white otherwise
- "Replace it" label (caption.bold, Teal) appears below text on negative entries, animated
- Swipe trailing: delete

### Summary bar
- Shown once ≥1 entry exists
- Single compact row: `+ 3  =  2  – 1` inline with color dots — no card, no shadow
- Sits directly below framing text, above suggestions

### Suggestion chips
- Horizontal scroll, shown always (not just on empty)
- Tapping a chip appends the behavior text immediately (no text field interaction)
- Chip grays out if already in list (by exact text match)
- Suggestions: Morning coffee, Check phone, Snooze alarm, Brush teeth, Breakfast, Exercise, Meditate, Read, Watch TV, Scroll social, Take vitamins, Journal, Evening walk, Drink water

### Empty state
- No habits yet: framing text + suggestions visible, entry list area hidden
- Friendly prompt: "Start with your morning. What's the first thing you actually do?"

### Input bar (bottom, pinned)
- `TextField("What do you actually do every day?", text: $newBehavior)`
- `+` button: disabled when empty, Teal when active
- `.regularMaterial` background

### Removed
- `loadHabitsIfNeeded()` — entirely deleted
- `isLoading` state — not needed
- `FlowLayout` — not used
- Legend (`LegendItem`) — symbols are self-explanatory; rating buttons serve as legend

### Kept
- `onReplace` → `showReplaceWizard` sheet (negative entry → wizard with `replacingBehavior`)
- `onContinue` parameter (onboarding mode)
- All persistence logic (`ScorecardEntry.load()` / `.save()`)
