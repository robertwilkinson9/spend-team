variables {
    team_spend_emails=["a@b.c", "d@e.f"]
}

run "test_alert_name" {
    command = plan

    assert {
	condition = aws_sns_topic.team_spend_alert.name == "team-spend-alert"
        error_message = "Incorrect team-spend-alert name"
    }
}

run "test_action_name" {
    command = plan

    assert {
	condition = aws_sns_topic.team_spend_action.name == "team-spend-action"
        error_message = "Incorrect team-spend-action name"
    }
}

run "test_first_team_spend_alert_emails_protocol" {
    command = plan

    assert {
	condition = aws_sns_topic_subscription.team_spend_alert_email_subscription["a@b.c"].protocol == "email"
        error_message = "Incorrect first aws_sns_topic_subscription alert protocol"
    }
}

run "test_first_team_spend_alert_emails_endpoint" {
    command = plan

    assert {
	condition = aws_sns_topic_subscription.team_spend_alert_email_subscription["a@b.c"].endpoint == "a@b.c"
        error_message = "Incorrect first aws_sns_topic_subscription alert endpoint"
    }
}

run "test_first_team_spend_alert_emails_topic_arn" {
    command = plan

    assert {
	condition = aws_sns_topic_subscription.team_spend_alert_email_subscription["a@b.c"].topic_arn == "arn:aws:sns:${var.AWS_REGION}:${var.awsID}:team-spend-alert"
        error_message = "Incorrect first aws_sns_topic_subscription alert topic"
    }
}

run "test_first_team_spend_action_emails_protocol" {
    command = plan

    assert {
	condition = aws_sns_topic_subscription.team_spend_action_email_subscription["a@b.c"].protocol == "email"
        error_message = "Incorrect first aws_sns_topic_subscription action protocol"
    }
}

run "test_first_team_spend_action_emails_endpoint" {
    command = plan

    assert {
	condition = aws_sns_topic_subscription.team_spend_action_email_subscription["a@b.c"].endpoint == "a@b.c"
        error_message = "Incorrect first aws_sns_topic_subscription action endpoint"
    }
}

run "test_first_team_spend_action_emails_topic_arn" {
    command = plan

    assert {
	condition = aws_sns_topic_subscription.team_spend_action_email_subscription["a@b.c"].topic_arn == "arn:aws:sns:${var.AWS_REGION}:${var.awsID}:team-spend-action"
        error_message = "Incorrect first aws_sns_topic_subscription action topic"
    }
}

run "test_second_team_spend_alert_emails_protocol" {
    command = plan

    assert {
	condition = aws_sns_topic_subscription.team_spend_alert_email_subscription["d@e.f"].protocol == "email"
        error_message = "Incorrect aws_sns_topic_subscription alert protocol"
    }
}

run "test_second_team_spend_alert_emails_endpoint" {
    command = plan

    assert {
	condition = aws_sns_topic_subscription.team_spend_alert_email_subscription["d@e.f"].endpoint == "d@e.f"
        error_message = "Incorrect second aws_sns_topic_subscription alert endpoint"
    }
}

run "test_second_team_spend_alert_emails_topic_arn" {
    command = plan

    assert {
	condition = aws_sns_topic_subscription.team_spend_alert_email_subscription["d@e.f"].topic_arn == "arn:aws:sns:${var.AWS_REGION}:${var.awsID}:team-spend-alert"
        error_message = "Incorrect aws_sns_topic_subscription alert topic"
    }
}

run "test_second_team_spend_action_emails_protocol" {
    command = plan

    assert {
	condition = aws_sns_topic_subscription.team_spend_action_email_subscription["d@e.f"].protocol == "email"
        error_message = "Incorrect aws_sns_topic_subscription action protocol"
    }
}

run "test_second_team_spend_action_emails_endpoint" {
    command = plan

    assert {
	condition = aws_sns_topic_subscription.team_spend_action_email_subscription["d@e.f"].endpoint == "d@e.f"
        error_message = "Incorrect second aws_sns_topic_subscription action endpoint"
    }
}

run "test_second_team_spend_action_emails_topic_arn" {
    command = plan

    assert {
	condition = aws_sns_topic_subscription.team_spend_action_email_subscription["d@e.f"].topic_arn == "arn:aws:sns:${var.AWS_REGION}:${var.awsID}:team-spend-action"
        error_message = "Incorrect aws_sns_topic_subscription action topic"
    }
}

run "test_lambda_team_spend_action_emails_topic_arn" {
    command = plan

    assert {
	condition = aws_sns_topic_subscription.team_spend_action_lambda_subscription.topic_arn == "arn:aws:sns:${var.AWS_REGION}:${var.awsID}:team-spend-action"
        error_message = "Incorrect lambda aws_sns_topic_subscription action topic_arn"
    }
}

run "test_lambda_team_spend_action_emails_protocol" {
    command = plan

    assert {
	condition = aws_sns_topic_subscription.team_spend_action_lambda_subscription.protocol == "lambda"
        error_message = "Incorrect lambda aws_sns_topic_subscription action protocol"
    }
}

run "test_lambda_team_spend_action_emails_endpoint" {
    command = plan

    assert {
	condition = aws_sns_topic_subscription.team_spend_action_lambda_subscription.endpoint == "arn:aws:lambda:${var.AWS_REGION}:${var.awsID}:function:team-spend-action"
        error_message = "Incorrect lambda aws_sns_topic_subscription action endpoint"
    }
}

run "test_aws_lambda_permission_with_sns_statement_id" {
    command = plan

    assert {
	condition = aws_lambda_permission.with_sns.statement_id == "AllowExecutionFromSNS"
        error_message = "Incorrect aws_lambda_permission_with_sns statement_id"
    }
}

run "test_aws_lambda_permission_with_sns_action" {
    command = plan

    assert {
	condition = aws_lambda_permission.with_sns.action == "lambda:InvokeFunction"
        error_message = "Incorrect aws_lambda_permission_with_sns action"
    }
}

run "test_aws_lambda_permission_with_sns_function_name" {
    command = plan

    assert {
	condition = aws_lambda_permission.with_sns.function_name == "team-spend-action"
        error_message = "Incorrect aws_lambda_permission_with_sns function_name"
    }
}

run "test_aws_lambda_permission_with_sns_principal" {
    command = plan

    assert {
	condition = aws_lambda_permission.with_sns.principal == "sns.amazonaws.com"
        error_message = "Incorrect aws_lambda_permission_with_sns principal"
    }
}
