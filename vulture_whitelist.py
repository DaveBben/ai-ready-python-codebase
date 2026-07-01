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
# them on its own. (The Lambda `handler` is invoked only by the string
# "index.handler" in CDK, but test_handler.py calls it, so vulture sees it used.)
#
# This list is for names no Python call site ever references. The AWS Lambda
# runtime passes `event` and `context` positionally; a hello-world handler reads
# neither, but both must stay in the signature — so they look dead but aren't.
event
context
