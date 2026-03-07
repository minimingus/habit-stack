# Dark UI + Guided Scorecard Onboarding — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Force the app into a bold dark aesthetic and add a guided time-of-day onboarding flow that helps users map their real daily behaviors before rating them in the scorecard.

**Architecture:** Two independent tracks. Track A (dark UI) touches the asset catalog + one line in HabitStackApp + a mechanical `Color.white`→`Color("CardBackground")` sweep across 15 view files. Track B (guided onboarding) adds one new SwiftUI file (`ScorecardOnboardingView`) and modifies `OnboardingContainerView` to route through it. No schema changes, no new models.

**Tech Stack:** SwiftUI, Asset Catalog (colorset JSON), existing `ScorecardEntry` UserDefaults persistence.

---

## Existing color asset state

Stone100 and Stone950 already have dark variants in the catalog. The others do not yet.

---

## Task 1: Add dark variants to existing color assets

**Files:**
- Modify: `HabitStack/Assets.xcassets/Colors/Stone500.colorset/Contents.json`
- Modify: `HabitStack/Assets.xcassets/Colors/TealLight.colorset/Contents.json`
- Modify: `HabitStack/Assets.xcassets/Colors/Teal.colorset/Contents.json`

**Step 1: Update Stone500** — add a dark appearance entry (#9CA3AF — warm readable gray on dark)

Replace the entire file with:
```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "0.424", "green" : "0.443", "red" : "0.471" }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [{ "appearance" : "luminosity", "value" : "dark" }],
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "0.686", "green" : "0.639", "red" : "0.612" }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

**Step 2: Update TealLight** — dark variant is #0D4A45 (deep teal, subtle on dark)

Replace the entire file with:
```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "0.945", "green" : "0.984", "red" : "0.800" }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [{ "appearance" : "luminosity", "value" : "dark" }],
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "0.271", "green" : "0.290", "red" : "0.051" }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

**Step 3: Update Teal** — dark variant is #14B8A6 (brighter cyan-teal, pops on dark)

