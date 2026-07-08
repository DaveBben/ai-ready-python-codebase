# mypy: strict typing with no escape hatches

mypy runs `strict = true`, so untyped code fails. On top of strict, five extra checks surface the mistakes agents make most and can't see on their own:

- **`warn_unreachable`** flags a dead branch left after a type narrows, often an agent bug.
- **`ignore-without-code`** bans a bare `# type: ignore`; it must name the error code. Paired with ruff's PGH003, type suppressions stay specific and reviewable rather than a blanket mute.
- **`redundant-expr`** flags always-true or dead sub-expressions.
- **`truthy-bool`** flags `if some_object:` where the object is always truthy.
- **`possibly-undefined`** flags a variable defined on only some branches.

Note the division of labor with ruff: mypy `--strict` does not catch `Any`, so the `ANN401` rule in [the ruff config](ruff.md) covers that gap. Together the two leave no untyped surface.
