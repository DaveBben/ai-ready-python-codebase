#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Stop hook — whole-package type check before the agent hands work back.
#
# WHY THIS EXISTS
#   The PostToolUse ruff hook deliberately skips mypy: mypy needs the whole
#   package and is too slow to run on every edit. The Stop event fires once,
#   when Claude believes it is finished — the right moment for a slower,
#   whole-package check. Exit 2 blocks the stop and returns the type errors,
#   so the agent fixes them before a human ever reviews the work.
#
# WHY ONLY MYPY
#   The full gate (vulture, pip-audit, pytest --cov) belongs in pre-commit and
#   CI. A Stop hook fires at the end of EVERY turn, including trivial ones;
#   pip-audit needs the network and pytest can take a while. mypy with a warm
#   cache is cheap enough, and type errors are the failure ruff can't catch.
#
# LOOP SAFETY
#   Two guards prevent runaway loops and pointless runs:
#   1. A per-session retry counter, keyed by session_id in TMPDIR. Each
#      blocked stop increments it; a green check clears it. After 3 blocks
#      the hook gives up and lets the stop through, so an unfixable error
#      can't trap the agent forever. (This replaces the old stop_hook_active
#      bail, which verified only once — the fix made after the first block
#      was never re-checked.)
#   2. Skip entirely when no .py file is modified (vs HEAD or untracked):
#      a Q&A turn that edited nothing shouldn't pay for a type check.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

root="${CLAUDE_PROJECT_DIR:-.}"

# Guard 1: retry counter (see LOOP SAFETY above).
sid="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("session_id",""))' 2>/dev/null || true)"
counter="${TMPDIR:-/tmp}/claude-stop-mypy-${sid:-unknown}"
count="$(cat "$counter" 2>/dev/null || true)"
case "$count" in ''|*[!0-9]*) count=0 ;; esac

cd "$root"

# Guard 2: only type-check when Python files actually changed this session.
# `git status --porcelain -- '*.py'` covers modified AND untracked files.
changed="$(git status --porcelain -- '*.py' 2>/dev/null || true)"
[ -z "$changed" ] && exit 0

if ! output="$(uv run mypy src 2>&1)"; then
  if [ "$count" -ge 3 ]; then
    # Give up: an error the agent couldn't fix in 3 tries won't yield to a 4th
    # block. Clear the counter so a later turn gets a fresh budget.
    rm -f "$counter"
    echo "stop-mypy: still red after 3 blocked stops — letting the stop through." >&2
    exit 0
  fi
  echo $((count + 1)) > "$counter"
  echo "mypy --strict failed. Fix these before finishing (CLAUDE.md: every function fully typed):" >&2
  echo "$output" >&2
  exit 2
fi

rm -f "$counter"
exit 0