Replace the entire file with:
```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "0.533", "green" : "0.580", "red" : "0.051" }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [{ "appearance" : "luminosity", "value" : "dark" }],
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "0.651", "green" : "0.722", "red" : "0.078" }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

---

## Task 2: Add new color assets (AppBackground, CardBackground)

**Files:**
- Create: `HabitStack/Assets.xcassets/Colors/AppBackground.colorset/Contents.json`
- Create: `HabitStack/Assets.xcassets/Colors/CardBackground.colorset/Contents.json`

**Step 1: Create AppBackground** — light=#FFFFFF, dark=#0C0C0C (near-black page background)

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "1.000", "green" : "1.000", "red" : "1.000" }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [{ "appearance" : "luminosity", "value" : "dark" }],
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "0.047", "green" : "0.047", "red" : "0.047" }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

**Step 2: Create CardBackground** — light=#FFFFFF, dark=#1C1C1E (iOS system grouped background dark)

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "1.000", "green" : "1.000", "red" : "1.000" }
      },
      "idiom" : "universal"
    },
    {
      "appearances" : [{ "appearance" : "luminosity", "value" : "dark" }],
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "0.118", "green" : "0.110", "red" : "0.110" }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

---

## Task 3: Force dark mode at the app root

**Files:**
- Modify: `HabitStack/HabitStackApp.swift`

**Step 1:** Add `.preferredColorScheme(.dark)` to the `WindowGroup`:

```swift
var body: some Scene {
    WindowGroup {
        RootView()
            .environment(rootViewModel)
            .preferredColorScheme(.dark)
            .onAppear {
                RevenueCatManager.shared.configure()
                PostHogSDK.shared.setup(
                    PostHogConfig(apiKey: Secrets.postHogAPIKey)
                )
            }
    }
}
```

---

## Task 4: Global Color.white → Color("CardBackground") sweep

**Files (all modifications):**
- `HabitStack/Views/FourLaws/HabitsScorecardView.swift`
- `HabitStack/Views/FourLaws/FourLawsView.swift`
- `HabitStack/Views/Today/HabitCardView.swift`
- `HabitStack/Views/Today/DailyInsightCard.swift`
- `HabitStack/Views/Today/HabitDetailView.swift`
- `HabitStack/Views/Today/MilestoneCelebrationView.swift`
- `HabitStack/Views/Analytics/AnalyticsView.swift`
- `HabitStack/Views/Analytics/StreakBarView.swift`
- `HabitStack/Views/Coach/CoachView.swift`
- `HabitStack/Views/Coach/CoachMessageView.swift`
- `HabitStack/Views/HabitWizard/WizardStepCueView.swift`
- `HabitStack/Views/HabitWizard/HabitTemplateLibraryView.swift`
- `HabitStack/Views/Onboarding/IdentityStatementView.swift`
- `HabitStack/Views/Reflection/WeeklyReflectionView.swift`
- `HabitStack/Views/Components/SkeletonView.swift`

**Rule:** Replace every `Color.white` (used as a card/surface background) with `Color("CardBackground")`.

**Exception — do NOT replace** `Color.white` when it is used as a foreground text/icon color (e.g. `.foregroundStyle(.white)` on a teal button). Only replace it when it appears as `.background(Color.white)`, `.fill(Color.white)`, or similar surface usage.

**Step 1:** For each file, read it, identify `Color.white` background usages, replace with `Color("CardBackground")`. Do this file-by-file.

**Key replacements by file:**

`HabitsScorecardView.swift`:
- `.background(Color.white)` on entry list VStack → `Color("CardBackground")`

`FourLawsView.swift`:
- `.background(Color.white)` on law cards and identity hero card → `Color("CardBackground")`

`HabitCardView.swift`:
- `Color.white` in the card background (the `habitWithStatus.isCompleted ? accentColor.opacity(0.07) : Color.white` ternary) → `Color("CardBackground")`
- Remove shadow (`.shadow(...)` line) — shadows are invisible on dark; replace with a subtle border:
  ```swift
  .overlay(
      RoundedRectangle(cornerRadius: 16)
          .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.5)
  )
  ```

`CoachMessageView.swift`:
- Coach bubble background `Color.white` → `Color("CardBackground")`

`DailyInsightCard.swift`:
- Card background `Color.white` → `Color("CardBackground")`

All others: apply same rule — `Color.white` as surface → `Color("CardBackground")`.

---

## Task 5: Global background sweep (Stone100 → AppBackground)

**Files with `.ignoresSafeArea()` or page-level backgrounds:**
- `HabitStack/Views/FourLaws/HabitsScorecardView.swift`
- `HabitStack/Views/FourLaws/FourLawsView.swift`
- `HabitStack/Views/Today/HabitDetailView.swift`
- `HabitStack/Views/Today/CompletionNoteSheet.swift`
- `HabitStack/Views/Today/HabitTimerView.swift`
- `HabitStack/Views/Today/MilestoneCelebrationView.swift`
- `HabitStack/Views/Analytics/AnalyticsView.swift`
- `HabitStack/Views/HabitWizard/HabitTemplateLibraryView.swift`

**Rule:** Replace `Color("Stone100").ignoresSafeArea()` with `Color("AppBackground").ignoresSafeArea()`.

Also check `TodayView.swift` and `CoachView.swift` for any `listStyle(.plain)` or `List` background — in SwiftUI a plain `List` on dark mode shows the system dark background automatically, but if the List uses `background(Color("Stone100"))` it should become `Color("AppBackground")`.

---

## Task 6: Auth + Onboarding screens polish

**Files:**
- `HabitStack/Views/Auth/AuthView.swift`
- `HabitStack/Views/Auth/SignUpView.swift`
- `HabitStack/Views/Onboarding/WelcomeView.swift`
- `HabitStack/Views/Onboarding/NotificationPermissionView.swift`

These screens don't set an explicit background (so they inherit the window background). With `.preferredColorScheme(.dark)` at the root they'll already be dark. However, they use `Color("Stone100")` for text field backgrounds — those will correctly use the dark variant. No code changes needed unless there are hardcoded `Color.white` issues found during review.

**Step 1:** Read each file. If any hardcoded `Color.white` surface usage exists, replace with `Color("CardBackground")`. If clean, no change.

---

## Task 7: Create ScorecardOnboardingView

**Files:**
- Create: `HabitStack/Views/Onboarding/ScorecardOnboardingView.swift`

This is the guided time-of-day flow. It manages its own internal step state and writes collected behaviors to `ScorecardEntry` (UserDefaults) when done, then shows the rating screen inline.

```swift
import SwiftUI

