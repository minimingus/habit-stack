# Better You - Complete Implementation Roadmap

## Vision
Transform Habit Stack into Better You with focus on:
- Future self identity
- Consistency over motivation
- Swipe-based habit adoption
- Incremental progress

---

## Phase 1: Foundation & Rebranding ✅ (Symphony)
**Goal:** Update copy, remove Atomic Habits references, set Better You tone

### Issues 1-7: Text & Copy Changes
These are safe for Symphony (text-only, no UI changes)

---

## Phase 2: Core Experience Redesign 🎨 (Mixed)
**Goal:** New onboarding, swipe UI, contextual suggestions

### Part A: Data Model & Logic (Manual/Careful)

#### Issue #8: Add "Future Self" Identity Model
**Type:** Manual (requires Swift coding)

**Description:**
Add new data model for storing user's selected identities

**Implementation:**
```swift
// New model: FutureSelf.swift
struct FutureSelf: Codable, Identifiable {
    let id: UUID
    let traits: [IdentityTrait]
    let createdAt: Date
}

enum IdentityTrait: String, Codable, CaseIterable {
    case stronger = "💪 Stronger"
    case focused = "🧠 Focused"
    case energetic = "⚡ Energetic"
    case calmer = "😌 Calmer"
    case disciplined = "🎯 Disciplined"
    case confident = "🌟 Confident"
    case healthier = "🏃 Healthier"
    case productive = "💼 Productive"
}
```

**Files:**
- Create: `HabitStack/Models/FutureSelf.swift`
- Update: `HabitStack/Models/Profile.swift` (add futureSelf property)
- Update: Database schema (if using Supabase)

**Test criteria:**
- [ ] Model compiles
- [ ] Can save/load from profile
- [ ] Migrations work (if needed)

**Symphony:** ❌ No - requires new Swift files + Xcode project changes

---

#### Issue #9: Habit Template Library with Trait Mapping
**Type:** Data + Logic (Mostly manual, Symphony can help with JSON)

**Description:**
Create habit template library mapped to identity traits

**Implementation:**
```swift
// New file: HabitTemplateLibrary.swift
struct HabitTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let emoji: String
    let description: String
    let suggestedDuration: Int // minutes
    let category: HabitCategory
    let identityTraits: [IdentityTrait] // which "future self" this supports
    let defaultTime: TimeOfDay
}

enum TimeOfDay: String, Codable {
    case morning, afternoon, evening, anytime
}

// Sample data
let habitTemplates: [HabitTemplate] = [
    HabitTemplate(
        name: "Morning Walk",
        emoji: "🏃",
        description: "Start your day strong",
        suggestedDuration: 15,
        category: .health,
        identityTraits: [.stronger, .energetic, .healthier],
        defaultTime: .morning
    ),
    HabitTemplate(
        name: "2-Minute Breathing",
        emoji: "🧘",
        description: "Clear your mind",
        suggestedDuration: 2,
        category: .mindfulness,
        identityTraits: [.focused, .calmer],
        defaultTime: .morning
    ),
    // ... more templates
]
```

**Files:**
- Create: `HabitStack/Models/HabitTemplate.swift`
- Create: `HabitStack/Data/HabitTemplateLibrary.swift`
- Create: `HabitStack/Data/habit-templates.json` (data file)

**Symphony:** 🟡 Partial
- ✅ Can create JSON data file with templates
- ❌ Cannot create Swift files or update Xcode project

**Approach:** You create the Swift structure, Symphony populates JSON data

---

### Part B: New Onboarding Flow (Manual)

#### Issue #10: Onboarding Screen 1 - "Imagine Your Future Self"
**Type:** Manual (new SwiftUI view)

**Description:**
Create animated intro screen with vision prompt

**Implementation:**
```swift
// New file: OnboardingVisionView.swift
struct OnboardingVisionView: View {
    @State private var showText = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated silhouette (use SF Symbols or Lottie)
            Image(systemName: "person.fill")
                .font(.system(size: 100))
                .foregroundColor(.blue)
                .scaleEffect(showText ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(), value: showText)
            
            VStack(spacing: 16) {
                Text("Imagine yourself 90 days from now...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("A better version of you.\nWhat's different?")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(showText ? 1 : 0)
            .animation(.easeIn(duration: 0.8).delay(0.5), value: showText)
            
            Spacer()
            
            Button("Continue") {
                // Navigate to next screen
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            showText = true
        }
    }
}
```

**Files:**
- Create: `HabitStack/Views/Onboarding/OnboardingVisionView.swift`

**Symphony:** ❌ No - SwiftUI code, needs Xcode

---

#### Issue #11: Onboarding Screen 2 - "Choose Your Future Self"
**Type:** Manual (new SwiftUI view)

