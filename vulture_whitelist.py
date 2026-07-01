# Vulture whitelist: names that ARE reachable at runtime but look dead to
# static analysis. Vulture treats every reference in this file as a "use", so
# listing a name here suppresses its false-positive report. Keep this list
# minimal — anything added here is a name vulture will never warn about again,
# so it must be genuinely runtime-reachable, not merely convenient to silence.
#
# Regenerate the candidate list (then prune real dead code) with:
#   uv run vulture src --make-whitelist
#
# Functions/methods used only by tests are NOT whitelisted here — `tests/` is in
# the scan path, so those references count as real uses and vulture resolves
# them on its own. This list is for names no Python call site ever references:

model_config  # pydantic-settings reads this at runtime; no call site touches it
