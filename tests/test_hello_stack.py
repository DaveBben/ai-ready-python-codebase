"""Fine-grained assertions against the synthesized HelloStack template.

The verification oracle for the infrastructure: these assert the exact
CloudFormation the stack produces, so a regression (wrong runtime, missing log
retention, a Lambda no longer wired to its managed log group) fails the suite
instead of reaching an AWS account.
"""

from aws_cdk.assertions import Match, Template


class TestHelloStack:
    """The stack should synthesize exactly the intended Lambda plus log group."""

    def test_creates_exactly_one_lambda(self, template: Template) -> None:
        template.resource_count_is("AWS::Lambda::Function", 1)

    def test_lambda_runs_python314_on_arm64(self, template: Template) -> None:
        template.has_resource_properties(
            "AWS::Lambda::Function",
            {
                "Runtime": "python3.14",
                "Handler": "index.handler",
                "Architectures": ["arm64"],
            },
        )

    def test_lambda_is_wired_to_the_managed_log_group(self, template: Template) -> None:
        # The construct's whole reason to exist: drop `log_group=` and the Lambda
        # silently reverts to an auto-created, never-expiring, unmanaged group — so
        # assert the wiring, not just that a LogGroup resource exists somewhere.
        template.has_resource_properties(
            "AWS::Lambda::Function",
            {
                "LoggingConfig": {
                    "LogGroup": {"Ref": Match.string_like_regexp("HelloLogGroup.*")}
                }
            },
        )

    def test_log_group_retains_one_week_and_is_destroyed_with_the_stack(
        self, template: Template
    ) -> None:
        template.has_resource_properties(
            "AWS::Logs::LogGroup",
            {"RetentionInDays": 7},
        )
        template.has_resource(
            "AWS::Logs::LogGroup",
            {"DeletionPolicy": "Delete", "UpdateReplacePolicy": "Delete"},
        )

    def test_outputs_the_function_name_as_a_reference(self, template: Template) -> None:
        template.has_output(
            "FunctionName",
            {"Value": {"Ref": Match.string_like_regexp("HelloFunction.*")}},
        )
