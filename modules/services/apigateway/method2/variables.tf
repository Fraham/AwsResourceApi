variable "rest_api_id" {
  type        = string
  description = "The id of the rest"
}

variable "region" {
      type        = string
  description = ""
}

variable "account_id" {
  type        = string
  description = "The id for the AWS account"
}

variable "lambdas"{

}

variable "methods"{
    type = map
}