struct ScorecardOnboardingView: View {
    let onContinue: () -> Void

    private enum Step: Int, CaseIterable {
        case intro, morning, afternoon, evening, night, rate
    }

    private struct Period {
        let step: Step
        let emoji: String
        let title: String
        let prompt: String
        let suggestions: [String]
    }

    private let periods: [Period] = [
        Period(step: .morning, emoji: "☀️", title: "Morning",
               prompt: "What do you actually do before noon?",
               suggestions: ["Snooze alarm", "Check phone in bed", "Brush teeth", "Coffee",
                             "Breakfast", "Exercise", "Meditate", "Shower", "Scroll social media"]),
        Period(step: .afternoon, emoji: "🌤", title: "Afternoon",
               prompt: "What do you actually do after lunch?",
               suggestions: ["Check phone", "Lunch", "Work / study", "Scroll social media",
                             "Coffee / snack", "Walk", "Watch YouTube", "Nap"]),
        Period(step: .evening, emoji: "🌆", title: "Evening",
               prompt: "What do you do in the evening?",
               suggestions: ["Dinner", "Watch TV / Netflix", "Scroll social media", "Read",
                             "Drink alcohol", "Exercise", "Call family", "Journal"]),
        Period(step: .night, emoji: "🌙", title: "Night",
               prompt: "How do you wind down?",
               suggestions: ["Check phone in bed", "Late-night snack", "Gaming",
                             "Read before sleep", "Skincare", "Take vitamins"]),
    ]

    @State private var currentStep: Step = .intro
    @State private var selected: Set<String> = []
    @State private var customText: String = ""
    @FocusState private var fieldFocused: Bool

    private var stepIndex: Int { currentStep.rawValue }
    // Progress: intro=0, morning=1..4, rate excluded from bar
    private var progressFraction: Double {
        guard currentStep != .intro && currentStep != .rate else { return 0 }
        return Double(stepIndex) / 4.0
    }

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()

