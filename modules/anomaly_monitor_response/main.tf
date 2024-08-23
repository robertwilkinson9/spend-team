resource "aws_ce_anomaly_monitor" "service_monitor" {
  name              = "AWSServiceMonitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

#import {
#  to = aws_ce_anomaly_monitor.service_monitor
#  id = "costAnomalyMonitorARN"
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
  runtime          = "nodejs20.x"
  image_uri        = "778666285893.dkr.ecr.eu-west-2.amazonaws.com/team-spend-action:latest"
  tags             = {"team": "spend"}
}
