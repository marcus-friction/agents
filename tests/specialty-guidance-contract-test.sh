#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

PYTHONDONTWRITEBYTECODE=1 python3 - "$REPO_ROOT" <<'PY'
from __future__ import annotations

from pathlib import Path
import re
import sys


repo = Path(sys.argv[1])


def read(relative: str) -> str:
    return (repo / relative).read_text(encoding="utf-8")


def require(relative: str, pattern: str, purpose: str) -> None:
    if re.search(pattern, read(relative), re.IGNORECASE | re.DOTALL) is None:
        raise AssertionError(f"{relative}: missing {purpose}")


def reject(relative: str, pattern: str, purpose: str) -> None:
    match = re.search(pattern, read(relative), re.IGNORECASE | re.DOTALL)
    if match is not None:
        excerpt = " ".join(match.group(0).split())
        raise AssertionError(f"{relative}: retains {purpose}: {excerpt}")


validation_sources = (
    ".agents/skills/architecture-review/SKILL.md",
    ".agents/skills/stack-architecture-review/SKILL.md",
    ".agents/skills/laravel/SKILL.md",
    ".agents/skills/laravel/rules/validation.md",
    ".agents/skills/laravel/rules/routing.md",
)
for source in validation_sources:
    require(
        source,
        r"Form Requests?.{0,260}(meaningful|complex|reus(?:e|ed)|authori[sz]ation|established).{0,260}(inline|small|simple|trivial)|"
        r"(inline|small|simple|trivial).{0,260}Form Requests?.{0,260}(meaningful|complex|reus(?:e|ed)|authori[sz]ation|established)",
        "proportional Form Request criteria for trivial and substantial input",
    )
    reject(
        source,
        r"(?:methods?|controllers?)[^\n]{0,80}(?:under|fewer than|more than|over|>)\s*\d+\s+lines?",
        "an arbitrary method-line extraction threshold",
    )

architecture_review = ".agents/skills/architecture-review/SKILL.md"
stack_architecture_review = ".agents/skills/stack-architecture-review/SKILL.md"
for source in (architecture_review, stack_architecture_review):
    require(
        source,
        r"resource-owning server|server that owns (?:the )?resource",
        "authorization at the resource-owning server boundary",
    )
    require(
        source,
        r"Nuxt/Nitro-owned|Nitro/Nuxt-owned|Nuxt-owned",
        "the Nuxt-owned authorization case",
    )
    require(
        source,
        r"Laravel-owned",
        "the Laravel-owned authorization case",
    )
    reject(
        source,
        r"(?:domain )?authori[sz]ation (?:at|through|belongs at) the Laravel resource-owning boundary",
        "an unconditional Laravel authorization owner",
    )

require(
    "project-templates/base/DESIGN.md",
    r"when Laravel owns|Laravel-owned",
    "conditional Laravel validation and authorization wording",
)
reject(
    "project-templates/base/DESIGN.md",
    r"Laravel owns domain validation and authori[sz]ation",
    "an unconditional Laravel domain-policy owner",
)
require(
    "CONTRIBUTING.md",
    r"When adopted.{0,220}(?:Forge|PM2|Cloudflare)|(?:Forge|PM2|Cloudflare).{0,220}when adopted",
    "conditional delivery guidance",
)

laravel_skill = read(".agents/skills/laravel/SKILL.md")
if "search-docs" in laravel_skill:
    raise AssertionError("Laravel skill requires an unavailable named documentation tool")
reject(
    ".agents/skills/laravel/SKILL.md",
    r"authori[sz]e every action via policies or gates",
    "an unqualified Laravel authorization owner",
)
require(
    ".agents/skills/laravel/SKILL.md",
    r"Laravel-owned|when Laravel owns",
    "Laravel authorization scoped to Laravel-owned resources",
)
require(
    ".agents/skills/laravel/SKILL.md",
    r"parallel agent.{0,180}(?:when|if) available.{0,240}(?:otherwise|unavailable).{0,160}inline|"
    r"(?:when|if) (?:parallel )?agent.{0,80}available.{0,300}(?:otherwise|unavailable).{0,160}inline",
    "a single-agent fallback for rule exploration",
)
require(
    ".agents/skills/laravel/SKILL.md",
    r"installed.{0,100}(?:source|version).{0,180}official Laravel documentation|official Laravel documentation.{0,180}installed.{0,100}(?:source|version)",
    "provider-neutral Laravel API verification",
)
require(
    ".agents/skills/security-review/SKILL.md",
    r"server that owns the protected\s+resource.{0,160}Laravel Policies or Gates when Laravel is that owner",
    "resource-owner-specific authorization in the security pass",
)

vue_skill = ".agents/skills/vue/SKILL.md"
require(
    vue_skill,
    r"Vue 3\.5.{0,220}reactive props destructur",
    "Vue 3.5 reactive props destructure support",
)
require(
    vue_skill,
    r"(?:watch|external).{0,180}(?:getter|toRef).{0,120}(?:getter|toRef)|(?:getter|toRef).{0,180}(?:watch|external)",
    "getter or toRef guidance for external prop use",
)
reject(
    vue_skill,
    r"Discourage using Reactive Props Destructure",
    "the blanket reactive-props-destructure warning",
)

vite_sources = (
    ".agents/skills/vite/SKILL.md",
    ".agents/skills/vite/references/rolldown-migration.md",
)
for source in vite_sources:
    reject(source, r"Vite 8 beta|Once stable", "stale Vite 8 beta guidance")
require(
    ".agents/skills/vite/SKILL.md",
    r"stable.{0,100}March 12, 2026|March 12, 2026.{0,100}stable",
    "the official Vite 8 stable release date",
)
require(
    ".agents/skills/vite/references/rolldown-migration.md",
    r"https://vite\.dev/blog/announcing-vite8(?:\s|$)",
    "the official Vite 8 stable announcement",
)

vitest_sources = (
    ".agents/skills/vitest/SKILL.md",
    ".agents/skills/vitest/references/core-config.md",
)
for source in vitest_sources:
    reject(source, r"Vitest 5(?:\.x|\s+is)?[^\n]{0,80}beta|v5 is currently in beta", "stale Vitest 5 beta guidance")
require(
    ".agents/skills/vitest/SKILL.md",
    r"stable.{0,100}September 3, 2026|September 3, 2026.{0,100}stable",
    "the official Vitest 5 stable release date",
)
require(
    ".agents/skills/vitest/references/core-config.md",
    r"Vitest 5 requires \*\*Vite >= 6\.4\.0\*\* and \*\*Node(?:\.js)? >= 22\.12\.0\*\*",
    "Vitest 5 stable runtime requirements",
)
require(
    ".agents/skills/vitest/SKILL.md",
    r"https://vitest\.dev/blog/vitest-5",
    "the official Vitest 5 stable announcement",
)

print("Specialty guidance contract tests passed")
PY
