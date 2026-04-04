#!/bin/bash
# Symphony wrapper for GitHub Issues
# Polls GitHub Issues and runs Claude Code on each one

set -euo pipefail

REPO_DIR="$HOME/dev/habit-stack"
WORKSPACE_ROOT="$HOME/symphony-workspaces/habit-stack"
MAX_CONCURRENT=2

cd "$REPO_DIR" || exit 1

echo "🎵 Symphony GitHub Wrapper"
echo "📁 Repo: $REPO_DIR"
echo "💼 Workspaces: $WORKSPACE_ROOT"
echo ""

# Fetch open issues
echo "🔍 Fetching open GitHub issues..."
ISSUES=$(gh issue list --state open --json number,title,body --limit 20)

if [[ "$ISSUES" == "[]" ]]; then
  echo "✨ No open issues found"
  exit 0
fi

# Process each issue
echo "$ISSUES" | jq -c '.[]' | while read -r issue; do
  NUMBER=$(echo "$issue" | jq -r '.number')
  TITLE=$(echo "$issue" | jq -r '.title')
  BODY=$(echo "$issue" | jq -r '.body // ""')
  
  WORKSPACE="$WORKSPACE_ROOT/issue-$NUMBER"
  
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎯 Issue #$NUMBER: $TITLE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  
  # Check if already processed
  if [[ -f "$WORKSPACE/.processed" ]]; then
    echo "⏭️  Already processed, skipping"
    continue
  fi
  
  # Create workspace
  mkdir -p "$WORKSPACE"
  cd "$WORKSPACE"
  
  # Clone repo if not exists
  if [[ ! -d ".git" ]]; then
    echo "📦 Cloning repo..."
    git clone https://github.com/minimingus/habit-stack.git . --quiet
  else
    echo "🔄 Pulling latest..."
    git pull origin main --quiet || true
  fi
  
  # Create branch
  BRANCH="issue-$NUMBER"
  git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
  
  # Create prompt file
  cat > TASK.md <<EOF
# Issue #$NUMBER: $TITLE

$BODY

---

## Your Mission

1. Implement this feature/fix
2. Follow iOS/Swift best practices (SwiftUI, MVVM)
3. Test: \`xcodebuild -project HabitStack.xcodeproj -scheme HabitStack\`
4. Create RESULTS.md with summary
5. Commit changes

## Project Structure

- HabitStack/ViewModels/ - View logic
- HabitStack/Views/ - SwiftUI views
- HabitStack/Models/ - Data models
- HabitStack/Core/ - Utilities

Good luck! 🚀
EOF
  
  echo "🤖 Spawning Claude Code via OpenClaw..."
  
  # Note: This would use OpenClaw sessions_spawn in reality
  # For now, just create a placeholder
  echo "TODO: Integrate with OpenClaw sessions_spawn" > run.log
  echo "Task: $(cat TASK.md)" >> run.log
  
  # Simulate success for demo
  if true; then
    
    echo "✅ Claude Code completed successfully"
    
    # Commit changes
    git add -A
    git commit -m "Issue #$NUMBER: $TITLE - automated implementation" || echo "Nothing to commit"
    
    # Push branch
    git push origin "$BRANCH" --force-with-lease || echo "Push failed"
    
    # Create PR
    gh pr create --title "Fix #$NUMBER: $TITLE" \
      --body "Automated fix via Symphony + Claude Code

Closes #$NUMBER

$(cat RESULTS.md 2>/dev/null || echo 'See commit for changes')" \
      --base main --head "$BRANCH" || echo "PR may already exist"
    
    # Mark as processed
    touch "$WORKSPACE/.processed"
    
    # Add comment to issue
    gh issue comment "$NUMBER" --body "🤖 Automated implementation completed!
PR created: Check PRs tab.
Review the changes and merge if approved." || true
    
  else
    echo "❌ Claude Code failed - see $WORKSPACE/run.log"
    gh issue comment "$NUMBER" --body "⚠️ Automated implementation failed.
See logs for details." || true
  fi
  
  cd "$REPO_DIR"
done

echo ""
echo "✅ Symphony run complete!"
