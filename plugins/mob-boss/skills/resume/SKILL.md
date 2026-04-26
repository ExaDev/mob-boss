---
name: resume
description: Resume an in-progress mob-boss dispatch that was interrupted. Reads the progress log, derives current phase, and re-enters the coordination loop.
disable-model-invocation: true
user-invocable: true
allowed-tools: Agent Read Write Edit Grep Glob Skill Monitor TaskCreate TaskUpdate TaskList TaskStop Bash(git status:*) Bash(git log:*) Bash(git diff:*) Bash(git show:*) Bash(git -C:*) Bash(bash ${CLAUDE_SKILL_DIR}/../dispatch/preamble.sh) Bash(echo * >> *) Bash(mkdir -p *) Bash(mv .mob-boss/*) Bash(ls .mob-boss/*) Bash(ls -la .mob-boss/*) Bash(ls -la ~/.mob-boss/*) Bash(cat .mob-boss/*) Bash(cat ~/.mob-boss/*) Bash(tail * .mob-boss/*) Bash(head * .mob-boss/*) Bash(wc -l .mob-boss/*) Bash(wc -l ~/.mob-boss/*) Bash(wc -l *) Bash(find .mob-boss/*) Bash(touch .mob-boss/*) Bash(sleep *) Write(.mob-boss/**) Edit(.mob-boss/**) Write(~/.mob-boss/**) Edit(~/.mob-boss/**)
---

# Mob Boss — Resume

Resume an in-progress dispatch that was interrupted (session ended, rate-limited, or paused).

## Context

```!
bash "${CLAUDE_SKILL_DIR}/../dispatch/preamble.sh"
```

## Your Task

Resume the in-progress dispatch:

1. **Start the Monitor** — invoke the Monitor tool with the command emitted by the preamble. Pass `persistent: true`. Non-negotiable.
2. **Read the progress log** — `.mob-boss/progress/events.jsonl`. Derive the current phase and outstanding work from the last events.
3. **Read the dispatch context** — `.mob-boss/dispatch-context.md` contains the approved design, user decisions, iteration log, and any mid-dispatch amendments.
4. **Check for unprocessed signals and feedback** — list `.mob-boss/signals/` and `.mob-boss/feedback/` for anything not yet processed.
5. **Re-enter the coordination loop** — invoke the team-manager skill inline via `Skill({ skill: "team-manager", args: "resume" })`, passing:
   - The dispatch context file path
   - The current phase
   - The variant in use
   - The path to evolved agent profiles at `~/.mob-boss/agents/main/`

If no in-progress dispatch is detected, report that to the user and suggest `/mob-boss:status` or `/mob-boss:dispatch <task>`.

Follow all the same rules as a full dispatch: progress tracking, patience rules, and close-out protocol.
