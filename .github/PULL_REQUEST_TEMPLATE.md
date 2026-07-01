<!-- Structured context for reviewers and for issue/PR-automation agents. -->

## What & why

<!-- One or two sentences: what this changes, and the reason. -->

## Verification

<!-- The AI-first gate: show the evidence, don't just claim it. -->

- [ ] `uv run ruff check . && uv run ruff format --check .`
- [ ] `uv run mypy src`
- [ ] `uv run pytest --cov`
- [ ] New or changed behavior is covered by a test

## Notes for reviewers

<!-- Anything non-obvious: trade-offs, follow-ups, risks. -->
