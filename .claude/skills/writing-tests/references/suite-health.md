# Suite Health: Coverage, Mutation, Flakiness, Speed

## Coverage is a gap-finder, never a target

`uv run pytest --cov` (branch coverage is on). Read the report for **what
never ran**: an uncovered error branch is real, but a covered line isn't
verified: zero-assertion suites can hit 100%. Never add a test whose only
purpose is the percentage.

## Mutation testing is the honest metric

`mutmut` introduces one small bug at a time and reruns the tests; a
**surviving mutant** is a bug the suite would ship. Use it surgically on the
module you just changed, not as a CI gate. Each survivor gets one of two
responses: add the missing assertion, or delete the code as unnecessary. It's
also the mechanical detector for tautological and vacuous tests
(`anti-patterns.md`), which kill no mutants.

## Flakiness: zero tolerance

One flaky test teaches everyone to rerun on red, then a real red gets rerun
too.

1. Quarantine the day it flakes
   (`@pytest.mark.skip(reason="flaky: <issue>")`).
2. Fix it (almost always a determinism bug; see `determinism.md`) or delete it
   within days, not months.
3. Reproduce order-dependence with `pytest-randomly`'s printed seed; isolation
   bugs by running the test alone, then with `-n auto`.
4. Never install rerun-on-failure plugins as the fix: retries convert a loud
   race into a silent one.

## Speed: fast enough to run on every change

Budgets: pure-logic tests in milliseconds, the fast loop under ~10 seconds,
the full gate a few minutes in CI. `--durations=10` names the slow tests: a
slow "unit" test is usually doing I/O it shouldn't; move it behind a fake or
behind `-m integration`.

## Deleting tests

A test earns its place only if it can fail on a plausible bug and point you to
it. Delete the **redundant** (kills the same mutants as a neighbor; keep the
readable one), the **level-duplicated** (keep the lowest level that expresses
the behavior), the **obsolete** (behavior gone, test survives on mocks), the
**unfailable**, and the **unreadable**. Note deletions in the commit message.
