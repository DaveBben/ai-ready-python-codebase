#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SessionStart hook — inject repo readiness into the agent's opening context.
#
# WHY THIS EXISTS
#   Anything this script prints to stdout is added to the agent's context at
#   session start (and on /clear and resume, when the built-in git snapshot
#   may be stale). It answers two questions the agent otherwise burns turns
#   discovering:
#     1. Is the environment ready? (.venv built and in sync with uv.lock)
#     2. Is there work in flight? (uncommitted changes)
#
#   Keep this fast and read-only: it runs at the start of EVERY session, and
#   its output is context the agent pays for on every turn. Print only what
#   changes behavior; never fix anything from here.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

root="${CLAUDE_PROJECT_DIR:-.}"
cd "$root"

# Environment readiness: a missing or stale venv makes every uv-run tool
# resolve from scratch. Tell the agent up front instead of letting the first
# test run fail confusingly.
if ! command -v uv >/dev/null 2>&1; then
  echo "NOTE: uv is not on PATH — install uv before using any tooling."
elif [ ! -d .venv ]; then
  echo "NOTE: .venv is missing — run 'uv sync' before using any tooling."
elif ! uv sync --check >/dev/null 2>&1; then
  echo "NOTE: .venv is out of sync with uv.lock — run 'uv sync'."
fi

# Work in flight. The harness injects a git snapshot at startup, but not after
# /clear or on resumed sessions; this keeps the picture current.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  dirty="$(git status --short)"
  if [ -n "$dirty" ]; then
    echo "Uncommitted changes at session start:"
    echo "$dirty"
  fi
fi

exit 0
