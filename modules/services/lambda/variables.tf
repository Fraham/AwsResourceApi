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