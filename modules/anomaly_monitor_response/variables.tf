variable "awsID" {
  description = "the AWS ID to use for all resources"
  type = number
# it is a number but should it be a string? XXX
  default = 0
}

# I guess that these email addresses should have the capacity
# to be lists - or something? XXX

variable "alert_email_address" {
  description = "the email address for alerts"
  type = string
  default = ""
}

# it may be desirable for this to be null, or a list? XXX

variable "action_email_address" {
  description = "the email address for actions"
  type = string
  default = ""
}
