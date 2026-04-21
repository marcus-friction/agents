# 2026-04-21 — Ecosystem Metadata Fix

## Summary
Patched incomplete YAML frontmatter across several skills to ensure they correctly register as slash commands within the agent ecosystem.

## Changes
- Addressed missing metadata bugs affecting `[/review]`, `[/brainstorm]`, `[/plan]`, `[/stats]`, and `[/wrap]`.
- Fixed by strictly declaring `name:` attributes, forcing standard skill indexing behavior.
- Updated `README.md` to index this fix (v1.5.4).

## Notes
- Slash commands are now dynamically verified to register cleanly on boot for these updated skills.
