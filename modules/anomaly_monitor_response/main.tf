# aws ce get-anomaly-monitors
# {
#     "AnomalyMonitors": [
#         {
#             "MonitorArn": "arn:aws:ce::778666285893:anomalymonitor/c1dbe37d-8fe1-4654-9ff1-8d4a18f29c34",
#             "MonitorName": "thresh",
#             "CreationDate": "2024-07-17T11:46:29.209Z",
#             "LastUpdatedDate": "2024-08-16T06:05:18.724Z",
#             "LastEvaluatedDate": "2024-08-16T06:05:18.724Z",
#             "MonitorType": "DIMENSIONAL",
#             "MonitorDimension": "SERVICE",
#             "DimensionalValueCount": 22
#         }
#     ]
# }

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

# aws sns list-topics | grep Spend
#             "TopicArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAction"
#             "TopicArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAlert"
#for topic in $(aws sns list-topics | grep Spend | awk '{print $NF}' | sed -e 's/^"//' | sed -e 's/"$//'); do aws sns get-topic-attributes --topic-arn $topic; done
# {
#     "Attributes": {
#         "Policy": "{\"Version\":\"2008-10-17\",\"Id\":\"__default_policy_ID\",\"Statement\":[{\"Sid\":\"__default_statement_ID\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"*\"},\"Action\":[\"SNS:GetTopicAttributes\",\"SNS:SetTopicAttributes\",\"SNS:AddPermission\",\"SNS:RemovePermission\",\"SNS:DeleteTopic\",\"SNS:Subscribe\",\"SNS:ListSubscriptionsByTopic\",\"SNS:Publish\"],\"Resource\":\"arn:aws:sns:eu-west-2:778666285893:TeamSpendAction\",\"Condition\":{\"StringEquals\":{\"AWS:SourceOwner\":\"778666285893\"}}}]}",
#         "Owner": "778666285893",
#         "SubscriptionsPending": "0",
#         "TopicArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAction",
#         "TracingConfig": "PassThrough",
#         "EffectiveDeliveryPolicy": "{\"http\":{\"defaultHealthyRetryPolicy\":{\"minDelayTarget\":20,\"maxDelayTarget\":20,\"numRetries\":3,\"numMaxDelayRetries\":0,\"numNoDelayRetries\":0,\"numMinDelayRetries\":0,\"backoffFunction\":\"linear\"},\"disableSubscriptionOverrides\":false,\"defaultRequestPolicy\":{\"headerContentType\":\"text/plain; charset=UTF-8\"}}}",
#         "SubscriptionsConfirmed": "2",
#         "DisplayName": "Team Spend Action",
#         "SubscriptionsDeleted": "0"
#     }
# }
# {
#     "Attributes": {
#         "Policy": "{\"Version\":\"2008-10-17\",\"Id\":\"__default_policy_ID\",\"Statement\":[{\"Sid\":\"__default_statement_ID\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"*\"},\"Action\":[\"SNS:Publish\",\"SNS:RemovePermission\",\"SNS:SetTopicAttributes\",\"SNS:DeleteTopic\",\"SNS:ListSubscriptionsByTopic\",\"SNS:GetTopicAttributes\",\"SNS:AddPermission\",\"SNS:Subscribe\"],\"Resource\":\"arn:aws:sns:eu-west-2:778666285893:TeamSpendAlert\",\"Condition\":{\"StringEquals\":{\"AWS:SourceOwner\":\"778666285893\"}}}]}",
#         "Owner": "778666285893",
#         "SubscriptionsPending": "0",
#         "TopicArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAlert",
#         "TracingConfig": "PassThrough",
#         "EffectiveDeliveryPolicy": "{\"http\":{\"defaultHealthyRetryPolicy\":{\"minDelayTarget\":20,\"maxDelayTarget\":20,\"numRetries\":3,\"numMaxDelayRetries\":0,\"numNoDelayRetries\":0,\"numMinDelayRetries\":0,\"backoffFunction\":\"linear\"},\"disableSubscriptionOverrides\":false,\"defaultRequestPolicy\":{\"headerContentType\":\"text/plain; charset=UTF-8\"}}}",
#         "SubscriptionsConfirmed": "1",
#         "DisplayName": "TeamSpendAlert",
#         "SubscriptionsDeleted": "0"
#     }
# }

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
#         "ResolvedImageUri": "778666285893.dkr.ecr.eu-west-2.amazonaws.com/team-spend-action@sha256:d0ec757342ba64f8f80c524431989d778c45289bfe312a58fe2dfbc0fa604c4e"
}

