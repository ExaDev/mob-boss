# React web — implementation guidance

**Scope:** How to structure feature code when building on a React-on-web stack (Next.js App Router, Vite, CRA, Remix, or any React-on-web framework — **not React Native**). Covers frontend data fetching, component decomposition, page/layout discipline, and backend module + service-layer structure when the framework is Next.js.

These principles are derived from exemplar packages in this monorepo (`mock-bank`, `admin-dashboard`) and apply when the target package uses React on the web. Not style — style lives in the project's own `CLAUDE.md` / `design-decisions.md` / project-expert orientation.

If the target stack is not React-on-web, this file does not apply — fall back to base developer.md rules only.

## Frontend — three-layer data fetching

Data fetching flows through three layers, one direction:

```
Component  →  Custom Hook  →  API Client
```

Every layer has one job. Cross-layer shortcuts are violations.

### Component layer

Components **never**:
- Call `fetch(...)` directly
- Call `useQuery(...)` or `useMutation(...)` directly
- Know endpoint URLs, HTTP methods, or response envelope shapes

Components consume data via custom hooks and render the result. If a component wants to list work items, it calls `useWorkItems()` — not `useQuery({ queryKey: [...], queryFn: fetch(...) })`.

Shape of a good component:

```tsx
const WorkItemList = () => {
  const { data, isLoading, error } = useWorkItems();
  if (isLoading) return <Skeleton />;
  if (error) return <ErrorBanner error={error} />;
  return <ul>{data.map(item => <WorkItemCard key={item.id} item={item} />)}</ul>;
};
```

### Custom hook layer

