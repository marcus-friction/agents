# 2026-08-20 — Ecosystem Architecture Consolidation

## Summary
Re-architected the agent ecosystem to rely on a centralized 3-file routing architecture (`README.md`, `AGENTS.md`, `DESIGN.md`) instead of fragmented individual rule files. This reduces context noise and gives agents a clearer hierarchy of constraints. 

## Changes
- **Core Architecture**
  - Consolidated all pragmatic and behavioral standards into `AGENTS.md`.
  - Defined explicit stack, vision, and infrastructure details in `README.template.md` (featuring Laravel AI and Postmark).
  - Adopted `CONTRIBUTING.md` and `DESIGN.md` as the specialized hubs for workflow and design constraints respectively.
- **Rule Clean-Up**
  - Deleted 17 legacy `.agents/rules/*.md` files, including `10_project.md`, `20_stack.md`, `50_security.md`, and more.
- **Skill Refactoring**
  - Swept through 13+ skill files (`onboard-project`, `review`, `start-project`, etc.) to remove hardcoded references to the deleted rule files.
  - Re-routed all skills to consult the 3 core architecture files.
  - Fixed a legacy path error in `office-hours` (changing `.agent/` to `.agents/`).

## Notes
- `update-agents` has been patched to handle the lack of `.agents/rules` correctly going forward, but the transition script should be closely monitored on the next upstream sync.
