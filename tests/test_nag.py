"""cdk-nag security oracle: the stack must have zero unsuppressed findings.

The infrastructure equivalent of the lint/type gate. A resource that violates an
AWS best practice raises an AwsSolutions error at synth time; this test fails on
any such error that isn't deliberately suppressed with a written justification.
"""

import aws_cdk as cdk
from aws_cdk import Aspects
from aws_cdk.assertions import Annotations, Match
from cdk_nag import AwsSolutionsChecks

from ai_ready_python_codebase.hello_stack import HelloStack


def test_stack_has_no_unsuppressed_nag_errors() -> None:
    app = cdk.App()
    stack = HelloStack(app, "NagTestStack")
    Aspects.of(stack).add(AwsSolutionsChecks())

    errors = Annotations.from_stack(stack).find_error(
        "*", Match.string_like_regexp(r"AwsSolutions-.*")
    )

    assert not errors, f"Unsuppressed cdk-nag findings: {errors}"
