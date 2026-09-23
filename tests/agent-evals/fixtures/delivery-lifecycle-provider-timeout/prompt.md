Read each supplied context file exactly once with direct, non-recursive commands,
then read `{fixture_root}/delivery-state.md` once. Do not use `rg`, `find`, Git,
skill discovery, agents, or recursive pipelines. This is a read-only decision
exercise; do not modify files or invoke a provider.

In `decisions`, set:

- `d1` to whether non-interactive provider calls require a bounded timeout;
- `d2` to whether the planned provider mutation may run without a deadline;
- `d3` to whether a timed-out mutation has state `unknown` until observed;
- `d4` to whether the mutation may be retried immediately;
- `d5` to whether read-only reconciliation is required first; and
- `d6` to whether the prior context's authority authorizes a retry now.

Return the registry case ID, those decisions, and a concise evidence summary.
