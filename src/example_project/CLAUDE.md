# Package conventions

Loads when you edit files in this package. Root `CLAUDE.md` has project-wide rules; this file has the patterns specific to `example_project`.

## Errors

- Raise a subclass of `ExampleProjectError` (see `exceptions.py`); add a new subclass rather than raising bare `ValueError`/`Exception`.
- A broad `except Exception` is allowed **only** if it logs with `exc_info=True` or re-raises. A silent swallow fails the BLE/TRY lint rules.

## Logging

- Call `setup_logging()` once at the entry point (`__main__.main` already does). It reads `LOG_LEVEL` and `LOG_JSON` from the environment.
- In modules, get a logger with `logging.getLogger(__name__)` and log through it; don't reconfigure handlers.
- Attach structured context with `extra={...}` — those keys land as top-level JSON fields. See `logger.py`.

## Tests for this package

- Put tests under `tests/`, mirroring the module path.
- Type your test functions too (mypy strict covers tests).
- Use `hypothesis` for functions with an invariant worth stressing (e.g. round-trips, idempotence). It finds the edge case a hand-written example won't.
