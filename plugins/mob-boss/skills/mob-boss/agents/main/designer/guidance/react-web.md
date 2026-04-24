# React web — mockup-production guidance

**Scope:** How to structure HTML prototypes so they convert 1:1 to React components on the web (Next.js, Vite, CRA, or any React-on-web stack — **not React Native**). This is about **structure, not style**.

**Not this file's job:** colours, typography, spacing tokens, component library conventions — those are project-specific and live in `CLAUDE.md`, `.claude/docs/design-decisions.md`, and the project-expert orientation snippet in your prompt. Read those for the project's design language; read this file for how to lay out the HTML so a developer can lift it into React with no restructuring.

## React-ready structure

These mockups will be converted to React applications or component libraries. The HTML must map 1:1 to future React components with no restructuring needed.

### Think in components from line one

Before writing any HTML, identify the component tree. Every distinct UI piece gets its own clearly bounded element. Name these with descriptive comments:

```html
<!-- Sidebar -->
<aside class="...">
  <!-- SidebarNav -->
  <nav class="...">
    <!-- NavItem -->
    <a class="..." href="#">
      <i class="fa-solid fa-house"></i>
      <span>Dashboard</span>
    </a>
    <!-- /NavItem -->
  </nav>
  <!-- /SidebarNav -->
</aside>
<!-- /Sidebar -->
```

### Component boundaries = element boundaries

Each component must be a single root element. Never split a logical component across sibling elements or rely on a parent's layout for the component's internal structure. The component must be self-contained — liftable into a React component as-is:

```html
<!-- GOOD: StatsCard is self-contained, lifts straight into <StatsCard /> -->
<div class="rounded-xl bg-white/5 border border-white/10 p-5">
  <div class="flex items-center gap-3 mb-3">
    <div class="w-10 h-10 rounded-lg bg-blue-500/15 flex items-center justify-center">
      <i class="fa-solid fa-users text-blue-400"></i>
    </div>
    <span class="text-sm text-white/50 font-medium">Total Users</span>
  </div>
  <div class="text-2xl font-bold tracking-tight text-white">12,847</div>
  <div class="text-xs text-emerald-400 mt-1">
    <i class="fa-solid fa-arrow-up mr-1"></i>12.5% from last month
  </div>
</div>

<!-- BAD: Layout grid wraps card internals — can't extract as one component -->
<div class="grid grid-cols-3 gap-4">
  <div class="col-span-1"><i class="fa-solid fa-users"></i></div>
  <div class="col-span-2">
    <span>Total Users</span>
    <span>12,847</span>
  </div>
</div>
```

### Class patterns that map to Tailwind + React

- Use Tailwind utility classes exclusively in the markup. No custom class names for styling.
- Custom CSS in `<style>` is only for things Tailwind can't express (complex animations, backdrop-filter, multi-step gradients).
- When custom CSS is needed, use CSS custom properties in `:root` — these map cleanly to theme tokens in the React app.

### Data and repetition

When you have repeated items (lists, cards, table rows), write out 3-5 realistic instances in full HTML. Don't use JS to generate them. This makes the future `.map()` call obvious.

Mark the repeated component clearly:

```html
<!-- ProjectCard (repeated) -->
<div class="...">...</div>
<!-- ProjectCard (repeated) -->
<div class="...">...</div>
<!-- ProjectCard (repeated) -->
<div class="...">...</div>
```

### Interactive state representation

Show states using Tailwind state variants for hover/focus/active. For toggled states (selected, expanded, open), include both variants as separate commented sections or use data attributes with minimal JS:

```html
<!-- TabButton: active -->
<button class="px-4 py-2 text-sm font-medium text-white border-b-2 border-blue-500" data-state="active">
  Overview
</button>
<!-- TabButton: default -->
<button class="px-4 py-2 text-sm font-medium text-white/50 border-b-2 border-transparent hover:text-white/70" data-state="default">
  Analytics
</button>
```

### Component manifest

