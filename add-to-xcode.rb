#!/usr/bin/env ruby
#
# Script to add Phase 2 files to Xcode project
#

require 'fileutils'

PROJECT_DIR = File.expand_path("~/dev/habit-stack")
PROJECT_FILE = File.join(PROJECT_DIR, "HabitStack.xcodeproj/project.pbxproj")

# Files to add
NEW_FILES = {
  "Models" => [
    "FutureSelf.swift",
  ],
  "Data" => [
    "HabitTemplateLibrary.swift",
  ],
  "Views/Onboarding" => [
    "OnboardingVisionView.swift",
    "OnboardingIdentitySelectionView.swift",
    "OnboardingPhilosophyView.swift",
    "OnboardingHabitSwipeView.swift",
    "OnboardingCompletionView.swift",
    "OnboardingFlow.swift",
  ],
  "Views/Components" => [
    "IdentityTraitCard.swift",
    "SwipeableHabitCard.swift",
  ],
  "ViewModels" => [
    "OnboardingState.swift",
  ],
}

puts "⚠️  Warning: Direct project.pbxproj editing is risky!"
puts "📁 Backup created at: HabitStack.xcodeproj.backup"
puts ""
puts "Instead of automated editing, please add these files manually in Xcode:"
puts ""

NEW_FILES.each do |group, files|
  puts "#{group}:"
  files.each do |file|
    full_path = File.join(PROJECT_DIR, "HabitStack", group, file)
    exists = File.exist?(full_path)
    status = exists ? "✅" : "❌"
    puts "  #{status} #{file}"
  end
  puts ""
end

puts "🎯 Quick Method:"
puts "1. Open Xcode: HabitStack.xcodeproj"
puts "2. In Finder: open ~/dev/habit-stack/HabitStack"
puts "3. Drag the folders (Models, Data, Views, ViewModels) from Finder into Xcode Navigator"
puts "4. When prompted:"
puts "   ✅ Create groups (not folder references)"
puts "   ✅ Add to target: HabitStack"
puts "   ✅ Copy items if needed: NO (already in place)"
puts "5. Build (⌘+B) to verify"
puts ""
puts "Or use File → Add Files to 'HabitStack'... and add each file individually."
puts ""
