# CLAUDE.md

Guidance for AI coding agents working in this repository.

## Contents

1. [Project Identity](#project-identity)
2. [Tech Stack and Codebase Map](#tech-stack-and-codebase-map)
3. [Operational Commands](#operational-commands)
4. [Workflow](#workflow)
5. [Critical Constraints](#critical-constraints)
6. [Pointers to Deeper Docs](#pointers-to-deeper-docs)

## Project Identity

A template Python codebase built to be Claude-first: fast, deterministic feedback loops (lint, types, tests, hooks) that let a coding agent verify its own work before a human looks at it. It serves engineers scaffolding a new Python project, and the agents working alongside them.

## Tech Stack and Codebase Map

- **Language**: Python. Dev on 3.13 (`.python-version`). Support floor is 3.12.
- **Package manager**: uv (`uv.lock` is authoritative).
- **Runtime dependencies**: none. This is a scaffold; add yours with `uv add`.
- **Tooling**: ruff (lint + format), mypy (strict types), pytest (tests), vulture (dead code), pip-audit (dependency CVEs), pre-commit (commit-time gate).
- **Container**: multi-stage `Dockerfile` (uv build → minimal non-root runtime) and a `docker-compose.yml` for one-shot runs.

### Directory Layout

- `src/example_project/` — example package
- `tests/` — pytest suite
- `docs/` — project documentation
- `.claude/` — Claude Code settings, hooks, and subagents
- `.devcontainer/` — isolated dev/agent environment (uv + commit gate on create)
- `.vscode/` — VS Code settings
- `.github/` — CI workflow (runs the full gate on PRs) and the PR template

## Operational Commands

```bash
uv sync                      # install deps (including dev group)
uv run example-project   # run the CLI
uv run pytest                # all tests
uv run pytest path::test     # a single test
uv run pytest --cov          # tests with coverage
uv run mypy src              # strict type check
uv run ruff check src tests  # lint
uv run ruff format src tests # format
uv run vulture               # dead-code scan
uv run pip-audit             # dependency CVE scan
uv run pre-commit install    # enable git-commit guardrails (one time)
```

The full gate, as one line (pre-commit enforces all of it at commit except the coverage report; use this for CI or an on-demand full check):

```bash
uv run ruff check src tests && uv run ruff format --check src tests \
  && uv run mypy src && uv run vulture && uv run pip-audit && uv run pytest --cov
```

## Workflow

**Use TDD.** Write the failing test first and confirm it fails, then write the minimal code to pass.

## Critical Constraints

- **Every function must be fully type-annotated.** mypy runs `--strict`; untyped code fails.
- **Behavior changes ship with tests.** New behavior gets a test at its public seam; bug fixes get a failing regression test first. How and where: `.claude/skills/writing-tests/SKILL.md`.
- **Fail loud.** Raise a subclass of `ExampleProjectError`; never swallow an exception silently (the linter enforces this: see BLE/TRY in pyproject).
- **Run the checks; don't just trust the diff.** Never claim a check passed without running it. pre-commit enforces the gate at commit, including pip-audit whenever `uv.lock` changes.
- **Keep the docs current.** When a change makes this file, the README, or a nested `CLAUDE.md` wrong, fix it in the same change. Stale docs mislead the next agent, which is worse than no docs. This includes the directory layout in any `CLAUDE.md`.

## Pointers to Deeper Docs

- `README.md` — overview and quick start.
- `docs/explanation/repo_defaults/` — the full rationale behind every tool, ruff rule, and default configuration choice in this repo.
