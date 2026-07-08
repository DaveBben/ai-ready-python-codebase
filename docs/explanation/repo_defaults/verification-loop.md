# The verification loop

The whole design is one verification loop enforced at three points: fast checks the instant an agent edits a file, a whole-package type check when its turn ends, and the full gate before a commit lands. Each layer is a subset of the same command list, so what an agent fixes at edit time it never rediscovers at commit time.

| Layer | Trigger | Enforced by | What it catches |
|-------|---------|-------------|-----------------|
| 1. Edit time | Agent saves a file | Claude Code `PostToolUse` hooks | Format and lint on the touched file; `uv.lock` drift on a `pyproject.toml` edit |
| 2. Turn end | Agent finishes its turn | Claude Code `Stop` hook | Whole-package `mypy --strict`, skipped when no Python file changed |
| 3. Commit time | `git commit` | `.pre-commit-config.yaml` | Lint, format, types, dead code, the test suite, and (on lockfile changes) dependency CVEs |

The canonical gate, the full command list, is:

```bash
uv run ruff check src tests && uv run ruff format --check src tests \
  && uv run mypy src && uv run vulture && uv run pip-audit && uv run pytest --cov
```

A GitHub Actions workflow (`.github/workflows/ci.yml`) runs that same one-liner on every push and pull request, across Python 3.12 and 3.13. "Passes locally" and "passes in CI" are the same contract.

## Layer 1: the edit-time hook, `.claude/hooks/ruff-fix.sh`

A rule in `CLAUDE.md` is advice the model may or may not follow. A hook is enforcement the harness runs every time. The hook, in order:

1. **Set safety flags.** `set -euo pipefail` exits on any error, unset variable, or failed pipe stage.
2. **Pick the fastest `ruff`.** It calls the venv binary directly if present, else `uv run ruff`. The direct call skips uv's per-invocation environment check, worth saving on a hook that fires on every edit.
3. **Extract the edited file path** from Claude Code's stdin JSON, and no-op on a parse failure so a spurious error never reaches the user.
4. **Skip files outside this repo.** A session can edit other working directories, and this repo's ruff rules must not be enforced there.
5. **Filter to Python files that still exist**, since an edit could have been a deletion.
6. **Auto-fix and format.** It runs `ruff check --fix` then `ruff format` and silences the output, spending the style budget for the agent.
7. **Re-check.** Whatever ruff still flags is a genuine problem no formatter can resolve, such as a blind `except` or an unused argument. The script prints those to stderr and **exits 2**. If ruff itself failed to run (a missing venv, a broken uv), the hook reports the cause and exits 0 instead: it fails open, so a broken tool can't phantom-block every edit.

Exit code 2 tells Claude Code to feed the hook's stderr back to the agent, which closes the loop: edit, check, correct, re-check, with no human prompting the fix.

mypy and pytest are left out here on purpose: they need the whole package and are too slow for an every-edit run. mypy runs instead at turn end (layer 2); pytest waits for the commit-time gate (layer 3). Automating the mechanical fixes leaves the agent's turns for the parts that need judgment.

## Layer 2: the turn-end hook, `stop-mypy.sh`

The `Stop` event fires once, when the agent believes it is finished: the right moment for a whole-package check too slow for every edit. The hook runs `mypy --strict` over the package whenever any Python file changed; exit 2 blocks the stop and feeds the errors back, so the agent fixes them before a human reviews anything. A per-session retry counter provides the loop's safety: each blocked stop increments it, a passing check clears it, and after three blocks the hook gives up and lets the stop through. The agent's fix therefore gets re-verified (a single-shot guard would check only once), while an unfixable error still can't trap the agent in a loop. pytest stays out of the turn-end layer; the full suite runs in pre-commit (layer 3), with coverage added in the manual full gate.

## Layer 3: pre-commit

Pre-commit is the commit-time backstop, enabled once with `uv run pre-commit install`. It runs the standard hygiene hooks (`trailing-whitespace`, `end-of-file-fixer`, `check-yaml`, `check-toml`, `check-added-large-files`, `check-merge-conflict`, `debug-statements`), keeps `uv.lock` in sync with `pyproject.toml`, and runs `ruff`, `ruff-format`, `mypy`, `vulture`, and `pytest` through `uv run`. Running them through `uv run` pins the same tool versions as the edit-time hook, so there's no "passes in the hook, fails at commit" skew.

`hadolint` lints the `Dockerfile` — unpinned base images, missing `USER`, `apt` without `--no-install-recommends`, and the like. It comes from the `AleksaC/hadolint-py` mirror, which ships hadolint as a pip-installed binary. The upstream hook runs the linter inside a container, which would make every commit depend on a running Docker daemon; the mirror drops that dependency, so a commit still passes with Docker stopped or uninstalled.

pytest runs here without `--cov`, on purpose. `fail_under` is unset, so coverage can't fail a commit anyway; the slower coverage readout stays in the manual full gate, where it's informative rather than a gate.

pip-audit runs here too, but only when the commit touches `uv.lock` (`files: ^uv\.lock$`). It needs the network, and a PyPI outage must not block a pure code commit. To land a dependency change while offline, skip just that hook: `SKIP=pip-audit git commit`.
