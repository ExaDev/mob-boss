#!/usr/bin/env bash
# mob-boss preamble — executed when the /mob-boss skill loads.
#
# Responsibilities:
#   1. Locate the current package root
#   2. Detect platform (Linux/macOS) and verify the file-watcher binary
#   3. Initialize .mob-boss/ if this is the first dispatch in this package
#   4. Detect stale in-progress dispatches and surface them for resume
#   5. Emit the exact Monitor command the orchestrator must invoke first
#   6. Load global metrics + the project expert orientation snippet
#
# Never exits non-zero silently — always explains what's wrong.

set -u

# Prefer the plugin's SKILL_DIR variable when available (Claude Code plugin context).
# Fall back to script-relative path for standalone / symlink installs.
if [[ -n "${CLAUDE_SKILL_DIR:-}" ]]; then
  SKILL_DIR="$CLAUDE_SKILL_DIR"
else
  SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# --- 1. Find the package root (polyglot: walk up looking for any recognised package marker) ---
# Recognises: CLAUDE.md (Anthropic convention), package.json (Node), pyproject.toml /
# setup.py / manage.py (Python), Cargo.toml (Rust), go.mod (Go), Gemfile (Ruby), pom.xml
# or build.gradle (Java), composer.json (PHP), Package.swift (Swift).
# Refuses monorepo roots: a directory that (a) matches a marker AND (b) has a packages/
# subdir AND (c) is the git top-level is treated as a monorepo root, not a package — the
# user must cd into a specific package.
find_package_root() {
  local dir="$PWD"
  local git_top=""
  git_top="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null || true)"

  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/CLAUDE.md" ]] \
       || [[ -f "$dir/package.json" ]] \
       || [[ -f "$dir/pyproject.toml" ]] \
       || [[ -f "$dir/setup.py" ]] \
       || [[ -f "$dir/manage.py" ]] \
       || [[ -f "$dir/Cargo.toml" ]] \
       || [[ -f "$dir/go.mod" ]] \
       || [[ -f "$dir/Gemfile" ]] \
       || [[ -f "$dir/pom.xml" ]] \
       || [[ -f "$dir/build.gradle" ]] \
       || [[ -f "$dir/composer.json" ]] \
       || [[ -f "$dir/Package.swift" ]]; then
      # Monorepo root guard
      if [[ -d "$dir/packages" ]] && [[ -n "$git_top" ]] && [[ "$git_top" == "$dir" ]]; then
        echo "__MONOREPO_ROOT__:$dir"
        return 0
      fi
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  echo "__NOT_FOUND__"
  return 0
}

PKG_ROOT_RAW="$(find_package_root)"

if [[ "$PKG_ROOT_RAW" == __MONOREPO_ROOT__:* ]]; then
  MONOREPO="${PKG_ROOT_RAW#__MONOREPO_ROOT__:}"
  cat <<EOF
ERROR: mob-boss cannot initialise at a monorepo root.

  Detected monorepo root: $MONOREPO
  (has packages/ subdirectory and is the git top-level)

  cd into a specific package first, e.g.:
    cd $MONOREPO/packages/<package-name>

  Then re-invoke /mob-boss.
EOF
  exit 1
fi

if [[ "$PKG_ROOT_RAW" == "__NOT_FOUND__" ]]; then
  cat <<EOF
ERROR: mob-boss cannot locate a package root.

  No package marker (CLAUDE.md, package.json, pyproject.toml, setup.py, manage.py,
  Cargo.toml, go.mod, Gemfile, pom.xml, build.gradle, composer.json, Package.swift)
  found in any parent directory of:
    $PWD

  cd into a package directory and try again.
EOF
  exit 1
fi

PKG_ROOT="$PKG_ROOT_RAW"
MB_DIR="$PKG_ROOT/.mob-boss"

echo "=== mob-boss session ==="
echo "Package root: $PKG_ROOT"

# --- 2. Platform detect + watcher check ---
case "$(uname -s)" in
  Linux*)
    PLATFORM=linux
    if ! command -v inotifywait >/dev/null 2>&1; then
      cat <<EOF
ERROR: mob-boss requires 'inotifywait' on Linux for reliable file-watching.
  Install: sudo apt install inotify-tools   (or your distro's equivalent)
  This is a one-time setup. The tool emits kernel-level file events, avoiding
  expensive polling loops.
EOF
      exit 1
    fi
    # Note: we single-quote $MB_DIR so it expands here, and leave the command
    # shell-ready. Claude passes this verbatim to the Monitor tool.
    #
    # IMPORTANT: watch BOTH create AND moved_to. Atomic writes (temp file +
    # rename to final name — Node's fs.writeFile, Edit tool, many editors) only
    # fire CREATE on the .tmp file and MOVED_TO on the final — watching CREATE
    # alone fires for the .tmp.* filename but misses the real signal filename.
    WATCH_CMD="inotifywait -m -e create -e moved_to --format '%w%f' '$MB_DIR/signals/' '$MB_DIR/feedback/'"
    ;;
  Darwin*)
    PLATFORM=macos
    if ! command -v fswatch >/dev/null 2>&1; then
      cat <<EOF
