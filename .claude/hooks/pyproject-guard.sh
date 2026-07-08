#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# PostToolUse hook (matcher: Edit|Write|MultiEdit) — keep pyproject.toml and uv.lock in sync.
#
# WHY THIS EXISTS
#   CLAUDE.md forbids hand-editing dependencies in pyproject.toml: uv.lock is
#   authoritative, and a hand-edited dependency silently desyncs the two. This
#   hook fires after any edit; if the edited file is pyproject.toml it asks uv
#   whether the lockfile still matches. Exit 2 feeds the drift back to the
#   agent so it reverts the hand-edit and uses `uv add` / `uv remove` instead.
#
#   Edits to non-dependency sections (ruff config, pytest config, etc.) pass
#   the check untouched — `uv lock --check` only fails on dependency drift.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

root="${CLAUDE_PROJECT_DIR:-.}"

# Parse the edited path from stdin JSON; swallow parse failures (see ruff-fix.sh).
file="$(python3 -c 'import json,sys; print((json.load(sys.stdin).get("tool_input") or {}).get("file_path",""))' 2>/dev/null || true)"

# Only act on THIS repo's pyproject.toml — an edit to some other project's
# pyproject.toml must not be judged against this repo's lockfile.
case "$file" in
  "$root"/pyproject.toml|pyproject.toml) ;;
  *) exit 0 ;;
esac
[ -f "$file" ] || exit 0

cd "$root"

if ! output="$(uv lock --check 2>&1)"; then
  echo "pyproject.toml no longer matches uv.lock:" >&2
  echo "$output" >&2
  echo "" >&2
  echo "Dependencies must be changed with 'uv add <pkg>' / 'uv remove <pkg>'," >&2
  echo "never by hand-editing pyproject.toml (see CLAUDE.md). If this edit was" >&2
  echo "intentional and non-dependency, something else broke the lock — run" >&2
  echo "'uv lock' to regenerate it." >&2
  exit 2
fi

exit 0
