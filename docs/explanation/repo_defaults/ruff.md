# Ruff: the linter as a deterministic oracle

`pyproject.toml` holds most of the repo's configuration, and the ruff block is its largest part. The config itself is comment-free; the rationale lives here. The governing idea: a linter is a deterministic oracle an agent runs and self-corrects against, with no human in the loop. Each rule family turns a common agent mistake into a fast failure. The table groups the rule families by the failure each prevents.

| Code(s) | Catches | Why it matters for an agent |
|---|---|---|
| **E, F** | pycodestyle errors, pyflakes: undefined names, unused imports (F401), unused vars (F841) | The correctness floor. |
| **B** | bugbear: mutable default args, misused loop vars | Classic LLM traps. |
| **PLE** | pylint errors: bad `super()` calls, bad string formatting | Real bugs, not style. |
| **RUF, PIE, RET, SIM, C4** | redundant branches, returns, comprehensions, passes | Cleans up leftovers after an agent's edits. |
| **UP, FURB, PTH, FLY** | pyupgrade, refurb, pathlib over `os.path`, f-strings | Counters training-data bias: agents default to whatever APIs were most common in training data, which skews old, so these push code to current idioms. |
| **S** | bandit security: S301 pickle, S506 `yaml.load`, S324 weak hashes, S603/S607 subprocess | Agents paste insecure snippets confidently, so this catches them at author time. |
| **BLE** | BLE001 blind `except Exception` | Fail-loud. Allowed only when it logs (`exc_info=True`) or re-raises. |
| **TRY, EM, RSE** | raise-and-return anti-patterns, over-broad tries, exception messages, `raise ... from` | Clean, correctly-chained error handling. |
| **C90, PLR, PLW** | McCabe complexity (C901), too many branches/statements/args, refactor smells | A complexity budget that keeps functions small enough to hold in context. |
| **ANN** | every function annotated; **ANN401 bans `Any`** | mypy `--strict` does *not* catch `Any`; this is the only check that does, and agents reach for `Any` to silence types they can't work out. |
| **I, N, TID, A** | import order, PEP 8 naming, no relative imports, no shadowing builtins | Predictable symbols, so an agent's just-in-time retrieval lands right. |
| **PGH** | PGH004 bans blanket `# noqa`; PGH003 bans blanket `# type: ignore` | No lazy suppression. Every suppression names a code and stays reviewable. |
| **G, LOG** | no f-strings or `.format` inside log calls | Keeps log records structured and machine-parseable. |
| **FBT, ARG, SLF, T20** | boolean-trap positional args, unused args, private-member access, stray `print` | API clarity and no stray output. An agent reading `f(True)` can't tell what it means. |
| **PT** | flake8-pytest-style | Uniform fixtures and asserts, so test files read alike. |
| **DTZ** | naive datetimes | A silent, data-corrupting mistake. |
| **PERF** | manual loops that should be comprehensions | Obvious performance anti-patterns. |
| **ERA** | commented-out code | A distinctly AI-authored smell: agents leave the old version behind after an edit, which pollutes future context. |
| **TC** | flake8-type-checking | Moves typing-only imports into `if TYPE_CHECKING:` blocks. |

**Only `E501` (line length) is ignored globally**, because line length is the formatter's job. One deliberate non-ignore: `S101` (assert) is *not* waived outside tests. An `assert` in production silently vanishes under `python -O`, so using one as a runtime guard is a real bug.

**Complexity threshold.** `max-complexity = 10` caps the number of independent paths through a function, a proxy for how much you must hold in your head to be sure it's correct. An agent reasons over what fits in its context, and a 30-path function is where it quietly breaks a branch it never traced. Ten is McCabe's original threshold; drop to 8 for a stricter ceiling. Much lower forces premature decomposition, and more tiny functions across more files are *more* to trace, not less.

**Per-file ignores.** Tests may assert freely (S101), use throwaway secrets (S105/S106), accept unused fixture params (ARG001), compare against literals (PLR2004), and skip return annotations (ANN201). None of those is a smell in a test. The CLI entry point may `print` (T201), the one place `print` is real.
