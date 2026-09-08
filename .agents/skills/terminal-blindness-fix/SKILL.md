---
name: terminal-blindness-fix
description: Diagnose and fix "Terminal Blindness" in local VS Code only when the user explicitly requests it or command output has been observed blank, unreadable, or missing because capture failed. Do not run during routine project setup.
---

# Terminal Blindness Fix

VS Code shell integration can sometimes prevent terminal output capture. Use
this workflow only after an observed blank, unreadable, or missing capture, or
when the user explicitly requests the fix. Normal terminal output or routine
project setup is not a trigger.

1. Confirm the host is local VS Code and distinguish capture failure from a
   command that legitimately emitted no output. An explicit bounded fix request
   may proceed directly within that scope after inspection.
2. Inspect `.vscode/settings.json`, its existing parents, and `.gitignore` without
   following symlinks or replacing unrelated settings.
3. If the failure was only observed and the accepted task did not authorize a
   settings change, present the exact patch and stop before the settings write.
   Do not continue until that exact document patch is approved; then revalidate
   the target and parent.
4. Minimally merge this setting into the physical project file:
   ```json
   {
       "terminal.integrated.shellIntegration.enabled": false
   }
   ```
5. Change `.gitignore` only when the scoped request includes making the setting
   trackable and an exception such as `!.vscode/settings.json` is actually
   necessary.
6. Re-run one previously unreadable command and report whether capture works. Do
   not broaden the fix when the failure has a different cause.
