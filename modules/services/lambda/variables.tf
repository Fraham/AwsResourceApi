# variable "lambda_name" {
#   type        = string
#   description = "Name of the lambda"
# }

# variable "handler" {
#   type        = string
#   description = ""
# }

# variable "role_arn" {
#   type        = string
#   description = ""
# }

variable "dependencies_layer_arn" {
  type        = string
  description = ""
}

variable "app_version" {
  type        = string
  description = "The version of the lambda code"
}

variable "project" {
  type        = string
  description = "Shorthand project name"
  default     = "ARA"
}

variable "bucket" {
  type        = string
  description = "S3 bucket where lambda code is stored"
}

variable "lambdas"{
    type = map
}

variable "account_id"{
    type        = string
}

variable "cloud_watch_alarm_topic" {
  type        = string
  description = "The SNS topic for CloudWatch alarms"
  default     = ""
}