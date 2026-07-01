# ai-ready-python-codebase

A template Python codebase designed to be **AI-first**: it gives coding agents
fast, deterministic feedback loops so they can verify their own work.

What makes it AI-first:

- **`CLAUDE.md` / `AGENTS.md`** — agent instructions in the open standard format
  (`AGENTS.md` is a symlink to `CLAUDE.md`; other tools read it too). Nested
  `CLAUDE.md` files add per-directory context on demand.
- **A strict, opinionated ruff ruleset** — each family chosen to catch a mistake
  agents commonly make; the rationale is commented inline in `pyproject.toml`.
- **mypy `--strict`** plus extra error codes that ban vague `# type: ignore`.
- **Layered guardrails** — a Claude Code `PostToolUse` hook auto-formats edits,
  pre-commit gates every commit, and CI enforces the same loop on every PR.
- **`.env.example`** — a discoverable, committed config contract.

## Development

```bash
# Install dependencies
uv sync

# Set up local configuration
cp .env.example .env

# Run tests
uv run pytest

# Run tests with coverage
uv run pytest --cov

# Type checking
uv run mypy src

# Linting and formatting
uv run ruff check src tests
uv run ruff format src tests

# Run the CLI
uv run ai-ready-python-codebase

# Install pre-commit hooks
uv run pre-commit install
```

## Before Creating PR

```bash
uv run ruff check src && uv run mypy src && uv run pytest
```
