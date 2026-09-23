# GitHub release adapter

Use only for a project that has adopted GitHub release publication. Follow the
[wrap GitHub adapter](../../wrap/references/github.md) for hostname/account/
repository authentication and identity checks. GitHub CLI setup and login never
authorize a tag or release.

Before publication, inspect existing local and remote tags and `gh release`
state. Confirm the exact version/tag, verified integrated commit, release title
and notes source, draft/prerelease/public exposure, automatic workflows or
deployments, credentials, and recovery. Create an annotated or lightweight tag
only as the project contract requires, and push only that exact tag when
authorized. Publish the GitHub release only with separate or unchanged exact
batch authority.

After each effect, observe the remote tag peeled commit and release metadata.
The tag and release target must resolve to the verified integrated revision.
If a tag exists at another commit or release metadata conflicts, stop; never
move, delete, overwrite, or recreate it automatically. After an ambiguous
timeout, inspect both tag and release before retrying. If the tag succeeded but
release publication did not, report `partial`, retain recovery state, and
request authority only for the remaining effect once its facts are revalidated.

When GitHub automation publishes from integration or a tag, monitor and verify
that result instead of invoking duplicate publication. Any automatic deployment
must have been disclosed and separately authorized before its trigger.
