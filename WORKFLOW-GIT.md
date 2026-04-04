---
# Git-Based Workflow (No External Tracker)
# Each git branch = one task for Claude Code

workspace:
  root: ~/symphony-workspaces/habit-stack

hooks:
  after_create: |
    # Clone the repo
    git clone https://github.com/minimingus/habit-stack.git .

  before_run: |
    # Checkout the branch for this task
    BRANCH_NAME="{{ branch_name }}"
    git fetch origin
    git checkout "$BRANCH_NAME" || git checkout -b "$BRANCH_NAME"
    git pull origin "$BRANCH_NAME" || true

  after_run: |
    # Commit and push changes
    git add -A
    git commit -m "{{ issue.title }} - automated changes" || true
    git push origin HEAD || true

agent:
  max_concurrent_agents: 2
  max_turns: 15

codex:
  command: claude-code --print --permission-mode bypassPermissions
  approval_policy: "on-request"
  thread_sandbox: "workspace-write"
  turn_timeout_ms: 1800000
---

# Habit Stack - iOS Development (Git Branch Mode)

You are working on **Habit Stack**, an iOS app (Swift/SwiftUI).

## Current Task

**Branch:** {{ branch_name }}
**Task:** {{ issue.title }}

{% if issue.description %}
**Details:**
{{ issue.description }}
{% endif %}

## Your Mission

1. Implement the feature/fix on this branch
2. Build and test: `xcodebuild -project HabitStack.xcodeproj -scheme HabitStack`
3. Update `RESULTS.md` with summary
4. Changes will be auto-committed to the branch

## Project Structure

```
HabitStack/
├── ViewModels/     # MVVM logic
├── Views/          # SwiftUI
├── Models/         # Data
├── Core/           # Supabase, RevenueCat, etc.
```

**iOS Best Practices:**
- SwiftUI + Combine
- MVVM architecture
- Keep views declarative
- Don't break the build!

Good luck! 🚀
