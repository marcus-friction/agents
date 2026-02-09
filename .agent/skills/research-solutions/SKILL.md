---
name: research-solutions
description: Search prior solutions before planning new work
---

# Research Solutions Skill

Search `docs/solutions/` for prior art before planning or debugging. This is the knowledge retrieval half of the compound engineering loop.

## Knowledge Sources

Antigravity provides knowledge at two levels:

1. **Conversation summaries** (automatic) — recent conversation titles and summaries are injected at the start of each session. Scan these for relevant prior work before searching docs.
2. **Solution docs** (explicit search) — `docs/solutions/` contains structured problem/solution pairs created by `/compound`.

## When to Use

- Before creating an implementation plan (step 1 of `/lfg`)
- When debugging a problem that might have been solved before
- When the compound rule (`45_workflow_compound.md`) triggers a lookup suggestion

## Steps

### 1. Keyword Search

Search the solutions directory for relevant terms:

```bash
# Search by keyword in filenames
find docs/solutions/ -name "*.md" 2>/dev/null

# Full-text search across all solutions
grep -rl "[keyword]" docs/solutions/ 2>/dev/null

# Search YAML frontmatter tags
grep -rl "tags:.*[keyword]" docs/solutions/ 2>/dev/null
```

### 2. Category Browse

If keyword search returns nothing, browse the relevant category:

| Problem Type | Category |
|-------------|----------|
| Build/compile failures | `docs/solutions/build-errors/` |
| Runtime exceptions | `docs/solutions/runtime-errors/` |
| Slow queries, timeouts | `docs/solutions/performance/` |
| Migrations, data issues | `docs/solutions/database/` |
| Auth, XSS, injection | `docs/solutions/security/` |
| Deploy/server issues | `docs/solutions/deployment/` |
| Visual/layout bugs | `docs/solutions/ui-bugs/` |
| API/service failures | `docs/solutions/integration/` |

### 3. Extract Relevant Context

When a matching solution is found, extract:

- **Root cause** — does it match the current problem?
- **Solution steps** — can they be reused directly?
- **Prevention notes** — has the recommended prevention been implemented?
- **Related links** — any other docs or issues referenced?

### 4. Report Findings

Report to the user or include in the implementation plan:

- Solutions found (with file paths)
- Whether they're directly applicable or just related
- Any prevention measures from past solutions that should be applied

## Rules

- Check conversation summaries first — they're already loaded and free. Then search `docs/solutions/`.
- Always search before saying "I don't have context on this" — between conversation memory and solution docs, there may be relevant prior work.
- If no solutions exist yet, say so — don't pretend to find something.
- Reference solution docs by path so the user can verify.
