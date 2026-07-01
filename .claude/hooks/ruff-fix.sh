#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# PostToolUse hook — the AI-first "deterministic guardrail" (research Pillar 3).
#
# WHY THIS EXISTS
#   A rule in AGENTS.md is advice the model may or may not follow. A hook is
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
#   are too slow for an every-edit hook. They run in pre-commit and CI, and are
#   listed in AGENTS.md's "Verification loop" gate.
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
if ! output="$(run_ruff check "$file" 2>&1)"; then
  echo "ruff found issues in $file that need a real fix (not auto-fixable):" >&2
  echo "$output" >&2
  exit 2
fi

exit 0
