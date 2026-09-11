---
name: compound
description: >-
  Assess solved problems for reusable project knowledge and, when authorized,
  capture only high-relevance learnings. Use after substantial troubleshooting
  or tricky implementation, when the user asks to document a solution or
  accepts a proposed durable handoff, or during an explicit wrap.
---

# Compound Knowledge

Rate candidate learnings before turning the strongest ones into concise,
searchable knowledge. Assessment may be proactive; persistence still requires
authority.

## Rate every candidate

After substantial troubleshooting or a tricky implementation, assess the
learning even when no artifact was requested. Search `docs/solutions/` and the
active documentation and tests first so existing coverage informs the rating.
Use evidence-backed ordinal judgment rather than a numeric score:

| Rating | Evidence required | Persistence |
|---|---|---|
| **High** | The root cause and fix are non-obvious and supported; recurrence or wider reuse is credible; and repository search would materially help future work. | Eligible to create or update a solution document. |
| **Medium** | The learning is plausible, but its evidence, recurrence, wider reuse, or retrieval value remains uncertain. | Keep in chat; do not persist or propose persistence yet. |
| **Low** | The change is trivial or obvious, one-off environment noise, unsupported, or lacks future retrieval value. | Keep in chat; do not persist. |

Report the rating value as `high`, `medium`, or `low`.
Only High-rated candidates qualify for compounding.
Authorization never changes qualification. A document request permits a write
only if the candidate rates High. If a requested candidate rates Medium or Low,
explain why it is not a solution artifact; offer ordinary documentation only as
a separate request.

Choose the disposition after rating:

- use `already captured` when active documentation or tests adequately explain
  a High-rated learning;
- use `updated` or `captured` for an authorized High-rated learning, preferring
  a relevant existing solution over a near-duplicate;
- use `proposed` for a High-rated learning found outside an authorized document
  or wrap request, and wait for acceptance before writing;
- use `required` when an accepted handoff cannot write the High-rated artifact
  without broader authority; and
- use `chat only` for Medium or `not applicable` for Low.

Always report the candidate, rating, evidence against the rating criteria,
existing coverage, disposition, and artifact path when one exists.
Keep the result in chat unless the High-rated candidate has write authority.

## Capture the reusable core

Use `references/solution-template.md` as a menu, not a form. Include only useful
sections:

- observable symptom and affected boundary;
- root cause and the evidence that proved it;
- minimal solution, including exact code or configuration only when it helps;
- dead ends only when they are plausible and reusable warnings;
- prevention only when there is a concrete test, guardrail, or practice;
- related code, tests, issues, or documents.

Do not claim unsupported causality or fabricate a prevention strategy to fill a
heading. Redact credentials, customer data, and private operational details.

## Store and verify

For a qualifying candidate, an explicit document request, an accepted proposed
handoff, or an explicit wrap of accepted work authorizes the ordinary repository
write. Use a short kebab-case path under the closest existing `docs/solutions/`
category. Create a new category only when it will remain meaningful; elevated
publication or sensitive-data effects still need an exact decision.

Check links, commands, snippets, and agreement with the implemented fix. For
security, data, or performance topics, apply the corresponding review only when
that boundary is actually present. Report the path and verification; do not
promote the lesson into always-on rules or a skill without a separate request.
