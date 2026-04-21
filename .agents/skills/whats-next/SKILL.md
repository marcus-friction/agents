---
name: /whats-next
description: Analyzes the current project repository and workflows to provide a high-level status report. Use this skill when the user asks for a status update, wants to know "what's next", asks where development left off, or needs a summary of recent work to regain context. Do NOT use this skill if the user is asking you to actually implement the next feature, commit code, or search the codebase for specific files.
---

# /whats-next

This skill allows the agent to analyze the current workspace, determine where the team is in the development cycle, summarize recent accomplishments, and suggest the next best course of action.

## When to Use

Use this skill when the user asks:
- "What's next?"
- "Where did we leave off?"
- "What should I work on today?"
- "Give me a status update on the project"
- "What is the next step in our plan?"

## Context Gathering (Tool-Agnostic)

You must gather context by inspecting generic aspects of the local repository and the current working environment. Do NOT look for hardcoded platform directories (e.g. `~/.gemini/antigravity` or Claude memory paths) as this skill must remain tool-agnostic. 

Instead, perform the following to gather context:

1. **Verify Workspace Root:**
   - Execute `git rev-parse --show-toplevel` and navigate to the project root. You must be at the root to avoid missing the context files listed below.
2. **Check Git State:**
   - Execute `git status` to see if there are staged/unstaged changes, or if the working tree is clean.
   - Execute `git log -n 5 --oneline` to read the subjects of the most recent commits.
3. **Review Planning Documents:**
   - Check the project root for common planning or status files: e.g., `task.md`, `ROADMAP.md`, `implementation_plan.md`, `TODO.md`. Read them if they exist.
4. **Review Release Documents:**
   - Check if there are recent files in `docs/releases/`. If there are, view the most recent one to understand recently merged scope.
5. **Introspect Agent Memory:**
   - Consult your native memory, persistent context annotations, or Knowledge Items available natively in your host environment.

## Development Cycle Assessment

Once you have gathered the context, analyze where the current repository stands in the typical workflow cycle: `/plan -> Implement -> /review -> /wrap`:
- **/plan**: No active coding tasks, `implementation_plan.md` exists but no git changes yet.
- **Implement**: Git has unstaged/staged code changes, tests might be missing, work is actively in flight.
- **/review**: Code is written, tests are present, perhaps pending a `review-gstack` or similar pre-merge audits.
- **/wrap**: The feature is complete and merged/committed, waiting for release docs or ready to start the next plan.
- **Idle**: Clean working tree and no active roadmap items.

## Reporting Format

You MUST format your output EXACTLY as follows using the provided markdown headers and bullet points. Be specific, concise, and **use plain English** intended for a non-technical stakeholder or product manager. **Do not expose raw git mechanisms** (like "commits" or "branches") unless absolutely necessary. Focus on **what was achieved** and what outcomes are next.

```markdown
# 🧭 What's Next: Project Status

**Executive Summary:** [Provide a 1-2 sentence plain-language summary so a stakeholder instantly understands the current status in 5 seconds. E.g., "We are currently implementing the user dashboard. The database schema has been verified, and we are working on the frontend layouts."]

## 📍 Current Focus
*   **Stage**: [/plan | Implement | /review | /wrap | Idle] - [1-sentence plain English explanation of why we are in this state. E.g., "Code is written but we need to run tests before considering it finished."]
*   **Active Area**: [What feature or component is currently being worked on? E.g., "User Authentication System"]

## 🕰️ Recent Updates
*   [Bullet point summary of the most recently completed features, bug fixes, or milestones. Frame these as outcomes, e.g., "Completed the user dashboard UI" instead of "Staged files for dashboard."]
*   [Second accomplishment if applicable]

## 🚧 Currently in Progress
*   [What specific tasks are actively half-finished or open right now?]
*   *(If none, state: "No features are currently mid-development.")*

## 🎯 Immediate Next Steps
1.  **[High Priority Task]**: [Detailed description of what specifically needs to be done right now, explained in a way a product manager would understand. E.g., "Run automated tests to verify the newly added API endpoint is stable", or "Draft the initial design for the user dashboard."]
2.  **[Secondary Task]**: [If applicable, the next sequential step.]

## 💡 Agent Suggestions
*   [Proactive recommendation from the agent to support the development lifecycle, phrased accessibly. E.g., "Run the pre-landing review before considering this complete."]
```
