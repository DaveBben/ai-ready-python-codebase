# Editor and environment config

These files keep the agent's *view* of the repo clean and give it the same feedback loop a human gets.

## `.editorconfig`

Sets baseline whitespace and encoding that any editor honors before a formatter runs: UTF-8, LF line endings, a final newline, and 4-space indents (2 for `yml`/`yaml`/`json`/`toml`). It covers what code alone can't tell an agent editing a fresh file, and it kills the noisy diffs (CRLF flips, a missing final newline) that bury a real edit. It complements ruff: EditorConfig governs the non-Python files ruff never touches, and it leaves trailing whitespace alone in `*.md`, where two trailing spaces are a hard line break.

## `.vscode/`

Three files pin the editor to behave like the commit gate. `settings.json` points the interpreter at the project's `.venv`, formats on save through ruff, organizes imports, and runs Pylance in `standard` mode so it doesn't fight mypy's gate with duplicate diagnostics. `extensions.json` recommends the ruff/mypy/Pylance toolchain and marks `pylint`, `black`, `isort`, and `flake8` as *unwanted*, since ruff already does their jobs. `launch.json` ships debug configs for the CLI, the current file, and the test suite.

## `.python-version`

A single line that `uv` and `pyenv` both read to select the dev interpreter. It pairs with the support floor in `pyproject.toml`: develop on the newer version, but don't emit syntax that breaks a floor user. See [dependencies](dependencies.md) for the full rationale.

## `.gitignore`

Keeps generated artifacts out of view, so what an agent sees is source and config, not thousands of derived files. It excludes the usual caches and `.env` (so real secrets never get committed), and commits `.claude/settings.json` while ignoring the per-developer `.claude/settings.local.json`.
