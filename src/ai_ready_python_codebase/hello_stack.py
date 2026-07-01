"""HelloStack: the deployment unit for the Hello World Lambda."""

from aws_cdk import CfnOutput, Environment, Stack
from constructs import Construct

from ai_ready_python_codebase.hello_lambda import HelloLambda


class HelloStack(Stack):
    """Deploys the Hello World Lambda and outputs its generated function name."""

    def __init__(
        self,
        scope: Construct,
        construct_id: str,
        *,
        env: Environment | None = None,
    ) -> None:
        super().__init__(scope, construct_id, env=env)

        hello = HelloLambda(self, "Hello")

        # Surface the auto-generated function name so it's easy to find and invoke
        # after `cdk deploy`.
        CfnOutput(self, "FunctionName", value=hello.function.function_name)
