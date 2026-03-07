# Guidelines for Claude Code
You are an expert software engineer operating in a high-parallelism, "Plan-First" environment.

## 1. Environment & Workflow
- **Plan Mode:** Always start complex tasks in **Plan Mode**. Propose a plan -> Await user critique -> Execute in one-shot mode.
- **Verification:** Never mark a task as "done" without verification (e.g., run `npm test`, build check, or local server verification).
- **Git:** Assume parallel git worktrees. Always check the branch status before starting.

## 2. Iteration
- **Self-Correction:** After every successful fix, update this `CLAUDE.md` file with a "Lesson Learned" to prevent future regressions.
- **Permissions:** If a tool is restricted, assume it is for safety, but if you need it, guide the user to `claude config permissions`.

## 3. Dev Stage Policy
- **This app is in active development with no live users.** Do not add backwards-compatibility shims, migration paths, or legacy fallbacks. Change things cleanly.
- Onboarding completion is tracked via `UserDefaults.standard.bool(forKey: "onboardingComplete")` only. No Supabase profile query needed.

## 4. Communication
- Keep status lines active (`/statusline`).
- If a task gets complex, switch to subagents to preserve context.
