variable "awsID" {
  description = "the AWS ID to use for all resources"
  type = number
  default = 0
}

variable "team_spend_emails" {
  description = "the email address for alerts"
  type = list(string)
  default = [""]
}
