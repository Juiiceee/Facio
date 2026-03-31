Commit all staged and unstaged changes following the project's Conventional Commits guidelines from CLAUDE.md.

Steps:
1. Run `git status` to see all changes
2. Run `git diff` and `git diff --cached` to understand what changed
3. Run `git log --oneline -5` to see recent commit style
4. Stage all relevant files (NOT .env, credentials, or secrets)
5. Write a commit message following these rules:
   - `fix:` for bug fixes, corrections — **triggers a patch version bump**
   - `impr:` for small improvements, UI tweaks, polish — no bump, shows in changelog
   - `refactor:` for code refactoring — no bump, shows in changelog
   - `feat:` for **big features only** (new major section, new module, new integration) — triggers minor bump
   - `chore:` for CI, config, dependencies, docs — hidden from changelog
   - Always ensure at least one `fix:` exists in a batch of commits to trigger a release
   - Use scopes: `fix(ui):`, `impr(pdf):`, `feat(sync):`, etc.
   - Message in English, concise, 1 line (max 72 chars)
   - NO Co-Authored-By line
6. Create the commit
7. Show the result

If the user provides an argument, use it as a hint for the commit message: $ARGUMENTS
