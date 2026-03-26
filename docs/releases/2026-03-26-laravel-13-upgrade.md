# 2026-03-26 — Framework Bump to Laravel 13 (v1.3.0)

## Summary
Upgraded baseline standards to Laravel 13 and Pest 4. The agent rules have been updated to reflect the new framework versions, ensuring that AI coding agents follow the latest conventions and best practices for the ecosystem.

## Changes
- **Framework Upgrade:** Bumped target framework from Laravel 12.x to Laravel 13.x in `.agent/rules/20_stack.md`.
- **Testing Upgrade:** Bumped target testing framework from Pest 3.x to Pest 4.x in `.agent/rules/20_stack.md` and `README.md`.
- **Skill Updates:** Updated `laravel` skill to reference Laravel 13 methods, structures, and capabilities natively. 
- **Release Tracking:** Added v1.3.0 release entry to `README.md`.

## Notes
- Laravel 13 requires PHP 8.3+. Our stack already targeted PHP 8.4, so no underlying PHP version changes were necessary in the standard configuration.
- Any project utilizing these rules should assure they are running PHP 8.4 and have bumped `phpunit/phpunit` to `^12.0`, `pestphp/pest` to `^4.0`, and `laravel/boost` to `^2.0` in their `composer.json` before prompting agents for code generation.
