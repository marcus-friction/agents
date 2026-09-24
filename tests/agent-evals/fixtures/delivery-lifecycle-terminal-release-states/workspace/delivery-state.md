# Terminal release dispositions in durable checkpoints

Two secret-free checkpoints have exact repository bindings, verified integration,
owned clean branches, sufficient merge-method proof, and exact cleanup authority.
Record A has release lifecycle disposition `not applicable` and no release
identity because the increment is internal-only. Record B has disposition
`deferred by adopted policy` with the adopted batching boundary and no current
publication effect. Their per-effect integration and cleanup identities use the
checkpoint status enum. No provider mutation is needed to read either record.
