# Dispatch Context — <dispatch-slug>

**Written**: Phase 1e (after user approval of the combined design at end of Phase 1d)
**Used**: Read by every developer/reviewer/architect/designer/expert spawn in this dispatch as the standing-context reference — replaces inline re-pasting of the plan across resumes.
**Update triggers**: user-approved amendments during the dispatch (add a ## Amendments section at the bottom rather than rewriting above).

---

## Task

<One paragraph: the user-facing description of what's being built and why.>

## Resolved user decisions (from Phase 1d approval)

<Enumerated list of the decisions the user confirmed during the approval exchange — scope boundaries, picked options, deferrals. Include every answered "open question" so spawns don't re-ask.>

## Approved design

The architect and designer worked together in Phase 1 (iteratively, not sequentially) to produce this agreed design. It is one artifact jointly owned by both roles — neither side is primary. Consumers (developer, reviewer) treat it as a unified contract.

### Structure and decomposition

<The approved architectural decisions: slice breakdown, file map, dependencies between slices, reuse analysis, test requirements, security considerations, risk flags.>

### Visual and interaction design

<When a prototype exists this section is a CONTRACT for the developer and reviewer — not a free-text summary. It MUST include:

**Prototype path** — absolute path to the HTML file (e.g. `<package>/src/<feature>/frontend/design/<feature-name>/index.html`). The developer opens this BEFORE writing any UI code; the feature-tier reviewer opens it during visual compliance.

**Enumerated states** — list every state the prototype depicts by name (e.g. "1. Idle  2. Running  3. Completed with inaccessibles (expanded)  4. Failed"). The developer's implementation MUST have a corresponding state for each. Deviations require a `DESIGN_QUESTION_*.md` signal before implementing.

**Design decisions** — non-obvious tokens or patterns the designer chose that the developer must reuse verbatim (e.g. "Running state uses amber outline, NOT primary blue — intentional secondary-tier signal"). Include the designer's `@expert:` tags here so they propagate.

**Flagged integration points** — places where the prototype renders fields the architect didn't originally specify (e.g. "prototype renders `parentTitle`; backend adds this to the inaccessible record shape").

If no UI work is involved in this dispatch, write "N/A — pure backend" and skip the sub-fields.>

### Integration points

<Where structure and visual constraints meet: data shapes the UI needs from the backend, API boundaries the frontend assumes, entity relationships rendered visually. This section exists because these decisions are genuinely shared between architect and designer — neither owns it alone.>

## Iteration log

How the design evolved during Phase 1. Not an audit of blame, just the history of the conversation so later spawns understand why the final shape is what it is.

- **Round 1**: <what each role produced, what was flagged by the other>
- **Round 2** (if any): <what was revised, by whom, why>
- <etc.>

If Phase 1 was single-round (no reconciliation needed), write: "Single round — initial outputs were coherent, no revisions needed."

## Project-expert orientation (snapshot)

<First ~40 lines of the Orientation section from `.mob-boss/expert/agent.md` at dispatch start. Snapshotted so spawns have the orientation even if the expert re-curates mid-dispatch.>

## Signal/feedback paths

- Signals: `<package>/.mob-boss/signals/`
- Feedback: `<package>/.mob-boss/feedback/`
- Progress log: `<package>/.mob-boss/progress/events.jsonl`

## Agent profile paths

- Developer: `~/.claude/skills/mob-boss/agents/main/developer.md`
- Reviewer: `~/.claude/skills/mob-boss/agents/main/reviewer.md`
- Architect: `~/.claude/skills/mob-boss/agents/main/architect.md`
- Designer: `~/.claude/skills/mob-boss/agents/main/designer.md`
- Project expert: `<package>/.mob-boss/expert/agent.md` (per-package state)

---

## Amendments

Append-only log of changes to the design after the initial approval. Each entry: date, what changed, who raised it, why, user-approval reference. Spawns read top-down; later spawns see amendments naturally without the upper body being rewritten.

<!-- Example:
### 2026-04-17 — Deferred Slice 6 to Phase 1.6
Raised by: user (mid-dispatch scope check)
Reason: Keep Phase 1.5 diff reviewable; `/projects/[id]` refactor deserves its own round.
Impact: Final tier-3 review reviews Slices 1–5 only.
-->
