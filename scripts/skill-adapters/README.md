# Skill adapter contract

`.agents/skills` is the canonical skill source. Each `*.sh` file in this directory describes how one consumer discovers that source. `scripts/register-skills.sh` discovers adapters by filename, so adding a consumer must not require changes to the registrar or canonical skills.

An adapter defines three required functions:

- `skill_adapter_supports_scope scope` returns success for supported `project` or `user` scopes.
- `skill_adapter_target scope project_root` prints the discovery path that should become a symlink.
- `skill_adapter_link_source scope skills_source` prints the symlink value. Project links should be repository-relative; user links should use the absolute canonical source passed by the registrar.

Adapters may also define:

- `skill_adapter_preflight scope project_root skills_source distribution_root` to validate provider-owned configuration before any registration mutation.
- `skill_adapter_configure scope project_root skills_source distribution_root` to stage provider-specific router candidates or maintain adapter-owned metadata after its link is registered.

Keep adapters small and provider-specific. Required path functions must print only their result, preflight functions must not mutate state, and adapters must never copy the skill tree or overwrite an existing discovery path. Registration is idempotent only when an existing symlink already has the exact expected value; a different symlink is a collision that requires an explicit user decision. Active provider instruction files are project-owned: adapters may stage candidates below `.agents/templates/adapters/`, but must not create, append to, or replace active project documentation.

The optional `--journal-output` integration writes a readable target/source list
for links created by that invocation. Registration assumes cooperative local
processes: it preflights all targets and rolls back a link only while it remains
the exact symlink value the registrar created. It does not claim protection
against a hostile process running as the same user.
