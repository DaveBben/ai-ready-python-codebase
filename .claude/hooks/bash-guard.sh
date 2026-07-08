#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# PreToolUse hook (matcher: Bash) — two hard blocks, nothing else.
#
# WHY THIS EXISTS
#   A PreToolUse hook runs BEFORE the command executes: exit 2 cancels the
#   tool call and feeds this script's stderr back to the agent, which
#   self-corrects in the same turn.
#
# WHAT IT BLOCKS
#   1. pip installs (pip, pip3, python -m pip). They desync the environment
#      from uv.lock, the authoritative lockfile.
#   2. `git commit --no-verify` (and its short flag -n). The pre-commit hook
#      IS the quality gate; --no-verify is the one flag that skips it.
#
#   Deliberately NOT blocked: poetry/virtualenv (not installed here; a rule
#   per hypothetical tool is blocklist creep), `uv pip install` (CLAUDE.md's
#   uv-only rule covers it as advice), and inline pytest/mypy/ruff runs
#   (directly running a single test is sometimes the right move). A rule
#   earns a slot here only when violating it is never correct AND one
#   command does real damage.
#
#   Runs on every Bash call, so it stays fast: one python3 call to parse and
#   separate data from code, then pure string matching.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# Parse the command from Claude Code's stdin JSON. Malformed stdin must not
# error the hook (it would surface as a spurious failure), so no-op instead.
cmd="$(python3 -c 'import json,sys; print((json.load(sys.stdin).get("tool_input") or {}).get("command",""))' 2>/dev/null || true)"
[ -z "$cmd" ] && exit 0

# Strip heredoc bodies and quoted segments before matching: a commit message,
# README heredoc, or echoed example that merely MENTIONS "pip install" or "-n"
# is data, not a command. Whole-string regexes (multi-line safe); naive on
# nesting and escapes, which is enough for a cooperative agent. Falls back to
# the raw command if python fails, preserving plain matching.
# printf, not echo: a command starting with -n/-e must not be eaten as a flag.
stripped="$(printf '%s' "$cmd" | python3 -c '
import re, sys
s = sys.stdin.read()
s = re.sub(r"<<-? *[\x27\"]?(\w+)[\x27\"]?.*?\n\1(\n|$)", "\n", s, flags=re.S)
s = re.sub(r"\x27[^\x27]*\x27", "", s, flags=re.S)
s = re.sub(r"\"[^\"]*\"", "", s, flags=re.S)
sys.stdout.write(s)
' 2>/dev/null || printf '%s' "$cmd")"

# ── Rule 1: no pip installs ──────────────────────────────────────────────────
# Match pip at a command boundary (start of string or after ; & | ( ` to catch
# chained and substituted commands). Versioned binaries (pip3.13, python3.13)
# and the no-space "-mpip" form count too. "uv pip" has no boundary before
# "pip", so it passes.
if printf '%s\n' "$stripped" | grep -Eq '(^|[;&|(`] *)(pip3?(\.[0-9]+)? |python3?(\.[0-9]+)? -m *pip)'; then
  echo "Blocked: this repo manages its environment with uv only (see CLAUDE.md)." >&2
  echo "Use 'uv add <pkg>' to add a dependency, 'uv run <cmd>' to run tools," >&2
  echo "and 'uv sync' to build the venv. uv.lock is the source of truth." >&2
  exit 2
fi

# ── Rule 2: no skipping the commit gate ──────────────────────────────────────
# Matches --no-verify anywhere in a git commit, plus the short form: a flag
# token containing 'n' (git commit's only lowercase-n short option is
# --no-verify, so -n, -an, -sn etc. all mean "skip hooks").
if printf '%s\n' "$stripped" | grep -Eq 'git commit[^;&|]*( --no-verify| -[a-zA-Z]*n)'; then
  echo "Blocked: 'git commit --no-verify' skips the pre-commit quality gate." >&2
  echo "Run the full gate from CLAUDE.md via the test-runner agent, fix what" >&2
  echo "fails, then commit normally." >&2
  exit 2
fi

exit 0
