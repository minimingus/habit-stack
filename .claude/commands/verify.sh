#!/bin/bash
# Generate Xcode project and build for iOS simulator
set -e

echo "Generating Xcode project..."
~/.mint/bin/xcodegen generate

echo "Building HabitStack..."
xcodebuild \
  -project HabitStack.xcodeproj \
  -scheme HabitStack \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -configuration Debug \
  build | xcpretty || xcodebuild \
  -project HabitStack.xcodeproj \
  -scheme HabitStack \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  -configuration Debug \
  build
