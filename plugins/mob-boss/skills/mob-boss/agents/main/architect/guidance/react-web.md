# React web — plan-review checklist

**Scope:** What to check and enforce when planning work for a React-on-web package (Next.js, Vite, CRA — **not React Native**). Use in Phase 1a when producing the implementation plan, and again during any reconcile or tier-3 consultation on a React-web feature.

Reference the full principles in `~/.claude/skills/mob-boss/agents/main/developer/guidance/react-web.md` — the developer reads those when implementing. Your job is to ensure your plan **routes the developer through the right structure** rather than letting them discover it on the fly.

## Plan structure checks

### File map

For every user-facing data-driven feature you plan:

- Does the file map include a `<feature>/frontend/api/<feature>-api.ts`?
- Does it include one or more `<feature>/frontend/hooks/use-<noun>.ts` files (one per query / mutation)?
- Are the UI components in `<feature>/frontend/components/`?
- For backend-touching features: are service + repository + schema under `<feature>/backend/`?
- Does the feature have a `DESIGN.md` that captures behaviour?

If a file map shows `useQuery` calls inside a component file, or `fetch(...)` in a component or page, the plan is wrong — flag it and restructure before the developer picks it up.

### Page / layout discipline

For every `page.tsx` or `layout.tsx` file you plan:

- Is it planned as a thin wrapper (≤ ~15 lines)?
- If the plan shows a page with its own state, effects, or fetch calls: that's a violation. The logic belongs in a feature component under `<feature>/frontend/components/`.
- For dashboard layouts: shared components (theme toggle, auth redirect hook, shell content) belong in `core/ui/components/` or a dedicated shell component — not inline in `layout.tsx`.

### Component sizing

For every new component you plan:

- Estimate its line count. If it's likely to exceed ~200 lines, decompose up front. Name each concern (lock, presence, chat, auto-save, form draft, dialog) and assign it to a hook or child component in the file map.
- If the feature has duplicate flows across surfaces (e.g. "link X to Y" appearing in two views), plan a shared hook + shared dialog component — don't let the developer duplicate.

### Backend routing (Next.js packages with API routes)

For every API route you plan:

- The plan must specify **which service method** the route calls — not "handler calls repository".
- If no service method exists for the operation, planning that method is part of the task, not an afterthought.
- Routes that need more than "parse → service → response" (e.g. SSE, AI streaming, multi-entity enrichment) require a corresponding service method that yields events or assembled DTOs. The plan must name it.

### Module + DI consistency

Check the target package's ApplicationContext and module layout before planning. If the package already uses:

- **The proxy (`getApplicationContext`) in routes**: plan new routes to use the proxy. Don't mix patterns.
- **Direct `ApplicationContext.getInstance()` in routes**: plan new routes to match the existing pattern, but flag a follow-up to migrate the whole package to the proxy.
- **Modules exposing services only** (mock-bank pattern): plan new module additions with private repositories and public services. Do not add public repository getters.
- **Modules exposing both services and repositories** (historical back-office pattern): match the existing pattern for the slice you're in, and flag a `@expert:` note that the module should be audited for service-only exposure.

If your plan touches multiple packages in the monorepo, call out any divergence between them in the plan — the cross-package consistency rule in the root `CLAUDE.md` requires this.

## Checklist for the plan document

Before you finalise the plan, confirm the following are present and correct:

- [ ] Every data-fetching interaction in the plan has an API client method + hook + component consumer, named and located
- [ ] No `page.tsx` is planned with inline state, effects, fetch calls, or business logic
- [ ] No component over ~200 lines is planned without decomposition
- [ ] Every API route names the service method it calls
- [ ] Duplicated flows across features have a shared extraction planned (hook + component)
- [ ] Module additions expose services, not repositories (or match existing package convention with a follow-up flagged)
- [ ] `DESIGN.md` for the feature is listed as either created or amended (with section names), per the DESIGN.md contract section in the base architect profile

## Tier-aware consultation scope for React-web questions

When consulted during a React-web build (via `mode: consultation`), match your answer to the tier as normal — but note the common tier-scope signals for this stack:

- **Tier 1 (unit)**: one hook's query-key, one API client's endpoint shape, one component's prop type, one route's service call. Narrow answer.
- **Tier 2 (composite)**: the shape of a feature's hook family + API client together, the decomposition of a component into hooks + children, whether two routes should share a service method.
- **Tier 3 (feature)**: cross-feature pattern violations, whether a new module should be introduced, proxy vs direct-import stance for the package, whether a shared extraction is warranted.

Do not escalate. A tier-1 question about "which layer owns cache invalidation?" gets "the hook" — not "let me redesign your data flow."

## When this guidance does not apply

- React Native packages (different primitives, different DI constraints).
- Non-React frameworks in the monorepo.
- Infrastructure-only changes (migrations, CI, Docker) where no component / route / module is touched.

Fall back to the base architect profile for those cases.
