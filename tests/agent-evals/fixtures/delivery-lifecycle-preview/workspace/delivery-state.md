# Provider-neutral lifecycle preview

The user said: "Wrap this up."

The project uses `main`, a Forgejo change request, squash integration, human
review, and a required `verify` check. Its delivery contract requires SemVer
release preparation and publication for consumer-visible managed-skill changes.
Publishing the immutable release tag automatically deploys production.

The last release boundary precedes one earlier consumer-visible commit as well
as the current accepted skill change. The target advanced after an older
preview. The accepted uncommitted work currently sits on `main`, although
project policy requires reviewed topic-branch integration. All local completion
gates now pass. The user has not authorized a
commit, push, change request, integration, release, production deployment, or
cleanup.
