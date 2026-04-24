---
name: close-out
description: Close out an in-progress mob-boss dispatch without further work. Archives signals and feedback, generates a summary, updates metrics, and runs project-expert curation.
disable-model-invocation: true
user-invocable: true
allowed-tools: Agent Read Write Edit Grep Glob Skill TaskCreate TaskUpdate TaskList TaskStop Bash(echo * >> *) Bash(mkdir -p *) Bash(mv .mob-boss/*) Bash(ls .mob-boss/*) Bash(ls -la .mob-boss/*) Bash(ls -la ~/.mob-boss/*) Bash(cat .mob-boss/*) Bash(cat ~/.mob-boss/*) Bash(wc -l .mob-boss/*) Bash(wc -l ~/.mob-boss/*) Bash(wc -l *) Bash(git log:*) Bash(bash ${CLAUDE_SKILL_DIR}/../dispatch/preamble.sh) Write(.mob-boss/**) Edit(.mob-boss/**) Write(~/.mob-boss/**) Edit(~/.mob-boss/**)
---

# Mob Boss — Close Out

Close out an in-progress dispatch without doing further work. Runs the full close-out protocol: archive, summary, metrics update, expert curation.

## Context

```!
bash "${CLAUDE_SKILL_DIR}/../dispatch/preamble.sh"
```

## Your Task

Run the close-out protocol on the in-progress dispatch:

1. **Archive** — create `<package>/.mob-boss/archive/<YYYY-MM-DD-slug>/` and move `signals/`, `feedback/` contents into it. Snapshot the final progress events into the archive directory.
2. **Generate summary** — write `<archive>/summary.md` with:
   - What was built (from the dispatch context and progress log)
   - Final review outcome (if a review ran) or "closed without completion"
   - Issue counts per tier (from any review metrics)
   - Collaboration metrics
   - Follow-up tickets worth filing
   - Phase 3 user-facing report
3. **Update global metrics** — append review metric JSONL lines to `~/.mob-boss/metrics/team-log.jsonl` with `"project":"<package-identifier>"`. Update `~/.mob-boss/metrics/summary.md`. Verify the write landed (`wc -l`).
4. **Project expert curation** — if facts were surfaced during the dispatch, spawn the project expert for curation. Otherwise note the deferral.
5. **Log `dispatch_closed`** — append the final event to `events.jsonl`.
6. **Report to the user** — present the summary and any recommendations.

Do NOT start a Monitor. Do NOT dispatch any new work.
