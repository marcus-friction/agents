Read each supplied context file exactly once with direct, non-recursive commands,
then read `{fixture_root}/delivery-state.md` once. Do not use `rg`, `find`, Git,
skill discovery, agents, or recursive pipelines. This is a read-only decision
exercise; do not modify files.

In `decisions`, set:

- `d1` to whether the terminal-handoff branch must be selected before delivery;
- `d2` to the applicable terminal cutoff;
- `d3` to whether the tracker must be current before publication of that handoff;
- `d4` to whether its later merge identity requires another evidence PR;
- `d5` to whether post-cutoff remediation starts a new tracked increment; and
- `d6` to whether later cleanup facts remain external.

Return the registry case ID, those decisions, and a concise evidence summary.