Hooks live in `<feature>/frontend/hooks/use-<noun>.ts`, one hook per query or mutation. They wrap React Query (or the project's equivalent) and return library-agnostic shapes. A caller of the hook should not have to know React Query is involved — if you swap fetch libraries tomorrow, only the hook changes.

```ts
// briefs/frontend/hooks/use-briefs.ts
export const useBriefs = () =>
  useQuery({
    queryKey: ['briefs'],
    queryFn: briefsApi.list,
  });

export const useCreateBrief = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: briefsApi.create,
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['briefs'] }),
  });
};
```

Hooks own: query keys, cache invalidation, optimistic updates, mutation side effects.

### API client layer

API clients live in `<feature>/frontend/api/<feature>-api.ts` as plain objects of typed functions. They are the frontend's "repository" — they know URLs and response shapes, nothing else. **No business logic. No caching. No error transformation.**

```ts
// briefs/frontend/api/briefs-api.ts
export const briefsApi = {
  list: (): Promise<Brief[]> =>
    fetch('/api/briefs').then(r => r.json()),
  create: (input: CreateBriefInput): Promise<Brief> =>
    fetch('/api/briefs', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(input),
    }).then(r => r.json()),
};
```

When adding a new feature that fetches data: you create the API client, then the hook, then consume it in the component. Not the other way around.

## Frontend — component decomposition

### God components are a smell

A component whose body grows past ~200 lines almost certainly holds multiple concerns. Common concerns that belong in dedicated hooks or child components:

- **Lock acquisition / heartbeat / release** → `use<Feature>Lock(id)` hook
- **SSE or WebSocket subscriptions** → `use<Feature>Stream(id)` hook
- **Auto-save with debounce / visibility triggers** → shared `useAutoSave(saveFn, deps)` in `core/ui/hooks/`
- **Chat state + streaming responses** → `use<Feature>Chat(id)` hook
- **Form draft persistence (sessionStorage / localStorage)** → `useDraftSession(key)` hook (shared if reused)
- **Dialog-specific state + UI** → extract dialog to its own component, lift open/close to parent
- **Inline sub-components defined in the same file** → extract to their own files; one component per file

When implementing a new feature: decompose up front. If you find yourself writing a 400-line component in one pass, stop and extract before committing more lines.

### Extract shared UI and hooks when duplicated

If two or more features implement the same user flow (e.g. "search and link X to Y"), extract a shared hook and component rather than duplicating. The shared extraction lives in whichever feature owns the flow most naturally, or in `core/ui/` if cross-feature. Reusable hook and dialog together form the pattern.

## Frontend — thin page and layout files

Next.js `page.tsx` and `layout.tsx` files are routing concerns only. They import a feature component, pass route params, and render. Nothing else.

### Correct shape

```tsx
// app/(dashboard)/briefs/new/page.tsx
'use client';
import { NewBriefCreator } from '@/briefs/frontend/components/NewBriefCreator';

const NewBriefPage = () => <NewBriefCreator />;
export default NewBriefPage;
```

```tsx
// app/(dashboard)/projects/[id]/page.tsx
'use client';
import { ProjectDetail } from '@/roadmap/frontend/components/ProjectDetail';

const ProjectPage = ({ params }: { params: { id: string } }) =>
  <ProjectDetail projectId={params.id} />;
export default ProjectPage;
```

### Anti-patterns that must not appear in page.tsx or layout.tsx

- `useState`, `useEffect` (beyond a single trivial one for route-param coercion if unavoidable)
- `fetch(...)` calls
- Business logic (filtering, sorting, permission decisions, data transformations)
- Inline component definitions (`const InlineThing = () => ...`)
- 100+ lines of JSX

All of those belong in a feature component under `<feature>/frontend/components/`. The page just wires the route to the component.

Dashboard / shared layouts follow the same rule: `layout.tsx` composes providers and a feature layout component (e.g. `<DashboardShell>`); the shell owns the auth redirects, sidebar state, etc.

## Backend — ApplicationContext, modules, and DI (Next.js packages)

When the React-web stack is Next.js and the package has API routes, the backend follows a specific DI structure.

### ApplicationContext

An async singleton with init-promise caching. Shape:

```ts
class ApplicationContext {
  private static initPromise: Promise<ApplicationContext> | null = null;
  private static resolvedInstance: ApplicationContext | null = null;

  static async getInstance(): Promise<ApplicationContext> { /* ... */ }

  static resetInstance(): void {
    ApplicationContext.initPromise = null;
    ApplicationContext.resolvedInstance = null;
  }

  private readonly _coreModule: CoreModule;   // eager — DB + migrations
  get roadmapModule(): RoadmapModule { /* lazy */ }
  get briefModule(): BriefModule { /* lazy */ }
}
```

**`resetInstance()` is mandatory** — tests need it for isolation. Skipping it forces casts through `Record<string, unknown>` which breaks when field names change.

**CoreModule is eager** — DB client construction + migrations. Failure to initialise prevents the app from starting, which is the correct behaviour.

**Feature modules are lazy** — created on first access via `??=` getters. Each module takes the shared DB client and constructs its own repositories + services.

### Modules expose services only, never repositories

**This is non-negotiable.** Repositories are internal implementation details of a module. Public getters expose services. Routes call services.

```ts
// GOOD — BriefModule only exposes services
export class BriefModule {
  constructor(private readonly db: DrizzleClient) {}

  private get briefRepository(): BriefRepository {
    return this._briefRepository ??= new BriefRepository(this.db);
  }

  get briefService(): BriefService {
    return this._briefService ??= new BriefService(this.briefRepository, ...);
  }
}

// BAD — exposes repository publicly; routes can skip the service
export class BriefModule {
  get repository(): BriefRepository { /* ... */ }
  get service(): BriefService { /* ... */ }
}
```

If a route reaches for `module.repository.findX()`, either the service is missing that operation (add it) or the route is putting business logic in the wrong place (move it).

### Proxy for circular-dependency break

`getApplicationContext()` is a late dynamic-import proxy in `core/context/application-context-proxy.ts`. Routes import the proxy, not the context class directly. This breaks circular dependencies that appear as the module graph grows:

```ts
// GOOD
import { getApplicationContext } from '@/core/context/application-context-proxy';

export const GET = async () => {
  const { briefModule } = await getApplicationContext();
  const briefs = await briefModule.briefService.list();
  return Response.json(briefs);
};

// AVOID — direct import risks circular deps as the graph grows
import { ApplicationContext } from '@/core/context/application-context';
```

If you're adding routes to a package that currently imports `ApplicationContext` directly, follow the existing pattern in that package and raise the proxy migration as a follow-up — don't mix patterns within a single PR.

## Backend — thin API routes (Controller pattern)

API routes are controllers. Their job: parse request, call service, format response. Everything else belongs in services.

### Correct shape

```ts
// api/briefs/route.ts
export const GET = () => withErrorHandler(async () => {
  const { briefModule } = await getApplicationContext();
  const briefs = await briefModule.briefService.list();
  return Response.json(briefs);
});

export const POST = (req: Request) => withErrorHandler(async () => {
  const input = createBriefSchema.parse(await req.json());
  const { briefModule } = await getApplicationContext();
  const brief = await briefModule.briefService.create(input);
  return Response.json(brief, { status: 201 });
});
```

### Anti-patterns that must not appear in route handlers

- Field-level changelog recording loops (lives in `ChangelogService.recordFieldChanges()`)
- Entity enrichment / name-map building (lives in the relevant service — if duplicated across routes, that's a strong signal)
- Multi-entity fetch + join assembly (service method returning the assembled DTO)
- Dual-entity validation (service method that raises domain errors)
- Streaming orchestration (service yields events; route just streams them)
- Permission checks beyond `requireRole(...)` (business-level auth lives in service — `AuthService.updateRole(currentUser, targetId, newRole)`)
- UUID parsing + derivation logic (helper or service method)

When a route gets past ~40 lines, stop and extract the logic. Three routes sharing the same enrichment shape is a guaranteed service extraction.

## Feature directory structure (Next.js React-web packages)

```
src/<feature>/
  module.ts                          # feature module (DI)
  frontend/
    api/<feature>-api.ts             # typed fetch wrappers
    hooks/use-<noun>.ts              # one hook per query/mutation
    components/                      # UI — no direct fetch, no direct useQuery
  backend/
    service/<feature>-service.ts     # business logic
    repository/<noun>-repository.ts  # data access (module-internal)
    schema/<noun>.schema.ts          # Drizzle schema + Zod
  DESIGN.md                          # feature design doc
```

Cross-cutting pieces live in `core/` — primitives, shared hooks (`useAutoSave`, `useDraftSession` if truly reused), ApplicationContext + proxy, error classes.

## When applying this guidance — where to start

On a new feature in a React-web package:

1. Read `CLAUDE.md` and the feature's DESIGN.md first (project style + feature behaviour)
2. Identify the feature directory; create it if missing, following the structure above
3. Plan backend first: schema → repository → service → route. Route is a thin Controller. Service owns the logic.
4. Plan frontend second: API client → hook → component. Components consume hooks. Pages are thin wrappers.
5. If decomposing an existing god component or fat route, extract in small chunks and emit `REVIEW_REQUEST` signals at each natural boundary — don't batch an entire rewrite.

On an existing feature that violates this guidance: flag the violation in your chunk signal as a `@expert:` or follow-up, but don't silently mix patterns. Either follow the existing (broken) pattern consistently in your slice and file a corrective follow-up, or migrate the affected surface to this guidance as part of your slice if scope allows. Discuss with the architect if unclear.
