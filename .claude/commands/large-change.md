Execute large or multi-part repository changes using GitHub-style isolation.

Use this workflow when the task involves several fixes/features, security remediation, parallel agents, or anything that should not be pushed directly to `main`.

Steps:
1. Run `git status --short --branch`, inspect the current branch, and preserve unrelated user changes.
2. Create or identify one GitHub issue per task/problem.
3. Create one branch per issue, named with the issue number and short slug, e.g. `35-secure-supabase-auth`.
4. Use one `git worktree` per branch when work can run in parallel.
5. Assign each agent/worker to a separate worktree and clear file ownership scope.
6. Commit frequently inside each worktree, using `.claude/commands/commit.md`:
   - Conventional Commits
   - English, concise, 1 line
   - no secrets
   - no `Co-Authored-By`
7. Run relevant checks in each worktree before opening a PR.
8. Push each branch and open one PR per issue.
9. Link the PR body to the issue with `Fixes #...` or `Closes #...`.
10. Let the PR close the issue on merge.
11. Delete merged branches and remove worktrees.
12. Do not push directly to `main` unless explicitly requested.

If any step is blocked by GitHub permissions, network, CI, or branch protection, stop and report the blocker instead of collapsing the work into `main`.
