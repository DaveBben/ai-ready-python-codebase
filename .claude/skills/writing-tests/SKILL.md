---
name: writing-tests
description: "How to write, change, and review pytest tests in this codebase. Use whenever the task involves tests in any way: writing a new test, writing a regression test for a bug, adding a fixture, reviewing test quality, diagnosing a flaky or slow suite, mocking an external service, or deciding what to test. Not for authoring specs or for docs-only changes."
paths:
  - "tests/**/*.py"
  - "**/test_*.py"
  - "**/conftest.py"
---

# Writing Tests

`--strict-markers` is on, so register any new marker in `pyproject.toml`
before first use (`slow` and `integration` already are). Tools named here are
suggestions, not dependencies; add one with `uv add --dev <tool>` when you
reach for it.

Regression tests (required for every bug fix) must fail on the
assertion and message you expect, not an `ImportError` or fixture typo: a test
that failed for the wrong reason verifies nothing once green.

Tests attach to seams (public boundaries), never internals. Agree the seams
with the user before writing tests. Match test names to the project's domain
language (check the `README` or any design docs if present).

## Suite shape: which kind of test to write

Tests split by directory: `tests/unit/` for fast, double-free logic tests,
`tests/integration/` for wiring and whole-journey tests.

Pick the level by the code, not by habit:

- **Pure logic** (parsing, pricing, date math) → plain unit tests, zero
  doubles. Logic tangled with I/O is a design problem: extract a pure function.
  Many cheap tests belong here.
- **Wiring** (service + repository + validation) → integration tests through
  the public seam, real collaborators, doubles only at true external
  boundaries. Default for feature work.
- **Whole journeys** (CLI invocation, HTTP round-trip) → a handful for critical
  paths only, marked `slow` or `integration`.
- **Code with invariants** (round-trips, encoders) → Hypothesis property tests.

## Non-negotiables for every test

- Test behavior through the seam; never reach into privates or assert how
  internals collaborate.
- Expected values come from an independent source: a worked example, the spec,
  or a known-good literal, never re-derived by the code's own formula.
- Deterministic: no real time, unseeded randomness, network, or shared state.
- One logical assertion per test; the name states the behavior
  (`test_expired_token_is_rejected`, not `test_validate_calls_checker`).
- Build test data with builders that default everything irrelevant.
- Don't test what other tools already guarantee (mypy strict proves the types;
  the stdlib isn't yours to test).

## Where to go deeper

Read the reference before writing the code it governs, not after:

| You are about to… | Read |
|---|---|
| Mock, stub, or fake anything (APIs, DB, filesystem) | `references/test-doubles.md` |
| Test code involving time, randomness, async, env vars, or files | `references/determinism.md` |
| Test a CLI, an HTTP endpoint, or code that hits a database | `references/integration-testing.md` |
| Set up fixtures, builders, `parametrize`, or snapshots | `references/test-data.md` |
| Review tests, or check your own for rot | `references/anti-patterns.md` |
| Investigate flakiness, slowness, or coverage; audit or prune the suite | `references/suite-health.md` |
