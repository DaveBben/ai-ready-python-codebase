# How the repo instructs agents

A few files configure an agent: a canonical instructions file, its per-module extensions, path-scoped rule files, a Claude Code settings file, and hook scripts. Together they give an agent rules it can read cheaply and feedback it cannot ignore.

## `CLAUDE.md`, the canonical instructions file

`CLAUDE.md` is the single source of truth for agent instructions. It stays short on purpose: every line spends context on every turn, so bloat makes an agent *ignore* the rules that matter.

## Nested `CLAUDE.md` files, loaded on demand

The root file carries only project-wide rules. Module-specific patterns live in nested files that load only when an agent touches that directory.

This is a context-budget strategy. Detailed conventions in the root file cost tokens on every turn, but most turns don't touch a given package. Scoping them to a nested file means an agent loads them only while working in that directory, next to the code they govern. Each package carries its own file, and the agent assembles exactly the ruleset for where it is working.

## Path-scoped rules

Topic rules live in `.claude/rules/`. Claude Code auto-discovers every `.md` file there, and each declares a `paths:` glob in its front matter so it loads only when Claude touches a matching file. This is the nested-`CLAUDE.md` move keyed to file globs rather than directories: the Python guidance arrives only when Python is in play. The repo ships two.

| Rule | Scopes to | What it says |
|---|---|---|
| `code.md` | `**/*.py` | After a significant change, review the diff with the `code-reviewer` agent. |
| `tests.md` | `tests/**`, `src/**/*.py` | The TDD loop: one verified-red test, minimal green, refactor only on green, done means the suite passed. |

## `.claude/settings.json`

This file configures Claude Code. Four parts matter.

**Schema.** A `$schema` reference points editors at the settings schema for validation and autocomplete, catching typos in the config itself.

**Allow list.** The `allow` list pre-approves the verification commands an agent needs to check its own work (`uv sync`, the `uv run` toolchain, and `test`), so it runs them without stopping to ask.

**Deny list.** The `deny` list hard-blocks access regardless of anything else, and deny beats allow:

- `.env*` files are sealed from the file tools (not readable, editable, or writable), so secrets never reach the model's context by accident. The glob covers variants like `.env.local`.
- `uv.lock` is write-blocked, enforcing the uv-only rule.
- `.git/**` is edit- and write-blocked, keeping the agent out of git internals (a writable `.git/hooks/` would let a stray file silently disable the commit gate).

The deny list stops accidents; it is not a security boundary. Anything on the allow list that executes code (`uv run pytest`, `uv run pre-commit`) can read any file the user can, including `.env`. Real secrets belong outside the repo directory.

**Hooks.** Every script in `.claude/hooks/` turns a written rule into enforcement the agent cannot skip, each wired to the event where enforcement is cheapest:

| Hook | Event | Enforces |
|---|---|---|
| `bash-guard.sh` | `PreToolUse` on `Bash` | Blocks pip installs (`pip`, `python -m pip`) and the one command that skips the commit gate (`git commit --no-verify`). Runs before the command executes, so the mistake never happens. |
| `ruff-fix.sh` | `PostToolUse` on `Edit\|Write\|MultiEdit` | Style and lint on the edited file. See [the verification loop](verification-loop.md). |
| `pyproject-guard.sh` | `PostToolUse` on `Edit\|Write\|MultiEdit` | `uv.lock` stays in sync with `pyproject.toml`, so dependencies change only through `uv add` / `uv remove`. |
| `stop-mypy.sh` | `Stop` | Whole-package `mypy --strict` before the agent hands work back, skipped when no Python file changed. |
| `session-start.sh` | `SessionStart` | Injects environment readiness (`.venv` built and in sync) and uncommitted work into the agent's opening context. |

A blocking hook exits 2 and prints its reason to stderr; Claude Code feeds that text back to the agent, which corrects course in the same turn. `PreToolUse` guards run on every Bash call, so they stay pure string matching; the slower whole-package check waits for the `Stop` event, which fires once per turn.

The dividing line: a rule goes in a hook only when violating it is *never* correct. The TDD loop stays prose on purpose, since an exploratory spike before the first test is sometimes the right move and a hard block would fight that.
