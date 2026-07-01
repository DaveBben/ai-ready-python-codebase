"""HelloLambda construct: a Lambda function that logs a greeting."""

from pathlib import Path

from aws_cdk import Duration, RemovalPolicy
from aws_cdk import aws_lambda as lambda_
from aws_cdk import aws_logs as logs
from cdk_nag import NagPackSuppression, NagSuppressions
from constructs import Construct

# The handler code is a sibling package; its directory is bundled as the Lambda
# deployment asset. Resolved from this file so it works regardless of CWD.
_HANDLER_DIR = Path(__file__).resolve().parent / "lambdas" / "hello"


class HelloLambda(Construct):
    """A Lambda that prints "Hello World", wired with cost/security defaults.

    Best-practice choices baked in so the template teaches them:
      * An explicit LogGroup with a retention policy. The log group Lambda would
        otherwise auto-create keeps logs forever and cannot be managed by CDK.
      * ARM64 (Graviton): cheaper and typically faster than x86 for Python.
      * memory_size=128 (AWS's floor) and a 10s timeout: this handler does no
        real work, so the cheapest, fastest-to-provision settings suffice — raise
        both only once the handler actually needs the headroom.
      * The L2 Function construct auto-generates the standard basic-execution role
        (CloudWatch Logs access). cdk-nag flags that AWS-managed policy (IAM4);
        the suppression below documents the deliberate decision to accept it.
    """

    def __init__(self, scope: Construct, construct_id: str) -> None:
        super().__init__(scope, construct_id)

        log_group = logs.LogGroup(
            self,
            "LogGroup",
            retention=logs.RetentionDays.ONE_WEEK,
            removal_policy=RemovalPolicy.DESTROY,
        )

        self.function = lambda_.Function(
            self,
            "Function",
            runtime=lambda_.Runtime.PYTHON_3_14,
            architecture=lambda_.Architecture.ARM_64,
            handler="index.handler",
            code=lambda_.Code.from_asset(
                str(_HANDLER_DIR),
                # Dev artifacts never run in Lambda; excluding them keeps the
                # deploy asset hash stable across local runs (no spurious redeploys).
                exclude=["__pycache__", "*.pyc"],
            ),
            memory_size=128,
            timeout=Duration.seconds(10),
            log_group=log_group,
        )

        # Document, don't silently ignore: cdk-nag AwsSolutions-IAM4 flags the
        # AWS-managed AWSLambdaBasicExecutionRole on the auto-created execution
        # role. Accepting it is a deliberate call (it's the standard minimal Logs
        # role), so we suppress WITH a written reason on the function subtree — the
        # "suppress with justification" discipline the template is teaching.
        NagSuppressions.add_resource_suppressions(
            self.function,
            [
                NagPackSuppression(
                    id="AwsSolutions-IAM4",
                    reason=(
                        "Standard AWS-managed basic-execution role for CloudWatch "
                        "Logs; scoping it further adds complexity with no security "
                        "gain for this demo Lambda."
                    ),
                ),
            ],
            apply_to_children=True,
        )
