# Dependencies and the Python version split

## Two Python versions, on purpose

- **Dev runs on the newest release** (pinned in `.python-version`), so local runs get current performance and error messages.
- **The support floor is one version back** (`requires-python` in `pyproject.toml`), so the template still runs on slower-moving managed runtimes and base images.

An agent can't infer this split. Editing on the newer interpreter, it would emit syntax that breaks a floor user at runtime. So the floor is stated explicitly, and ruff's `target-version` is pinned to it to fail newer-only syntax at author time.

## Runtime dependencies

There are none. The template is a scaffold, not an application, so it imposes no runtime library, logging strategy, or config framework. Those belong to the project you build. Add what you need with `uv add`, which keeps `uv.lock` authoritative. The value here is entirely in the dev toolchain below.

## Dev dependencies, the verification toolbox

Each dev dependency is an oracle an agent runs to check its own work: **pytest** (test runner), **pytest-cov** (coverage), **hypothesis** (property-based testing that finds edge cases hand-written examples miss), **mypy** (types), **ruff** (lint and format), **vulture** (dead code), **pip-audit** (known CVEs in deps), and **pre-commit** (the commit-time gate).

## Build system

Packaging is standards-based (PEP 517/621) with **hatchling**. The wheel path is set explicitly (`packages = ["src/example_project"]`) so a future rename can't silently break the build, and the version is single-sourced from `__init__.py`.
