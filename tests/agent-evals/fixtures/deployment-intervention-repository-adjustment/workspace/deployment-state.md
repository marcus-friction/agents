# Repository adjustment state

The user explicitly authorized preparation of the application for deployment,
including ordinary scoped repository edits and tests, but did not authorize a
production deployment. The current start script binds only to localhost and
ignores the platform `PORT`. The fix belongs in the repository and needs local
verification; no privileged dashboard access or owner choice is required.
