# Laravel + Nuxt on Cloud

## Map the applications

Cloud supports Nuxt server rendering and static generation. Use the project's
adopted mode; do not disable SSR to make a deployment pass. Laravel's Inertia
SSR option is not the runtime for a separate Nuxt application.

For a monorepo, create one Cloud application for the Laravel root and another
for the Nuxt root, each connected to the same repository. For separate repos,
connect each independently and record both release revisions. Each app has its
own environments, variables, domains, scaling and deployment status. Shared
build dependencies may be read from sibling directories, but runtime artifacts
must be present inside the deployed application root.

For example, the selected topology might be:

```text
app.example.com -> Nuxt application -> api.example.com -> Laravel application
                                                        -> PostgreSQL
```

Keep the established direct-browser API or Nitro proxy design. A diagram of a
server call does not grant a private network: verify reachability and TLS for
the actual backend URL. Do not assume two Cloud apps have private connectivity.
Laravel remains the authorization owner for Laravel-owned resources.

Sources checked 2026-09-11:
[Nuxt announcement](https://laravel.com/blog/deploy-nextjs-and-nuxt-apps-on-laravel-cloud),
[monorepos](https://laravel.com/cloud/docs/monorepos).

## Build and runtime

- Select a supported Node version compatible with the project's Nuxt version
  and lockfile. Preserve the package manager and workspace build graph.
- Derive install/build commands from the repo; frozen lockfile installation
  must include the tooling needed to build even if runtime uses production mode.
- For SSR, Cloud expects Nitro's Node server output at
  `.output/server/index.mjs`. Identify a previous host's `nitro.preset` or
  `NITRO_PRESET` before changing it. Prepare the Cloud-specific setting without
  breaking an existing host still serving during migration.
- Confirm the start command, output path, listen interface and Cloud port agree.
  Do not hardcode a port incompatible with the platform's `PORT` value.
- For an already-adopted static app, verify generated output, deep-link fallback
  and any build-time API dependency. Do not promise runtime server routes in a
  static deployment.

Map configuration to the keys actually consumed by Nuxt `runtimeConfig` and
the project's matching `NUXT_*` variables. Keep private API/service credentials
server-only. Public API/site URLs may be public; `NUXT_PUBLIC_*` must never
contain secrets. Do not assume the auto-provided site URL configures the API.
Separate build-time values from runtime overrides and verify both on Cloud.

Sources: [Cloud quickstart](https://laravel.com/cloud/docs/quickstart),
[deployment troubleshooting](https://laravel.com/cloud/docs/deployments),
[Nuxt runtime config](https://nuxt.com/docs/4.x/guide/going-further/runtime-config).

## Authentication across apps

Inspect the actual authentication flow before choosing domains or variables.
For Sanctum cookie authentication, place frontend and API under an owned shared
domain, for example `app.example.com` and `api.example.com`, or preserve an
existing same-origin proxy. Do not assume two generated platform domains allow
shared cookies, and never set a cookie domain covering other tenants.

Verify the frontend origin in Sanctum's stateful-domain configuration, explicit
credentialed CORS origins, cookie domain/secure settings, CSRF initialization,
and the client's cookie/XSRF behavior. Preserve narrow scopes and session
isolation between production and staging. Do not use wildcard origins or switch
to bearer tokens merely to bypass a cookie problem.

For authenticated SSR, inspect how the server forwards the current request's
cookies and required origin information to the trusted backend. Forward only
the headers needed for that fixed destination; do not leak credentials to
user-selected hosts. If the adopted proxy handles session creation or renewal,
verify that response cookies reach the browser. Avoid shared authentication
state or caching personalized responses across users.

With an existing token-based design, preserve its token storage, identity
handoff and authorization ownership instead of imposing Sanctum sessions.

Test login, authenticated page reload with SSR, an authorized API action,
rejection of unauthorized access and logout using designated test accounts.
Report domain/DNS or browser-test gaps explicitly.

Source: [Sanctum SPA authentication](https://laravel.com/framework/docs/13.x/sanctum#spa-authentication).

## Release compatibility

A shared Git push does not make the two application deployments atomic. Choose
and record a release order based on API compatibility and build dependencies.
A usual sequence is additive backend migration/API changes, backend health,
frontend release, then the integrated flow. If an old frontend cannot use the
new backend, prepare a compatible staged change or obtain a deliberate
maintenance/cutover decision instead of assuming ordering solves it.

Record both previous working revisions and the candidate pair. If one app
fails, inspect which code and migrations are already live before another
deployment. Apply the [recovery guidance](verification-and-recovery.md).
