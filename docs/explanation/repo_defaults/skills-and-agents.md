# Bundled agents

Subagents live in `.claude/agents/` as Markdown files with YAML front matter. Each defines a focused worker the main agent delegates to, with its own tool allowlist and model. The point is context economy: a subagent runs a noisy or specialized job in its own window and hands back only the distilled result, so the main agent's context stays clean.

The `code-reviewer` fires through the [path-scoped `code.md` rule](agent-instructions.md#path-scoped-rules): after a significant Python change, the main agent hands the diff to it rather than grading its own work.

| Agent | Model | What it does |
|---|---|---|
| `code-reviewer` | `opus` | Reviews a diff for the failure modes AI-written code actually has, plus test integrity. It carries its own review rubric — four tiers, from correctness and security through to whether a test would fail if the behavior broke — so it needs nothing else installed. Reports findings; the main agent acts on them. |

Two design choices shape it. **Read-only**: the agent gets no `Edit`, so it reports and the main agent acts on the findings. **Model matched to the job**: diff review is judgment-heavy, so it runs on `opus`. Handing the diff to a separate window keeps the review independent — a reviewer grading its own work in the main context both crowds that context and marks its own homework.
