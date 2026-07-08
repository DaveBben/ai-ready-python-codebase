# Deterministic tests, coverage, and dead code

The pytest config converts soft warnings an agent would scroll past into hard failures it must fix:

- **`--strict-markers` and `--strict-config`** make an unknown marker or malformed config a hard error.
- **`-ra`** prints the reason for every non-pass, which gives the loop a concrete signal to act on.
- **`filterwarnings = ["error"]`** promotes warnings to failures. A `DeprecationWarning` is the single best free signal that an agent is using an old API, the same training-data bias the UP/FURB rules target.
- **`xfail_strict = true`** fails the suite when a test marked `xfail` actually passes, so a bug an agent silently fixed can't keep hiding behind an expected failure.
- **`markers = ["slow", "integration"]`** pre-registers the custom marks that `--strict-markers` would otherwise reject. The suite splits to match: fast tests in `tests/unit`, slower end-to-end ones in `tests/integration`.

**Coverage** measures branch coverage (`branch = true`) and lists the exact unexecuted line numbers (`show_missing`), which turns "did the agent test what it wrote?" into a precise, actionable readout instead of a bare percentage. `fail_under` is intentionally omitted so the starter suite doesn't fail an empty project; set `fail_under = 80` once there's real code to make coverage a hard commit gate.

**Mutation testing** (opt-in, via the `mutation` dependency group) answers the question coverage can't: do the tests actually *assert* anything? Coverage only proves a line ran. An agent can hit 100% with tests that would pass even if the logic were wrong — the "perpetually green" failure mode that AI-written tests fall into. `mutmut` introduces small bugs into `src/` and reruns the suite; a mutant that survives is a line no test would catch breaking. It's deliberately excluded from the commit and CI gates because it's slow — run it on demand or in a nightly job:

```bash
uv run --group mutation mutmut run      # mutate src/, report survivors
uv run --group mutation mutmut results  # inspect what survived
```

**Vulture** catches unreachable functions and methods that ruff's F401/F841 can't see. It scans `tests/` alongside `src/`, so a public API exercised only by tests isn't mistaken for dead code, and it excuses pytest fixtures, which are called by name via injection. For names that are live at runtime but invisible to static analysis (a framework hook, a plugin entry point), generate a `vulture_whitelist.py` with `uv run vulture --make-whitelist` and add it to the `[tool.vulture]` paths.
