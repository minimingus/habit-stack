# Better You - Phase 2 Implementation Files

**Status:** ✅ Ready to copy into Xcode

All files are complete and ready to use. Simply add them to your Xcode project.

---

## 📁 File Structure

```
Phase2-Implementation/
├── Models/
│   ├── FutureSelf.swift          ✅ Issue #16
│   └── HabitTemplate.swift        ✅ Issue #17
├── Data/
│   └── HabitTemplateLibrary.swift ✅ Issue #17
├── Views/
│   ├── Onboarding/
│   │   ├── OnboardingVisionView.swift           ✅ Issue #18
│   │   ├── OnboardingIdentitySelectionView.swift ✅ Issue #19
│   │   ├── OnboardingPhilosophyView.swift       ✅ Issue #20
│   │   ├── OnboardingHabitSwipeView.swift       ✅ Issue #20
│   │   ├── OnboardingCompletionView.swift       ✅ Issue #20
│   │   └── OnboardingFlow.swift                 ✅ Issue #22
│   └── Components/
│       ├── IdentityTraitCard.swift    ✅ Component for #19
│       └── SwipeableHabitCard.swift   ✅ Issue #21
└── ViewModels/
    └── OnboardingState.swift          ✅ Issue #22
```

---

## 🚀 How to Add to Xcode

### Step 1: Open Your Xcode Project
```bash
cd ~/dev/habit-stack
open HabitStack.xcodeproj
```

### Step 2: Create Group Structure

1. Right-click on `HabitStack` folder in Xcode
2. New Group → `Models` (if doesn't exist)
3. New Group → `Data` (if doesn't exist)
4. New Group → `Views`
   - Inside Views: New Group → `Onboarding`
   - Inside Views: New Group → `Components`
5. New Group → `ViewModels` (if doesn't exist)

### Step 3: Add Files

**For each file:**

1. Right-click on the target group
2. Add Files to "HabitStack"...
3. Navigate to `~/dev/habit-stack/Phase2-Implementation/`
4. Select the file
5. ✅ Check "Copy items if needed"
6. ✅ Check "HabitStack" target
7. Click Add

**OR use drag-and-drop:**

1. Open Finder: `~/dev/habit-stack/Phase2-Implementation/`
2. Drag entire folders into Xcode groups
3. ✅ Choose "Copy items if needed"
4. ✅ Choose "Create groups"

---

## ⚙️ Integration Steps

### 1. Update Profile Model

Add `futureSelf` property to your existing `Profile` model:

```swift
struct Profile {
    // ... existing properties
    var futureSelf: FutureSelf?
}
```

### 2. Wire Up Onboarding

In `HabitStackApp.swift` or wherever you handle app launch:

```swift
@main
struct HabitStackApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                // Your main app view
                TodayView()
            } else {
                OnboardingFlow()
            }
        }
    }
}
```

### 3. Save Data After Onboarding

Update `OnboardingFlow.swift` → `completeOnboarding()`:

```swift
private func completeOnboarding() {
    // 1. Save future self
    let futureSelf = FutureSelf(traits: Array(state.selectedTraits))
    // Save to your Profile/Database (Supabase, etc.)
    
    // 2. Create habits from templates
    for habitTemplate in state.adoptedHabits {
        // Convert HabitTemplate → Habit and save
        // let habit = Habit(from: habitTemplate)
        // saveHabit(habit)
    }
    
    // 3. Mark onboarding complete
    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    
    // 4. Navigate to main app
    dismiss()
}
```

---

## 🧪 Test Each Screen

### Preview Individual Views

Each view has `#Preview` at the bottom. Use Xcode Canvas to test:

1. Open any view file
2. ⌘ + Option + Enter (show Canvas)
3. Click "Resume" to see live preview

### Test Full Flow

1. Set `hasCompletedOnboarding = false` in UserDefaults
2. Run app in simulator
3. Walk through onboarding

To reset:
```swift
UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
```

---

## ✅ What's Implemented

### Data Layer
- [x] FutureSelf identity model
- [x] IdentityTrait enum (8 traits)
- [x] HabitTemplate model
- [x] HabitTemplateLibrary (16 curated habits)
- [x] Habit filtering by identity traits

### Onboarding Flow
- [x] Screen 1: Vision (animated intro)
- [x] Screen 2: Choose identity (multi-select grid)
- [x] Screen 3: Philosophy (transition screen)
- [x] Screen 4: Swipe to adopt (Tinder-style cards)
- [x] Screen 5: Completion (summary + CTA)
- [x] Navigation coordination
- [x] State management

### Components
- [x] IdentityTraitCard (selectable)
- [x] SwipeableHabitCard (Tinder gestures)
- [x] PrincipleRow (philosophy screen)

---

## 🚧 TODO (You Need to Do)

### Required
- [ ] Add files to Xcode project
- [ ] Update Profile model with `futureSelf` property
- [ ] Wire up onboarding to app launch
- [ ] Implement data persistence (save FutureSelf + habits)
- [ ] Convert HabitTemplate → Habit (your existing model)
- [ ] Test onboarding flow end-to-end
- [ ] Build and verify no compile errors

### Issues #23-24 (Not Yet Implemented)
- [ ] Add Habit flow (contextual swipe) - Issue #23
- [ ] Habit Replacement flow (swap) - Issue #24

These use the same SwipeableHabitCard component but need:
- Modal sheet for Add Habit button
- Replacement UI in HabitDetailView

Do you want me to create those files too?

---

## 💡 Tips

### Compile Errors?

If you get errors about missing dependencies:
- `HabitCategory` - might need to import from existing code
- `Habit` model - you already have this, just need to map from HabitTemplate

### Swipe Not Working?

- Test on device or simulator (not preview)
- Gestures work better on real device

### Want to Customize?

- **Colors:** Change `.accentColor` in views
- **Animations:** Adjust `.animation()` parameters
- **Habit Library:** Edit `HabitTemplateLibrary.all`
- **Traits:** Edit `IdentityTrait` enum

---

## 📊 What Phase 2 Gives You

### Before
- ❌ Generic "What's your identity?" text field
- ❌ No habit suggestions
- ❌ No contextual onboarding

### After
- ✅ Beautiful 5-screen onboarding flow
- ✅ Identity-based habit suggestions
- ✅ Swipeable Tinder-style UI
- ✅ Consistency-focused messaging
- ✅ 16 curated habit templates
- ✅ Data-driven personalization

---

## 🎨 Design Decisions

### Why Swipe UI?
- Familiar (Tinder-style)
- Fun, engaging
- Reduces choice paralysis
- Mobile-first interaction

### Why Identity First?
- Creates emotional buy-in
- Drives habit relevance
- "Become" mindset vs "do" mindset
- Better retention

### Why 3 Habits?
- Not overwhelming
- Builds momentum
- Atomic Habits principle: start small
- Higher completion rate

---

## 📞 Need Help?

If you get stuck:
1. Check `BETTER_YOU_ROADMAP.md` for detailed implementation notes
2. Each file has `#Preview` for testing in isolation
3. Xcode errors? Build (⌘+B) to see all issues at once

**Files are ready. Copy them to Xcode and let's ship! 🚀**
