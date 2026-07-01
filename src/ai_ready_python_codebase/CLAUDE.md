# Package conventions

Loads when you edit files in this package. Root `CLAUDE.md` has project-wide
rules; this file has the patterns specific to `ai_ready_python_codebase`.

## Logging

- Get a logger with `get_logger(__name__)` from `logger.py`. Do not call
  `logging.getLogger` directly, and do not `print` (except in `__main__.py`).
- Pass event data as **structured key-values**, not interpolated strings:
  - Good: `log.info("user_fetched", user_id=uid, ms=elapsed)`
  - Bad: `log.info(f"fetched user {uid}")` — the linter (G/LOG) rejects this; it
    breaks JSON log parsing.

## Configuration

- Add settings as typed fields on `Settings` in `config.py`. They load from env
  vars automatically (pydantic-settings), uppercased (`log_level` ← `LOG_LEVEL`).
- Mirror every new field in `.env.example` with a comment. That file is the
  discoverable config contract; keep it in sync.

## Errors

- Raise a subclass of `AiReadyPythonCodebaseError` (see `exceptions.py`); add a
  new subclass rather than raising bare `ValueError`/`Exception`.
- A broad `except Exception` is allowed **only** if it logs with `exc_info=True`
  or re-raises. A silent swallow fails the BLE/TRY lint rules.

## HTTP

- Use `httpx` (already a dependency). Prefer `httpx.AsyncClient` for I/O; the
  ASYNC lint rules flag blocking calls inside `async` functions.
- Tests mock HTTP with `respx` — do not make real network calls in tests.

## Tests for this package

- Put tests under `tests/`, mirroring the module path.
- Type your test functions too (mypy strict covers tests).
- Use `hypothesis` for functions with an invariant worth stressing (e.g.
  round-trips, idempotence) — it finds the edge case a hand-written example won't.