ERROR: mob-boss requires 'fswatch' on macOS for reliable file-watching.
  Install: brew install fswatch
  This is a one-time setup. The tool emits kernel-level file events (FSEvents),
  avoiding expensive polling loops.
EOF
      exit 1
    fi
    # IMPORTANT: include Renamed + MovedTo alongside Created. Atomic writes land
    # via rename on macOS FSEvents — Created alone misses the final filename.
    WATCH_CMD="fswatch -0 --event Created --event Renamed --event MovedTo '$MB_DIR/signals/' '$MB_DIR/feedback/' | tr '\0' '\n'"
    ;;
  *)
    echo "ERROR: mob-boss only supports Linux and macOS (got: $(uname -s))"
    exit 1
    ;;
esac

echo "Platform: $PLATFORM"

# --- 3. Initialize .mob-boss/ if missing ---
FRESH_INIT=false
if [[ ! -d "$MB_DIR" ]]; then
  FRESH_INIT=true
  echo ""
  echo "First-time setup: creating $MB_DIR/"
  mkdir -p "$MB_DIR"/{signals,feedback,archive,progress,expert/knowledge}

  # Gitignore the whole .mob-boss/ directory (machine-local for now)
  if [[ -f "$PKG_ROOT/.gitignore" ]]; then
    if ! grep -qxF ".mob-boss/" "$PKG_ROOT/.gitignore"; then
      {
        echo ""
        echo "# mob-boss orchestration state (machine-local)"
        echo ".mob-boss/"
      } >> "$PKG_ROOT/.gitignore"
      echo "  Added .mob-boss/ to $PKG_ROOT/.gitignore"
    fi
  else
    {
      echo "# mob-boss orchestration state (machine-local)"
      echo ".mob-boss/"
    } > "$PKG_ROOT/.gitignore"
    echo "  Created $PKG_ROOT/.gitignore with .mob-boss/ entry"
  fi

  # Copy templates into the new .mob-boss/
  if [[ -f "$SKILL_DIR/templates/LICENSE.md" ]]; then
    cp "$SKILL_DIR/templates/LICENSE.md" "$MB_DIR/LICENSE.md"
  fi
  if [[ -f "$SKILL_DIR/templates/project-expert-seed.md" ]]; then
    cp "$SKILL_DIR/templates/project-expert-seed.md" "$MB_DIR/expert/agent.md"
  fi

  echo "  Initialized signals/ feedback/ archive/ progress/ expert/"
fi

# Ensure subdirs exist even if someone partially cleaned up
mkdir -p "$MB_DIR"/{signals,feedback,archive,progress,expert/knowledge}

# --- 4. Stale-dispatch detection ---
PROGRESS_LOG="$MB_DIR/progress/events.jsonl"
HAS_STALE=false
DISPATCH_ID=""
DISPATCH_PHASE=""

if [[ -s "$PROGRESS_LOG" ]]; then
  # Last dispatch_started event
  LAST_STARTED_LINE="$(grep -n '"event":"dispatch_started"' "$PROGRESS_LOG" | tail -1 | cut -d: -f1)"
  LAST_CLOSED_LINE="$(grep -n '"event":"dispatch_closed"' "$PROGRESS_LOG" | tail -1 | cut -d: -f1)"
  LAST_STARTED_LINE="${LAST_STARTED_LINE:-0}"
  LAST_CLOSED_LINE="${LAST_CLOSED_LINE:-0}"

  if [[ "$LAST_STARTED_LINE" -gt "$LAST_CLOSED_LINE" ]]; then
    HAS_STALE=true
    # Extract dispatch_id from the started event (simple sed — avoids jq dep)
    DISPATCH_ID=$(sed -n "${LAST_STARTED_LINE}p" "$PROGRESS_LOG" | \
      sed -n 's/.*"dispatch_id":"\([^"]*\)".*/\1/p')
    # Last phase_transition event after that start line
    LAST_PHASE=$(tail -n +"$LAST_STARTED_LINE" "$PROGRESS_LOG" | \
      grep '"event":"phase_transition"' | tail -1 | \
      sed -n 's/.*"phase":"\([^"]*\)".*/\1/p')
    DISPATCH_PHASE="${LAST_PHASE:-dispatch_started}"
  fi
fi

