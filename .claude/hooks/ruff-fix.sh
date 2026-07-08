#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# PostToolUse hook — the Claude-first "deterministic guardrail" (research Pillar 3).
#
# WHY THIS EXISTS
#   A rule in CLAUDE.md is advice the model may or may not follow. A hook is
#   enforcement the harness runs FOR the model, every time, no matter what — the
#   model cannot forget it or skip it. Claude Code fires this after every Edit or
#   Write to a Python file (wired in .claude/settings.json).
#
# WHAT IT DOES
#   1. Auto-fixes and formats the edited file with ruff, so the agent never
#      spends a turn on style — it stays on logic.
#   2. Re-checks the file. If anything remains UNFIXABLE (a real problem: a
#      security finding, a blind except, an unused arg), it prints the errors to
#      stderr and exits 2. Exit code 2 tells Claude Code to feed that output back
#      to the agent, which closes the loop: edit → check → correct → re-check.
#
#   mypy/pytest are intentionally NOT run here — they need the whole package and
#   are too slow for an every-edit hook. mypy runs at turn end (Stop hook) and in
#   pre-commit; pytest runs in pre-commit and the full gate.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

root="${CLAUDE_PROJECT_DIR:-.}"

# Prefer the resolved venv binary. Calling ruff directly skips uv's per-invocation
# environment check — cheap once, but this hook runs on every edit, so three
# `uv run` calls per edit add up. Fall back to `uv run` if the venv isn't built.
if [ -x "$root/.venv/bin/ruff" ]; then
  run_ruff() { "$root/.venv/bin/ruff" "$@"; }
else
  run_ruff() { uv run ruff "$@"; }
fi

# Parse the edited path from Claude Code's stdin JSON. Empty or malformed stdin
# must NOT error the hook: under `set -e` a failed parse would surface as a
# spurious hook error to the user, so swallow it and no-op instead.
file="$(python3 -c 'import json,sys; print((json.load(sys.stdin).get("tool_input") or {}).get("file_path",""))' 2>/dev/null || true)"

# Only files inside THIS repo: the session can edit additional working dirs
# and scratchpads, and this repo's ruff rules must not be enforced there.
case "$file" in
  "$root"/*) ;;
  *) exit 0 ;;
esac

# Only act on Python files that still exist (an edit could have been a deletion).
case "$file" in
  *.py) [ -f "$file" ] || exit 0 ;;
  *)    exit 0 ;;
esac

# Step 1: fix what's mechanically fixable, then format. Silence normal output —
# the agent doesn't need to read successful housekeeping.
run_ruff check --fix "$file" >/dev/null 2>&1 || true
run_ruff format "$file" >/dev/null 2>&1 || true

# Step 2: re-check. Surface only what a human/agent must actually decide on.
# ruff exits 1 for lint findings; anything else means ruff itself broke
# (missing venv, broken uv) — report the real cause and fail open, or every
# edit would exit 2 with a phantom "lint" error.
set +e
output="$(run_ruff check "$file" 2>&1)"
code=$?
set -e

if [ "$code" -eq 1 ]; then
  echo "ruff found issues in $file that need a real fix (not auto-fixable):" >&2
  echo "$output" >&2
  exit 2
elif [ "$code" -ne 0 ]; then
  echo "ruff-fix hook: ruff failed to run (exit $code) — not a lint finding:" >&2
  echo "$output" >&2
fi

exit 0
