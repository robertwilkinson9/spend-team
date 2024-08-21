module "team_spend_anomaly_monitor_response" {
  source  = "./modules/anomaly_monitor_response"

  awsID = var.awsID
  alert_email_address = var.alert_email_address
  action_email_address = var.action_email_address
}

provider "aws" {
  region = "eu-west-2"
# Tags to apply to all AWS resources by default
  default_tags {
    tags = {
      "cost:owner" = "team-spend-XXX"
      "cost:allocation" = "who-knows-XXX"
      "information:owner" = "team-spend-XXX"
      "information:designation" = "InternalUseOnly"
      "information:classification" = "Unrestricted"
      "information:context" = "Public"
      "resource:owner" = "team-spend-XXX"
      "resource:role" = "Operations"
      "metadata:version:tag" = "0.0.1"
    }
  }
}

variable "awsID" {
  description = "the AWS ID to use for all resources"
  type = number
}

# I guess that these email addresses should have the capacity
# to be lists - or something? XXX

variable "alert_email_address" {
  description = "the email address for alerts"
  type = string
}

# it may be desirable for this to be null, or a list? XXX

variable "action_email_address" {
  description = "the email address for actions"
  type = string
}
