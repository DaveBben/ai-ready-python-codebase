# Package conventions

Loads when you edit files in this package. Root `AGENTS.md` has project-wide
rules; this file has the CDK patterns specific to `ai_ready_python_codebase`.

## Layout

- `hello_lambda.py` — a **construct** (`HelloLambda`): a reusable logical unit
  (the Lambda plus its log group). Infrastructure belongs in constructs.
- `hello_stack.py` — a **stack** (`HelloStack`): a deployment unit that composes
  constructs. Stacks wire things together; they don't define low-level resources.
- `lambdas/<name>/index.py` — Lambda **handler code**, bundled as a deploy asset.
- As the app grows, group constructs under `constructs/` and stacks under
  `stacks/`; keep `app.py` (repo root) a thin orchestrator.

## Constructs and stacks

- Put every resource in a Construct, not directly in a Stack. AWS best practice:
  constructs are the reusable units, stacks are deployment boundaries.
- Lambda functions: use ARM64, set an explicit `LogGroup` with a retention and
  `RemovalPolicy` (the auto-created log group is unmanaged and never expires),
  and let the L2 `Function` construct build the standard basic-execution role
  (cdk-nag flags its AWS-managed policy as IAM4 — suppress with a reason, as
  `hello_lambda.py` does, or scope the role yourself).
- Don't hardcode account/region in a stack; accept `env` and pass it from `app.py`.

## Lambda handler code (`lambdas/`)

- Handlers run in the AWS runtime, NOT as part of this package: keep them
  self-contained (stdlib only unless you bundle deps). Never import from
  `ai_ready_python_codebase` — that code isn't in the Lambda zip.
- `print` is the intended interface to CloudWatch here (T201 is waived for
  `lambdas/`); `event`/`context` may be unused (ARG001 waived). Type them with
  `object`, never `Any` (ANN401).

## Tests

- Assert on synthesized templates with `aws_cdk.assertions.Template`. Synthesis
  is in-process, so tests need no AWS credentials and no CDK CLI (a Node.js
  runtime is still required — CDK Python calls into jsii).
- Prefer fine-grained assertions (`has_resource_properties`) over snapshots, so
  each test states exactly which property matters and why.
- Unit-test handler code directly (see `tests/test_handler.py`).
