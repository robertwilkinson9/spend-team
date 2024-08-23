resource "aws_sns_topic" "team_spend_alert" {
  name = "team-spend-alert"
}

#import {
#  to = aws_sns_topic.team_spend_alert
#  id = "arn:aws:sns:eu-west-2:${var.awsID}:team-spend-alert.arn"
#}

resource "aws_sns_topic" "team_spend_action" {
  name = "team-spend_action"
}

#import {
#  to = aws_sns_topic.team_spend_action
#  id = "arn:aws:sns:eu-west-2:0123456789012:team-spend-action"
#}

resource "aws_sns_topic_subscription" "team_spend_alert_email_subscription" {
  topic_arn = "arn:aws:sns:eu-west-2:${var.awsID}:team-spend-alert"
  protocol  = "email"
  endpoint  = "${var.alert_email_address}"
}

resource "aws_sns_topic_subscription" "team_spend_action_email_subscription" {
  topic_arn = "arn:aws:sns:eu-west-2:${var.awsID}:team-spend-action"
  protocol  = "email"
  endpoint  = "${var.action_email_address}"
}

resource "aws_sns_topic_subscription" "team_spend_action_lambda_subscription" {
  topic_arn = "arn:aws:sns:eu-west-2:${var.awsID}:team-spend-action"
  protocol  = "lambda"
  endpoint  = "arn:aws:lambda:eu-west-2:${var.awsID}:function:team-spend-action"
}

# need to add permissions for sns to invoke the lambda too
# https://stackoverflow.com/questions/66853200/how-to-create-aws-lambda-trigger-in-terraform

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_function.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.team_spend_action.arn
}
