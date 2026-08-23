---
name: update-agentsmd-codex
description: Use when docs/agents/index.md imports change and the Codex-only generated AGENTS.override.md must be refreshed.
license: "MIT"
compatibility: "Windows 11 with Windows PowerShell 5.1+"
metadata:
  author: "nevmerzhitsky"
  version: "1.0"
---

# Generate Codex Agent Instructions

Run this skill after adding, removing, reordering, or editing instructions reachable from `docs/agents/index.md`.

```powershell
& "<skill-directory>\scripts\Update-CodexAgentsOverride.ps1" -RepositoryRoot "<repository-root>"
```

`RepositoryRoot` is required and has no default value. Pass it using the named-argument notation `-RepositoryRoot "<absolute-path>"`, where `<absolute-path>` is the absolute path to the root of the repository whose `AGENTS.override.md` must be generated. Keep the path quoted so repositories with spaces are supported.

The script resolves the manifest imports recursively, preserves first-occurrence order, and writes their expanded content to root `AGENTS.override.md`. Codex reads this override in preference to `AGENTS.md`; do not edit the generated file manually. Review the resulting diff before committing it.

If the `git` utility is available on the system, then, after the skill runs successfully, the user should be suggested to add the `AGENTS.override.md` file to `.gitignore`, if that file is not already ignored (check by running `git check-ignore AGENTS.override.md`).
