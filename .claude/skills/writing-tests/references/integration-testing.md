# Integration Testing Mechanics

Pytest mechanics per surface; principles live in SKILL.md.

## Layout and selection

Fast, double-free logic tests live under `tests/unit/`; wiring and boundary
tests (CLI, HTTP, database) under `tests/integration/`. Select by path, plus
marker for the slow cases:

```bash
uv run pytest tests/unit          # the fast loop
uv run pytest tests/integration   # boundary/contract tests
uv run pytest -m "not slow"       # skip the slow subprocess smokes
```

Each behavior gets **one home**: don't assert a rule twice at different levels
(see `suite-health.md`).

## CLI

In-process is the default: design `main` to take `argv: list[str] | None =
None` (with click/typer, use `CliRunner`), call it directly, assert exit codes
via `pytest.raises(SystemExit)` and output via `capsys`. Assert the stable
contract (exit code, the parseable line), not help text wording.

In-process tests miss broken entry points and import-time crashes: add one or
two `subprocess.run` smoke tests marked `slow` to cover packaging. Don't build
the suite on subprocesses: they run an order of magnitude slower and catch
nothing else pytest can't.

## HTTP APIs

Test through routes, not handler functions: routing, validation, and
serialization are the wiring these tests exist to cover.

- Build the app through a `create_app(...)` factory that accepts its
  boundaries; drive it with `TestClient` (a fixture that enters the context
  manager runs lifespan). FastAPI `dependency_overrides`: override only
  boundary adapters, never internal services.
- Use `httpx.AsyncClient(transport=ASGITransport(app=app))` for async tests.
- Assert status plus the contract fields, and cover the error contract: one
  test per documented failure mode (422 on bad payload, 402 on declined
  payment).

## Databases

Real engine, disposable instance, clean state per test: one testcontainers
container per session, migrations applied once, each test wrapped in a
transaction and rolled back (schema recreation is the slow last resort). Test
through your repository seam: only that layer verifies the SQL, mapping, and
constraints. Assert behaviors (`pytest.raises(DuplicateUserError)`), not raw
rows.

## What integration tests are not

Not a second unit suite: if a pure function's edge cases are covered directly,
the endpoint test needs one happy path plus the error contract. Not end-to-end
either: a handful of whole-journey tests is the ceiling.
