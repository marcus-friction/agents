Read the complete security-review and architecture context under
`{context_root}`, then inspect `{fixture_root}/boundaries.md`. Record a short
review in `case-note.md`; that is the only authorized fixture write.

In `decisions`, set:

- `d1` to whether the local prototype keeps secret isolation;
- `d2` to whether the web/service product separates identity, session, claims,
  and authorization at the owning boundaries;
- `d3` to whether the disposable store needs a tested rebuild path;
- `d4` to whether the material store needs recovery evidence; and
- `d5` to whether severity considers exploitability, exposure, impact,
  reversibility, control owner, and evidence.

Return the registry case ID, those decisions, and a concise evidence summary.
