# React web — review checklist

**Scope:** What to flag when reviewing work in a React-on-web package (Next.js, Vite, CRA, Remix — **not React Native**). Symmetric with the developer's `react-web.md` implementation guidance and the architect's `react-web.md` plan checklist — this file translates those principles into tier-scoped review flags.

These rules apply in addition to the base reviewer profile, not instead of it. If the target stack is not React-on-web, this file does not apply — fall back to base reviewer rules only.

Read the base reviewer's **Findings format** and **metric names** before applying this checklist — the review output shape is unchanged.

## How tier scope applies to React-web reviews

A `useQuery` inside a component file is a unit-tier finding (local violation in a reviewed file). The same `useQuery` pattern repeated across three components is a composite-tier finding (cohesion issue). A package where modules expose repositories instead of services is a feature-tier finding (architectural). **Raise each violation at the right tier — don't escalate and don't defer.** The reviewer's value is proportional to tier discipline.

## Tier 1 — Unit review

Apply these checks to every file changed in the chunk. Each check includes the signal to look for, the flag shape, and the metric to emit.

### Components

**No direct `fetch` in components.** Grep the changed component files for `fetch(`. Every match is a BLOCKER at unit tier — the component should be calling a hook, which calls an API client.

```
metric: convention_violation
detail: "<file>.tsx calls fetch() directly — should go through an API client + hook"
severity: BLOCKER
```

**No direct `useQuery` / `useMutation` in components.** Grep for `useQuery(` and `useMutation(` imports in component files. Every match is a BLOCKER — these belong in a custom hook under `<feature>/frontend/hooks/`.

```
metric: convention_violation
detail: "<file>.tsx calls useQuery/useMutation directly — wrap in a custom hook"
severity: BLOCKER
```

**Component size.** Flag any component file exceeding ~200 lines as a WARNING (decomposition needed). Past ~400 is a BLOCKER. Look for multiple concerns in one file (lock management + chat + form state + dialog UIs — each belongs in its own hook or child component).

```
metric: cohesion_issue
detail: "<file>.tsx is N lines mixing <concerns> — needs decomposition into hooks + child components"
severity: WARNING or BLOCKER
```

**Inline sub-components.** Any `const SomeSub = (...) => ...` defined inside another component file is a WARNING — should be extracted to its own file, one component per file.

```
metric: structure_violation
detail: "<SubComponent> is defined inline in <file>.tsx — extract to own file"
severity: WARNING
```

### API clients

**Thin fetch wrappers only.** Every function in `<feature>/frontend/api/*-api.ts` should be URL + HTTP method + typed response. If you see business logic, caching, error transformation, or state — it's a BLOCKER.

```
metric: convention_violation
detail: "<api-file>.ts contains <logic-type> — API clients are thin, logic belongs in hooks or services"
severity: BLOCKER
```

**Location.** API clients must live in `<feature>/frontend/api/`, not scattered. If the code creates the directory structure incorrectly, flag as structure_violation.

### Hooks

**Location + naming.** Hooks live in `<feature>/frontend/hooks/use-<noun>.ts`, one hook per query or mutation. A single `use-<feature>.ts` file containing 6 unrelated hooks is a WARNING (scope).

**Library leakage.** A hook that returns `{ data, isLoading, error }` from React Query directly is fine (that IS the library-agnostic shape). A hook that returns the raw `UseQueryResult` object or requires the caller to pass React Query options is a WARNING — over-coupled to the library.

```
metric: convention_violation
detail: "use<X>() leaks React Query shape — caller shouldn't need to know about useQuery"
severity: WARNING
```

**Query-key shape.** Query keys should be `['<feature>']` for lists, `['<feature>', id]` for details, `['<feature>', id, '<sub>']` for nested. Mismatched shapes across hooks in the same feature is a cohesion issue for composite tier, but the unit-tier reviewer can still flag a single-file violation (e.g. a stringly-typed key like `'briefs-${id}'`).

```
metric: convention_violation
detail: "use<X>() query key shape — should be ['<feature>', id], not ..."
severity: WARNING
```

### API routes

**Thin Controller pattern.** Every `route.ts` handler should be: parse request, call service, format response. Grep changed routes for these smells:

- `module.repository.` or `module.<x>Repository.` — BLOCKER if the route bypasses the service layer. Should call `module.<x>Service.<method>()`.
- `for (const change of changes)` field-level changelog loops — BLOCKER, belongs in `ChangelogService.recordFieldChanges()`.
- Multi-entity name-map building (`const names = new Map(...); entries.forEach(...)`) — BLOCKER, belongs in a service enrichment method.
- Polling loops (`setInterval`, `while (true)`) or streaming orchestration (`ReadableStream` with business logic in the pull) — BLOCKER, service should yield events.
- Route handler body over ~40 lines of its own logic (not counting imports and export wrapper) — WARNING for 40-80, BLOCKER past ~80.