**Description:**
Multi-select grid of identity traits

**Implementation:**
```swift
// New file: OnboardingIdentitySelectionView.swift
struct OnboardingIdentitySelectionView: View {
    @State private var selectedTraits: Set<IdentityTrait> = []
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Who do you want to become?")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Select all that resonate")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(IdentityTrait.allCases) { trait in
                    IdentityTraitCard(
                        trait: trait,
                        isSelected: selectedTraits.contains(trait)
                    ) {
                        toggleSelection(trait)
                    }
                }
            }
            
            Spacer()
            
            Button("Next") {
                // Save selected traits and navigate
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedTraits.isEmpty)
        }
        .padding()
    }
    
    func toggleSelection(_ trait: IdentityTrait) {
        if selectedTraits.contains(trait) {
            selectedTraits.remove(trait)
        } else {
            selectedTraits.insert(trait)
        }
    }
}

struct IdentityTraitCard: View {
    let trait: IdentityTrait
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(trait.emoji)
                    .font(.system(size: 40))
                
                Text(trait.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(height: 120)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
```

**Files:**
- Create: `HabitStack/Views/Onboarding/OnboardingIdentitySelectionView.swift`
- Create: `HabitStack/Views/Components/IdentityTraitCard.swift`

**Symphony:** ❌ No - SwiftUI code

---

#### Issue #12: Onboarding Screen 3 - "The Path Forward"
**Type:** Manual (simple SwiftUI view)

**Description:**
Transitional screen explaining the approach

**Implementation:**
```swift
// New file: OnboardingPhilosophyView.swift
struct OnboardingPhilosophyView: View {
    let selectedTraits: [IdentityTrait]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("To become \(traitsString),")
                    .font(.title2)
                + Text("\nsmall daily actions matter most.")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                Text("Let's build your routine,\none habit at a time.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    PrincipleRow(icon: "📊", text: "Consistency beats intensity")
                    PrincipleRow(icon: "🌱", text: "Small steps, big changes")
                }
            }
            
            Spacer()
            
            Button("Start Building") {
                // Navigate to habit swipe screen
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    var traitsString: String {
        selectedTraits.map { $0.displayName.lowercased() }
            .joined(separator: ", ")
    }
}

struct PrincipleRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title3)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
```

**Files:**
- Create: `HabitStack/Views/Onboarding/OnboardingPhilosophyView.swift`

**Symphony:** ❌ No - SwiftUI code

---

#### Issue #13: Swipeable Habit Card Component
**Type:** Manual (complex SwiftUI component)

**Description:**
Tinder-style swipeable card for habit adoption

**Implementation:**
```swift
// New file: SwipeableHabitCard.swift
struct SwipeableHabitCard: View {
    let template: HabitTemplate
    @State private var offset: CGSize = .zero
    @State private var isDragging = false
    
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    var body: some View {
        ZStack {
            // Card background with gradient based on swipe direction
            RoundedRectangle(cornerRadius: 16)
                .fill(cardColor)
                .shadow(radius: isDragging ? 8 : 4)
            
            VStack(spacing: 20) {
                Text(template.emoji)
                    .font(.system(size: 60))
                
                VStack(spacing: 8) {
                    Text(template.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(template.suggestedDuration) minutes · \(template.category.displayName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(template.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                HStack(spacing: 50) {
                    Label("Skip", systemImage: "xmark")
                        .foregroundColor(.red)
                    Label("Adopt", systemImage: "checkmark")
                        .foregroundColor(.green)
                }
                .font(.callout)
            }
            .padding(30)
        }
        .frame(width: 320, height: 450)
        .offset(offset)
        .rotationEffect(.degrees(Double(offset.width / 20)))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    isDragging = true
                    offset = gesture.translation
                }
                .onEnded { gesture in
                    isDragging = false
                    
                    if abs(offset.width) > 100 {
                        // Swipe completed
                        let direction: SwipeDirection = offset.width > 0 ? .right : .left
                        handleSwipe(direction)
                    } else {
                        // Snap back
                        withAnimation(.spring()) {
                            offset = .zero
                        }
                    }
                }
        )
    }
    
    var cardColor: LinearGradient {
        if offset.width > 50 {
            return LinearGradient(colors: [.green.opacity(0.3), .white], startPoint: .leading, endPoint: .trailing)
        } else if offset.width < -50 {
            return LinearGradient(colors: [.red.opacity(0.3), .white], startPoint: .trailing, endPoint: .leading)
        } else {
            return LinearGradient(colors: [.white], startPoint: .top, endPoint: .bottom)
        }
    }
    
    func handleSwipe(_ direction: SwipeDirection) {
        withAnimation(.easeOut(duration: 0.3)) {
            offset = CGSize(
                width: direction == .right ? 500 : -500,
                height: 0
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if direction == .right {
                onSwipeRight()
            } else {
                onSwipeLeft()
            }
            offset = .zero
        }
    }
}

enum SwipeDirection {
    case left, right
}
```

