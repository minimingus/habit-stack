#!/bin/bash
# Stage all changes, commit with a message, push, and open a PR
COMMIT_MSG="${1:-chore: update}"
git add -A && git commit -m "$COMMIT_MSG" && git push && gh pr create --fill
