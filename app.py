"""CDK application entry point.

The orchestrator: it composes stacks and synthesizes, nothing more. Real
infrastructure lives in constructs (see src/ai_ready_python_codebase/) that the
stacks assemble — per AWS guidance, logical units are constructs, stacks are
deployment units, and this file just wires them together. Kept thin on purpose.
"""

import os

import aws_cdk as cdk
from cdk_nag import AwsSolutionsChecks

from ai_ready_python_codebase.hello_stack import HelloStack

app = cdk.App()

# cdk-nag: the synth-time security oracle. AwsSolutionsChecks runs the AWS
# best-practice rule pack as an Aspect over every stack — deterministic, no AWS
# account needed — so an insecure change fails synth (and the nag test) instead of
# reaching deploy. The infrastructure equivalent of the ruff/mypy gate.
cdk.Aspects.of(app).add(AwsSolutionsChecks())

# Account/region come from the standard env vars the CDK CLI injects, so the same
# code deploys wherever the active AWS credentials point. Both are None during a
# plain `cdk synth` / CI run, which yields an environment-agnostic template — the
# right behavior there (no account baked in).
HelloStack(
    app,
    "HelloStack",
    env=cdk.Environment(
        account=os.environ.get("CDK_DEFAULT_ACCOUNT"),
        region=os.environ.get("CDK_DEFAULT_REGION"),
    ),
)

app.synth()