#robert@CIC001419:~/src/typescript/spend-team$ aws iam list-roles | grep DevOps
#            "RoleName": "AWSReservedSSO_LD-DevOpsAccess_c56db55a3b79e611",
#            "Arn": "arn:aws:iam::778666285893:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_LD-DevOpsAccess_c56db55a3b79e611",
#            "Description": "Permission Set for the RTNPlaygroundDevOps Learning and Development account users",
#            "RoleName": "AWSReservedSSO_RTNDevOps-EngineerFullAccess_10f8c0cf65fd5e09",
#            "Arn": "arn:aws:iam::778666285893:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_RTNDevOps-EngineerFullAccess_10f8c0cf65fd5e09",
#                            "AWS": "arn:aws:iam::477504957304:role/service-role/RTNDevOps-CodeBuild-service-role"

#robert@CIC001419:~/src/typescript/spend-team$ aws iam get-role --role-name AWSReservedSSO_LD-DevOpsAccess_c56db55a3b79e611
#{
#    "Role": {
#        "Path": "/aws-reserved/sso.amazonaws.com/eu-west-2/",
#        "RoleName": "AWSReservedSSO_LD-DevOpsAccess_c56db55a3b79e611",
#        "RoleId": "AROA3KTBATNC2UGVZQM5E",
#        "Arn": "arn:aws:iam::778666285893:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_LD-DevOpsAccess_c56db55a3b79e611",
#        "CreateDate": "2021-12-01T11:15:37Z",
#        "AssumeRolePolicyDocument": {
#            "Version": "2012-10-17",
#            "Statement": [
#                {
#                    "Effect": "Allow",
#                    "Principal": {
#                        "Federated": "arn:aws:iam::778666285893:saml-provider/AWSSSO_e8264dc942f31fa6_DO_NOT_DELETE"
#                    },
#                    "Action": [
#                        "sts:AssumeRoleWithSAML",
#                        "sts:TagSession"
#                    ],
#                    "Condition": {
#                        "StringEquals": {
#                            "SAML:aud": "https://signin.aws.amazon.com/saml"
#                        }
#                    }
#                }
#            ]
#        },
#        "Description": "Permission Set for the RTNPlaygroundDevOps Learning and Development account users",
#        "MaxSessionDuration": 43200,
#        "RoleLastUsed": {
#            "LastUsedDate": "2024-08-19T15:35:05Z",
#            "Region": "eu-west-2"
#        }
#    }
#}

