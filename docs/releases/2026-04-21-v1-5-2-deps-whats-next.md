# 2026-04-21 — v1.5.2 Dependency Hardening & /whats-next

## Summary
Introduced robust, cross-platform system dependency bootstrapping to standardize environment provisioning for Laravel/Nuxt development, and added a novel `/whats-next` skill to generate concise, high-fidelity project status reports.

## Changes
- **Dependency Installation**: Added `install-dependencies.sh` script to idempotently verify and install NVM, Node.js 22 LTS, PHP 8.4, Composer, Git, and Docker.
- **Windows Guidance**: Implemented safety checks in the dependency script to enforce WSL2 execution for native Windows users, halting execution with actionable instructions.
- **Ecosystem Installer Hook**: Updated the root `install.sh` to seamlessly download and trigger the cross-platform dependency scripts automatically.
- **Tool Discovery Fixes**: Implemented fallback folder copying for `~/.claude/skills/` symlink failures (often experienced by Windows developers mounting file systems).
- **New Skill (`/whats-next`)**: Designed a tool-agnostic context parsing skill that analyzes Git logs, release documents, and active artifacts to produce outcome-driven project summaries, devoid of development jargon, for stakeholders.
- **Documentation**: Updated `README.md` to reflect `v1.5.2` System Dependencies configurations.

## Notes
- `install-dependencies.sh` uses `set -e` and prevents duplicated global path manipulation during redundant executions.
- Agents leveraging `/whats-next` should avoid path hardcoding and retrieve context dynamically based on their respective runtime engine capabilities (Antigravity, Claude Code, Cursor, etc.).