```
metric: convention_violation
detail: "<route>.ts calls repository directly — should go through <service>.<method>()"
severity: BLOCKER
```

```
metric: plan_deviation
detail: "<route>.ts contains <pattern> — belongs in <service-name>.<method>()"
severity: BLOCKER
```

### Pages and layouts

**Thin wrappers.** Every `page.tsx` / `layout.tsx` changed should be near-trivial — import a feature component, pass route params, render. Flag these smells:

- Any `useState` / `useEffect` in the file — WARNING (minor), BLOCKER if accompanied by `fetch()` or business logic.
- Any `fetch(` in the file — BLOCKER.
- Any `const InlineThing = () => ...` in the file — WARNING (extract to `core/ui/components/` or a feature component).
- More than ~15 lines — WARNING; more than ~50 — BLOCKER.

```
metric: structure_violation
detail: "<page>.tsx contains state / effects / fetch / inline components — page should be a thin wrapper"
severity: WARNING or BLOCKER
```

### Modules and DI

**Direct ApplicationContext import in a new route.** If the package is currently using `getApplicationContext()` proxy (check existing routes), and the new route imports `ApplicationContext` directly — WARNING at unit tier (should match existing pattern). If the package is mid-migration, accept but flag with `@expert:`.

**Public repository getter added to a module.** If the module currently exposes services only (mock-bank pattern) and the new diff adds a `get <x>Repository` public getter, flag as BLOCKER. If the module already exposes repositories (historical back-office pattern), accept but flag as a `@expert:` or follow-up — the package has a known drift.

```
metric: convention_violation
detail: "<Module> gained a public repository getter — modules should expose services only"
severity: BLOCKER
```

### Tests at unit tier

**Hook tests co-located.** Every new hook file must have a co-located `.test.ts` verifying query keys, mutation callbacks, and side effects (cache invalidation). Missing — BLOCKER.

**API client tests — minimal.** API clients are thin enough that a single happy-path test per method is sufficient. Missing — WARNING.

**Route handler tests.** Every new route must have a route-level test verifying request parsing, service-call, response shape, and error-path. Missing — BLOCKER.

**Component tests.** Every component with interactive behaviour or conditional render logic needs a component test. Purely presentational components (render a label from a prop) don't strictly need one — SUGGESTION at most.

```
metric: tests_missing
detail: "<new-file>.tsx has no co-located test"
severity: BLOCKER (hook, route) or WARNING (component) or SUGGESTION (pass-through)
```

## Tier 2 — Composite review

Tier-2 is about **how the units in the slice hang together**. Apply all tier-1 checks to any files not yet reviewed in earlier unit passes, then add these cross-unit checks.

### Three-layer coherence

**API client + hook + component line up.** The slice should have one API client method per backend call, one hook per query/mutation that wraps an API client method, and components consuming the hook. Flag misalignment:

