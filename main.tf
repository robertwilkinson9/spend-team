# this file should become a module after development
# when so, the provider stanza should be dropped
# and presumably the awsID itoo? which similarly should be
# defined at the top level. XXX

module "team_spend_anomaly_monitor_response" {
  source  = "./modules/anomaly_monitor_response"

#  version = "1.0.0"

  awsID = var.awsID
  alert_email_address = var.alert_email_address
  action_email_address = var.action_email_address
}

provider "aws" {
  region = "eu-west-2"
# Tags to apply to all AWS resources by default
  default_tags {
    tags = {
      Owner = "team-spend"
    }
  }
}

variable "awsID" {
  description = "the AWS ID to use for all resources"
  type = number
# it is a number but should it be a string? XXX
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