# $ aws iam get-role --role-name PlaygroundGenericRoleForServices
# {
#     "Role": {
#         "Path": "/",
#         "RoleName": "PlaygroundGenericRoleForServices",
#         "RoleId": "AROA3KTBATNCX6FSCQATE",
#         "Arn": "arn:aws:iam::778666285893:role/PlaygroundGenericRoleForServices",
#         "CreateDate": "2021-12-02T12:52:03Z",
#         "AssumeRolePolicyDocument": {
#             "Version": "2012-10-17",
#             "Statement": [
#                 {
#                     "Effect": "Allow",
#                     "Principal": {
#                         "Service": [
#                             "health.amazonaws.com",
#                             "ec2scheduled.amazonaws.com",
#                             "events.amazonaws.com",
#                             "sms.amazonaws.com",
#                             "codebuild.amazonaws.com",
#                             "appsync.amazonaws.com",
#                             "rds.amazonaws.com",
#                             "waf-regional.amazonaws.com",
#                             "dynamodb.amazonaws.com",
#                             "application-autoscaling.amazonaws.com",
#                             "monitoring.rds.amazonaws.com",
#                             "replication.dynamodb.amazonaws.com",
#                             "ecs-tasks.amazonaws.com",
#                             "sns.amazonaws.com",
#                             "config-conforms.amazonaws.com",
#                             "backup.amazonaws.com",
#                             "replicator.lambda.amazonaws.com",
#                             "codepipeline.amazonaws.com",
#                             "logger.cloudfront.amazonaws.com",
#                             "ecs.application-autoscaling.amazonaws.com",
#                             "s3.amazonaws.com",
#                             "apigateway.amazonaws.com",
#                             "ec2.amazonaws.com",
#                             "guardduty.amazonaws.com",
#                             "dynamodb.application-autoscaling.amazonaws.com",
#                             "ec2.application-autoscaling.amazonaws.com",
#                             "qldb.amazonaws.com",
#                             "elasticloadbalancing.amazonaws.com",
#                             "elasticache.amazonaws.com",
#                             "elasticfilesystem.amazonaws.com",
#                             "eks.amazonaws.com",
#                             "lambda.amazonaws.com",
#                             "shield.amazonaws.com",
#                             "sqs.amazonaws.com",
#                             "cloudfront.amazonaws.com",
#                             "ops.apigateway.amazonaws.com",
#                             "config.amazonaws.com",
#                             "tagpolicies.tag.amazonaws.com",
#                             "athena.amazonaws.com",
#                             "elasticbeanstalk.amazonaws.com",
#                             "inspector.amazonaws.com",
#                             "lightsail.amazonaws.com",
#                             "codedeploy.amazonaws.com",
#                             "ecs.amazonaws.com",
#                             "opsworks.amazonaws.com",
#                             "dms.amazonaws.com",
#                             "cloudformation.amazonaws.com",
#                             "kms.amazonaws.com",
#                             "resource-groups.amazonaws.com",
#                             "ssm.amazonaws.com",
#                             "autoscaling.amazonaws.com",
#                             "fsx.amazonaws.com",
#                             "opsworks-cm.amazonaws.com",
#                             "serverlessrepo.amazonaws.com",
#                             "managedservices.amazonaws.com",
#                             "eks-fargate-pods.amazonaws.com",
#                             "cloudtrail.amazonaws.com",
#                             "states.amazonaws.com",
#                             "ses.amazonaws.com",
#                             "securityhub.amazonaws.com",
#                             "logs.amazonaws.com",
#                             "dlm.amazonaws.com",
#                             "ec2fleet.amazonaws.com",
#                             "codecommit.amazonaws.com"
#                         ]
#                     },
#                     "Action": "sts:AssumeRole"
#                 }
#             ]
#         },
#         "Description": "",
#         "MaxSessionDuration": 3600,
#         "Tags": [
#             {
#                 "Key": "Name",
#                 "Value": "PlaygroundGenericRole"
#             },
#             {
#                 "Key": "cost:association",
#                 "Value": "NSC"
#             },
#             {
#                 "Key": "resource:environment",
#                 "Value": "Core"
#             },
#             {
#                 "Key": "information:designation",
#                 "Value": "InternalUseOnly"
#             },
#             {
#                 "Key": "resource:owner",
#                 "Value": "RTN"
#             },
#             {
#                 "Key": "information:owner",
#                 "Value": "1160445"
#             },
#             {
#                 "Key": "cost:allocation",
#                 "Value": "600015786"
#             },
#             {
#                 "Key": "cost:owner",
#                 "Value": "1137969"
#             }
#         ],
#         "RoleLastUsed": {
#             "LastUsedDate": "2024-08-19T19:01:17Z",
#             "Region": "eu-west-2"
#         }
#     }
# }

#robert@CIC001419:~/src/typescript/spend-team$
# The lambda function is written in typescript.
# Lambdas must be deployed in Python or Javascript
# We deploy a docker image containing the transpiled Typescript and move the resultant Javascript into AWS.
# We could list the final Typescript transpilation as Javascript and deploy this as a zip file,
# the difference being that the Javascript could be viewed, which may or may not be desirable? XXX

# aws lambda get-function --function-name team-spend-action
# {
#     "Configuration": {
#         "FunctionName": "team-spend-action",
#         "FunctionArn": "arn:aws:lambda:eu-west-2:778666285893:function:team-spend-action",
#         "Role": "arn:aws:iam::778666285893:role/PlaygroundGenericRoleForServices",
#         "CodeSize": 0,
#         "Description": "",
#         "Timeout": 3,
#         "MemorySize": 128,
#         "LastModified": "2024-08-07T13:20:10.000+0000",
#         "CodeSha256": "d0ec757342ba64f8f80c524431989d778c45289bfe312a58fe2dfbc0fa604c4e",
#         "Version": "$LATEST",
#         "TracingConfig": {
#             "Mode": "PassThrough"
#         },
#         "RevisionId": "321d3751-c7bd-41ce-8cfb-2d567b104016",
#         "State": "Active",
#         "LastUpdateStatus": "Successful",
#         "PackageType": "Image",
#         "ImageConfigResponse": {},
#         "Architectures": [
#             "x86_64"
#         ],
#         "EphemeralStorage": {
#             "Size": 512
#         },
#         "SnapStart": {
#             "ApplyOn": "None",
#             "OptimizationStatus": "Off"
#         },
#         "LoggingConfig": {
#             "LogFormat": "Text",
#             "LogGroup": "/aws/lambda/team-spend-action"
#         }
#     },
#     "Code": {
#         "RepositoryType": "ECR",
#         "ImageUri": "778666285893.dkr.ecr.eu-west-2.amazonaws.com/team-spend-action:latest",
#         "ResolvedImageUri": "778666285893.dkr.ecr.eu-west-2.amazonaws.com/team-spend-action@sha256:d0ec757342ba64f8f80c524431989d778c45289bfe312a58fe2dfbc0fa604c4e"
#     },
#     "Tags": {
#         "team": "spend"
#     }
# }

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
# resource "aws_lambda_function" "terraform_function" {
#  function_name    = "team-spend-action"
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.team_spend_action.arn
}
#aws sns list-subscriptions | grep Spend
#             "SubscriptionArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAction:45909378-bd41-4d4d-afb1-96a17bd9eecc",
#             "TopicArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAction"
#             "SubscriptionArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAction:430ed0ff-4769-4ce4-a322-4dcaeec03c15",
#             "TopicArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAction"
#             "SubscriptionArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAlert:da58f922-d3fb-4245-96e9-f639a757a8de",
#             "TopicArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAlert"

