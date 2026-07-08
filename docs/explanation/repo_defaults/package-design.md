# How the package is engineered

Every file under `src/` is small, typed, and single-purpose, so an agent gets unambiguous structure and deterministic feedback.

## src layout and absolute imports

The package lives under `src/`, not at the repo root, and every tool is wired to match: `pythonpath = ["src"]` for pytest, `mypy_path = "src"`, and `src = ["src"]` for ruff. Two payoffs:

- **Tests run against the installed package, not loose files.** A flat layout lets `import your_package` resolve to the source tree in the current directory, so a test can pass locally yet fail once packaged. The src layout forecloses that false green.
- **Imports are absolute and unambiguous.** Ruff's `TID` family bans relative imports, so an agent doing just-in-time symbol retrieval lands on the full dotted path every time, with no `..` arithmetic from the current file's depth.

## A single typed exception root, and "fail loud"

Root every exception the package raises in one base class (here `ExampleProjectError`) that all the others subclass. A caller can then `except ExampleProjectError` to catch anything the package raises on purpose, while a genuine bug like a `KeyError` still escapes uncaught. That line separates expected failures from programming errors an agent should fix.

Silent swallowing is a lint failure: ruff's `BLE` and `TRY` families flag a blind `except Exception` unless it logs with `exc_info=True` or re-raises. Agents reach for a broad try/except to turn a red test green, and here that instinct fails the linter instead of hiding the defect.

## `py.typed`, shipping types with the package

`py.typed` is an empty PEP 561 marker. Its presence tells a downstream type checker that the package's inline annotations can be trusted. Without it, mypy in a consuming project treats every import from the package as `Any`, a hole in type coverage exactly where an agent needs the guardrail. The marker makes strict typing portable to anyone who installs the wheel.
