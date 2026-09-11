---
name: build-start-scripts
description: Standards and patterns for building reliable local dev startup scripts (serve.sh, start.sh). Use this skill when creating, modifying, or reviewing any shell script that boots Docker containers, Laravel Sail, Nuxt dev servers, or background services. Also use when the user mentions "serve script", "startup script", "docker compose up", "sail up", or asks to fix orphaned containers, port conflicts, or flaky local environments. Proactively suggest when you see startup-related issues in scripts being edited.
---

# Start Scripts

How to build local dev startup scripts that are reliable, idempotent, and pleasant to use.

Startup scripts are the first thing a developer runs. If they fail, nothing else matters. These patterns exist because we've hit every failure mode below in production — orphaned containers blocking ports, silent hangs on unhealthy databases, zombie processes after Ctrl+C.

## Reconcile before starting

Normal startup does not run `docker compose down`. Resolve the Compose project
name and inspect its services, health, ports, and ownership first. Reuse healthy
dependencies, start only missing or stopped services, and fail with a clear
diagnosis when an unknown process owns a required port. Do not kill or replace
unknown processes.

An explicit reset may remove containers or orphans only after verifying the
named Compose project is disposable and previewing the affected services,
volumes, and recovery. A reset is a separate destructive operation, not startup
hygiene.

After showing the exact effect preview, obtain one exact decision for the named
project and listed effects. An already-supplied decision is sufficient only when
it matches that preview. Only then execute the reset.

Snapshot service state before `up` and track which services transitioned to
running during the current invocation. That ownership record controls cleanup.

## Port Discipline

Port conflicts are the #1 cause of "the script worked yesterday" failures. Every project should own a distinct port range so multiple projects can coexist locally.

- Define all ports via environment variables with explicit defaults in `docker-compose.yml`:
  ```yaml
  ports:
    - '${APP_PORT:-8900}:80'
  ```
- Defaults in `docker-compose.yml` must match `.env` values — they're the fallback, not an override.
- When ports change, update **every** reference. The blast radius is larger than you'd expect:
  - `.env` and `.env.example`
  - `docker-compose.yml` defaults
  - Framework configs (`nuxt.config.ts` proxy targets, Laravel CORS defaults)
  - Startup script banner output
  - Infrastructure documentation
  - README files

The infrastructure rule (`README.md`) is the single source of truth for the
project's port mapping. Defer to it rather than inventing a baseline port.

## Graceful Shutdown

Trap signals to clean up what this invocation started, in reverse order—child
processes first, then services. Preserve pre-existing or shared processes,
containers, networks, and volumes.

```bash
STARTED_SERVICES=()

cleanup() {
    echo -e "${YELLOW}Shutting down...${NC}"

    # Kill background processes (Nuxt, queue watchers, etc.)
    if [[ -n "${NUXT_PID:-}" ]]; then
        kill "$NUXT_PID" 2>/dev/null || true
        wait "$NUXT_PID" 2>/dev/null || true
    fi

    # Stop only services recorded as transitioned by this invocation.
    if [[ ${#STARTED_SERVICES[@]} -gt 0 ]]; then
        if ! docker compose stop "${STARTED_SERVICES[@]}"; then
            echo -e "${YELLOW}Some current-run services could not be stopped; inspect them manually.${NC}"
        fi
    fi

    echo -e "${GREEN}Current-run services stopped.${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM
```

Initialize `STARTED_SERVICES=()` before installing the trap. Record a service
only after verifying its transition from the pre-start snapshot. The
`${VAR:-}` pattern avoids `set -u` errors if a PID was never set, and `wait`
prevents zombie processes. If ownership is uncertain, retain the service and
report it instead of broadening cleanup.

## Idempotency

The script must be safe to run repeatedly without manual cleanup. This means:

- **Dependency installation**: Only when missing (e.g., check `node_modules` existence before `npm install`).
- **Migrations**: Run Laravel migrations non-interactively with `--force` after
  the database is healthy. Already-applied migrations remain unchanged.
- **No interactive prompts**: The script should work unattended. No `read` calls, no confirmations.

```bash
# Install only when needed — saves 10+ seconds on repeat runs
if [[ ! -d "node_modules" ]]; then
    npm install
fi

./vendor/bin/sail artisan migrate --force
```

## Health Checks

Starting a service doesn't mean it is ready. Databases in particular take a few
seconds to accept connections. Running Laravel migrations against an unready
database produces misleading connection failures.

Wait with a bounded timeout — never hang forever.

```bash
echo -e "${CYAN}Waiting for database...${NC}"
timeout=30
until ./vendor/bin/sail exec pgsql pg_isready -q -U sail 2>/dev/null || [[ $timeout -le 0 ]]; do
    sleep 1
    ((timeout--))
done

if [[ $timeout -le 0 ]]; then
    echo -e "${RED}Database did not become ready in time.${NC}"
    exit 1
fi
```

This pattern gives the database 30 seconds, checks every second, and fails explicitly with a clear message instead of hanging.

## Script Structure

A consistent structure makes scripts scannable and debuggable.

```bash
#!/usr/bin/env bash
set -euo pipefail
```

- `set -e`: Exit on any error.
- `set -u`: Error on undefined variables (catches typos).
- `set -o pipefail`: Catch failures in piped commands.

Number steps sequentially in comments so log output maps to code:

```bash
# ── 1. Inspect current processes, ports, and services ─────
# ── 2. Start missing Laravel Sail services ────────────────
# ── 3. Wait for health checks ─────────────────────────────
# ── 4. Run Laravel migrations / seeds ─────────────────────
# ── 5. Install frontend dependencies if needed ────────────
# ── 6. Start Nuxt dev server ──────────────────────────────
# ── 7. Ready ──────────────────────────────────────────────
```

Define all paths relative to script location so the script works from any working directory:

```bash
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
API_DIR="$ROOT_DIR/platform/api"
WEB_DIR="$ROOT_DIR/platform/dashboard"
```

## Output

Developers judge a script by its output. Clean, color-coded output builds trust.

```bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
```

- **Cyan** for progress ("Starting Laravel Sail services...")
- **Green** for success (ready banner)
- **Red** for errors ("Database did not become ready")
- **Yellow** for warnings and shutdown messages

Print a clear service table on success:

```bash
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Project Name — Running${NC}"
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo ""
echo -e "  ${CYAN}Dashboard${NC}   → http://localhost:3100"
echo -e "  ${CYAN}API${NC}         → http://localhost:8900"
echo -e "  ${CYAN}Mailpit${NC}     → http://localhost:8906"
echo ""
echo -e "  Press ${YELLOW}Ctrl+C${NC} to stop all services."
```

Suppress noisy subprocess output with `2>/dev/null` where it is safe, but never
suppress error output from steps that might fail.

## Complete Template

For reference, here's the full structure a startup script should follow:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Header comment with service table
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
# Path variables

# Color definitions
# Cleanup trap

# ── 1. Snapshot current processes, ports, and Compose service state
# ── 2. Start only missing or stopped Sail services; record transitions
# ── 3. Wait for bounded health checks
# ── 4. Install backend dependencies and run Laravel migrations / seeds
# ── 5. Install frontend dependencies if needed
# ── 6. Start a tracked Nuxt dev process
# ── 7. Print ready banner
# ── 8. Wait for background processes; clean up only current-run ownership
```
