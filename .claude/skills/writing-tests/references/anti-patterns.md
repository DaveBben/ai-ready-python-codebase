# Anti-Patterns

Checklist for reviewing tests: each has a tell you can grep or spot in seconds.

## Implementation-coupled

The test knows how, not what: it mocks internal collaborators, touches private
attributes, or asserts call order between your own objects. **Tell:** a
refactor breaks the test while behavior is unchanged.

## Side-channel verification

The test bypasses the interface, querying the database directly instead of
asking the code. Assert through the interface callers use
(`get_user(user.id).name`, not a raw `SELECT`) so the test survives any
storage change.

## Tautological

Expected value is computed the same way the code computes it: the test passes
by construction and can never disagree. **Tell:** the assertion contains a
loop, `sum()`, comprehension, or the implementation's own formula. Expected
values come from a worked example, the spec, or a known-good literal.

## Vacuous

The test can't fail, or fails without testing anything. **Tells:**

- No assertion ("it didn't raise" only counts when documented, e.g.
  `validate(good_config)  # must not raise`).
- Assertions that accept anything: `assert result is not None`, or
  `assert isinstance(result, dict)` on your own typed code (mypy guarantees it).
- Try/except swallowing the assertion. `assert True` in any branch.
- An early return or skip that most runs hit.

This is AI-generated tests' signature failure: plausible-looking tests
weakened until they pass. Verify the test fails first, for the reason you
expect, before trusting it. For tests written *after* the code (bug fix,
characterization), confirm the failure anyway: revert the fix or mutate one
line, and never skip it because the code already exists.

## Over-specified

Vacuous's mirror image: asserting everything, so the test fails on anything.
**Tells:** whole-`__dict__` comparisons, log message wording, exact whitespace
that isn't a contract, `assert_called_once_with` on every argument. Assert
exactly the contract: the field carrying the behavior, the message pattern
(`match=`) not the whole string.

## Sleep-based synchronization

`time.sleep(0.5)` waiting for something to happen, or a rerun-on-failure
decorator hiding the same race. Wait on the real signal (see
`determinism.md`); flakiness policy lives in `suite-health.md`.

## Rot patterns to delete on sight

- Test-only production code: `if TESTING:` branches. Inject the dependency
  instead.
- Tests skipped or xfailed with no linked issue.
- Commented-out tests. Git remembers; delete them.
- Tests of deleted behavior kept green by ever-growing mocking.
- Horizontal slices: all tests written first, verifying imagined behavior.

The fuller audit lives in `suite-health.md`. Deleting a bad test is a positive
contribution: say what you deleted and why in the commit message.
