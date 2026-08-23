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
& scripts\Update-OpenCodeInstructions.ps1
```

The script resolves imports recursively, preserves first-occurrence order, replaces only `opencode.json.instructions`, and validates that every resolved file exists. Review the resulting diff. Restart OpenCode after changing `opencode.json`; it loads configuration only at startup.