echo ""
if [[ "$HAS_STALE" == "true" ]]; then
  echo "=== In-progress dispatch detected ==="
  echo "Dispatch ID: $DISPATCH_ID"
  echo "Last phase: $DISPATCH_PHASE"
  echo ""
  echo "Recent events (last 10):"
  tail -10 "$PROGRESS_LOG"
  echo ""

  UNPROCESSED_SIGNALS="$(find "$MB_DIR/signals/" -maxdepth 1 -type f -name '*.md' 2>/dev/null | grep -v '_CHECKED\|_DONE' | head -20)"
  UNPROCESSED_FEEDBACK="$(find "$MB_DIR/feedback/" -maxdepth 1 -type f -name '*.md' 2>/dev/null | grep -v '_ADDRESSED\|_DONE\|_ANSWERED\|_RECEIVED' | head -20)"

  if [[ -n "$UNPROCESSED_SIGNALS" ]]; then
    echo "Unprocessed signal files:"
    echo "$UNPROCESSED_SIGNALS" | sed 's|^|  |'
  else
    echo "No unprocessed signal files."
  fi
  if [[ -n "$UNPROCESSED_FEEDBACK" ]]; then
    echo "Pending feedback files:"
    echo "$UNPROCESSED_FEEDBACK" | sed 's|^|  |'
  fi

  # Dispatch-context (resume fallback standing-context file)
  DISPATCH_CONTEXT="$MB_DIR/dispatch-context.md"
  if [[ -f "$DISPATCH_CONTEXT" ]]; then
    DC_AGE=$(( ($(date +%s) - $(stat -c %Y "$DISPATCH_CONTEXT" 2>/dev/null || stat -f %m "$DISPATCH_CONTEXT")) / 60 ))
    echo "Dispatch-context file: $DISPATCH_CONTEXT (last modified ${DC_AGE} min ago)"
    echo "  Fresh agent spawns on this dispatch should reference this file for standing context"
    echo "  instead of re-pasting the approved design. Check the ## Amendments section for"
    echo "  mid-dispatch changes before resuming."
  else
    echo "Dispatch-context file NOT FOUND at $DISPATCH_CONTEXT."
    echo "  This dispatch started before the v1.2 fallback pattern — if resuming, either"
    echo "  (a) write one now from the archive/recent-events and use it going forward, or"
    echo "  (b) proceed with inline-plan spawns as before (no break, just less efficient)."
  fi
  echo ""
  echo "RESUME_OR_FRESH: a dispatch is in flight. Ask the user: resume, close out, or start new?"
  echo ""
fi

# --- 5. Emit mandatory Monitor command for Claude ---
cat <<EOF
=== MANDATORY FIRST ACTION ===
Before any other tool call — including before dispatching the developer or the
team-manager — you MUST start the Monitor tool with the command below and
persistent=true. The coordination loop is blind without it.

Monitor command (verbatim, copy into the Monitor tool's 'command' parameter):

  $WATCH_CMD

This streams one line per file creation into your context as a notification.
No polling, no missed signals. Do not skip this step.

EOF

# --- 6. Global metrics context ---
GLOBAL_METRICS="$HOME/.claude/skills/mob-boss/metrics"

echo "=== Current Metrics (global) ==="
if [[ -f "$GLOBAL_METRICS/summary.md" ]]; then
  cat "$GLOBAL_METRICS/summary.md"
else
  echo "(no metrics yet)"
fi
echo ""

echo "=== Recent Task Log (last 20 lines) ==="
if [[ -s "$GLOBAL_METRICS/team-log.jsonl" ]]; then
  tail -20 "$GLOBAL_METRICS/team-log.jsonl"
else
  echo "(empty)"
fi
echo ""

echo "=== Changelog ==="
if [[ -f "$HOME/.claude/skills/mob-boss/changelog/CHANGELOG.md" ]]; then
  head -30 "$HOME/.claude/skills/mob-boss/changelog/CHANGELOG.md"
else
  echo "(no changelog yet)"
fi
echo ""

# --- 7. Project expert orientation snippet ---
echo "=== Project Expert Orientation ==="
if [[ -f "$MB_DIR/expert/agent.md" ]]; then
  echo "Expert profile: $MB_DIR/expert/agent.md"
  # Pull a short orientation section (~40 lines) for context injection
  head -60 "$MB_DIR/expert/agent.md"
  echo ""
  if [[ -d "$MB_DIR/expert/knowledge" ]] && [[ -n "$(ls -A "$MB_DIR/expert/knowledge" 2>/dev/null)" ]]; then
    echo "Knowledge base entries:"
    ls -1 "$MB_DIR/expert/knowledge/" | sed 's|^|  |'
  else
    echo "(expert knowledge base is empty — expert will accrue facts during dispatches)"
  fi
else
  echo "(no expert yet; will be seeded on first dispatch using the template)"
fi
echo ""

# --- 8. Env summary ---
cat <<EOF
=== Environment ===
Package root:  $PKG_ROOT
.mob-boss:     $MB_DIR
Signals:       $MB_DIR/signals/
Feedback:      $MB_DIR/feedback/
Progress log:  $PROGRESS_LOG
Archive:       $MB_DIR/archive/
Expert:        $MB_DIR/expert/
Platform:      $PLATFORM
Fresh init:    $FRESH_INIT
Stale:         $HAS_STALE

EOF
