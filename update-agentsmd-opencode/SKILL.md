---
name: update-agentsmd-opencode
description: Use when docs/agents/index.md imports change and opencode.json.instructions must be synchronized in the manifest-defined order.
license: "MIT"
compatibility: "Windows 11 with Windows PowerShell 5.1+"
metadata:
  author: "nevmerzhitsky"
  version: "1.0"
---

# Update OpenCode Agent Instructions

Run this skill after adding, removing, or reordering `@` imports reachable from `docs/agents/index.md`.

```powershell
& "<skill-directory>\scripts\Update-OpenCodeInstructions.ps1" -RepositoryRoot "<repository-root>"
```

`RepositoryRoot` is required and has no default value. Pass it using the named-argument notation `-RepositoryRoot "<absolute-path>"`, where `<absolute-path>` is the absolute path to the root of the repository whose `opencode.json` must be updated. Keep the path quoted so repositories with spaces are supported.

The script resolves imports recursively, preserves first-occurrence order, replaces only `opencode.json.instructions`, and validates that every resolved file exists. Review the resulting diff. Restart OpenCode after changing `opencode.json`; it loads configuration only at startup.
