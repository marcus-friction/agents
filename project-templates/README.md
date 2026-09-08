# Project Document Candidates

Files in `base/` are the canonical upstream candidates for foundational project
documentation. Installation stages byte-identical copies under
`.agents/templates/`; it never makes them active policy.

Use `onboard-project` to reconcile a candidate with repository evidence and
existing root documents. Preserve current meaning, badges, commands, links,
license text, local constraints, and uncommitted content unless an approved
exact patch changes them. A new project may adopt a candidate only after its
placeholders and component classifications are resolved.

The candidate set is intentionally compact:

- `README.md` records product intent and verified operating instructions.
- `AGENTS.md` contains high-frequency agent rules.
- `ARCHITECTURE.md` records component status and system boundaries.
- `CONTRIBUTING.md` defines delivery and verification policy.
- `DESIGN.md` defines interface tokens and behavior when UI is adopted.

Projects own their active root documents. Updates to this directory create new
candidates for review; they do not authorize mechanical replacement downstream.
