# CLAUDE.md

Guidance for AI coding agents working in this repository. Kept deliberately
short and high-signal: every line here spends context on every turn, so bloat
makes the agent *ignore* the rules that matter. Module-specific patterns live in
nested files (e.g. `src/ai_ready_python_codebase/CLAUDE.md`) that load only when
you touch that directory.

## Project overview

A template Python codebase designed to be AI-first: fast, deterministic feedback
loops (lint, types, tests, hooks) that let an agent verify its own work.

## Golden rules

- **Use `uv` for everything.** Never call `pip`, `poetry`, `python -m venv`, or a
  global `python` directly. Dependencies: `uv add` / `uv add --dev`, never edit
  `pyproject.toml` deps by hand. This keeps `uv.lock` authoritative.
- **Every function is fully type-annotated.** mypy runs in `--strict`; untyped
  code fails. No bare `# type: ignore` — cite the error code.
- **Fail loud.** Raise a subclass of `AiReadyPythonCodebaseError`; never swallow
  an exception silently (the linter enforces this — see BLE/TRY in pyproject).
- **Run the checks; don't just trust the diff.** After a change, run the
  verification loop below. Listing a command is not running it.

## Development commands

```bash
uv sync                      # install deps (including dev group)
uv run ai-ready-python-codebase   # run the CLI
uv run pytest                # all tests
uv run pytest path::test     # a single test
uv run pytest --cov          # tests with coverage
uv run mypy src              # strict type check
uv run ruff check src tests  # lint
uv run ruff format src tests # format
uv run pre-commit install    # enable git-commit guardrails (one time)
```

## Tech stack (pinned — do not assume newer/older APIs)

- **Python**: dev on 3.13; supported floor is 3.12 (`requires-python`). Ruff
  lints against 3.12, so don't emit 3.13-only syntax.
- **httpx** ≥0.28 — async HTTP client (do not add `requests`).
- **pydantic** ≥2.10 / **pydantic-settings** ≥2.6 — models and config.
- **structlog** ≥24.4 — structured logging (see logger.py).
- Tooling: **uv**, **ruff**, **mypy**, **pytest**, **vulture**.

## Project structure

- `src/ai_ready_python_codebase/` — the package (src layout; import absolutely as
  `from ai_ready_python_codebase... import ...`, never relative).
  - `config.py` — `Settings` (env-driven). Mirror new settings in `.env.example`.
  - `logger.py` — logging setup; get a logger with `get_logger(__name__)`.
  - `exceptions.py` — exception hierarchy rooted at `AiReadyPythonCodebaseError`.
  - `__main__.py` — CLI entry point.
- `tests/` — pytest suite; `conftest.py` holds fixtures.

## Verification loop (run before every PR)

```bash
uv run ruff check src tests && uv run ruff format --check src tests \
  && uv run mypy src && uv run vulture && uv run pytest --cov
```

CI runs the same gate on push and PR. A `PostToolUse` hook auto-formats and
re-lints each file you edit, so style is handled for you — spend your turns on
logic, not formatting.
