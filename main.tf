provider "aws" {
  region = "eu-west-2"
}

variable "awsID" {
  description = "the AWS ID to use for all resources"
  type = number
# it is a number but should it be a string? XXX
  default = 778666285893
}

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
#  to = aws_ce_anomaly_monitor.example
#  id = "costAnomalyMonitorARN"
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
