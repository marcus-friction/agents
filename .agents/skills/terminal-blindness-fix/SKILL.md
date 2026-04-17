---
name: terminal-blindness-fix
description: Fixes "Terminal Blindness" in local VS Code environments where shell integration prevents the agent from reading terminal output. Run this skill when setting up a new project or if terminal outputs from commands appear blank.
---

# Terminal Blindness Fix

If the agent runs in a local VS Code environment, shell integration can cause terminal output capture to fail ("terminal blindness"). This skill sets up exactly what's needed to disable it for the local project.

1. Check if `.vscode/settings.json` exists in the project root. Create it if it doesn't.
2. Ensure the following configuration is present to disable shell integration:
   ```json
   {
       "terminal.integrated.shellIntegration.enabled": false
   }
   ```
3. Update `.gitignore` to allow this setting to be committed if necessary (e.g., adding an exception `!.vscode/settings.json` if `.vscode/` is ignored by default).
