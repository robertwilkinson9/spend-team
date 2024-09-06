run "test_service_monitor_name" {
    command = plan

    assert {
	condition = aws_ce_anomaly_monitor.service_monitor.name == "AWSServiceMonitor"
        error_message = "Incorrect team-spend-service_monitor name"
    }
}

run "test_service_monitor_type" {
    command = plan

    assert {
	condition = aws_ce_anomaly_monitor.service_monitor.monitor_type == "DIMENSIONAL"
        error_message = "Incorrect team-spend-service_monitor monitor_type"
    }
}

run "test_service_monitor_dimension" {
    command = plan

    assert {
	condition = aws_ce_anomaly_monitor.service_monitor.monitor_dimension == "SERVICE"
        error_message = "Incorrect team-spend-service_monitor monitor_dimension"
    }
}

#data "aws_iam_policy_document" "AWSLambdaTrustPolicy" {
#  statement {
#    actions    = ["sts:AssumeRole"]
#    effect     = "Allow"
#    principals {
#      type        = "Service"
#      identifiers = ["lambda.amazonaws.com"]
#    }
#  }
#}

run "test_aws_iam_policy_document" {
    command = plan

    variables {
#	aws_iam_policy_document.AWSLambdaTrustPolicy.effect = "Allow"
	effect = "Allow"
    }
}

#resource "aws_iam_role" "terraform_function_role" {
#  name               = "terraform_function_role"
#  assume_role_policy = data.aws_iam_policy_document.AWSLambdaTrustPolicy.json
#}

run "test_aws_iam_role_name" {
    command = plan

    assert {
	condition = aws_iam_role.terraform_function_role.name == "terraform_function_role"
        error_message = "Incorrect aws_iam_role_name"
    }
}

#run "test_aws_iam_role_assume_role_policy" {
#    command = plan
#
##    variables {
##      actions    = ["sts:AssumeRole"]
##      effect     = "Allow"
###      principals {
###        type        = "Service"
###        identifiers = ["lambda.amazonaws.com"]
###      }
##    }
#
#    assert {
#	condition = aws_iam_role.terraform_function_role.assume_role_policy == data.aws_iam_policy_document.AWSLambdaTrustPolicy.json
#        error_message = "Incorrect aws_iam_role_assume_role_policy"
#    }
#}

#resource "aws_iam_role_policy_attachment" "terraform_lambda_policy" {
#  role       = aws_iam_role.terraform_function_role.name
#  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
#}
#
#resource "aws_lambda_function" "terraform_function" {
#  function_name    = "team-spend-action"
#  package_type     = "Image"
#  handler          = "index.js"
#  role             = aws_iam_role.terraform_function_role.arn
#  runtime          = "nodejs20.x"
#  image_uri        = "778666285893.dkr.ecr.eu-west-2.amazonaws.com/team-spend-action:latest"
#  tags             = {"team": "spend"}
#}