Every HTML page must include a component manifest comment block immediately inside `<body>`. This is the conversion blueprint — it captures everything that can't be expressed visually in the mockup but is essential for building the real app. Without it, the developer converting the mockup has to guess at data sources, state management, responsive behaviour, and edge cases.

**Format:**

```html
<body>
<!--
@page /dashboard/projects
@layout DashboardLayout (shared: Sidebar, TopBar)

@component ProjectCard
  @props title: string, status: "active" | "paused" | "completed", url: string, clicks: number, createdAt: Date
  @data GET /api/projects → ProjectCard[]
  @empty "No links yet. Create your first short link."
  @loading skeleton (3 cards)
  @responsive below md: stack vertically, hide clicks column

@component CreateLinkModal
  @trigger "Create Link" button in TopBar
  @state local (useState: isOpen)
  @fields url: required|url, customSlug: optional, expiresAt: optional|date
  @submit POST /api/links → close modal, prepend to list, toast "Link created"
  @error inline field errors + toast on server failure

@component Sidebar
  @responsive below md: collapse to bottom nav, hide labels
  @state activeItem driven by current route

@component StatsCard
  @props label: string, value: number, trend: number, icon: IconName
  @data included in GET /api/projects (summary field)
  @variants default, loading (skeleton pulse)

@component AnalyticsChart
  @props data: { date: string, clicks: number }[]
  @data GET /api/projects/:id/analytics?range=7d
  @empty "No data yet. Share your link to start tracking."
  @loading skeleton (chart placeholder)
-->
```

**Annotation reference:**

| Tag | Purpose | Required? |
|---|---|---|
| `@page` | The route this page maps to in the real app. Use Next.js-style dynamic segments: `/projects/[id]` | Yes |
| `@layout` | Which shared layout wraps this page, and what components are in it. Maps to Next.js `layout.tsx` | Yes if shared elements exist |
| `@component` | Declares a component. One block per component on the page | Yes for every component |
| `@props` | The component's prop interface with types. Use TypeScript-style notation | Yes |
| `@data` | Where the data comes from: API endpoint, server fetch, static, or parent prop. Include the HTTP method and what it returns | Yes if component has dynamic data |
| `@state` | What interactive state the component manages and how it's driven (local useState, URL params, route, context) | Yes if component is interactive |
| `@trigger` | What user action opens/activates this component (for modals, popovers, drawers) | Yes for overlay components |
| `@fields` | Form field names with validation rules (required, optional, type constraints) | Yes for form components |
| `@submit` | What happens on form submission: endpoint, optimistic behaviour, success/error handling | Yes for form components |
| `@error` | How errors are displayed (inline, toast, banner) | Yes for forms and data-fetching components |
| `@empty` | The empty state message/UI when there's no data | Yes for list/collection components |
| `@loading` | How the loading state looks (skeleton, spinner, placeholder) | Yes for data-fetching components |
| `@responsive` | How the component adapts at breakpoints. Be specific about what changes | Recommended |
| `@variants` | Named visual variants of the component (size, colour, state) | If applicable |

**Rules for the manifest:**

- Every component visible on the page must have a `@component` block.
- Props should cover every piece of dynamic data visible in the mockup's realistic content. If the mockup shows "Project Alpha" as a title, `title: string` must be in `@props`.
- `@data` should be specific enough to write the fetch call. `GET /api/projects` is good. `"from the server"` is not.
- `@empty` and `@loading` are required for any component that fetches data — these are the states most often forgotten during conversion.
- `@responsive` should describe behaviour, not breakpoints. "Collapse to bottom nav" is better than "hidden below 768px".

### Avoid these anti-patterns

- **Deeply nested wrappers** that exist only for layout — flatten where possible.
- **Sibling-dependent styling** (`.card + .card { margin-top }`) — use gap utilities on the parent.
- **Global selectors** that style by tag name (`p { }`, `h2 { }`) — these break when components are composed.
- **Inline styles** (`style="..."`) — always use Tailwind classes or `<style>` blocks.
- **`onclick` handlers in HTML** — if JS interactivity is needed, use `data-action` attributes and a small event delegation script at the bottom of the file.
