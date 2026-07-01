#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# PostToolUse hook — the AI-first "deterministic guardrail" (research Pillar 3).
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
#   are too slow for an every-keystroke hook. They run in pre-commit and CI, and
#   are listed in CLAUDE.md's "Before creating a PR" gate.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# Claude Code passes the tool call as JSON on stdin. Pull out the edited path.
# (python3 is guaranteed present in a Python project, so no jq dependency.)
file="$(python3 -c 'import json,sys; print((json.load(sys.stdin).get("tool_input") or {}).get("file_path",""))')"

# Only act on Python files that still exist (an edit could have been a deletion).
case "$file" in
  *.py) [ -f "$file" ] || exit 0 ;;
  *)    exit 0 ;;
esac

# Step 1: fix what's mechanically fixable, then format. Silence normal output —
# the agent doesn't need to read successful housekeeping.
uv run ruff check --fix "$file" >/dev/null 2>&1 || true
uv run ruff format "$file" >/dev/null 2>&1 || true

# Step 2: re-check. Surface only what a human/agent must actually decide on.
if ! output="$(uv run ruff check "$file" 2>&1)"; then
  echo "ruff found issues in $file that need a real fix (not auto-fixable):" >&2
  echo "$output" >&2
  exit 2
fi

exit 0
