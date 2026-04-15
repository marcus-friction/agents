---
name: start-scripts
description: Standards and patterns for building reliable local dev startup scripts (serve.sh, start.sh). Use this skill when creating, modifying, or reviewing any shell script that boots Docker containers, Sail, dev servers, or background services. Also use when the user mentions "serve script", "startup script", "docker compose up", "sail up", or asks to fix orphaned containers, port conflicts, or flaky local environments. Proactively suggest when you see startup-related issues in scripts being edited.
---

# Start Scripts

How to build local dev startup scripts that are reliable, idempotent, and pleasant to use.

Startup scripts are the first thing a developer runs. If they fail, nothing else matters. These patterns exist because we've hit every failure mode below in production — orphaned containers blocking ports, silent hangs on unhealthy databases, zombie processes after Ctrl+C.

## Clean Slate Startup

Containers from a previous run are never trustworthy. State drifts — volumes get corrupted, networks get orphaned, port bindings leak. Starting fresh eliminates an entire class of "works on my machine" bugs.

```bash
# Remove all containers for this project, including orphans from renamed services
docker compose down --remove-orphans 2>/dev/null || true
```

Do this as the **first operational step**, before `sail up` or `docker compose up`. The `|| true` ensures a clean first run (when there's nothing to remove) doesn't abort the script.

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
  - Framework configs (nuxt.config.ts proxy targets, cors.php defaults)
  - Startup script banner output
  - Infrastructure documentation
  - README files

The infrastructure rule (`60_infrastructure.md`) is the single source of truth for this project's port mapping. Defer to it.

## Graceful Shutdown

Zombie processes and orphaned containers make the next startup fail. Trap signals to clean up everything the script started, in reverse order — child processes first, then containers.

```bash
cleanup() {
    echo -e "${YELLOW}Shutting down...${NC}"

    # Kill background processes (Nuxt, watchers, etc.)
    if [[ -n "${NUXT_PID:-}" ]]; then
        kill "$NUXT_PID" 2>/dev/null || true
        wait "$NUXT_PID" 2>/dev/null || true
    fi

    # Stop containers last
    cd "$API_DIR" && ./vendor/bin/sail down 2>/dev/null || true

    echo -e "${GREEN}All services stopped.${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM
```

The `${VAR:-}` pattern avoids `set -u` errors if the variable was never set (e.g., script failed before reaching that step). The `wait` prevents zombie processes.

## Idempotency

The script must be safe to run repeatedly without manual cleanup. This means:

- **Dependency installation**: Only when missing (e.g., check `node_modules` existence before `npm install`).
- **Migrations**: Run non-interactively with `--force`. Idempotent by nature — already-applied migrations are skipped.
- **No interactive prompts**: The script should work unattended. No `read` calls, no confirmations.

```bash
# Install only when needed — saves 10+ seconds on repeat runs
if [[ ! -d "node_modules" ]]; then
    npm install
fi

# --force skips the "are you sure?" prompt
./vendor/bin/sail artisan migrate --force 2>/dev/null
```

## Health Checks

Starting a service doesn't mean it's ready. Databases in particular take a few seconds to accept connections. If you run migrations against an unready database, you get cryptic connection errors.

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
# ── 1. Remove existing containers ─────────────────────────
# ── 2. Start Sail ─────────────────────────────────────────
# ── 3. Run migrations ────────────────────────────────────
# ── 4. Install frontend dependencies ─────────────────────
# ── 5. Start Nuxt dev server ─────────────────────────────
# ── 6. Ready ──────────────────────────────────────────────
```

Define all paths relative to script location so the script works from any working directory:

```bash
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
API_DIR="$ROOT_DIR/platform/api"
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

- **Cyan** for progress ("Starting Sail containers...")
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

Suppress noisy subprocess output with `2>/dev/null` where it's safe — but never suppress error output from steps that might fail (like `sail up`).

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

# ── 1. Remove existing containers (including orphans)
# ── 2. Start containers
# ── 3. Wait for health checks
# ── 4. Run migrations / seeds
# ── 5. Install frontend dependencies (if needed)
# ── 6. Start dev servers (backgrounded)
# ── 7. Print ready banner
# ── 8. Wait for background processes
```
