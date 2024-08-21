resource "aws_ce_anomaly_monitor" "service_monitor" {
  name              = "AWSServiceMonitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

#import {
#  to = aws_ce_anomaly_monitor.service_monitor
#  id = "costAnomalyMonitorARN"
#}

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

# need IAM role for the lambda to run as ...

# https://stackoverflow.com/questions/57288992/terraform-how-to-create-iam-role-for-aws-lambda-and-deploy-both gives

data "aws_iam_policy_document" "AWSLambdaTrustPolicy" {
  statement {
    actions    = ["sts:AssumeRole"]
    effect     = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "terraform_function_role" {
  name               = "terraform_function_role"
  assume_role_policy = data.aws_iam_policy_document.AWSLambdaTrustPolicy.json
}

resource "aws_iam_role_policy_attachment" "terraform_lambda_policy" {
  role       = aws_iam_role.terraform_function_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "terraform_function" {
  function_name    = "team-spend-action"
  package_type     = "Image"
  handler          = "index.js"
  role             = aws_iam_role.terraform_function_role.arn
  runtime          = "nodejs8.10"
  image_uri        = "778666285893.dkr.ecr.eu-west-2.amazonaws.com/team-spend-action:latest"
  tags             = {"team": "spend"}
}

# The lambda function is written in typescript.
# Lambdas must be deployed in Python or Javascript
# We deploy a docker image containing the transpiled Typescript and move the resultant Javascript into AWS.
# We could list the final Typescript transpilation as Javascript and deploy this as a zip file,
# the difference being that the Javascript could be viewed, which may or may not be desirable? XXX

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

resource "aws_ce_anomaly_subscription" "anomaly_subscription_20" {
  name      = "TeamSpend20"
  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn
  ]

  subscriber {
    type    = "SNS"
    address = "arn:aws:sns:eu-west-2:${var.awsID}:team-spend-alert"
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["1"]
    }
  }
}

resource "aws_ce_anomaly_subscription" "anomaly_subscription_40" {
  name      = "TeamSpend40"
  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn
  ]

  subscriber {
    type    = "SNS"
    address = "arn:aws:sns:eu-west-2:${var.awsID}:team-spend-alert"
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["2"]
    }
  }
}

resource "aws_ce_anomaly_subscription" "anomaly_subscription_60" {
  name      = "TeamSpend60"
  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn
  ]

  subscriber {
    type    = "SNS"
    address = "arn:aws:sns:eu-west-2:${var.awsID}:team-spend-alert"
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["3"]
    }
  }
}

resource "aws_ce_anomaly_subscription" "anomaly_subscription_80" {
  name      = "TeamSpend80"
  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn
  ]

  subscriber {
    type    = "SNS"
    address = "arn:aws:sns:eu-west-2:${var.awsID}:team-spend-alert"
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["4"]
    }
  }
}

resource "aws_ce_anomaly_subscription" "anomaly_subscription_action" {
  name      = "TeamSpendAction"
  frequency = "IMMEDIATE"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.service_monitor.arn
  ]

  subscriber {
    type    = "SNS"
    address = "arn:aws:sns:eu-west-2:${var.awsID}:team-spend-alert"
  }

  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["5"]
    }
  }
}
