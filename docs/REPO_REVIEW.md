# Repository Review and Capability Roadmap

This review assesses `odscex` against its stated goal: helping administrators manage SharePoint shortcuts in OneDrive for individual users and organization-scale desired-state assignments.

## Review scope

The review covered:

* Public module surface in `src/public/`.
* Private Microsoft Graph and path helper implementation in `src/private/`.
* Module packaging metadata in `src/odscex.psd1` and loader behavior in `src/odscex.psm1`.
* User guidance in `README.md`, `USAGE.md`, and `docs/*.md`.
* Current gaps in automated validation, operational safety, accessibility, and enterprise rollout ergonomics.

## Current strengths

* The module already exposes the core lifecycle commands administrators need: connect, inspect OneDrive drives, create/get/remove shortcuts, converge shortcut state, resolve target users, run desired-state assignments, apply plan files, run Graph batches, and test baseline permissions.
* Existing commands cover both one-off user operations and broad targeting through CSV files, groups, filters, and all users.
* The Graph helper centralizes authentication, request retries, pagination, and national cloud endpoint selection.
* Documentation now presents examples using splatting, which is easier to copy, modify, and audit than long inline commands.

## Priority recommendations

### P0 - Build confidence before broad tenant changes

1. **Add a Pester test suite and CI workflow.**
   * Validate module import, manifest metadata, command discovery, parameter sets, plan parsing, report export, path encoding, retry behavior, and WhatIf behavior.
   * Use mocked Graph responses for unit tests and a separate opt-in integration test profile for real tenants.
   * Add PSScriptAnalyzer to catch style, compatibility, and security regressions.

2. **Add a dedicated plan validation command.**
   * Proposed command: `Test-odscexPlan`.
   * Validate JSON/PSD1 plan schema, required fields, supported target selectors, duplicate shortcut names, invalid states, missing libraries, and relative OneDrive path issues before any tenant mutation.
   * Return structured validation objects and a non-zero CI-friendly failure option.

3. **Add first-class dry-run diff output.**
   * Proposed command: `Compare-odscexShortcutState`, or a `-PlanOnly`/`-Diff` mode on `Invoke-odscexApply`.
   * Show current state, desired state, proposed action, and reason for every target user.
   * Export the diff to CSV/JSON so administrators can approve changes before applying them.

4. **Improve report durability and resume behavior.**
   * Persist progress incrementally instead of writing only at the end of an assignment.
   * Store stable resume metadata such as run ID, target hash, current index, and plan item name.
   * Add `-ResumePath` so failed runs can resume without manually calculating `-ResumeFrom`.

### P1 - Make onboarding and authentication easier

5. **Support more authentication modes.**
   * Add managed identity support for Azure Automation, Azure Functions, and hosted runners.
   * Add device-code or interactive sign-in for delegated pilot scenarios.
   * Add certificate thumbprint/path lookup so users do not need to construct certificate objects manually.
   * Add environment-variable based authentication for CI/CD pipelines.

6. **Add a permission matrix and readiness command.**
   * Proposed command: `Get-odscexRequiredPermission` or expanded `Test-odscexPermission` output.
   * Map each command and scenario to required Microsoft Graph permissions.
   * Include checks for application permissions, site access, group membership reads, OneDrive provisioning, and selected-permission grants.

7. **Add a guided setup document.**
   * Include Entra app registration steps, certificate creation, least-privilege guidance, admin consent notes, national cloud caveats, and a pilot rollout checklist.
   * Provide separate setup tracks for local administration, CI/CD, and Azure Automation.

### P1 - Improve operator safety and observability

8. **Add structured logging.**
   * Emit run IDs, plan item names, user identifiers, target site/library, Graph request IDs, retry counts, and elapsed time.
   * Support `-LogPath`, JSON Lines output, and redaction of secrets or tokens.

9. **Expose richer error and status objects.**
   * Standardize error categories and status codes for authentication failure, permission failure, target lookup failure, conflict, throttling, and Graph transient failures.
   * Include Graph request IDs and retry metadata in result objects when available.

