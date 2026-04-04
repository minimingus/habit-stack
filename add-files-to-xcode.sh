#!/bin/bash

# Add Phase 2 files to Xcode project
# This script lists all new files that need to be added

PROJECT_DIR="$HOME/dev/habit-stack"
cd "$PROJECT_DIR"

echo "📁 Files copied to project structure:"
echo ""
echo "Models:"
ls -1 HabitStack/Models/*.swift | grep -E "(FutureSelf|HabitTemplate)" || echo "  (check manually)"

echo ""
echo "Data:"
ls -1 HabitStack/Data/*.swift 2>/dev/null || echo "  (check manually)"

echo ""
echo "Views/Onboarding:"
ls -1 HabitStack/Views/Onboarding/*.swift 2>/dev/null || echo "  (check manually)"

echo ""
echo "Views/Components:"
ls -1 HabitStack/Views/Components/*.swift 2>/dev/null || echo "  (check manually)"

echo ""
echo "ViewModels:"
ls -1 HabitStack/ViewModels/*.swift | grep "Onboarding" || echo "  (check manually)"

echo ""
echo "======================================"
echo ""
echo "⚠️  NEXT STEPS IN XCODE:"
echo ""
echo "1. In Xcode Navigator (left panel):"
echo "2. Right-click 'HabitStack' folder"
echo "3. Select 'Add Files to HabitStack...'"
echo "4. Navigate to each folder and add:"
echo "   - HabitStack/Models/FutureSelf.swift"
echo "   - HabitStack/Models/HabitTemplate.swift"
echo "   - HabitStack/Data/HabitTemplateLibrary.swift"
echo "   - HabitStack/Views/Onboarding/*.swift (all 6 files)"
echo "   - HabitStack/Views/Components/*.swift (both files)"
echo "   - HabitStack/ViewModels/OnboardingState.swift"
echo ""
echo "5. ✅ Check 'Copy items if needed' (if prompted)"
echo "6. ✅ Select 'HabitStack' target"
echo "7. Build (⌘+B) to check for errors"
echo ""
echo "OR: Drag folders from Finder into Xcode groups"
echo ""