**Files:**
- Create: `HabitStack/Views/Components/SwipeableHabitCard.swift`

**Symphony:** ❌ No - Complex SwiftUI with gestures

---

#### Issue #14: Onboarding Screen 4 - "Swipe to Adopt"
**Type:** Manual (uses SwipeableHabitCard)

**Description:**
Onboarding screen with card stack of suggested habits

**Implementation:**
```swift
// New file: OnboardingHabitSwipeView.swift
struct OnboardingHabitSwipeView: View {
    let selectedTraits: [IdentityTrait]
    @State private var suggestedHabits: [HabitTemplate] = []
    @State private var currentIndex = 0
    @State private var adoptedHabits: [HabitTemplate] = []
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Based on who you want to become,")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Here are 3 habits to start:")
                    .font(.headline)
            }
            .padding(.top)
            
            ZStack {
                // Show 2 cards at a time for depth effect
                ForEach(currentIndex..<min(currentIndex + 2, suggestedHabits.count), id: \.self) { index in
                    SwipeableHabitCard(
                        template: suggestedHabits[index],
                        onSwipeLeft: { skipHabit(at: index) },
                        onSwipeRight: { adoptHabit(at: index) }
                    )
                    .zIndex(Double(suggestedHabits.count - index))
                    .opacity(index == currentIndex ? 1.0 : 0.5)
                    .scaleEffect(index == currentIndex ? 1.0 : 0.95)
                }
            }
            .frame(height: 500)
            
            Text("\(adoptedHabits.count)/3 habits adopted")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if adoptedHabits.count >= 3 {
                Button("Continue") {
                    // Navigate to summary screen
                }
                .buttonStyle(.borderedProminent)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadSuggestedHabits()
        }
    }
    
    func loadSuggestedHabits() {
        // Filter habits that match selected traits
        suggestedHabits = HabitTemplateLibrary.all.filter { template in
            !Set(template.identityTraits).isDisjoint(with: Set(selectedTraits))
        }
        .shuffled()
        .prefix(10) // Queue up 10 suggestions
        .map { $0 }
    }
    
    func skipHabit(at index: Int) {
        currentIndex += 1
    }
    
    func adoptHabit(at index: Int) {
        adoptedHabits.append(suggestedHabits[index])
        currentIndex += 1
    }
}
```

**Files:**
- Create: `HabitStack/Views/Onboarding/OnboardingHabitSwipeView.swift`

**Symphony:** ❌ No - SwiftUI + complex logic

---

#### Issue #15: Onboarding Screen 5 - "You're Ready"
**Type:** Manual (simple SwiftUI)

**Description:**
Summary screen showing adopted habits, ready to start

**Implementation:**
```swift
// New file: OnboardingCompletionView.swift
struct OnboardingCompletionView: View {
    let adoptedHabits: [HabitTemplate]
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Your first 3 habits:")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(adoptedHabits) { habit in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(habit.emoji) \(habit.name)")
                            .font(.body)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
            
            VStack(spacing: 12) {
                Text("Start tomorrow. Track daily.")
                    .font(.body)
                
                Text("Small wins compound.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("Consistency > Perfection")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .padding(.top, 8)
            }
            
            Spacer()
            
            Button("Let's go! →") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}
```

**Files:**
- Create: `HabitStack/Views/Onboarding/OnboardingCompletionView.swift`

**Symphony:** ❌ No - SwiftUI

---

#### Issue #16: Wire Up New Onboarding Flow
**Type:** Manual (navigation + state management)

**Description:**
Connect all onboarding screens into flow, handle data persistence

**Implementation:**
```swift
// Update: HabitStackApp.swift or OnboardingCoordinator
struct OnboardingFlow: View {
    @StateObject private var onboardingState = OnboardingState()
    
    var body: some View {
        NavigationStack(path: $onboardingState.path) {
            OnboardingVisionView()
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .vision:
                        OnboardingVisionView()
                    case .identity:
                        OnboardingIdentitySelectionView()
                    case .philosophy:
                        OnboardingPhilosophyView(selectedTraits: onboardingState.selectedTraits)
                    case .habitSwipe:
                        OnboardingHabitSwipeView(selectedTraits: onboardingState.selectedTraits)
                    case .completion:
                        OnboardingCompletionView(
                            adoptedHabits: onboardingState.adoptedHabits,
                            onComplete: completeOnboarding
                        )
                    }
                }
        }
    }
    
    func completeOnboarding() {
        // Save user's future self identity
        // Save adopted habits
        // Mark onboarding complete
        // Navigate to main app
    }
}

class OnboardingState: ObservableObject {
    @Published var path: [OnboardingStep] = []
    @Published var selectedTraits: [IdentityTrait] = []
    @Published var adoptedHabits: [HabitTemplate] = []
}

enum OnboardingStep: Hashable {
    case vision, identity, philosophy, habitSwipe, completion
}
```