10. **Add conflict discovery and remediation guidance.**
    * Proposed command: `Find-odscexShortcutConflict`.
    * Identify same-named files/folders/shortcuts, non-shortcut conflicts, target mismatches, and duplicate shortcuts before mutation.
    * Provide recommended `ConflictAction` values for each conflict type.

11. **Add configurable rate limiting.**
    * Replace the current sequential-only assignment behavior with an explicit rate limiter that can safely use concurrency when requested.
    * Respect `Retry-After`, jitter retries, and allow tenant-specific limits.

### P2 - Expand desired-state and targeting capabilities

12. **Publish a JSON Schema for plan files.**
    * Provide editor validation, examples, and CI validation for `shortcuts.json`.
    * Version the plan schema so future changes can be introduced safely.

13. **Support include/exclude target composition.**
    * Allow plans to combine groups, CSV files, filters, all users, and explicit exclusions.
    * Add de-duplication and deterministic target ordering.
    * Add target preview output before assignment.

14. **Add metadata-driven targeting.**
    * Support department, office location, usage location, custom security attributes, or extension attributes.
    * Provide examples that avoid unsafe broad filters.

15. **Support plan variables and environment overlays.**
    * Allow one plan to work across dev/test/prod tenants by substituting site URLs, library IDs, group IDs, and report paths.
    * Keep secrets out of plan files.

16. **Add generated sample plan templates.**
    * Proposed command: `New-odscexPlanTemplate`.
    * Generate starter JSON for group, CSV, filtered, and all-user scenarios.

### P2 - Improve accessibility and documentation

17. **Add task-focused quickstarts.**
    * Create short pages for common workflows: pilot one user, assign to a group, assign from CSV, remove from a population, dry-run a plan, and recover from a failed run.
    * Include expected outputs and troubleshooting sections.

18. **Add migration guidance from `odsc-ev`.**
    * Document command rename mapping, module uninstall/install steps, script migration tips, and compatibility considerations.
    * Consider temporary aliases from old command names to new command names with deprecation warnings.

19. **Improve external help generation.**
    * Adopt a documentation generation workflow so markdown docs and XML help stay in sync with command parameters.
    * Add examples for every parameter set and all supported output formats.

20. **Add accessibility-oriented docs conventions.**
    * Keep examples copy-paste friendly, avoid line-continuation backticks, explain placeholders clearly, and provide table summaries for visual scanning.
    * Add plain-language descriptions of Graph permissions and tenant-wide impact.

### P3 - Enterprise packaging and lifecycle

21. **Add release automation.**
    * Validate manifest, run tests, build module artifacts, generate help, sign scripts when configured, publish GitHub releases, and optionally publish to PowerShell Gallery.

22. **Add support policy and compatibility matrix.**
    * State supported PowerShell versions, operating systems, Microsoft clouds, and Microsoft Graph API assumptions.
    * Document how breaking changes are handled.

23. **Add performance benchmarks.**
    * Benchmark assignment throughput, throttling behavior, report writing, and large target resolution.
    * Use benchmark results to set safe defaults for `ThrottleLimit` and retry settings.

24. **Add localization-ready messages.**
    * Move user-facing strings into a structure that can be localized later.
    * Keep structured result values invariant while allowing messages to be translated.

## Suggested implementation order

1. Add Pester/PSScriptAnalyzer/CI and a mocked Graph test harness.
2. Add `Test-odscexPlan` plus a JSON Schema for plan files.
3. Add dry-run diff/report output for plans and assignments.
4. Add durable incremental reporting and `-ResumePath`.
5. Add managed identity and certificate-thumbprint authentication.
6. Expand permission/readiness checks and onboarding docs.
7. Add structured logs, richer error metadata, and conflict discovery.
8. Add target composition and plan template generation.

## Review notes

The highest-impact improvements are not new shortcut operations; they are confidence-building capabilities around validation, preview, reporting, resumability, authentication, and documentation. Those additions would make the module more useful for its stated purpose because shortcut assignment is usually a tenant-wide administrative operation where operators need predictable plans, auditable results, clear recovery paths, and safe defaults.