#for arn in $(aws sns list-subscriptions | grep Spend | grep ionArn | awk '{print $NF}' | sed -e 's/^"//' | sed -e 's/",$//'); do echo $arn; done

# {
#     "Attributes": {
#         "SubscriptionPrincipal": "arn:aws:iam::778666285893:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_LD-DevOpsAccess_c56db55a3b79e611",
#         "Owner": "778666285893",
#         "RawMessageDelivery": "false",
#         "TopicArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAction",
#         "Endpoint": "arn:aws:lambda:eu-west-2:778666285893:function:team-spend-action",
#         "Protocol": "lambda",
#         "PendingConfirmation": "false",
#         "ConfirmationWasAuthenticated": "true",
#         "SubscriptionArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAction:45909378-bd41-4d4d-afb1-96a17bd9eecc"
#     }
# }
# {
#     "Attributes": {
#         "SubscriptionPrincipal": "arn:aws:iam::778666285893:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_LD-DevOpsAccess_c56db55a3b79e611",
#         "Owner": "778666285893",
#         "RawMessageDelivery": "false",
#         "TopicArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAction",
#         "Endpoint": "robert.wilkinson@raytheon.co.uk",
#         "Protocol": "email",
#         "PendingConfirmation": "false",
#         "ConfirmationWasAuthenticated": "false",
#         "SubscriptionArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAction:430ed0ff-4769-4ce4-a322-4dcaeec03c15"
#     }
# }
# {
#     "Attributes": {
#         "SubscriptionPrincipal": "arn:aws:iam::778666285893:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_LD-DevOpsAccess_c56db55a3b79e611",
#         "Owner": "778666285893",
#         "RawMessageDelivery": "false",
#         "TopicArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAlert",
#         "Endpoint": "robert.wilkinson@raytheon.co.uk",
#         "Protocol": "email",
#         "PendingConfirmation": "false",
#         "ConfirmationWasAuthenticated": "false",
#         "SubscriptionArn": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAlert:da58f922-d3fb-4245-96e9-f639a757a8de"
#     }
# }

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

# aws ce get-anomaly-subscriptions
# {
#     "AnomalySubscriptions": [
#         {
#             "SubscriptionArn": "arn:aws:ce::778666285893:anomalysubscription/584c6dc6-9992-4826-90fa-b223f068db3d",
#             "AccountId": "778666285893",
#             "MonitorArnList": [
#                 "arn:aws:ce::778666285893:anomalymonitor/c1dbe37d-8fe1-4654-9ff1-8d4a18f29c34"
#             ],
#             "Subscribers": [
#                 {
#                     "Address": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAlert",
#                     "Type": "SNS",
#                     "Status": "CONFIRMED"
#                 }
#             ],
#             "Threshold": 1.0,
#             "Frequency": "IMMEDIATE",
#             "SubscriptionName": "TeamSpend20",
#             "ThresholdExpression": {
#                 "Dimensions": {

