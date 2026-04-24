# Mob Boss Changelog

## v1.8 — 2026-04-21

**Type**: Efficiency refinements — review batching, model tiering, lazy expert curation (direct user direction)

**Changed**:
- `agents/main/developer.md` (tier-cadence batching rule)
- `team-manager/SKILL.md` (reviewer model tiering in Phase 2b + expert curation threshold in Phase 2d)
- `mob-boss/SKILL.md` (close-out step 4 updated to match lazy curation)

**What**:

- **developer.md — Tier-cadence batching.** Unit signals are now optional for low-complexity plumbing chunks (additive migrations, pure types/schema, trivial wiring with no conditional logic). Skip the unit signal for those and roll them into the next composite signal with a "Unit skipped — rolled in here:" note. One composite signal per slice — no multiple composite reviews for the same slice. If 2+ prior composite signals were already APPROVE / APPROVE WITH WARNINGS, roll remaining composite-scoped chunks directly into tier-3 rather than sending another composite review. This formalises what task 7 did naturally (C5–C9 rolled to tier-3 after C0/C3+C4 composites were clean).

- **team-manager/SKILL.md Phase 2b — Reviewer model tiering.** Reviewer spawn model is now tier-dependent: unit → haiku, composite → sonnet, feature → sonnet. Unit-tier reviews check local correctness against well-defined rules — haiku is adequate and ~80% cheaper. Composite and feature tiers involve cross-unit reasoning where sonnet earns its cost. Feature tier stays at sonnet; tier-3 thoroughness comes from scope (full feature review), not model depth.

- **team-manager/SKILL.md Phase 2d — Lazy expert curation.** Expert close-out curation is now conditional: skip when fewer than 3 `@expert:` facts surfaced AND no Orientation amendment is needed AND this is not the first dispatch (knowledge base already seeded). Below threshold, note the deferral in Phase 3 and carry facts forward to the next dispatch that crosses it. This avoids spawning the expert for clean, low-information dispatches where the knowledge base gains nothing.

**Evidence (7-task baseline)**:

- Task 7 (most efficient, ~2 hours) arrived at its efficiency by naturally batching C5–C9 into tier-3. Formalising this as a rule gives every future dispatch the same benefit without relying on the developer outpacing review cadence.
- 7 tasks × ~11 reviews average = ~77 incremental reviews. Roughly half were unit-tier. Moving unit reviews to haiku reduces their cost ~80% without quality risk at that scope.
- Expert curation cost is constant per dispatch regardless of fact count. Tasks 5+7 produced 0–3 and 21 facts respectively — the constant spawn cost only makes sense when facts are substantial. Deferred facts carry forward; nothing is lost.

**Expected improvement**:
- Unit-tier review token cost down ~80%.
- Clean dispatches with 2+ approved composites skip the intermediate composite reviews and go to tier-3 — fewer total spawns.
- Expert curation only fires when there's genuine new knowledge to integrate.

**Source**: Direct user direction (session 2026-04-21). User: "features are taking a little too long and costing too many tokens." Three recommendations presented from 7-task data analysis; all three explicitly approved. No experiment — direct merge into main.

---

## v1.7 — 2026-04-18

**Type**: Architect + team-manager phase-shape discipline — vertical-first slicing (direct user direction, same session)

**Changed**:
- `agents/main/architect.md` (new "Phase shape — vertical-first, horizontal-within" section)
- `team-manager/SKILL.md` (new Phase 1c-bis gate before user presentation)
- `packages/clearkstake-back-office/docs/plans/frontend-di-refactor-audit.md` (restructured from F1/F2/B1/D1 horizontal → V1-V10 vertical)
- new user-memory `feedback_vertical_phase_horizontal_chunks.md`

**What**:

- **architect.md — "Phase shape — vertical-first, horizontal-within"** (new non-negotiable section). Every phase (user-visible dispatch) must be a vertical slice ending in demonstrable working functionality end-to-end. Within a phase, chunks may be horizontal if efficient. First phase of a refactor must be the smallest working exemplar of the target pattern — not scaffolding, not hooks-without-consumers, not services-without-routes. Subsequent phases propagate the exemplar to other surfaces, each itself vertical per-surface. Explicit anti-patterns enumerated (all-hooks phase, all-services phase, all-refactor-no-consumers phase). Section instructs architect to name each phase's deliverable in one sentence during 1d presentation; if the sentence doesn't describe something the user can see working, restructure before presenting. Overrides any dependency-order preference that would produce a horizontal plan.
- **team-manager/SKILL.md — new "Phase 1c-bis gate"** inserted between 1c (reconcile) and 1d (present to user). Reviews every phase in the architect's draft against the vertical-first rule. If any phase reads as horizontal ("all the hooks", "all the services", "scaffolding / migrations with no consumers", "mass-rename without wired deliverable"), team-manager spawns architect for a reconcile round before showing the user. Explicit exception for purely infrastructure tasks (migrate DI container, add proxy everywhere) — flagged to user so they confirm they're getting a plumbing-only dispatch. Adds explicit "One-sentence deliverable per phase" to 1d presentation format.
- **Refactor plan restructured from 4 phases (F1/F2/B1/D1) to 10 phases (V1-V10)**. V1 is the exemplar vertical — Streams settings end-to-end (frontend + backend + DI + proxy + resetInstance + tests) in one dispatch. V2-V9 are propagation phases, each delivering a complete vertical for a specific surface: V2 (People + Clients settings), V3 (Users + AuthService), V4 (Brief types), V5 (fat pages sweep), V6 (Roadmap + link-brief), V7 (BriefCreator decomposition), V8 (brief streaming services), V9 (changelog consolidation + remaining thin routes). V10 is documentation alignment last. Each phase has explicit "One-sentence deliverable", "Close-out demo" (user-exercisable outcome), and "Addresses" (which V* audit items close). Phase ordering specifies which later phases depend on which earlier ones.
- **Memory `feedback_vertical_phase_horizontal_chunks.md`** — captures the vertical-phase / horizontal-chunk preference as a durable feedback item with the "why" (user's recurring observation that dispatches feel slower than not using the skill, specific failure mode of "UI not connected in a phase"), and "how to apply" (architect decomposes vertical, team-manager challenges horizontal phases, propagation phases are allowed and explicitly vertical per-surface).

**Rationale — user evidence**:

- Task 4 close-out: user feedback "Taking longer to implement changes than not using the skill. They may be better tested though." (qualitative wall-clock signal, logged in v1.3 changelog)
- This session: "since using mob boss i feel like im not producing feature any where near as fast, i feel like perhaps the phases are a bit too broken down, for example i get UI that is not connected in a phase, this is not super helpful to me. I would prefer to get a smaller vertical implemented with the patterns for other places so i can see it work end to end, and then later phases applying to other places"
- User refinement on nuance: "there is room for horizontal at lower levels, but vertical at higher levels. at the granular horizontal might make sense to deliver a higher level vertical efficiently"

Two separate user signals converge on the same failure mode: horizontal phasing creates invisible intermediate dispatches (hooks without consumers, components without backends) that don't feel like progress. The quality gains from tiered review don't compensate for the invisibility. Vertical phases give visible working software at every close-out; the wall-clock cost reframes as "shipping a feature" rather than "paying for ceremony". Nuance: this is purely about the user-visible phase boundary — inside a phase, horizontal chunks are fine if they deliver the vertical slice more efficiently.

**Expected improvement**:

- User sees working software at every dispatch close-out. No more "where's my feature?" between phases.
- Wall-clock tradeoff improves perceptibly: same number of dispatches, but each one ships a demoable deliverable, so the time feels spent-not-wasted.
- Architect plans stop producing horizontal-first phasings (which was the natural tendency from dependency-order reasoning). Team-manager catches slipped cases at 1c-bis before user review.
- Refactor plan now has 10 vertical phases with explicit deliverables. When dispatched, the user will see streams settings working end-to-end after V1 — the first demonstrable milestone.

**Source**: Direct user direction (session 2026-04-18, third ask in this session). No experiment — direct merge into main. User's specific failure-mode observation + nuanced refinement on chunk vs phase level make this a high-confidence protocol change.

## v1.6 — 2026-04-18

**Type**: Reviewer stack-guidance infrastructure — React web (direct user direction, same session)

**Changed**:
- `agents/main/reviewer.md` (pointer section added)
- new `agents/main/reviewer/guidance/react-web.md`

**What**:

- **`reviewer/guidance/react-web.md` (new)** — tier-mapped review checklist for React-on-web code. Unit tier covers component-level pattern violations (no direct `fetch` / `useQuery` / `useMutation` in components, thin API clients, hook query-key shape, route Controller pattern including anti-smells like repository bypass / field-loop recording / polling orchestration, thin pages/layouts, module repository-exposure violations, hook/route test co-location) with explicit metric names and severity thresholds for each rule. Composite tier covers three-layer coherence (API client + hook + component alignment, layer-skip detection), intra-slice duplication, service-method composition, boundary test coverage across layers, and shared-extraction flagging. Feature tier covers feature-directory structure, module services-only exposure, layered-access audit across all routes in the feature, proxy-usage consistency, pages-across-feature thinness, cross-feature duplication survey, DESIGN.md reflection of the feature (including applied amendments), and a security re-run reminder. Each rule spells out the metric name, severity, and a template detail string so output is consistent across reviews and dispatches.
- **`reviewer.md`** — new "Stack-specific review guidance" section added after "Discover the project's standards". Same table-of-two-guidances pattern as developer/architect/designer pointers. Instructs stack detection from `package.json` + file extensions, to apply the stack checklist alongside the base tier-aware review, to note absence in output when no stack file exists, and to prefer base rules over stack rules if they ever conflict (they shouldn't — stack extends base).
- **Drift-handling discipline**: `react-web.md` explicitly tells the reviewer how to handle known package drift (e.g. historical back-office modules exposing repositories) — accept with a `@expert:` follow-up rather than BLOCKER, to avoid blocking legitimate work in a partially-migrated package while still surfacing the debt. This prevents the reviewer from treating every instance of drift as a new violation.

**Rationale**:

- Completes the four-agent stack-guidance system: developer / architect / designer / reviewer each have react-web guidance that cross-references into a consistent set of principles. The reviewer guidance is the enforcement layer that closes the loop — without it, the developer's rules are aspirational rather than enforced per-dispatch.
- Tier-mapped structure means unit-tier reviewers don't escalate to architectural findings (violates the existing tier-discipline rule that drives down rework cycles), and tier-3 reviewers catch the systemic patterns that tier-1/2 can't see. Matches how the back-office audit surfaced violations — individual smells at many sites were clearly a feature-tier cohesion finding, not many unit-tier ones.
- Explicit metric names + severity templates in the stack file keep review output consistent enough that the mob-boss metrics layer can aggregate patterns across dispatches without drift.

**Source**: Direct user direction (session 2026-04-18, immediate follow-on to v1.5). No experiment — direct merge into main. User asked whether the reviewer needs guidance given the developer/architect/designer guidance just landed; confirmed yes and approved this draft.

**Expected improvement**:

- `formal_reviewer_catches_inline_would_miss` continues to trend up — specifically the review now has a concrete checklist to catch the V1-V9 classes of violation the back-office audit surfaced (god components, direct `fetch` in components, direct repo calls in routes, fat pages, fat routes, module repo exposure).
- Reviewer output becomes more consistent across dispatches and reviewers (different sonnet spawns) because the checklist pins down both what to flag and how to phrase it.
- The back-office refactor (Phase F1/F2/B1/D1, per v1.5 plan) gets its own enforcement layer — each phase's review can reference this file by name when flagging violations, making remediation targeted.

## v1.5 — 2026-04-18

**Type**: Developer + architect stack-guidance infrastructure — React web (direct user direction, same session)

**Changed**:
- `agents/main/developer.md` (pointer section added)
- `agents/main/architect.md` (pointer section added)
- new `agents/main/developer/guidance/react-web.md`
- new `agents/main/architect/guidance/react-web.md`
- new `packages/clearkstake-back-office/docs/plans/frontend-di-refactor-audit.md` (refactor plan saved for future dispatch)

**What**:

- **`developer/guidance/react-web.md` (new)** — positive-form principles for React-on-web implementation derived from a 2026-04-17 audit of back-office violations against mock-bank + admin-dashboard exemplars. Covers: three-layer data fetching (Component -> Hook -> API Client) with strict layer responsibilities and anti-patterns; component decomposition (god-component threshold, named concern extractions, shared UI/hook extraction when duplicated); thin page / layout files (≤ ~15 lines, no state / effects / fetch / inline sub-components / business logic); ApplicationContext + module DI (async singleton, eager CoreModule, lazy feature modules, `resetInstance()` for tests); services-only module exposure (repositories are internal); thin API routes (Controller pattern); `getApplicationContext()` proxy for circular-dep protection; feature directory structure; order of operations when implementing. The file starts with an explicit "this is structure guidance, not style" preamble mirroring the designer/guidance pattern.
- **`architect/guidance/react-web.md` (new)** — plan-review checklist for React-on-web plans. Covers: file-map structural checks (feature directory shape, api/hooks/components split); page/layout discipline checks; component sizing checks with up-front decomposition requirement; backend routing checks (every route names its service method); module/DI consistency checks (proxy adoption, services-only getters) with a rule to match existing package conventions + flag migrations rather than mix patterns silently; a pre-finalise checklist; tier-aware consultation guidance for React-web questions; explicit "when this guidance does not apply" clause.
- **`developer.md`** — new "Stack-specific implementation guidance" section added after "Discover the project". Same table-of-two-guidances pattern as designer.md (stack implementation guidance vs project conventions). Stack detection via `package.json` + file extensions, falls back to base rules with a user-facing note if no guidance file exists, and instructs the developer to raise `DEVELOPER_ASKS_ARCHITECT` when stack is unclear. Separately instructs: when existing project diverges from stack ideal, follow the current project pattern within the slice and raise a `@expert:` or follow-up rather than mixing patterns silently.
- **`architect.md`** — symmetric "Stack-specific plan-review guidance" section added after "Discover the project's architecture". Same pattern as the developer section. Applies the checklist in Phase 1a before the combined plan is presented to the user in Phase 1d. Reiterates the rule about matching existing project conventions and flagging migration follow-ups explicitly.
- **Refactor plan saved** at `packages/clearkstake-back-office/docs/plans/frontend-di-refactor-audit.md`. Captures the full violation inventory (V1-V10) from the 2026-04-17 audit and consolidates the original 10-phase breakdown into **4 phases** (F1 brief+roadmap frontend decomposition, F2 settings hooks + thin pages/layouts, B1 backend service-layer + DI housekeeping + thin routes, D1 documentation alignment). Each consolidated phase ships as one coherent delivery — responds to user feedback that the original phasing was over-fragmented ("it does not feel like we achieve a lot in a phase"). Plan lives in the back-office repo so the next mob-boss dispatch has a durable input.

**Rationale**:

- Stack-specific guidance scales better as external files than inlined into the base profiles. Mirrors the designer/guidance pattern just landed in v1.4 and the project-expert knowledge-base pattern.
- Separating "stack structural guidance" (in skill, cross-project) from "project conventions" (in repo, per-project) prevents the agents from conflating the two. Each has a clear home.
- Splitting architect vs developer guidance files lets the architect operate as a planning gate without reading the full implementation detail, and lets the developer get deeper implementation guidance without architect-scoped checklist overhead.
- Saving the refactor plan in-repo (rather than as a skill-level doc) keeps it durable across mob-boss sessions and versionable alongside the code it refactors.

**Source**: Direct user direction (session 2026-04-18). User provided the full audit + original plan verbatim; the extraction (positive-form principles for the agents) and the phase consolidation (10 → 4) are my restructuring with user approval on the consolidation call. No experiment — direct merge into main.

**Expected improvement**:

- New React-web features across the monorepo inherit the Component -> Hook -> API Client + services-only module structure without the developer having to re-derive it from exemplar packages each time.
- Architect plans for React-web work catch structural violations before the developer starts coding (e.g. a plan with `useQuery` in a component file gets flagged in Phase 1 rather than surfacing at tier-3).
- Back-office refactor work becomes a properly-scoped dispatch with a durable plan input — the next `Task 5` dispatch can point at the plan file rather than re-litigating what needs to change.
- Future Vue / Svelte / RN stacks slot in as new guidance files — one per agent per stack — without touching the base profiles.

## v1.4 — 2026-04-18

**Type**: Designer mockup-production guidance — React web (direct user direction, post-v1.3 same session)

**Changed**: `agents/main/designer.md`, new `agents/main/designer/guidance/react-web.md`

**What**:

- **New file `designer/guidance/react-web.md`**. Standalone mockup-production guidance for React-on-web projects (Next.js, Vite, CRA — not React Native). Covers: component-first thinking, component = single-root-element rule, Tailwind-only classes, data repetition (3-5 realistic instances, no JS generation), interactive state representation via Tailwind variants + data attributes, the **component manifest** (`@page`/`@component`/`@props`/`@data`/`@state`/`@trigger`/`@fields`/`@submit`/`@error`/`@empty`/`@loading`/`@responsive`/`@variants` annotations inside `<body>`), and anti-patterns to avoid. File preamble makes explicit this is **structure guidance, not style** — project colours/typography/spacing tokens remain in `CLAUDE.md` + `design-decisions.md` + project-expert orientation per existing design-language discovery flow.
- **designer.md — "Stack-specific mockup-production guidance" section** added between the prototype-production section and the revise-freely section. Distinguishes the two kinds of guidance (mockup-production vs project style) in a comparison table, instructs identifying target stack from `package.json` + file extensions + architect-ask-if-unclear, and maps target stacks to their guidance files. Currently react-web is the only stack with a guidance file; React Native, Vue, Svelte are noted as "produce with base rules and flag to user" placeholders for future additions.

**Rationale**:

- Inline all stack-specific guidance in designer.md would bloat the profile (the react-web content alone is ~130 lines — comparable to the base designer role). Adding Vue or RN later would push this further.
- Specialised designer variants (e.g. `designer-react-web.md`, `designer-react-native.md`) would duplicate role content (consultation tiers, output format, file structure) across N files; any change to the core role would need to be applied N times.
- External guidance files mirror the project-expert knowledge-base pattern already in use (`.mob-boss/expert/knowledge/<topic>.md`) — the designer reads the relevant stack file after identifying the target. Scales linearly with stacks. Keeps designer.md focused on the role.
- Explicit split between "mockup production" (lives in the skill, cross-project) and "project style" (lives in the repo, per-project) prevents the designer from drifting guidance between the two — each kind has a clear home.

**Source**: Direct user direction (session 2026-04-18). User provided the react-web content verbatim; architecture decision (external guidance files) was recommended and user-approved. No experiment — direct merge into main.

**Expected improvement**:

- React-on-web mockups arrive with a component manifest and component-boundaried HTML, making developer conversion to React a lift-not-rewrite job.
- No confusion between "how do I structure this" (react-web.md) and "what does it look like" (project's own design-language sources) — they're separately sourced.
- Future stacks (RN, Vue, Svelte) slot in as single new guidance files without touching designer.md.

## v1.3 — 2026-04-18

**Type**: Agent profile + protocol refinements (direct user direction, patience-rule override at 4/5 tasks)

**Changed**: `agents/main/developer.md`, `agents/main/architect.md`, external `team-manager/SKILL.md`

**What**:

- **developer.md — Pattern-generalisation rule (A)**. New subsection "Pattern-generalise every feedback item" under Collaborative Protocol. When feedback lists N sites, treat as exemplars not exhaustive list — grep the slice for the pattern, fix every match, state the pattern searched in the next REVIEW_REQUEST. Also strengthened the chunk-done check: re-list `.mob-boss/feedback/` before emitting the `REVIEW_REQUEST` for a chunk; address unaddressed BLOCKERs first.
- **developer.md — Dispatch-context amendment eagerness (B)**. New subsection "Dispatch-context amendments are first-action items". Amendments in `dispatch-context.md`'s `## Amendments` section get applied as the first action of the slice that touches the named file. Name the applied amendment IDs in the slice's `REVIEW_REQUEST`. Raise `DEVELOPER_ASKS_ARCHITECT` if amendment scope is ambiguous.
- **team-manager SKILL.md — Designer prototype gate (C)**. Phase 1b gains a "Prototype-as-gate — required for UX-visible changes" block. For any user-facing layout / navigation / interaction / visual change, designer's HTML prototype is a user-approval gate before Phase 2 code. Team-manager presents prototype to user, iterates until approved, persists prototype URL + approval status into `dispatch-context.md`. Backend-only changes are exempt.
- **team-manager SKILL.md — Dev-agent rabbit-hole timeout (D)**. Phase 2b gains a "Watch for dev-agent rabbit holes" block. If 15+ minutes elapse since last dev signal on a chunk the plan scoped trivial (≤ 30 lines / ≤ 20 min), team-manager reads dev output via TaskOutput. On repeated retries / scope expansion / post-primary-fix secondary investigation: TaskStop + adjudicate inline. Fires on plan-vs-reality mismatch, not absolute time. Logged as `dev_agent_timed_out`.
- **architect.md — DESIGN.md contract plan section (E)**. New non-negotiable plan section "DESIGN.md contract" listing every feature DESIGN.md the plan touches, which sections each slice modifies, and which amendments from `dispatch-context.md` apply to those files. Makes DESIGN.md edits first-class slice tasks, not tail-end cleanup.

**Evidence** (4 tasks completed, 2026-04-16 through 2026-04-17):

- `feedback_ignored` across all 4 tasks: T1 3×, T2 3-4×, T3 1×, T4 1×. Meta-guidance in T2 ("grep every site") drove the trend down but pattern is still present — codifying it closes the loop. (Drives A.)
- `plan_deviation` as DESIGN.md drift: T3 had 6 WARNINGs at tier-3, all user-approved Phase 1d amendments the dev never applied in slice work. T4 continued the pattern at lower count. (Drives B and E.)
- `formal_reviewer_catches_inline_would_miss` in T4: 2 real production bugs + 1 E2E regression. Validates current review discipline — not touched. Designer-prototype-as-gate in T4 caught 7+ UX issues across 3 iteration rounds before any code landed; T3 shipped the wrong interaction model when the gate was absent and required a full revision dispatch (T4 itself). (Drives C.)
- `dev_agent_timed_out` T4 Slice 4 V2: dev burned 25+ min on secondary SVG-render-timing issue after primary fix landed. Team-manager TaskStop + inline adjudication closed it in minutes. (Drives D.)
- User qualitative feedback (T4 end): "Taking longer to implement changes than not using the skill. They may be better tested though." Five changes above are designed to **reduce rework rounds** (A, B, E cut DESIGN.md drift + pattern-re-raise cycles; C prevents UX revision dispatches; D prevents per-dispatch rabbit holes) rather than add ceremony — each one cuts loop time if it fires.

**Expected improvement**:

- `feedback_ignored` trends to ≤ 1 per task or zero — the pattern-generalise procedure is explicit and self-checkable.
- DESIGN.md drift at tier-3 drops from 6 WARNINGs (T3 peak) to 0-1 — amendments flow into slice work from day one.
- UX-visible dispatches no longer require post-landing revision cycles — designer gate catches model misreads before code cost.
- Dev rabbit-hole cost capped at ~15 min instead of 25+ — team-manager intervenes on plan-vs-reality mismatch.
- Wall-clock tradeoff improves: cut rework rounds, keep quality gains. Next 2 tasks are the evaluation window.

**Source**: Direct user direction at 4/5 tasks. Patience-rule overridden explicitly by user ("dont want to wait for another cycle to do some refinement"). Evidence threshold (≥ 3 occurrences) met for A and exceeded for E; B had 2 tasks but high count on T3; C is 1-task qualitative evidence with dramatic payoff; D is 1 occurrence but low-cost operational rule. No experiments — direct merge into main. Evaluation window: T5 and T6. If any metric regresses or a new pattern surfaces, revert or refine.

## v1.2 — 2026-04-17

**Type**: Harness + protocol fixes (direct user direction, post-task-2)
**Changed**: `team-manager/SKILL.md`, `team-manager/context.sh`, `mob-boss/preamble.sh`, `agents/main/developer.md`
**What**:
- **team-manager SKILL.md (durable)**: `disable-model-invocation: true` removed — was blocking the `Skill({skill: "team-manager"})` invocation prescribed by mob-boss protocol itself. Fixed in-session during task 2; now durable.
- **team-manager SKILL.md + Phase 1a + Rules**: added dispatch-context persistence + SendMessage-fallback pattern. Architect plan gets written to `.mob-boss/dispatch-context.md` at Phase 1a end. A new "Resuming a stopped developer agent" section under Rules tells the team-manager to prefer SendMessage when available, and fall back to fresh Agent spawns that reference `.mob-boss/dispatch-context.md` + existing profile paths instead of re-pasting context — saves onboarding tokens and keeps prompt cache warm across resumes. Logs a resume-strategy field on `agent_spawned` events.
- **team-manager context.sh**: agent-profile precedence reordered to `project-local → evolved-at-skills/mob-boss → canonical`. Previously skipped the mob-boss evolved set entirely, loading the canonical 4-profile baseline instead of the 5-profile evolved set (which includes project-expert). Now loops over all 5 roles with a proper header formatter.
- **mob-boss preamble.sh**: Monitor command now watches `moved_to` (Linux inotifywait) / `Renamed` + `MovedTo` (macOS fswatch) alongside Created. Atomic writes (temp file + rename, as Node's `fs.writeFile` and the Edit tool both use) were firing notifications only on the `.tmp.*` filename, not the real signal filename — every signal arrival required manual `ls` in the handler to discover the real filename.
- **agents/main/developer.md**: added a "Directory discipline — non-negotiable" block under "How to signal" that enumerates which file prefixes belong in `signals/` vs `feedback/` and explicitly warns against writing into `feedback/`. Task 2 logged one `protocol_violation` where a REVIEW_REQUEST landed in feedback/.

**Evidence**:
- Task 1 surfaced context.sh + team-manager gating issues during mob-boss's own initial run
- Task 2 surfaced all 5 smoke-test findings in practice
- Token-cost of fresh-Agent resumes (~15–20K overhead across ~5 resumes in task 2) documents the SendMessage-fallback value

**Expected improvement**:
- Monitor no longer requires manual disk probes when signal temp files fire
- Fresh dispatches correctly load the evolved profile set (including project-expert) — no manual override needed
- team-manager can be invoked via `Skill` tool per documented protocol
- Fresh-Agent resume prompts shrink when they can reference `dispatch-context.md` instead of inlining the plan
- Developer protocol_violations on misfiled signals should trend to zero

**Source**: Direct user direction (no experiment). Patience-rule exception: these are protocol/harness fixes surfaced during real dispatch execution, not reactive agent-behaviour tweaks.

## v1.0 — 2026-04-16

**Type**: Bootstrap
**What**: Initial bootstrap — copied canonical agent definitions (architect, designer, developer, reviewer) into mob boss working directory. No modifications yet. Baseline metrics collection begins.

## v1.1 — 2026-04-16

**Type**: Main updated (direct edit, pre-baseline)
**Changed**: developer.md, reviewer.md, architect.md, designer.md; also external: team-manager SKILL.md (at user's direction)
**What**:
- **developer.md**: Replaced commit-frequently protocol with a no-commits + three-tier chunk/signal review loop. Developer writes `REVIEW_REQUEST.md` at the repo root after each chunk (unit / composite / feature tier), then continues without waiting. Picks up `REVIEW_FEEDBACK.md` between chunks.
- **reviewer.md**: Rewrote with tier-aware review scope: unit = local correctness, composite = cohesion across composed units, feature = architectural. Added tier-specific metrics (`boundary_test_gap`, `cohesion_issue`, `integration_issue`) and a `tier` field in metrics JSONL.
- **architect.md**: Added tier-aware consultation mode. Tier 1 = local answer only, tier 2 = slice-scope, tier 3 = full feature/architectural lens. Hard rule against tier escalation.
- **designer.md**: Replaced flat consultation mode with tier-aware version. Tier 1 = one element/state, tier 2 = slice/component family, tier 3 = feature-wide UI coherence. Output format gained `Tier` and `Prototype impact` fields.
- **team-manager SKILL.md**: Phase 2b rewritten to read `Tier:` from each `REVIEW_REQUEST*.md` and pass it verbatim into every reviewer / architect / designer spawn. Final review pinned to tier 3. Added hard rule about tier discipline.
**Evidence**: No task-log baseline yet (0 completed tasks). This is a protocol-level change driven by explicit user instruction — the new mob-boss terms require single-developer-no-commits with incremental mid-flight review, and the user called out that review scope should tier up from unit → composite → feature rather than flat, and that all collaborating agents need to know how to assess a question for a given scale.
**Expected improvement**: Reviewer catches local bugs fast (unit tier), coherence issues at slice boundaries (composite), and architectural/composition issues before the feature is "done" (tier 3). Architect and designer respond proportionately to the scale of the question, avoiding derailing rework from over-scoped answers. Developer never blocks on reviewer.
**Source**: Direct user direction (no experiment). Patience-rule exception documented: normally would require 3+ occurrences across 5+ tasks, but this is re-aligning the profiles with a rewritten mob-boss skill protocol, not a reactive tweak.

## Task-log entry — 2026-04-16

**Type**: Task completed (no agent modification)
**Task**: back-office Links + OG previews (2.1–2.9)
**Result**: APPROVE WITH WARNINGS after two tier-3 rounds. 738/738 tests pass, 0 TS errors. User commits diff themselves.
**Patterns observed (1 task, insufficient for modification):**
- `feedback_ignored` fired 3× within this single task — mapDbWorkItem flagged three times before fix, brief-prompts ID format flagged twice, `as any[]` cast claimed "removed" then found present. Developer appears to complete forward-motion chunks rather than pausing to address spanning feedback. Watch for recurrence in tasks 2–5 before proposing a profile change.
- `plan_deviation` fired 5× — includes a genuinely-good divergence (republish cleanup), a security gap (SSRF not considered by plan), and the ID-format contradiction. Mix of plan error vs developer drift — needs disambiguation across tasks.
- `integration_issue` at tier-3 caught SSRF that the architect's plan didn't anticipate. Suggests tier-3 review is pulling its weight and the architect profile may benefit from an explicit security pass on the plan — but 1 occurrence is not yet enough.
**No modifications**: baseline 1/5. Continuing to collect.

## v1.2 — 2026-04-17

**Type**: Protocol + infrastructure rewrite (direct edit, pre-baseline — no experiment)
**Changed**:
- `SKILL.md` (mob-boss) — rewritten
- `preamble.sh` (new) — replaces the old `context.sh` for mob-boss; platform-detect, `.mob-boss/` init, stale-progress detection, mandatory Monitor command emission
- `templates/LICENSE.md` (new) — ExaDev licence template with `{{LICENSEE}}` placeholder
- `templates/project-expert-seed.md` (new) — seed profile copied into every new package's `.mob-boss/expert/agent.md`
- `templates/gitignore-snippet` (new) — one-line `.mob-boss/` entry added to the package `.gitignore` on first init
- `agents/main/project-expert.md` (new agent) — hybrid role: orientation-injection + consultable peer + active-participation HOW opinions; learning-loop via `@expert:` tags and close-out curation
- `agents/main/developer.md` — signal paths moved from repo root to `.mob-boss/signals/` and `.mob-boss/feedback/`; feedback-check between chunks upgraded to non-negotiable; E2E dev-server-starts-itself instruction added
- `agents/main/reviewer.md` — signal path updated; `@expert:` tagging convention added
- `agents/main/architect.md` — project-expert orientation consumption added; mandatory security-considerations plan section added; verify-claims-against-actual-code directive added; `@expert:` tagging added
- `agents/main/designer.md` — orientation consumption added; `@expert:` tagging added; `DESIGN_ANSWER` path updated
- `team-manager/SKILL.md` (external; user-owned but rewritten at user direction) — all signal paths moved to `.mob-boss/`; Monitor is mob-boss's responsibility (team-manager inherits from parent session); Phase 1a-prelude for orientation injection; Phase 2d for expert close-out curation
- `metrics/team-log.jsonl` — migrated all 40 existing entries to include `"project":"clearkstake-api/clearkstake-back-office"`

**Evidence**:
- Single-task baseline shows `feedback_ignored=3` and one new `integration_issue` (SSRF). Protocol fixes address the root causes but are not metric-driven yet — they're structural.
- User feedback (not metrics): (a) permission prompts for state writes are noise; (b) Claude failed to watch signal files autonomously twice; (c) nested sub-agent spawning is blocked — team-manager cannot be wrapped in an Agent call; (d) signal files at repo root mix with user code and aren't auto-cleaned.

**What changed in the orchestration model**:
1. **Containment** — every dispatch's transient state lives in `<package>/.mob-boss/` (gitignored). No more repo-root litter. Archive + summary persists locally at close-out.
2. **Monitor is mandatory and pre-loaded** — preamble emits the exact `inotifywait` / `fswatch` command; mob-boss's first tool call must start it. Team-manager inherits the notification stream.
3. **Team-manager runs inline only** — Skill tool, never Agent. Removes the broken Option B.
4. **Progress is appended, not rewritten** — `events.jsonl` accumulates state transitions; resume derives current state from the log. Cheap writes.
5. **Global metrics get project tagging** — `~/.claude/skills/mob-boss/metrics/team-log.jsonl` gains a `project` field per entry.
6. **Project expert** — new fifth agent, persistent per-package at `.mob-boss/expert/`. Injects orientation into every agent spawn; consultable for package questions; active participation for HOW-opinions; curates `@expert:`-tagged facts at close-out.

**Expected improvement**:
- Reduce user interruption (permission prompts) to near-zero once `.claude/settings.json` permission patterns are confirmed.
- Eliminate missed signals — Monitor is mandatory before dispatch.
- Eliminate nested-spawning failure mode.
- Increase review quality over dispatches as the project expert accumulates package-specific knowledge and injects it into every agent.
- Cleaner commit history — no more orphaned signal files under version control.

**Source**: Direct user direction (session 2026-04-17). Pre-baseline; patience-rule exception for a protocol + infrastructure rewrite, not a reactive metric-driven tweak.
