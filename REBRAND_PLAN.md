# Better You - Rebranding Plan

## Overview
Shift from Atomic Habits methodology to personal improvement focus.
Avoid copyright issues while keeping core habit-building principles.

## Terminology Changes

### Core Concepts

| Old (Atomic Habits) | New (Better You) | Context |
|---------------------|------------------|---------|
| Identity | Who do you want to become? | Onboarding question |
| Atomic Habits | Small daily improvements | Philosophy |
| Habit Stack | Better You | App name |
| Build new habits | Choose 3 habits you'd like to adopt | New habits flow |
| Break bad habits | Choose habits you'd like to change | Habit replacement |
| Habit tracking | Progress tracking | General term |
| Scorecard | Daily review / Self-assessment | Review screen |
| Cue/Craving/Response/Reward | Keep as-is (scientific) | Internal only |
| 1% better | Small steps forward | Messaging |

### UI/UX Language Shifts

#### Onboarding
- ❌ "Who do you want to be?"
- ✅ "Who do you want to become?"

#### New Habits
- ❌ "Add a new habit"
- ✅ "Choose a habit you'd like to adopt"
- ❌ "Build 3 atomic habits"
- ✅ "Start with 3 small habits"

#### Habit Replacement
- ❌ "Bad habits to break"
- ✅ "Habits you'd like to change"
- ❌ "Quit smoking"
- ✅ "Replace smoking with..." (suggest alternative)

#### Progress/Analytics
- ❌ "Habit scorecard"
- ✅ "Your progress" / "Daily review"
- Keep: streaks, completion rate (neutral terms)

#### Coach/Guidance
- ❌ "Based on Atomic Habits"
- ✅ "Based on habit science" / "Proven strategies"
- Focus: personal growth, self-improvement

---

## Implementation Phases

### Phase 1: Core Text Changes (Low Risk)
**Focus:** Hardcoded strings, marketing copy

Issues to create:
1. Update onboarding flow text
2. Update habit creation wizard text
3. Update analytics/review screen labels
4. Update coach messages and tips
5. Update app description and marketing copy

### Phase 2: Data Model Updates (Medium Risk)
**Focus:** Model field names, enum values (if user-visible)

Issues:
6. Rename user-facing model fields (if any)
7. Update placeholder text in forms
8. Review and update any stored user-facing strings

### Phase 3: Visual/Conceptual Redesign (High Risk)
**Focus:** Screen flow, information architecture

Issues:
9. Redesign onboarding to emphasize "becoming"
10. Update habit wizard to focus on "adoption" vs "building"
11. Refactor "scorecard" screen to "progress review"

---

## Symphony Task Breakdown

### Issue Template Structure
Each issue should:
- Be self-contained (one screen or one flow)
- Include before/after examples
- List all strings to change
- Note any edge cases (plurals, etc.)

### Suggested Issues

#### Issue #1: Onboarding Identity Question
**Title:** Update onboarding identity question to "Who do you want to become?"

**Description:**
Change the main onboarding question from current wording to focus on personal growth.

**Files likely affected:**
- Onboarding view
- Any related copy

**Before:**
"Who do you want to be?" or similar

**After:**
"Who do you want to become?"

**Success criteria:**
- Question flows naturally
- Placeholder/hint text updated
- Any related help text updated

---

#### Issue #2: New Habit Creation - Language Shift
**Title:** Update new habit flow to use "adopt" language

**Description:**
Shift from "build/add habits" to "choose habits to adopt"

**Changes:**
- Button: "Add Habit" → "Adopt a Habit"
- Header: "Build a New Habit" → "Choose a Habit to Adopt"
- Prompt: "What habit do you want to build?" → "What habit would you like to adopt?"
- Limit text: "Build 3 habits to start" → "Start with 3 habits"

**Files likely affected:**
- Habit wizard view
- Habit creation form
- Templates/suggestions screen

---

#### Issue #3: Habit Replacement Flow
**Title:** Reframe "bad habits" as "habits to change"

**Description:**
Remove negative framing around habit replacement

**Changes:**
- Section title: "Bad Habits" → "Habits to Change"
- Prompt: "Which bad habit do you want to quit?" → "Which habit would you like to change?"
- Suggestion flow: Instead of "quit X", suggest "replace X with Y"

**Files likely affected:**
- Habit wizard
- Habit list/categories
- Coach suggestions

---

#### Issue #4: Analytics/Review Screen Rebranding
**Title:** Rename "Scorecard" to "Daily Review" or "Progress"

**Description:**
Remove Atomic Habits-specific terminology from review screen

**Changes:**
- Screen title: "Scorecard" → "Your Progress" or "Daily Review"
- Navigation label: same
- Any references in help text or tips

**Files likely affected:**
- Analytics view
- Tab bar / navigation
- Coach tips referencing scorecard

---

#### Issue #5: Coach Messages - Remove "Atomic Habits" References
**Title:** Update coach messages to use neutral habit science language

**Description:**
Replace any direct references to "Atomic Habits" with generic habit science terms

**Changes:**
- "Based on Atomic Habits" → "Based on habit science"
- "James Clear says..." → Remove or generalize
- "1% better every day" → "Small steps forward" or "Daily progress"

**Files likely affected:**
- CoachViewModel
- Tips database / hardcoded tips
- Onboarding coach messages

---

#### Issue #6: App Name & Display Name
**Title:** Update all references from "Habit Stack" to "Better You"

**Description:**
Final rebranding - update app name throughout

**Changes:**
- App display name (Info.plist) - already done in PR #7
- References in text (e.g., "Welcome to Habit Stack")
- About screen
- Settings
- Any hardcoded app name strings

**Files likely affected:**
- About view
- Settings
- Welcome/onboarding
- Info.plist (already updated)

---

#### Issue #7: Widget Rebranding
**Title:** Update widget display name and messaging

**Description:**
Ensure widget aligns with Better You branding

**Changes:**
- Widget display name (done in PR #7)
- Widget preview text
- Widget content labels

**Files likely affected:**
- Widget Info.plist (done)
- Widget view
- Widget timeline provider

---

## Conservative Approach for Symphony

Since Claude Code can't test Swift builds, we should:

1. **One screen/flow per issue** - easier to review
2. **Provide exact before/after strings** - less ambiguity
3. **Mark as "needs Xcode verification"** - you'll test each PR
4. **No data model changes via Symphony** - too risky without build testing
5. **Keep issues small** - 5-10 string changes max per issue

---

## Suggested Order

1. Issue #6 (App name - build on PR #7)
2. Issue #1 (Onboarding identity)
3. Issue #2 (New habit language)
4. Issue #3 (Habit replacement)
5. Issue #5 (Coach messages)
6. Issue #4 (Analytics screen)
7. Issue #7 (Widget)

---

## Next Steps

1. Review this plan
2. Adjust terminology as needed
3. I'll create the GitHub issues
4. Symphony will tackle them one by one
5. You review + merge each PR in Xcode

---

**Estimated effort:**
- 7 issues × ~2 min each = ~15 minutes Symphony time
- ~$5-7 in API costs
- Your review time: 10-15 min per PR = ~2 hours total

Want me to proceed with creating the issues?