- Component calls `fetch()` directly despite the slice containing an API client — WARNING (API client exists but wasn't used).
- Hook uses `fetch()` instead of the API client it was supposed to wrap — BLOCKER (layer skipped).
- API client method unused by any hook — WARNING (dead code or incomplete slice).

```
metric: cohesion_issue
detail: "Slice has API client method <m> but hook use<X> calls fetch directly"
severity: BLOCKER
```

### Duplication within the slice

**Repeated flow across surfaces.** If the slice touches multiple views and implements the same flow in each (search-and-link, modal-and-list, etc.) — BLOCKER. Extract to a shared hook + shared component.

```
metric: reuse_missed
detail: "<flow> implemented twice in <file-A> and <file-B> — extract shared hook + component"
severity: BLOCKER
```

### Service composition

**Service method consistency.** If the slice's routes all call the same service, check the service methods are coherent — one public method per route operation, not a mega-method that accepts a `mode` flag. Repositories called by services should be composable, not duplicated call-sequences.

```
metric: cohesion_issue
detail: "<Service> has <pattern-of-duplication> across methods — extract helper or refactor"
severity: WARNING
```

### Boundary test coverage

**Handoffs between layers tested.** For a slice with component + hook + API client + route + service + repository:

- Hook test covers the API-client error case (rejected promise) → component's error state.
- Route test covers service-throws-domain-error → response shape.
- Service test covers repository-returns-empty / repository-throws → service behaviour.

If a layer's failure mode isn't tested at the consumer level, flag as boundary_test_gap WARNING. If a BLOCKER-class error path (e.g. lock-acquire-fails in a brief flow) has no test, BLOCKER.

```
metric: boundary_test_gap
detail: "<consumer-layer> doesn't test <producer-layer>'s <failure-mode>"
severity: WARNING or BLOCKER
```

### Cohesion of the slice

**Naming + shape consistency across units.** Do the hooks use the same naming convention? Do the API client methods follow the same parameter shape (input object vs positional)? Do the routes all use `withErrorHandler` or all roll their own? Inconsistency within a single slice is a WARNING.

### Shared extraction opportunity

If the slice surfaces a pattern that other slices in the same feature (or a sibling feature) could use — `useAutoSave`, `useDraftSession`, a confirm-dialog component — and the slice DIDN'T extract it, flag as WARNING with a specific recommendation. If the slice over-extracts (single-use abstraction), SUGGESTION.

## Tier 3 — Feature review

Tier-3 is **architectural**. Every tier-1/tier-2 check applies to anything not yet reviewed, plus these feature-wide checks.

### Feature directory structure

The feature directory should match:

```
src/<feature>/
  module.ts
  frontend/{api, hooks, components}
  backend/{service, repository, schema}
  DESIGN.md
```

Missing pieces — BLOCKER (feature can't be complete without them, unless explicitly scope-limited).

```
metric: structure_violation
detail: "Feature <f> missing <directory/file>"
severity: BLOCKER or WARNING depending on scope
```

### Module exposure

**Modules expose services only.** Read the module class. Public getters should return services, not repositories. Repositories should be private getters. Any public repository getter is a BLOCKER unless the package is known to have this drift (then WARNING + `@expert:` follow-up note).

### Layered access across the feature

**No route bypasses the service.** Grep every route in the feature for `module.<x>Repository.` — every match is a BLOCKER. Services own business logic; routes orchestrate HTTP.

### ApplicationContext + proxy

**Proxy usage consistent.** Check whether the package uses `getApplicationContext()` proxy or direct `ApplicationContext.getInstance()`. If mixed within a package (some routes one way, some the other), flag the divergence as WARNING with a migration recommendation — consistency within a package matters more than the direction of consistency.

**resetInstance present.** If tests cast through `Record<string, unknown>` to reset the singleton, the package is missing `ApplicationContext.resetInstance()` — WARNING + `@expert:` note.

### Pages across the feature

**All pages thin.** Walk every `page.tsx` and `layout.tsx` the feature introduces or touches. Any fat one survived this dispatch — WARNING (it's a separate cleanup but worth surfacing).

### Duplication across features

**Shared-extraction survey.** Quickly scan sibling features in the same package for patterns this feature could have shared (or did inadvertently copy). Flag duplication that crossed feature boundaries as BLOCKER — that's the kind of architecture debt that compounds.

### Documentation

**DESIGN.md reflects the feature.** The feature's DESIGN.md must name the components, hooks, API client methods, services, and routes introduced — not just narrative behaviour. If DESIGN.md still describes the pre-refactor state, flag as BLOCKER (core rule of this workflow).

**Amendments from dispatch-context applied.** If the dispatch-context's `## Amendments` section named specific DESIGN.md changes and the feature's DESIGN.md doesn't reflect them, flag as BLOCKER (this is the DESIGN.md drift pattern the developer profile explicitly warns against — if it reached feature tier unaddressed, the developer missed the first-action rule).

### Security pass (base profile reminder)

Apply the base reviewer's security checklist — no PII logging, Zod at boundaries, parameterised queries, no new SSRF-adjacent patterns, auth on every mutating route. This doesn't change for React-web but is worth re-running explicitly at feature tier.

## When this guidance does not apply

- React Native packages (different review lens).
- Non-React frameworks in the monorepo.
- Infrastructure-only changes (migrations, CI, Docker) — fall back to base reviewer rules.

Note the absence in your output so the user can see you checked and the guidance wasn't applicable.

## Output expectations for React-web reviews

Your standard base-reviewer output (Chunk, Summary, Findings, Metrics JSONL, Recommendation) is unchanged. When applying this guidance, the **Findings section can cite the rule by name** so the developer can look it up:

> BLOCKER — `<file>.tsx` calls `fetch()` directly. See `react-web.md` "Components — no direct fetch."

That citation style is optional but useful when a pattern-generalise fix needs to sweep multiple sites — the developer can grep the guidance to re-derive the full rule.
