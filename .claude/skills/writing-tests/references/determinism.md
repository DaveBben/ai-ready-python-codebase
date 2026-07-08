# Determinism

Every test must produce the same result on every run, in any order, in
parallel. Sources to control:

## Time

Inject a clock (a `now: datetime` parameter); never call `datetime.now()` in
logic under test. For code you can't restructure yet, freeze with
`time-machine` (`@time_machine.travel("2026-07-06 12:00 +0000", tick=False)`).
Construct test datetimes as timezone-aware; ruff's DTZ rules enforce this in
`src` too.

## Randomness

Inject a seeded `random.Random` (or `numpy.random.Generator`); never
module-level `random.seed()`, which leaks between tests. Add `pytest-randomly`
to randomize test order each session and print the seed; `--randomly-seed=X`
reproduces a failure.

## Concurrency and async

- Use `pytest-asyncio` or anyio; await real completion, don't poll.
- `time.sleep()` in a test is a bug. Wait on the actual signal (an
  `asyncio.Event`, a returned future, a queue item). No signal to wait on
  means the production code lacks one: add it.

## Filesystem, environment, network

- Files: `tmp_path`; accept `pathlib.Path` parameters so tests can point code
  there.
- Env vars: read at the edge, pass values inward. Where code still reads
  `os.environ`, use `monkeypatch.setenv`/`delenv` (undone per test).
- Network: `pytest-socket` blocks sockets suite-wide; integration fixtures opt
  back in via `socket_enabled`, so an accidental live call fails loudly. No
  test outside `-m integration` touches the network.

## Isolation

Each test builds its own world: no module-level mutable state, no
session-scoped fixture holding anything mutable, no order dependence. That
isolation buys `uv run pytest -n auto` (pytest-xdist) dividing wall time by
core count.

## Guardrails already on in this repo

`pyproject.toml` sets `filterwarnings = ["error"]` and `xfail_strict = true`.
Don't weaken either to pass a test: fix the cause, or filter the specific
warning with a comment saying why.
