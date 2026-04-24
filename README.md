# mob-boss

> Claude Code plugin — AI agent team orchestration with tiered incremental review, metrics-driven evolution, and per-package knowledge accumulation.

## What it does

Mob-boss orchestrates a team of specialised AI agents to deliver features end-to-end:

- **Architect** — designs implementation plans, verifies claims against actual code, enforces vertical-first phase shape
- **Designer** — produces HTML/CSS/JS prototypes as contracts, with component manifests for 1:1 conversion
- **Developer** — implements features with TDD discipline, emits tiered review signals (unit → composite → feature)
- **Reviewer** — tier-aware code review with stack-specific checklists (React web supported)
- **Project Expert** — accumulates package-specific knowledge across dispatches, orients every agent, offers opinions on HOW

The mob-boss skill itself is the top-level orchestrator — it dispatches the team, monitors metrics, and evolves agent definitions through patient A/B testing (minimum 5 tasks, 3 pattern occurrences before any modification).

## Installation

```bash
# Add the marketplace
/plugin marketplace add exadev/mob-boss

# Install the plugin
/plugin install mob-boss@exadev-mob-boss
```

## Usage

```bash
# Check in-progress dispatch status
/mob-boss:mob-boss

# Start a new task
/mob-boss:mob-boss Implement user authentication with OAuth2

# Resume an interrupted dispatch
/mob-boss:mob-boss resume

# Close out an in-progress dispatch without further work
/mob-boss:mob-boss close-out
```

## Requirements

### Platform file-watcher (mandatory)

The orchestration loop relies on file-watching for real-time signal coordination:

- **macOS**: `brew install fswatch`
- **Linux**: `sudo apt install inotify-tools` (or your distro's equivalent)

### Supported stacks

Stack-specific guidance is provided for:

| Stack | Architect | Developer | Designer | Reviewer |
|---|---|---|---|---|
| React on web (Next.js, Vite, CRA) | ✅ | ✅ | ✅ | ✅ |
| React Native | — | — | — | — |
| Other | Falls back to base rules | Falls back to base rules | Falls back to base rules | Falls back to base rules |

## How it works

### Per-dispatch flow

1. **Phase 1** — Architect and designer collaborate to produce a unified design (plan + prototype)
2. **Phase 2** — Developer implements in chunked slices with tiered review signals
3. **Phase 3** — Close-out: archive, metrics, project-expert curation, user report

### Tiered review

Every chunk emits a review signal at one of three tiers:

| Tier | Scope | Focus |
|---|---|---|
| Unit (~50–150 lines) | One testable piece | Correctness, conventions, local bugs |
| Composite | A cohesive slice of units | Coherence, boundary tests, duplication |
| Feature | The whole feature | Architecture, plan compliance, security, integration |

### Agent evolution

Mob-boss tracks metrics across dispatches and evolves agent profiles when thresholds are met:

- **Minimum 5 completed tasks** before any agent modification
- **Minimum 3 occurrences** of a metric pattern before it's considered systemic
- All changes are logged in the changelog with evidence

### Project expert

Each package accumulates knowledge:

- `@expert:` tags in agent reports surface facts worth remembering
- Close-out curation investigates, cross-references, and records into `.mob-boss/expert/knowledge/`
- The orientation snippet is injected into every agent spawn in future dispatches

### State layout

| Location | Purpose |
|---|---|
| `${CLAUDE_SKILL_DIR}/` (plugin) | Read-only: canonical agent profiles, templates, preamble |
| `~/.mob-boss/` (global) | Mutable: evolved agents, experiment variants, metrics, changelog |
| `<package>/.mob-boss/` (per-package) | Mutable: signals, feedback, archive, project-expert knowledge |

## Structure

```
plugins/mob-boss/
├── .claude-plugin/plugin.json
└── skills/
    ├── mob-boss/
    │   ├── SKILL.md                      # Orchestrator instructions
    │   ├── preamble.sh                   # Runtime environment setup + global state seeding
    │   ├── agents/main/                  # Canonical agent profiles
    │   │   ├── architect.md + guidance/
    │   │   ├── developer.md + guidance/
    │   │   ├── designer.md + guidance/
    │   │   ├── reviewer.md + guidance/
    │   │   └── project-expert.md
    │   └── templates/                    # Copied into each new package on init
    └── team-manager/
        ├── SKILL.md                      # Dispatch coordinator
        └── context.sh                    # Agent profile loading
```

## Licence

This plugin is the property of ExaDev Ltd. See the licence template in `templates/LICENSE.md` for terms applied to generated orchestration artefacts.
