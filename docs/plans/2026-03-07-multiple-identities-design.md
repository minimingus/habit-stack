# Multiple Identities Design

## Problem

The app shows a single global identity statement ("I am becoming someone who reads every day"). In reality a person is building several identity dimensions simultaneously — athlete, reader, meditator. Collapsing this to one string misrepresents who they are becoming.

## Goal

Surface all active identity dimensions the user is building, each backed by evidence from its associated habits.

## Data Layer — No Changes

Each habit already carries an identity statement via the `craving` field (set in WizardStepCraving). The `identity_votes` Supabase table stores per-habit statements; every habit completion adds a vote. No schema changes required.

The `onboardingIdentityStatement` UserDefaults key is retired — it was a single-identity shortcut that is now obsolete.

## Identity Tab — Carousel

Replace the single `IdentityHeroCard` with a `TabView(.page)` carousel. Each page is one unique identity statement derived from habits' `craving` fields (deduplicated). Habits sharing the same statement are grouped under one card.

**Each carousel card shows:**
- "I am becoming someone who [statement]"
- Small habit chips below (emoji + name) — the habits backing this identity
- Evidence count: total `identity_votes` completions across all those habits
- Page indicator dots at bottom

**Empty states:**
- If a user has habits but none have a `craving` set: single placeholder card — "Add a 'why' to your habits to build your identity."
- If user has no habits: same placeholder.

The global **Edit Identity sheet is removed**. Identity is now edited per-habit in the wizard's "Why" step (WizardStepCravingView). Users can tap any habit chip on a carousel card to open the habit wizard for that habit.

## Today View — Toast

On habit completion the toast shows that specific habit's `craving` field as its identity statement. If the habit has no `craving`, no toast is shown. This is already the correct behaviour — the only change is reading from the habit's own field rather than the global UserDefaults key.

## Files Changed

| File | Change |
|------|--------|
| `HabitStack/Views/FourLaws/FourLawsView.swift` | Replace `IdentityHeroCard` + `EditIdentitySheet` with `IdentityCarousel` (paged `TabView`) |
| `HabitStack/ViewModels/TodayViewModel.swift` | `topIdentityStatement` reads from the just-completed habit's `craving`, not UserDefaults |
| `HabitStack/Views/Onboarding/IdentityStatementView.swift` | Remove or repurpose (onboarding no longer sets a global statement) |

## What Is Not Changing

- `IdentityVote` model and Supabase table — unchanged
- `WizardStepCravingView` — unchanged (already sets per-habit identity)
- `HabitCardView`, `XPHeaderView` — unchanged
- Supabase schema — unchanged
