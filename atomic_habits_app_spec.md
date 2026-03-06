# Atomic Habits Inspired iOS App -- Product Spec for LLM Improvement

## Source

Based on ideas from the book **Atomic Habits by James Clear**.

Goal: Build an iOS app that helps users develop positive habits using
behavioral psychology principles.

------------------------------------------------------------------------

# Core Philosophy

The app should implement the behavioral loop:

Cue → Craving → Response → Reward

Focus on **identity change**, not just habit tracking.

Users should think: "I am becoming the type of person who does this
habit."

------------------------------------------------------------------------

# Core MVP Features

## 1. Habit Creation

Users can create habits with: - name - frequency (daily / weekly /
custom) - reminder time - category

Example: - Read 10 minutes - Drink water - Walk 10 minutes

------------------------------------------------------------------------

## 2. Habit Tracking

Users mark habits as completed each day.

Features: - checkbox completion - streak counter - daily progress bar -
completion calendar

------------------------------------------------------------------------

## 3. Daily Dashboard

Home screen should show today's habits.

Example:

Today's Progress: 60%

\[ \] Read 2 pages \[ \] Drink water \[ \] Walk 10 minutes

Streak: 8 days

Goal: user completes habits in under 30 seconds.

------------------------------------------------------------------------

# Identity-Based Habit System

During onboarding ask:

Who do you want to become?

Examples: - a reader - a healthy person - a calm person - a productive
person

Then automatically suggest habits.

Example:

Identity: Become a reader

Suggested habits: - Read 2 pages - Carry a book - Read before bed

------------------------------------------------------------------------

# The 4 Laws of Behavior Change

The app should implement these principles.

## 1. Make It Obvious

Features: - reminders - morning habit list - visual cues - habit
stacking suggestions

Habit stacking formula:

After I \[existing habit\] I will \[new habit\]

Example:

After I make coffee I will write 1 sentence in my journal

------------------------------------------------------------------------

## 2. Make It Attractive

Gamification elements: - XP points - badges - achievements - streak
rewards

Example badges: - 7 day streak - 30 day streak - 100 habits completed

------------------------------------------------------------------------

## 3. Make It Easy

Support "2-minute habits".

Example:

Habit: Run 5km Tiny version: Put on running shoes

Examples of tiny habits: - read 1 page - meditate 1 minute - do 1
push-up

------------------------------------------------------------------------

## 4. Make It Satisfying

Immediate rewards after completion.

Ideas: - confetti animation - sound feedback - streak update - progress
meter

------------------------------------------------------------------------

# Advanced Features

## Habit Streaks

Track: - current streak - longest streak

------------------------------------------------------------------------

## Habit Heatmap

Visual calendar similar to GitHub contributions.

Shows consistency across days.

------------------------------------------------------------------------

## Habit Score

Daily progress percentage.

Example:

Today's progress: 72%

Completed: ✓ Drink water ✓ Read ✗ Workout

------------------------------------------------------------------------

## Habit Levels

Allow gradual progression.

Example:

Meditation

Level 1 -- 1 minute Level 2 -- 3 minutes Level 3 -- 5 minutes Level 4 --
10 minutes

Users unlock next level after consistency.

------------------------------------------------------------------------

# Anti-Failure Design

Implement "Never Miss Twice".

If a user misses a day show:

"You missed yesterday. That's okay. Rule: Never miss twice. Start again
today."

Goal: prevent users from quitting.

------------------------------------------------------------------------

# Environment Design Coaching

Suggest environmental changes.

Examples:

Want to read more? - put a book on your pillow - remove social media
from home screen - keep a book in your bag

Goal: make habits easier through environment design.

------------------------------------------------------------------------

# Weekly Reflection System

Once per week prompt reflection.

Questions: - which habit worked best? - which habit was hardest? - what
will you adjust next week?

Metrics: - habits completed - consistency percentage

------------------------------------------------------------------------

# Notification Strategy

Helpful reminders, not annoying ones.

Examples:

"Your reading habit takes 2 minutes." "Don't break your 9-day streak."
"Tiny progress today matters."

------------------------------------------------------------------------

# Potential AI Coach Feature

Use AI to analyze behavior.

Examples:

If user misses habit repeatedly:

"Your workout habit may be too difficult. Try the 2-minute version."

AI suggestions: - adjust habit difficulty - recommend habit stacking -
suggest environment changes

------------------------------------------------------------------------

# Suggested App Structure

## Home Screen

Daily habits list progress bar streak counter

## Habit Detail Screen

habit description identity connection streak history tiny version option

## Insights Screen

completion rate best habits hardest habits

## Weekly Review Screen

habit analytics reflection questions

------------------------------------------------------------------------

# UX Principles

The app must be:

-   extremely fast
-   minimal friction
-   visually motivating
-   simple to use daily

User should complete daily habits within 30 seconds.

------------------------------------------------------------------------

# Future Expansion Ideas

-   habit accountability partners
-   group challenges
-   AI coaching
-   habit difficulty adjustment
-   habit recommendations
-   behavioral analytics

------------------------------------------------------------------------

# Goal for LLM

Use this specification to:

-   improve product design
-   suggest UX improvements
-   generate iOS SwiftUI components
-   optimize habit engagement
-   recommend retention mechanics
