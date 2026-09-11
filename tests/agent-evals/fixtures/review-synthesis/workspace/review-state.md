# Review state

The accepted request is to add a tenant-scoped export endpoint. Its explicit
requirements are tenant authorization, cursor pagination, and an unauthorized
access test. The requested mode is report-only.

The accepted plan is
`docs/plans/2026-09-09-tenant-export/implementation-plan.md`; its sibling
`tasks.md` is the authorized live tracker for this increment.

The local change inventory is:

- `src/ExportController.java`: tracked and modified; accepted.
- `src/ExportControllerTest.java`: tracked and modified; accepted.
- `src/ExportPolicy.java`: untracked, named by the accepted plan, and accepted.
- `marketing/homepage.md`: dirty but unrelated.

Every selected pass has completed. Correctness, in the orchestrator's current
context, reports `tenant-export-ownership` at
`src/ExportController.java:42`, P1, confidence 75: the lookup accepts a tenant
ID without constraining it to the authenticated tenant. It quotes the lookup
line and proposes scoping the repository query.

Security, run as a fresh clean-context subagent, reports
`cross-tenant-export` at `src/ExportController.java:42`, P1, confidence 75.
It describes the same defect, failure path, and correction and quotes the same
lookup. Architecture reports no findings. Testing confirms pagination tests
exist but the explicitly required unauthorized-access test is absent; that
absence is part of the ownership finding's verification, not a different
defect.

The same security reviewer also notices an unauthenticated debug endpoint in
unchanged `src/LegacyAdminController.java:9`. History and the diff show that it
predates the change and the export path does not depend on it.
