variable "awsID" {
  description = "the AWS ID to use for all resources"
  type = number
# it is a number but should it be a string? XXX
  default = 0
}

# I guess that these email addresses should have the capacity
# to be lists - or something? XXX

variable "team_spend_emails" {
  description = "the email address for alerts"
  type = list(string)
  default = [""]
#  type = string
#  default = ""
}