            switch currentStep {
            case .intro:
                introView
                    .transition(.opacity)
            case .rate:
                HabitsScorecardView(onContinue: onContinue)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            default:
                if let period = periods.first(where: { $0.step == currentStep }) {
                    periodView(period)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }

    // MARK: - Intro

    private var introView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                Text("📋")
                    .font(.system(size: 64))

                VStack(spacing: 12) {
                    Text("What does your day\nactually look like?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("Stone950"))
                        .multilineTextAlignment(.center)

                    Text("Most habits are invisible. Before building new ones,\nlet's see what you actually do each day.")
                        .font(.subheadline)
                        .foregroundStyle(Color("Stone500"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                withAnimation { currentStep = .morning }
            } label: {
                Text("Map My Day →")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Teal"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Period step

    private func periodView(_ period: Period) -> some View {
        VStack(spacing: 0) {
            // Progress bar
            progressBar
                .padding(.horizontal, 24)
                .padding(.top, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(period.emoji)
                            .font(.system(size: 44))
                        Text(period.title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color("Stone950"))
                        Text(period.prompt)
                            .font(.subheadline)
                            .foregroundStyle(Color("Stone500"))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Chip grid
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 130), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(period.suggestions, id: \.self) { suggestion in
                            let isOn = selected.contains(suggestion)
                            Button {
                                withAnimation(.spring(duration: 0.2)) {
                                    if isOn { selected.remove(suggestion) }
                                    else { selected.insert(suggestion) }
                                }
                                HapticManager.impact(.light)
                            } label: {
                                Text(suggestion)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity)
                                    .background(isOn ? Color("Teal") : Color("Stone100"))
                                    .foregroundStyle(isOn ? .white : Color("Stone950"))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .strokeBorder(isOn ? Color.clear : Color.white.opacity(0.06), lineWidth: 0.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Custom add field
                    HStack(spacing: 10) {
                        TextField("Add your own…", text: $customText)
                            .focused($fieldFocused)
                            .submitLabel(.done)
                            .onSubmit { addCustom() }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color("Stone100"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Button(action: addCustom) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    customText.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? Color("Stone500").opacity(0.4) : Color("Teal")
                                )
                        }
                        .disabled(customText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 100)
                }
            }

            // Bottom bar
            HStack {
                Button("Skip") { advance() }
                    .foregroundStyle(Color("Stone500"))

                Spacer()

                Button {
                    advance()
                } label: {
                    Text(currentStep == .night ? "Done →" : "Next →")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Color("Teal"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .padding(.top, 12)
            .background(.regularMaterial)
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color("Stone100"))
                    .frame(height: 4)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color("Teal"))
                    .frame(width: geo.size.width * progressFraction, height: 4)
                    .animation(.spring(duration: 0.4), value: progressFraction)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Helpers

    private func advance() {
        fieldFocused = false
        addCustom() // flush any pending text
        if currentStep == .night {
            commitEntries()
            withAnimation { currentStep = .rate }
        } else {
            withAnimation {
                currentStep = Step(rawValue: currentStep.rawValue + 1) ?? .rate
            }
        }
    }

    private func addCustom() {
        let trimmed = customText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        selected.insert(trimmed)
        customText = ""
        HapticManager.impact(.light)
    }

    private func commitEntries() {
        guard !selected.isEmpty else { return }
        var existing = ScorecardEntry.load()
        let existingBehaviors = Set(existing.map { $0.behavior })
        let newEntries = selected
            .filter { !existingBehaviors.contains($0) }
            .map { ScorecardEntry(id: UUID(), behavior: $0, rating: nil) }
        existing = newEntries + existing
        ScorecardEntry.save(existing)
    }
}
```

---

## Task 8: Wire ScorecardOnboardingView into OnboardingContainerView

**Files:**
- Modify: `HabitStack/Views/Onboarding/OnboardingContainerView.swift`

**Step 1:** Remove the `.habitScorecard` step from `OnboardingViewModel`. Replace it with routing through `ScorecardOnboardingView`, which handles the scorecard internally.

The `OnboardingViewModel.Step` enum currently has:
```swift
case welcome, habitScorecard, identityStatement, notificationPermission, complete
```

Change the body's `case .habitScorecard:` from:
```swift
HabitsScorecardView(onContinue: { viewModel.advance() })
```
to:
```swift
ScorecardOnboardingView(onContinue: { viewModel.advance() })
```

That's the only change. `ScorecardOnboardingView` now owns the guided collection + rating screen, and calls `onContinue` at the very end.

---

## Task 9: Add XcodeGen entry for new file (if needed)

**Files:**
- Check: `project.yml`

If `project.yml` exists and controls file inclusion (XcodeGen-based project), the new `ScorecardOnboardingView.swift` file must be discoverable. Most XcodeGen configs use a glob pattern like `HabitStack/**/*.swift` which picks up new files automatically. Verify this is the case — if the pattern covers the Onboarding directory, no action is needed.

Run `grep -r "Onboarding" project.yml` to confirm. If the glob covers it, skip. If explicit file lists are used, add the new file path.

---

## Verification

After all tasks:

1. **Launch app** — UI is dark immediately, no light flash
2. **Auth screen** — dark background, teal accents pop
3. **Onboarding** → Welcome → tap "Get Started" → guided intro appears ("What does your day actually look like?")
4. **Tap "Map My Day →"** → Morning step appears, chips visible (dark background, teal when selected)
5. **Tap several chips** → they highlight teal, progress bar advances
6. **Type custom behavior** → appears selected, clears field on submit
7. **Tap "Next →"** through Afternoon/Evening/Night → progress bar fills
8. **Tap "Done →"** on Night → scorecard appears pre-populated with selected behaviors, no spinner (all local)
9. **Rate behaviors** → red/teal strips appear, "Replace it" on negatives
10. **Tap "Continue →"** → IdentityStatement screen
11. **Today view** — dark, habit cards use CardBackground (#1C1C1E) instead of white
12. **Habit card shadows** replaced by subtle border
13. **Identity tab** — dark background, law cards use CardBackground
14. **Coach tab** — coach bubbles use CardBackground
15. **Kill app, reopen** — dark stays (not system-dependent, forced)

---

## Notes

- `ScorecardEntry` model at `HabitStack/Models/ScorecardEntry.swift` — no changes.
- Chips that were selected remain selected if user taps "Previous" (state is `Set<String>`, never cleared between steps).
- Users who already completed onboarding will NOT see the guided flow on next open (the `onboardingComplete` UserDefaults flag is already set). This is correct — the guided flow is for first-time users only.
- If a behavior was added in the guided flow and is also one of the 15 suggestion chips in the main scorecard, it will appear grayed-out (already added) in the standalone scorecard. This is correct behavior.
