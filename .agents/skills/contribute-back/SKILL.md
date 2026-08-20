---
name: contribute-back
description: Scan local agent ecosystem (.agents/) for modifications or new skills, propose them to the user, and automatically create a Pull Request to the central marcus-friction/agents repository.
---

# Agent Instruction: Contribute Back

You are tasked with comparing the user's local `.agents/` directory against the upstream central repository (`https://github.com/marcus-friction/agents.git`) to identify improvements, new skills, or fixes that can be contributed back to the community.

## Execution Pipeline

### Phase 1: Diff & Analysis
You must first determine what has changed locally without modifying the user's project. Run the following bash script to generate a diff of local changes vs upstream. 

Copy and execute the following complete script:

```bash
set -e

echo "Environment clean. Initializing diff comparison..."
TMP_DIR="/tmp/agents-contribute"

# Resilient Cleanup Trap
trap 'rm -rf "$TMP_DIR"' EXIT

# Isolate & Fetch
rm -rf "$TMP_DIR"
if ! git clone --depth 1 https://github.com/marcus-friction/agents.git "$TMP_DIR" > /dev/null 2>&1; then
    echo "Error: Failed to clone the repository."
    exit 1
fi

# Exclusion list: project-specific templates that must NEVER leak upstream
EXCLUDE=""

echo ""
echo "=== MODIFIED/NEW FILES IN LOCAL .agents/ ==="
# Compare local .agents/ against upstream, ignoring project-specific config templates
SUMMARY=$(diff -qr $EXCLUDE "$TMP_DIR/.agents" .agents 2>/dev/null || true)

if [ -z "$SUMMARY" ]; then
  echo "No local modifications detected. Your ecosystem is in sync with upstream."
  exit 0
fi

echo "$SUMMARY"

echo ""
echo "=== DETAILED DIFF OF CHANGES ==="
diff -ruN $EXCLUDE "$TMP_DIR/.agents" .agents || true
```

### Phase 2: Proposal
Analyze the terminal output of the diff script. You must identify:
1. **New Skills**: Entirely new agent workflows created locally that don't exist upstream.
2. **Modified Rules/Skills**: Core improvements made to existing standard skills or core rules.

> [!WARNING]
> DO NOT attempt to "clean up" or lint the local additions. You must take the user's raw files exactly as they are currently written locally. Do not include anything from the `docs/solutions/` directory.

Present a concise summary to the user:
> *"I have analyzed your local agent ecosystem. Here are the enhancements that differ from the central repository:"*
> - *[List changes clearly]*
> 
> *"Which of these changes would you like me to contribute back to the central repository via a Pull Request?"*

**STOP and wait for the user to confirm.**

### Phase 3: Creating the Pull Request
Once the user explicitly specifies which changes to contribute back, you will submit the Pull Request. 

**PR Content Directive:** Generate a descriptive PR title and body based on the user's approved selection from Phase 2. The title must summarize the specific changes (e.g., *"Add brainstorm skill, refine review-plan Phase 2 logic"*). The body must list each contributed file with a one-line explanation of what it does or what changed. Do not use generic placeholder text.

Select the appropriate method based on your capabilities:

**Method A: Native MCP Capabilities (Preferred)**
If you are equipped with the GitHub MCP server (e.g., `github-mcp-server` tools):
1. Use the `mcp_github-mcp-server_fork_repository` tool to fork `marcus-friction/agents`.
2. Fetch the base `sha` from the main branch and explicitly create a random branch name for the PR using `mcp_github-mcp-server_create_branch`.
3. Read the contents of the chosen local files using your local file reading tools.
> [!CAUTION]
> You must push ONLY the specific files the user approved in Phase 2. Do not push the entire diff set. Ensure all pushed files are strictly within the `.agents/` path — never leak the user's private project files.
4. Push all approved changes simultaneously using `mcp_github-mcp-server_push_files` to your forked repository branch.
5. Execute `mcp_github-mcp-server_create_pull_request` against the base repository `marcus-friction/agents`.

**Method B: Fallback CLI Generation**
If you do not have MCP integration, you MUST first verify that the user has the GitHub CLI installed and authenticated by executing `gh auth status` in their terminal before generating the script below.

If `gh` is authenticated, output this absolutely safe structural `gh` script for the user to execute:

> [!CAUTION]
> Never run `gh repo fork --remote` inside the user's actual project directory. Doing so binds the upstream repo to their private commit history. You MUST stage the PR in a pure transient directory.

```bash
set -e

# 1. Isolate the PR environment completely outside the user's project
PROJECT_ROOT=$(git rev-parse --show-toplevel)
PR_DIR=$(mktemp -d)

# Resilient Cleanup Trap
trap 'cd "$PROJECT_ROOT" && rm -rf "$PR_DIR"' EXIT

cd "$PR_DIR"

# 2. Fork the repo into the sandbox
gh repo fork marcus-friction/agents --clone
cd agents

# 3. Create the staging branch
git checkout -b feature/agent-contribution

# 4. Copy authorized changes perfectly (Agent should generate exact 'cp' commands)
# Example: cp -a "$PROJECT_ROOT/.agents/skills/new-skill" ".agents/skills/new-skill"

# 5. Commit and push from the sandbox
git add .
git commit -m "Enhance Agent Ecosystem: [Summary]"
git push -u origin feature/agent-contribution

# 6. Create the PR (Sandbox self-destructs automatically via trap)
gh pr create --repo marcus-friction/agents --title "Enhance Agent Ecosystem: [Summary]" --body "This PR contributes back local ecosystem improvements."
```