**Files:**
- Update: `HabitStack/HabitStackApp.swift`
- Create: `HabitStack/ViewModels/OnboardingState.swift`

**Symphony:** ❌ No - App architecture

---

### Part C: Main App - Add Habit with Swipe

#### Issue #17: Contextual Habit Suggestions (Add Habit Flow)
**Type:** Manual (same swipe UI, different data source)

**Description:**
When user taps [+] button, show swipeable habits based on their identity

**Implementation:**
- Reuse `SwipeableHabitCard` component
- Filter `HabitTemplateLibrary` by user's `FutureSelf.traits`
- Exclude already-adopted habits
- Present in modal sheet

**Files:**
- Create: `HabitStack/Views/AddHabit/AddHabitSwipeView.swift`
- Update: Main view's [+] button action

**Symphony:** ❌ No - SwiftUI

---

#### Issue #18: Habit Replacement Flow
**Type:** Manual (new UI pattern)

**Description:**
Allow user to replace a habit with a swipeable alternative

**Implementation:**
- Add "Replace" option to existing habit detail view
- Show swipeable suggestions for same time slot
- On adoption, archive old habit and create new one

**Files:**
- Update: `HabitStack/Views/HabitDetailView.swift`
- Create: `HabitStack/Views/ReplaceHabit/HabitReplacementView.swift`

**Symphony:** ❌ No - SwiftUI

---

### Part D: Coach & Messaging Updates

#### Issue #19: Update Coach Messages - Consistency Tone
**Type:** Symphony ✅ (text-only)

**Description:**
Replace all motivational/energetic coach messages with consistency-focused tone

**Files:**
- `HabitStack/ViewModels/CoachViewModel.swift`
- Any hardcoded tip strings

**Examples:**
```
Old: "You're crushing it! 🔥"
New: "You're showing up. That's what matters."

Old: "Beast mode activated!"
New: "Day 3. You're building momentum. 🌱"

Old: "Don't give up now!"
New: "Tomorrow's a new chance. Consistency beats perfection."
```

**Symphony:** ✅ Yes - text replacement

---

#### Issue #20: Update Celebration/Streak Messages
**Type:** Symphony ✅ (text-only)

**Description:**
Update streak celebration text to focus on consistency

**Examples:**
```
Old: "🔥 7-day streak! You're on fire!"
New: "One week strong. Small wins compound. 💪"

Old: "Streak broken 😢 Get back on track!"
New: "Streaks reset. Habits don't. Keep going."
```

**Symphony:** ✅ Yes - text replacement

---

## Summary: Issue Breakdown

### Symphony CAN Handle (Phase 1 + Coach Text):
1. ✅ App name (done in PR #7)
2. ✅ Rebrand terminology (scorecard, bad habits, etc.)
3. ✅ Coach messages - consistency tone
4. ✅ Celebration text updates
5. ✅ Button labels ("Add" → "Adopt")
6. ✅ Help text / placeholder updates

**Total Symphony issues:** ~6-8 (text-only)

### Manual Development Required (Phase 2):
7. ❌ FutureSelf data model
8. ❌ HabitTemplate library
9. ❌ Onboarding screens 1-5 (5 new views)
10. ❌ Swipeable card component
11. ❌ Wire up onboarding flow
12. ❌ Add habit swipe view
13. ❌ Habit replacement flow

**Total manual issues:** ~13 (SwiftUI development)

---

## Recommended Approach

### Option A: Two-Phase Rollout
1. **Now:** Symphony handles text changes (Phase 1)
2. **Later:** You/developer builds new UI (Phase 2)

### Option B: Wait and Do It All
Skip Symphony, hire iOS dev or build yourself

### Option C: Hybrid
1. Symphony does text (1 week of issues)
2. You start UI work in parallel
3. Merge both when ready

---

## Cost Estimate

**Symphony (Phase 1):**
- 6-8 issues × 2 min each = ~15-20 min
- ~$7-10 total

**Phase 2 (Manual Dev):**
- 13 issues = ~40-60 hours of iOS development
- If hiring: $2,000-$5,000 (depends on dev rate)
- If you build: time investment

---

**מה אתה מעדיף לעשות?**

1. Start Symphony on Phase 1 now?
2. Plan Phase 2 more before starting anything?
3. Hire a dev and hand them this roadmap?
