#!/bin/bash
# Create GitHub Issues from tasks.md backlog

cd ~/dev/habit-stack || exit 1

# Create issues from backlog
gh issue create --title "Add completion sound on habit check-off" \
  --body "Implement haptic + audio feedback when user checks off a habit. Should feel satisfying!" \
  --label "enhancement,audio"

gh issue create --title "Implement habit difficulty progression (Level 1 → 2 → 3)" \
  --body "Add difficulty levels to habits. Requires DB migration to add 'difficulty_level' column. UI should show level badge." \
  --label "enhancement,database"

gh issue create --title "Add weekly reflection push notification" \
  --body "Send push notification every Friday evening to trigger weekly reflection sheet." \
  --label "enhancement,notifications"

gh issue create --title "Quick-add flow (name only, skip wizard)" \
  --body "Fast habit creation: just name, use smart defaults. Good for power users." \
  --label "enhancement,ux"

gh issue create --title "Archive view (see + restore archived habits)" \
  --body "Dedicated view to browse archived habits and restore them if needed." \
  --label "enhancement,feature"

gh issue create --title "Trend line in analytics (4-week completion rate)" \
  --body "Add trend chart showing completion rate over last 4 weeks. Helps visualize progress." \
  --label "enhancement,analytics"

gh issue create --title "Monthly summary screen or notification" \
  --body "End-of-month recap: total completions, longest streak, best habit, etc." \
  --label "enhancement,analytics"

gh issue create --title "iOS home screen widget" \
  --body "Widget showing today's habits + progress ring. Uses WidgetKit." \
  --label "enhancement,widget"

gh issue create --title "Habit templates library (Pro feature)" \
  --body "Pre-built habit templates users can choose from. Pro feature only." \
  --label "enhancement,pro-feature"

gh issue create --title "CSV export (Pro feature)" \
  --body "Export all habit data to CSV file. Pro feature for power users." \
  --label "enhancement,pro-feature"

gh issue create --title "Offline mode with sync queue" \
  --body "Allow offline usage, queue changes, sync when connection returns." \
  --label "enhancement,offline"

echo "✅ Created GitHub Issues from backlog!"
