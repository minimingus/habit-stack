# Habit App LLM Enhancement & Habit Library Guide

## Purpose

This document is designed to be provided to a Large Language Model (LLM)
so it can analyze and improve an existing habit-building iOS application
inspired by Atomic Habits.

The goal is incremental enhancement, not rewriting the app.

The LLM should audit the app, determine what is already implemented, and
propose safe improvements.

------------------------------------------------------------------------

# LLM ENHANCEMENT INSTRUCTIONS

The application already exists.

Your role:

• Audit existing systems\
• Identify missing behavioral principles\
• Suggest small improvements\
• Avoid breaking existing functionality

Rules:

1.  Do NOT rewrite working systems.
2.  Determine if each feature already exists.
3.  If a feature exists → evaluate and suggest improvements only.
4.  If a feature partially exists → propose incremental enhancements.
5.  If a feature does not exist → suggest minimal additions.
6.  Avoid architectural rewrites.

Priorities:

1.  Improve habit adherence
2.  Improve retention
3.  Improve usability
4.  Maintain simplicity
5.  Preserve existing workflows

------------------------------------------------------------------------

# Core Habit Psychology Model

Behavior loop used in the app:

Cue → Craving → Response → Reward

Primary focus:

Identity-based behavior change

Users should feel:

"I am becoming the type of person who does this habit."

------------------------------------------------------------------------

# Product Goals

Primary Goal Help users build consistent positive habits.

Secondary Goals

• Increase habit completion rate\
• Increase streak length\
• Improve retention\
• Reduce daily friction

Success Metrics

• Daily active users • Habit completion rate • Average streak length •
30‑day retention • Weekly habit consistency

------------------------------------------------------------------------

# Feature Audit Framework

For every system evaluate:

Step 1 --- Detect\
Does the feature exist?

Step 2 --- Evaluate\
Assess usability and effectiveness.

Step 3 --- Improve\
Suggest small improvements.

Step 4 --- Integrate\
If missing, propose minimal additions.

------------------------------------------------------------------------

# Core Habit Tracking Audit

Check whether the app supports:

• habit creation • habit editing • daily completion tracking • reminders
• streak tracking • completion history

Evaluate:

• How many taps to complete a habit? • Is progress visible? • Is
completion satisfying?

------------------------------------------------------------------------

# Daily Dashboard Audit

The home screen should allow users to complete habits quickly.

Ideal principle:

Daily check-in \< 30 seconds.

Evaluate:

• clarity of today's habits • progress visibility • streak visibility •
speed of completion

------------------------------------------------------------------------

# Identity-Based Habit System

Evaluate whether habits connect to identity.

Examples:

• Become a reader\
• Become a healthy person\
• Become calm\
• Become productive

If missing:

Suggest identity prompts during onboarding.

------------------------------------------------------------------------

# Behavioral Principle Audit

Evaluate whether the following principles are implemented.

## Make It Obvious

Check for:

• reminders • cues • habit stacking • visible habit list

Enhancements:

• smarter reminders • contextual cues

------------------------------------------------------------------------

## Make It Attractive

Check for:

• streak rewards • achievements • progress visualization

Enhancements:

• milestone celebrations • badges • visual progress feedback

------------------------------------------------------------------------

## Make It Easy

Check for:

• simple completion interaction • tiny habit versions

Enhancements:

• 2‑minute habit mode • simplified UI

------------------------------------------------------------------------

## Make It Satisfying

Check for:

• completion feedback • streak updates • visual rewards

Enhancements:

• confetti animation • progress score

------------------------------------------------------------------------

# Retention System Audit

Check for:

• streak tracking • milestone rewards • encouragement after missed days
• progress insights

Enhancements:

• comeback prompts • streak recovery encouragement

------------------------------------------------------------------------

# Anti‑Failure Design

Rule:

Never miss twice.

If a user misses a day, encourage immediate restart.

Possible improvements:

• supportive notifications • restart prompts

------------------------------------------------------------------------

# Habit Heatmap

Evaluate whether a calendar visualization exists.

Benefits:

• visual consistency • motivational streaks

Enhancements:

• monthly heatmap • weekly summary

------------------------------------------------------------------------

# Weekly Reflection

Evaluate whether users reflect on progress.

Example prompts:

• What habit worked best this week? • What habit was hardest? • What
should change next week?

------------------------------------------------------------------------

# AI Coaching Opportunities

If analytics exist, AI can suggest:

• reducing difficulty of failing habits • habit stacking opportunities •
improving reminder timing

All AI coaching must be optional and non‑intrusive.

------------------------------------------------------------------------

# UX Friction Audit

Evaluate:

• taps required to complete a habit • taps required to create a habit •
time required for daily use

Goal:

Minimal friction.

------------------------------------------------------------------------

# Habit Template Structure

Habit templates should use a consistent format.

{ "title": "","category": "","identity": "","frequency":
"","tinyVersion": "","cue": "","difficulty": "" }

------------------------------------------------------------------------

# Example Habit Library

## Health

Drink a glass of water\
Tiny version: take one sip\
Cue: after waking up

Walk 10 minutes\
Tiny version: put on walking shoes\
Cue: after lunch

Stretch for 5 minutes\
Tiny version: one stretch\
Cue: after waking

Exercise 30 minutes\
Tiny version: put on workout clothes\
Cue: after waking

Sleep before 11 PM\
Tiny version: turn off lights\
Cue: after brushing teeth

------------------------------------------------------------------------

## Mind & Mental Health

Meditate 5 minutes\
Tiny version: 3 deep breaths\
Cue: after sitting at desk

Practice gratitude\
Tiny version: think of one good thing\
Cue: before sleep

Journal 5 minutes\
Tiny version: write one sentence\
Cue: after brushing teeth

Take mindful break\
Tiny version: close eyes 10 seconds\
Cue: after finishing a task

Step outside for fresh air\
Tiny version: open window\
Cue: after lunch

------------------------------------------------------------------------

## Learning

Read 10 minutes\
Tiny version: read one page\
Cue: after dinner

Learn a new word\
Tiny version: read one word\
Cue: after unlocking phone

Study 15 minutes\
Tiny version: study 2 minutes\
Cue: after breakfast

Listen to a podcast\
Tiny version: listen 2 minutes\
Cue: during commute

Practice a skill\
Tiny version: practice 2 minutes\
Cue: after work

------------------------------------------------------------------------

## Productivity

Plan the day\
Tiny version: write one task\
Cue: after opening laptop

Deep work session\
Tiny version: work 2 minutes\
Cue: after planning day

Clean workspace\
Tiny version: move one item\
Cue: after work

Review goals\
Tiny version: read goals\
Cue: morning routine

Prepare tomorrow tasks\
Tiny version: write one task\
Cue: before sleep

------------------------------------------------------------------------

## Relationships

Send a message to a friend\
Tiny version: short text\
Cue: after lunch

Express gratitude\
Tiny version: say thank you\
Cue: after interaction

Call family member\
Tiny version: voice message\
Cue: Sunday afternoon

Give a compliment\
Tiny version: one kind word\
Cue: meeting someone

Ask someone about their day\
Tiny version: ask one question\
Cue: after dinner

------------------------------------------------------------------------

# Starter Habit Packs

Better Mornings • Drink water • Stretch • Plan the day

Calm Mind • Meditate • Gratitude • Journal

Learning • Read • Learn a new word • Listen to a podcast

------------------------------------------------------------------------

# LLM Output Expectations

When analyzing the app the LLM should produce:

1.  Feature audit
2.  UX friction analysis
3.  Behavioral principle coverage
4.  Retention improvement ideas
5.  Safe enhancement suggestions

Avoid recommending full rewrites.

Focus on incremental improvements that strengthen habit formation.
