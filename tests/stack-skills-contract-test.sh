#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

python3 - "$REPO_ROOT" <<'PY'
from pathlib import Path
import re
import sys

root = Path(sys.argv[1])


def skill(name: str) -> str:
    return (root / ".agents" / "skills" / name / "SKILL.md").read_text(
        encoding="utf-8"
    )


laravel = skill("laravel")
laravel_queue = (root / ".agents/skills/laravel/rules/queue-jobs.md").read_text(
    encoding="utf-8"
)
assert "installed framework" in laravel
assert "meaningful or complex, reused" in laravel
assert "Laravel-owned resources" in laravel
assert "idempotency" in laravel_queue.lower()
assert "search-docs" not in laravel

nuxt = skill("nuxt")
assert "Nuxt" in nuxt and "SSR" in nuxt
assert "useFetch" in nuxt and "useAsyncData" in nuxt

nitro = skill("nitro")
nitro_cache = (root / ".agents/skills/nitro/references/core-cache.md").read_text(
    encoding="utf-8"
)
assert "cache: false" in nitro_cache
assert "authenticated" in nitro_cache.lower()
assert "identity" in nitro_cache.lower() and "permission" in nitro_cache.lower()

pinia = skill("pinia")
assert "Pinia" in pinia and "type-safe" in pinia

vite = skill("vite")
assert "Vite 8" in vite and "Rolldown" in vite

vitest = skill("vitest")
assert "Vitest" in vitest and "coverage" in vitest.lower()

vue = skill("vue")
assert "Composition API" in vue and "defineProps" in vue

vue_best = skill("vue-best-practices")
assert "<script setup" in vue_best and "TypeScript" in vue_best
assert "Load only" in vue_best or "relevant" in vue_best.lower()

vueuse = skill("vueuse-functions")
assert "already use VueUse" in vueuse
assert "explicitly asks to evaluate or adopt" in vueuse
assert "Do not add VueUse" in vueuse

playwright = skill("playwright")
assert "last resort" in playwright.lower()
assert "structural css" in playwright.lower()
assert "existing Playwright" in playwright
browser_execution = re.sub(
    r"\s+", " ",
    playwright.split("## Prepare browser execution", 1)[1].split(
        "## Select elements by contract", 1
    )[0],
)
assert "If a browser-capable subagent is available," in browser_execution
subagent_path, host_path = browser_execution.split(
    "If no browser-capable subagent is available,", 1
)
assert "port forwarding" in subagent_path
assert "subagent's browser" in subagent_path
assert "host browser" in host_path and "ready" in host_path

print("Laravel and Nuxt stack skill contracts passed")
PY
