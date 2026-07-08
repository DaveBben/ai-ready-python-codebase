---
paths:
  - "tests/**"
  - "**/tests/**"
  - "src/*.py"
  - "src/**/*.py"
---

# Before implementing, write the failing test

Work in vertical slices: one test, one minimal implementation, repeat. Never slice horizontally: tests written in bulk encode behavior you guessed before the code taught you anything.

1. **Red.** Write ONE failing test and run it; confirm it fails on the assertion you expect before writing any implementation. Red and green are separate steps: never write the test and the implementation together.
2. **Green means minimal.** Write only enough code to pass the current test, then start the next slice.
3. **Refactor only on green**, and rerun the suite after; passing tests are the proof that behavior didn't change.
4. **Done means verified.** A slice is complete when the suite ran and passed, not when the code is written. Never report success that the tests haven't confirmed.
