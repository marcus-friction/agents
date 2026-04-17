---
name: update-agents
description: Pulls the latest agent rules and skills from the remote repository without wiping local project customizations. Use this skill when the user asks to "update agents", "sync agents", or "pull the latest agent rules".
---

# Agent Instruction: Run Agent Update

You are tasked with updating the local project's `.agents/` directory (rules and skills) from the central upstream repository (`https://github.com/marcus-friction/agents.git`). 

**Crucial Objective**: This update MUST be purely non-destructive to local adjustments. You cannot blindly overwrite active uncommitted work or bespoke project-level customizations.

## Execution Pipeline

You must execute the update using the single, unified bash script provided below. Do not attempt to run these commands individually, as agent environments reset their shell state between blocks.

Copy and execute the following complete script:

```bash
set -e

# 1. Base Environment & Cleanliness Gate
cd "$(git rev-parse --show-toplevel)" || { echo "Must be in a git repository."; exit 1; }

if ! git diff --quiet HEAD -- .agents/ AGENTS.md CLAUDE.md 2>/dev/null; then
  echo "ERROR: Uncommitted changes detected in your agent files."
  echo "You must commit or stash active work before running an update to prevent data loss."
  exit 1
fi

echo "Environment clean. Initializing update..."
TMP_DIR="/tmp/agents-update"

# 2. Resilient Cleanup Trap
# Ensures the temporary isolation directory is ALWAYS deleted, even if the script aborts midway.
trap 'rm -rf "$TMP_DIR"' EXIT

# 3. Isolate & Fetch
rm -rf "$TMP_DIR"
git clone --depth 1 https://github.com/marcus-friction/agents.git "$TMP_DIR"

# 4. File Synchronization & Protection

# Update Rules Pass 1: Sync core rules, explicitly excluding customizable templates
rsync -a \
  --exclude="10_project.md" \
  --exclude="23_design_system.md" \
  --exclude="60_infrastructure.md" \
  "$TMP_DIR/.agents/rules/" .agents/rules/

# Update Rules Pass 2: Safely add customizable templates ONLY if they do not exist locally
rsync -a --ignore-existing "$TMP_DIR/.agents/rules/" .agents/rules/

# Update Skills: Recursively replace standard skills, untouched local bespoke skills stay safe
rsync -a "$TMP_DIR/.agents/skills/" .agents/skills/

# Update Base Routers (Do not overwrite README.md automatically)
cp "$TMP_DIR/AGENTS.md" ./AGENTS.md
[ -f "$TMP_DIR/CLAUDE.md" ] && cp "$TMP_DIR/CLAUDE.md" ./CLAUDE.md || true

# 5. Orphan Analysis & Verification
echo ""
echo "--- ORPHAN ANALYSIS (SKILLS) ---"
echo "The following skills exist locally but are NOT present in the upstream repository:"
comm -23 <(ls -1 .agents/skills/ | sort) <(ls -1 "$TMP_DIR/.agents/skills/" | sort)
echo "--------------------------------"
echo ""
echo "--- ORPHAN ANALYSIS (RULES) ---"
echo "The following rules exist locally but are NOT present in the upstream repository:"
comm -23 <(ls -1 .agents/rules/ | sort) <(ls -1 "$TMP_DIR/.agents/rules/" | sort)
echo "-------------------------------"
echo ""

echo "Update complete. Reviewing final git status:"
git status
```

### Final Report & User Interaction
End your turn by presenting the user with:
1. A summary of the rules or skills that were modified or added (based on the `git status` output).
2. Confirmation that local custom templates were safely bypassed.
3. **CRITICAL**: Explicitly read the `ORPHAN ANALYSIS` outputs from the terminal. If any orphaned skills or rules are listed, prompt the user: 
   > *"I noticed the following items exist locally but not upstream: `[Item X, Item Y]`. Are these your custom workflows, or are they deprecated upstream files you would like me to clean up?"*
