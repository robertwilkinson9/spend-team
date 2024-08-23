module "team_spend_anomaly_monitor_response" {
  source  = "./modules/anomaly_monitor_response"

  awsID = var.awsID
  team_spend_emails = var.team_spend_emails
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

variable "team_spend_emails" {
  description = "the email address for alerts"
  type = list(string)
  default = [""]
}
