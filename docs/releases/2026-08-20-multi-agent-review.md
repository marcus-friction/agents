# 2026-08-20 — Multi-Agent Code Review (CE Implementation)

## Summary
Upgraded the `review` workflow by introducing a parallel, multi-agent orchestrator (`ma-review`) based on the latest Compound Engineering methodology.

## Changes
- **Agent Orchestrator**
  - Added `ma-review` skill to orchestrate parallel execution of specialized review personas.
- **Review Personas**
  - Converted previous static checklists into dedicated persona prompts: `ma-architecture-review`, `ma-performance-review`, and `ma-security-review`.
  - Injected CE heuristics and "Attacker/Scalability" mindsets into the personas.
  - Added noise-reduction rules ("What You Don't Flag") to suppress defense-in-depth on already protected code and purely stylistic choices.
- **Documentation**
  - Added the `ma-review` skill to the available skills table in `README.md`.

## Notes
- The original sequential `/review` skill remains untouched so both modes are available side-by-side.
- The new `ma-review` skill assumes the environment supports parallel execution (or manual sequential adoption) of the personas.