# aws ce get-anomaly-subscriptions
# {
#     "AnomalySubscriptions": [
#         {
#             "SubscriptionArn": "arn:aws:ce::778666285893:anomalysubscription/584c6dc6-9992-4826-90fa-b223f068db3d",
#             "AccountId": "778666285893",
#             "MonitorArnList": [
#                 "arn:aws:ce::778666285893:anomalymonitor/c1dbe37d-8fe1-4654-9ff1-8d4a18f29c34"
#             ],
#             "Subscribers": [
#                 {
#                     "Address": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAlert",
#                     "Type": "SNS",
#                     "Status": "CONFIRMED"
#                 }
#             ],
#             "Threshold": 1.0,
#             "Frequency": "IMMEDIATE",
#             "SubscriptionName": "TeamSpend20",
#             "ThresholdExpression": {
#                 "Dimensions": {
#                     "Key": "ANOMALY_TOTAL_IMPACT_ABSOLUTE",
#                     "Values": [
#                         "1"
#                     ],
#                     "MatchOptions": [
#                         "GREATER_THAN_OR_EQUAL"
#                     ]
#                 }
#             }
#         },
#         {
#             "SubscriptionArn": "arn:aws:ce::778666285893:anomalysubscription/8bb3933b-fc44-4642-993f-37c9e1e81ff3",
#             "AccountId": "778666285893",
#             "MonitorArnList": [
#                 "arn:aws:ce::778666285893:anomalymonitor/c1dbe37d-8fe1-4654-9ff1-8d4a18f29c34"
#             ],
#             "Subscribers": [
#                 {
#                     "Address": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAlert",
#                     "Type": "SNS",
#                     "Status": "CONFIRMED"
#                 }
#             ],
#             "Threshold": 4.0,
#             "Frequency": "IMMEDIATE",
#             "SubscriptionName": "TeamSpend80",
#             "ThresholdExpression": {
#                 "Dimensions": {
#                     "Key": "ANOMALY_TOTAL_IMPACT_ABSOLUTE",
#                     "Values": [
#                         "4"
#                     ],
#                     "MatchOptions": [
#                         "GREATER_THAN_OR_EQUAL"
#                     ]
#                 }
#             }
#         },
#         {
#             "SubscriptionArn": "arn:aws:ce::778666285893:anomalysubscription/c6c8dbb0-ec2c-4c8a-a85d-3a1579c2c87a",
#             "AccountId": "778666285893",
#             "MonitorArnList": [
#                 "arn:aws:ce::778666285893:anomalymonitor/c1dbe37d-8fe1-4654-9ff1-8d4a18f29c34"
#             ],
#             "Subscribers": [
#                 {
#                     "Address": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAlert",
#                     "Type": "SNS",
#                     "Status": "CONFIRMED"
#                 }
#             ],
#             "Threshold": 2.0,
#             "Frequency": "IMMEDIATE",
#             "SubscriptionName": "TeamSpend40",
#             "ThresholdExpression": {
#                 "Dimensions": {
#                     "Key": "ANOMALY_TOTAL_IMPACT_ABSOLUTE",
#                     "Values": [
#                         "2"
#                     ],
#                     "MatchOptions": [
#                         "GREATER_THAN_OR_EQUAL"
#                     ]
#                 }
#             }
#         },
#         {
#             "SubscriptionArn": "arn:aws:ce::778666285893:anomalysubscription/d2b9a01a-41a4-4dd1-9ed3-085ee7bd564b",
#             "AccountId": "778666285893",
#             "MonitorArnList": [
#                 "arn:aws:ce::778666285893:anomalymonitor/c1dbe37d-8fe1-4654-9ff1-8d4a18f29c34"
#             ],
#             "Subscribers": [
#                 {
#                     "Address": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAlert",
#                     "Type": "SNS",
#                     "Status": "CONFIRMED"
#                 }
#             ],
#             "Threshold": 3.0,
#             "Frequency": "IMMEDIATE",
#             "SubscriptionName": "TeamSpend60",
#             "ThresholdExpression": {
#                 "Dimensions": {
#                     "Key": "ANOMALY_TOTAL_IMPACT_ABSOLUTE",
#                     "Values": [
#                         "3"
#                     ],
#                     "MatchOptions": [
#                         "GREATER_THAN_OR_EQUAL"
#                     ]
#                 }
#             }
#         },
#         {
#             "SubscriptionArn": "arn:aws:ce::778666285893:anomalysubscription/f5dcb18b-101b-4b24-bb28-0eb1dd0eb5cd",
#             "AccountId": "778666285893",
#             "MonitorArnList": [
#                 "arn:aws:ce::778666285893:anomalymonitor/c1dbe37d-8fe1-4654-9ff1-8d4a18f29c34"
#             ],
#             "Subscribers": [
#                 {
#                     "Address": "arn:aws:sns:eu-west-2:778666285893:TeamSpendAction",
#                     "Type": "SNS",
#                     "Status": "CONFIRMED"
#                 }
#             ],
#             "Threshold": 5.0,
#             "Frequency": "IMMEDIATE",
#             "SubscriptionName": "TeamSpendAction",
#             "ThresholdExpression": {
#                 "Dimensions": {
#                     "Key": "ANOMALY_TOTAL_IMPACT_ABSOLUTE",
#                     "Values": [
#                         "5"
#                     ],
#                     "MatchOptions": [
#                         "GREATER_THAN_OR_EQUAL"
#                     ]
#                 }
#             }
#         }
#     ]
# }
