---
description: Wrap up work — atomic commits and push to origin
---

# Wrap

Get all work neatly committed in atomic commits and pushed to origin.

## When to Use

At the end of a work session, before switching context, or when the user says "wrap it up."

## Steps

// turbo-all

1. **Clean up the workspace.** Scan for leftover files that serve no purpose anymore — scratch scripts, temporary debugging files, one-off test fixtures, `/tmp/` artifacts, or `console.log` / `dd()` statements left in source files. Also check if any new environment variables were added to `.env` without updating `.env.example`. Present findings and resolve with user approval.

2. **Compound check.** If a non-trivial bug was fixed or a tricky implementation was solved during this session, invoke the `compound` skill to document the solution before proceeding. Skip for routine feature work or trivial changes.

3. **Survey the workspace.** Run `git status` and `git diff --stat` across all relevant repos to see what's changed. Present a concise summary to the user.

4. **Documentation sync.** Review the staged changes for anything that affects the project's `README.md` — new features, changed API endpoints, modified configuration, added dependencies, or updated setup steps. If so, update the README before proceeding.

5. **Release document.** Generate a release document at `docs/releases/YYYY-MM-DD-{slug}.md` summarizing what was accomplished. Ensure the directory exists (`mkdir -p docs/releases`) before writing the file. Pull context from the conversation, `task.md`, or walkthrough artifacts. Structure:

   ```markdown
   # [Date] — [Release Title]

   ## Summary
   [1-2 sentence overview of what changed and why]

   ## Changes
   - [Bullet list of changes, grouped by concern]

   ## Notes
   - [Any caveats, follow-ups, or deployment considerations]
   ```

6. **Group changes into atomic units.** Analyze the diff and organize changes into the smallest logical commits. Each commit should:
   - Represent exactly one self-contained change (one bug fix, one feature, one refactor)
   - Leave the codebase in a working state
   - Be describable in a single sentence
   - Never mix concerns (e.g., formatting + logic, feature + refactor)

   Present the proposed commit plan to the user for approval before committing.

7. **Stage and commit.** For each atomic unit, in dependency order (foundations first):
   - Stage only the relevant files: `git add <specific files>`
   - Use `git add -p` when a file contains changes belonging to different commits
   - Write a clear, conventional commit message:
     ```
     type(scope): concise description

     Optional body explaining why, not what.
     ```
   - Valid types: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`, `ci`

8. **Verify clean state.** Run `git status` to confirm no uncommitted changes remain. Run `git log --oneline -n <count>` to review the commit sequence.

9. **Push.** Push to origin:
   - `git push origin <branch>` for existing branches
   - `git push -u origin <branch>` for new branches
   - If push is rejected, `git pull --rebase origin <branch>` then retry

10. **Confirm.** Report what was committed and pushed — branch name, commit count, and a one-line summary per commit.

11. **Merge and clean up (feature branches only).** If the current branch is a feature branch (not `master`, `main`, or `staging`), ask the user if they want to squash-merge into the target branch. On confirmation:
    - `git checkout <target>` and `git pull origin <target>`
    - `git merge --squash <feature-branch>`
    - **CRITICAL:** Check `git status` for "Unmerged paths". If merge conflicts exist, notify the user and HALT. Do not commit.
    - Commit with a clean summary message
    - `git push origin <target>`
    - `git branch -D <feature-branch>` and `git push origin --delete <feature-branch>`
    - If declined, skip — the branch stays as-is.

## Rules

- Always present the commit grouping plan before executing — the user approves the structure.
- Never use `git add .` or `git add -A` — stage files explicitly per commit.
- Never use `git reset --hard` or force-push unless the user explicitly requests it.
- Never merge or delete branches without explicit user confirmation.
- If the diff is trivial (single concern), skip the grouping step and commit directly.
- Commit messages must follow Conventional Commits format.
- If tests or linting haven't been run recently, suggest running them before committing — but don't block on it unless the user asks.
