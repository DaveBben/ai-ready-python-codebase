# ai-ready-python-codebase (AWS CDK)

An **AWS CDK** app (Python) that deploys a Hello World Lambda — built as an
**AI-first** template: it gives coding agents fast, deterministic feedback loops
so they can verify their own infrastructure changes.

What makes it AI-first:

- **`AGENTS.md` / `CLAUDE.md`** — agent instructions in the open standard format.
  `AGENTS.md` is canonical (cross-tool); `CLAUDE.md` is a symlink to it. Nested
  `CLAUDE.md` files add per-directory context on demand.
- **A strict, opinionated ruff ruleset** — each family chosen to catch a mistake
  agents commonly make; the rationale is commented inline in `pyproject.toml`.
- **mypy `--strict`** plus extra error codes that ban vague `# type: ignore`.
- **In-process synth tests** — `aws_cdk.assertions` verify the generated
  CloudFormation with no AWS account and no CDK CLI (a local Node.js runtime is
  needed — CDK's jsii core), so the loop stays fast.
- **cdk-nag security oracle** — the AwsSolutions rule pack runs as a synth-time
  Aspect, so an insecure change fails the build like a lint error would.
- **Layered guardrails** — a Claude Code `PostToolUse` hook auto-formats edits,
  pre-commit gates every commit, and CI enforces the same loop on every PR.

## What it deploys

`HelloStack` → a Python 3.14 Lambda on ARM64 that prints "Hello World", with an
explicit CloudWatch log group (one-week retention) and the standard
AWS-managed basic-execution role.

## Develop

```bash
uv sync                       # install Python deps
uv run pytest --cov           # run tests (synth runs in-process — no AWS needed)
uv run mypy src app.py        # strict type check
uv run ruff check . && uv run ruff format .
uv run python app.py          # quick synth smoke test (runs cdk-nag)
npm ci && npx cdk synth       # authoritative synth (reads cdk.json)
uv run pre-commit install     # enable commit-time guardrails (one time)
```

## Deploy

The CDK CLI is Node-based (pinned in `package.json`); everything else is Python.

```bash
npm ci                        # install the pinned cdk CLI
npx cdk bootstrap             # once per account/region
npx cdk deploy                # needs AWS credentials
```

## Before creating a PR

```bash
uv run ruff check . && uv run ruff format --check . \
  && uv run mypy src app.py && uv run vulture \
  && uv run pytest --cov && uv run python app.py
```
