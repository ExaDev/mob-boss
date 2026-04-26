---
name: init
description: Verify mob-boss setup and seed global state. Locates package root, seeds ~/.mob-boss/ from canonical profiles, checks for optional file-watcher, and confirms readiness. Run this before your first dispatch or after updating the plugin.
disable-model-invocation: true
user-invocable: true
allowed-tools: Read Glob Bash(bash ${CLAUDE_SKILL_DIR}/../dispatch/preamble.sh) Bash(ls -la ~/.mob-boss/*) Bash(cat ~/.mob-boss/*) Bash(wc -l ~/.mob-boss/*) Bash(which *)
---

# Mob Boss — Init

Verify that mob-boss is set up correctly and ready for dispatches. Run this before your first dispatch or after updating the plugin.

## Context

```!
bash "${CLAUDE_SKILL_DIR}/../dispatch/preamble.sh"
```

## Your Task

Run the preamble (it seeds `~/.mob-boss/` if needed), then verify the environment:

1. **Platform file-watcher** — if `fswatch` (macOS) or `inotifywait` (Linux) is on PATH, report "native watcher available". If missing, report "polling fallback — install fswatch/inotify-tools for instant events". This is not a blocker.
2. **Package root** — confirm a package marker was found (CLAUDE.md, package.json, etc.)
3. **Global state** — confirm `~/.mob-boss/` was seeded with agents, metrics, and changelog
4. **Per-package state** — confirm `.mob-boss/` was initialised with signals/, feedback/, archive/, progress/, expert/
5. **Agent profiles** — list the evolved profiles at `~/.mob-boss/agents/main/` and confirm all five roles are present (developer, designer, architect, reviewer, project-expert)

Present a clear readiness report. If anything is missing, explain what needs to be fixed.

Do NOT start a Monitor. Do NOT modify any state beyond what the preamble seeds.
