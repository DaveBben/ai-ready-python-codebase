# AGENTS.md

Guidance for AI coding agents working in this repository. This is the canonical,
cross-tool instructions file (the open AGENTS.md standard); `CLAUDE.md` is a
symlink to it, so Claude Code and other agents read exactly the same content.

Kept deliberately short and high-signal: every line here spends context on every
turn, so bloat makes the agent *ignore* the rules that matter. Module-specific
patterns live in nested files (e.g. `src/ai_ready_python_codebase/CLAUDE.md`)
that load only when you touch that directory.

## Project overview

An AWS CDK (Python) app that deploys a Hello World Lambda — built as an AI-first
template: the same fast, deterministic feedback loops (lint, types, tests, hooks)
as the base Python template, applied to infrastructure-as-code so an agent can
verify its own CDK changes without an AWS account.

## Golden rules

- **Use `uv` for Python, `npm` for the CDK CLI.** Never call `pip`/`poetry`/a
  global `python`. Dependencies: `uv add` / `uv add --dev`, never hand-edit
  `pyproject.toml` deps. The Node-based `cdk` CLI is pinned in `package.json`.
- **Every function is fully type-annotated.** mypy runs `--strict`; untyped code
  fails. No bare `# type: ignore` (cite the code), and no `Any` (ANN401).
- **Infrastructure goes in constructs, not stacks.** A stack composes constructs;
  it doesn't define low-level resources. Don't hardcode account/region — take
  `env` and pass it from `app.py`.
- **Lambda handlers are self-contained.** They run in the AWS runtime, so never
  import from `ai_ready_python_codebase`; stdlib only unless you bundle deps.
- **Run the checks; don't just trust the diff.** Listing a command is not running
  it — run the verification loop below.

## Development commands

```bash
uv sync                       # install Python deps (incl. dev group)
npm ci                        # install the pinned CDK CLI (for cdk synth/deploy)
uv run pytest                 # all tests (synth runs in-process — no AWS needed)
uv run pytest path::test      # a single test
uv run pytest --cov           # tests with coverage
uv run mypy src app.py        # strict type check (include the app entry point)
uv run ruff check .           # lint
uv run ruff format .          # format
uv run python app.py          # quick synth smoke test (runs cdk-nag; ignores cdk.json)
npx cdk synth                 # authoritative synth: reads cdk.json, runs cdk-nag
npx cdk deploy                # deploy (needs AWS credentials)
```

## Tech stack (pinned — do not assume newer/older APIs)

- **Python**: dev on 3.13; floor is 3.12 (`requires-python`). Ruff lints against
  3.12 — don't emit 3.13-only syntax.
- **aws-cdk-lib** ≥2.260 + **constructs** ≥10.4 — CDK v2 (one package; v1 is EOL).
- **cdk-nag** <3 — the synth-time security oracle. When it flags something, fix it
  or suppress WITH a written justification (see hello_lambda.py); never blanket it.
- **Lambda runtime**: Python 3.14 (latest) on ARM64.
- **Node.js** — required even to run tests/synth: CDK Python calls into a Node
  runtime via jsii. (The **cdk** CLI, npm, is separate — needed only to deploy.)
  Pinned to 22 in `.nvmrc`/CI: aws-cdk's own floor is Node ≥18, but 18 has reached
  end-of-life, so 22 is the newest LTS line to build against.
- Tooling: **uv**, **ruff**, **mypy**, **pytest**, **vulture**.

## Project structure

- `app.py` — CDK entry point (thin orchestrator: compose stacks, `app.synth()`).
- `cdk.json` — tells the CDK CLI how to run the app (`uv run python app.py`). Its
  `context` block is the full feature-flag set `cdk init` stamps into new
  projects: each flag defaults off so an already-deployed stack doesn't break,
  but a brand-new stack has nothing to break, so it carries the whole
  recommended set and starts on today's best-practice defaults.
- `src/ai_ready_python_codebase/` — the package (import absolutely, never relative).
  - `hello_lambda.py` — `HelloLambda` construct (the Lambda + its log group).
  - `hello_stack.py` — `HelloStack` stack (composes constructs).
  - `lambdas/hello/index.py` — the Lambda handler (bundled as a deploy asset).
- `tests/` — pytest suite; `conftest.py` holds the synthesized-`Template` fixture.

## Verification loop (run before every PR)

```bash
uv run ruff check . && uv run ruff format --check . \
  && uv run mypy src app.py && uv run vulture \
  && uv run pytest --cov && uv run python app.py
```

CI runs the same gate on push and PR (it installs Node for CDK's jsii runtime).
A `PostToolUse` hook auto-formats and re-lints each file you edit, so style is
handled for you — spend your turns on logic, not formatting.
