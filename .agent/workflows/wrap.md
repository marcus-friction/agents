---
description: Wrap up work — atomic commits and push to origin
---

# Wrap

Get all work neatly committed in atomic commits and pushed to origin.

## When to Use

At the end of a work session, before switching context, or when the user says "wrap it up."

## Steps

// turbo-all

1. **Survey the workspace.** Run `git status` and `git diff --stat` across all relevant repos to see what's changed. Present a concise summary to the user.

2. **Group changes into atomic units.** Analyze the diff and organize changes into the smallest logical commits. Each commit should:
   - Represent exactly one self-contained change (one bug fix, one feature, one refactor)
   - Leave the codebase in a working state
   - Be describable in a single sentence
   - Never mix concerns (e.g., formatting + logic, feature + refactor)

   Present the proposed commit plan to the user for approval before committing.

3. **Stage and commit.** For each atomic unit, in dependency order (foundations first):
   - Stage only the relevant files: `git add <specific files>`
   - Use `git add -p` when a file contains changes belonging to different commits
   - Write a clear, conventional commit message:
     ```
     type(scope): concise description

     Optional body explaining why, not what.
     ```
   - Valid types: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`, `ci`

4. **Verify clean state.** Run `git status` to confirm no uncommitted changes remain. Run `git log --oneline -n <count>` to review the commit sequence.

5. **Push.** Push to origin:
   - `git push origin <branch>` for existing branches
   - `git push -u origin <branch>` for new branches
   - If push is rejected, `git pull --rebase origin <branch>` then retry

6. **Confirm.** Report what was committed and pushed — branch name, commit count, and a one-line summary per commit.

## Rules

- Always present the commit grouping plan before executing — the user approves the structure.
- Never use `git add .` or `git add -A` — stage files explicitly per commit.
- Never use `git reset --hard` or force-push unless the user explicitly requests it.
- If the diff is trivial (single concern), skip the grouping step and commit directly.
- Commit messages must follow Conventional Commits format.
- If tests or linting haven't been run recently, suggest running them before committing — but don't block on it unless the user asks.
