# Agent Instructions

> [!WARNING]
> **INSTRUCTION BUDGET MANAGEMENT**
> Do not read all files in this router blindly. You must respect the LLM instruction budget. 
> Only load `ALWAYS ON` rules natively, and implement **progressive disclosure** by fetching `CONTEXTUAL RULES` *only* when the specified conditions actively apply to the task at hand.

This file serves as the root router for AI coding agents working in this repository. 
When executing tasks, agents MUST consult the relevant rule files linked below based on their trigger conditions.

## Global Rules (Always On)
These rules dictate persona, boundaries, and fundamental architecture. You MUST read and abide by these during every session.

- `[.agents/rules/00_meta.md](.agents/rules/00_meta.md)` : **READ FOR** the mandatory agent persona, conduct guidelines, and anti-patterns.
- `[.agents/rules/10_project.md](.agents/rules/10_project.md)` : **READ FOR** the project's vision, specific goals, target users, and constraints.
- `[.agents/rules/20_stack.md](.agents/rules/20_stack.md)` : **READ FOR** the strict tech stack boundaries, directory structure, and dependency update discipline.
- `[.agents/rules/60_infrastructure.md](.agents/rules/60_infrastructure.md)` : **READ FOR** the environment matrix, port configurations, and service infrastructure rules.

## Contextual Rules (Model Decision)
These rules are conditionally triggered. Only read these files if the conditions defined below actively match your current task.

### Development & Framework Standards
- `[.agents/rules/21_standards_laravel.md](.agents/rules/21_standards_laravel.md)` : **APPLY WHEN** writing, reviewing, or modifying Laravel backend code (PHP, Eloquent, controllers).
- `[.agents/rules/22_standards_nuxt.md](.agents/rules/22_standards_nuxt.md)` : **APPLY WHEN** writing, reviewing, or modifying Nuxt/Vue frontend code (components, stores, composables).
- `[.agents/rules/25_caching_performance.md](.agents/rules/25_caching_performance.md)` : **APPLY WHEN** working with Redis, caching logic, HTTP response headers, or CDN optimization.
- `[.agents/rules/26_email.md](.agents/rules/26_email.md)` : **APPLY WHEN** implementing or modifying email templates, notifications, and transactional mailings.
- `[.agents/rules/50_security.md](.agents/rules/50_security.md)` : **APPLY WHEN** handling input validation, API keys, authentication logic, file uploads, or authorization.

### UI, Design & Accessibility
- `[.agents/rules/11_design.md](.agents/rules/11_design.md)` : **APPLY WHEN** writing Tailwind classes, implementing UI structures, or making general visual design choices.
- `[.agents/rules/23_design_system.md](.agents/rules/23_design_system.md)` : **APPLY WHEN** building cohesive UI components, picking colors/typography, or applying strict spacing tokens.
- `[.agents/rules/24_accessibility.md](.agents/rules/24_accessibility.md)` : **APPLY WHEN** building forms, navigation menus, modals, or any interactive visual elements requiring ARIA/WCAG compliance.

### Workflows & Operations
- `[.agents/rules/40_workflow_development.md](.agents/rules/40_workflow_development.md)` : **APPLY WHEN** initiating branches, crafting PRs, or executing git lifecycle hooks.
- `[.agents/rules/41_workflow_testing.md](.agents/rules/41_workflow_testing.md)` : **APPLY WHEN** writing or reviewing Pest/Vitest tests, or responding to architecture test requirements.
- `[.agents/rules/42_workflow_debugging.md](.agents/rules/42_workflow_debugging.md)` : **APPLY WHEN** actively troubleshooting errors, running isolation tests, or trying to reproduce a bug.
- `[.agents/rules/43_workflow_deployment.md](.agents/rules/43_workflow_deployment.md)` : **APPLY WHEN** deploying code, managing environment progression, or dealing with server pipelines.
- `[.agents/rules/44_workflow_database.md](.agents/rules/44_workflow_database.md)` : **APPLY WHEN** constructing migrations, building seeders, or initiating any destructive database resets.


## Agent Ecosystem & Capabilities
Beyond these core rules, this repository contains an arsenal of specialized Skills. **Do NOT blindly read these directories.** 
Instead, be aware that they exist. If your task requires complex execution (e.g., project planning, design systems, architectural testing, rigorous code review, or framework-specific setups), you MUST:
1. Scan the `README.md` for a full index of available skills.
2. Manually read specific execution skills in `.agents/skills/`.
