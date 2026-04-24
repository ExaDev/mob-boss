---
name: status
description: Report the state of in-progress mob-boss dispatches. Shows stale dispatches, unprocessed signals, pending feedback, and current phase. Use to check what's happening without starting or resuming work.
disable-model-invocation: true
user-invocable: true
allowed-tools: Read Glob Bash(ls .mob-boss/*) Bash(ls -la .mob-boss/*) Bash(cat .mob-boss/*) Bash(tail * .mob-boss/*) Bash(head * .mob-boss/*) Bash(wc -l .mob-boss/*) Bash(wc -l ~/.mob-boss/*) Bash(bash ${CLAUDE_SKILL_DIR}/../dispatch/preamble.sh)
---

# Mob Boss — Status

Report the current state of in-progress dispatches.

## Context

```!
bash "${CLAUDE_SKILL_DIR}/../dispatch/preamble.sh"
```

## Your Task

Read the preamble output and present a clear status report:

1. **Global state** — how many dispatches completed, active experiments, protocol version
2. **Per-package state** — any in-progress dispatches, their phase, unprocessed signal files, pending feedback
3. **Project expert** — whether orientation exists, knowledge base size
4. **Stale dispatches** — if `RESUME_OR_FRESH` was flagged, surface it prominently

If there are no in-progress dispatches, say so clearly.

Do NOT start a Monitor. Do NOT modify any state. This is a read-only check.
