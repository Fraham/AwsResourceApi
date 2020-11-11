provider "aws" {
  region = var.region
}

variable "bucket" {
  type        = string
  description = "S3 bucket where lambda code is stored"
}

variable "region" {
  type        = string
  description = "The AWS region the resource API is being deployed to"
}

variable "app_version" {
  type        = string
  description = "The version of the lambda code"
}

variable "cloud_watch_alarm_topic" {
  type        = string
  description = "The SNS topic for CloudWatch alarms"
  default     = ""
}

variable "project" {
  type        = string
  description = "Shorthand project name"
  default     = "ARA"
}

data "aws_caller_identity" "current" {}

module "lambdas" {
  source = "./modules/services/lambda"

  lambdas = {
    "list_lambdas" = {
      lambda_name = "ListLambdas"
      handler     = "listLambdas.handler"
      policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": "lambda:ListFunctions",
        "Resource": "*"
    }
  ]
}
EOF
    },
    "get_lambda_metrics" = {
      lambda_name = "GetLambdaMetrics"
      handler     = "getLambdaMetrics.handler"
      policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": "cloudwatch:GetMetricStatistics",
        "Resource": "*"
    }
  ]
}
EOF
    },
    "get_lambda_alarms" = {
      lambda_name = "GetLambdaAlarms"
      handler     = "getLambdaAlarms.handler"
      policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": "cloudwatch:DescribeAlarmsForMetric",
        "Resource": "*"
    }
  ]
}
EOF
    },
    "list_cloudwatch_alarms" = {
      lambda_name = "ListCloudWatchAlarms"
      handler     = "getLambdaAlarms.handler"
      policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": "cloudwatch:DescribeAlarms",
        "Resource": "*"
    }
  ]
}
EOF
    },
    "get_cloudwatch_alarm" = {
      lambda_name = "GetCloudWatchAlarm"
      handler     = "getCloudWatchAlarm.handler"
      policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": "cloudwatch:DescribeAlarms",
        "Resource": "*"
    }
  ]
}
EOF
    },
    "list_api_gateway" = {
      lambda_name = "ListApiGateway"
      handler     = "listApiGateways.handler"
      policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": "apigateway:GET",
        "Resource": "*"
    }
  ]
}
EOF
    },
    "list_api_gateway_resource" = {
      lambda_name = "ListApiGatewayResource"
      handler     = "listApiGatewayResources.handler"
      policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": "apigateway:GET",
        "Resource": "*"
    }
  ]
}
EOF
    },
    "get_lambda" = {
      lambda_name = "GetLambda"
      handler     = "getLambda.handler"
      policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "lambda:GetFunction",
            "lambda:InvokeFunction",
            "cloudwatch:GetMetricStatistics"
        ],
        "Resource": "*"
    }
  ]
}
EOF
    },
    "list_s3_buckets" = {
      lambda_name = "ListS3Buckets"
      handler     = "listS3Buckets.handler"
      policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "s3:ListAllMyBuckets",
            "s3:ListBucket"
        ],
        "Resource": "*"
    }
  ]
}
EOF
    },
    "get_s3_bucket_location" = {
      lambda_name = "GetS3BucketLocation"
      handler     = "getS3BucketLocation.handler"
      policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetBucketLocation"
        ],
        "Resource": "*"
    }
  ]
}
EOF
    },
    "get_s3_bucket_logging" = {
      lambda_name = "GetS3BucketLogging"
      handler     = "getS3BucketLogging.handler"
      policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetBucketLogging"
        ],
        "Resource": "*"
    }
  ]
}
EOF
    }
  }

  project                 = var.project
  bucket                  = var.bucket
  app_version             = var.app_version
  account_id              = data.aws_caller_identity.current.account_id
  cloud_watch_alarm_topic = var.cloud_watch_alarm_topic
}

output "lambda_names" {
  value = values(module.lambdas.lambdas)[*].function_name
}

resource "aws_api_gateway_rest_api" "resource_api" {
  name        = "ResourceAPI"
  description = "The REST resource API"
}

module "api_gateway_rest_api_id_methods" {
  source = "./modules/services/apigateway/method"

  region      = var.region
  account_id  = data.aws_caller_identity.current.account_id
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  lambdas     = module.lambdas.lambdas

  methods = {
    "list_lambdas" = {
      resource_id   = aws_api_gateway_resource.lambda.id
      resource_path = aws_api_gateway_resource.lambda.path
    },
    "get_lambda" = {
      resource_id   = aws_api_gateway_resource.lambda_functionarn.id
      resource_path = aws_api_gateway_resource.lambda_functionarn.path
    },
    "get_lambda_metrics" = {
      resource_id   = aws_api_gateway_resource.lambda_functionarn_metrics.id
      resource_path = aws_api_gateway_resource.lambda_functionarn_metrics.path
    },
    "get_lambda_alarms" = {
      resource_id   = aws_api_gateway_resource.lambda_functionarn_alarms.id
      resource_path = aws_api_gateway_resource.lambda_functionarn_alarms.path
    },
    "list_cloudwatch_alarms" = {
      resource_id   = aws_api_gateway_resource.cloud_watch_alarms.id
      resource_path = aws_api_gateway_resource.cloud_watch_alarms.path
    },
    "get_cloudwatch_alarm" = {
      resource_id   = aws_api_gateway_resource.cloud_watch_alarmarn.id
      resource_path = aws_api_gateway_resource.cloud_watch_alarmarn.path
    },
    "list_api_gateway" = {
      resource_id   = aws_api_gateway_resource.api_gateway.id
      resource_path = aws_api_gateway_resource.api_gateway.path
    },
    "list_api_gateway_resource" = {
      resource_id   = aws_api_gateway_resource.api_gateway_rest_api_id_resources.id
      resource_path = aws_api_gateway_resource.api_gateway_rest_api_id_resources.path
    },
    "list_s3_buckets" = {
      resource_id   = aws_api_gateway_resource.s3_bucket.id
      resource_path = aws_api_gateway_resource.s3_bucket.path
    },
    "get_s3_bucket_location" = {
      resource_id   = aws_api_gateway_resource.s3_bucket_name_location.id
      resource_path = aws_api_gateway_resource.s3_bucket_name_location.path
    },
    "get_s3_bucket_logging" = {
      resource_id   = aws_api_gateway_resource.s3_bucket_name_logging.id
      resource_path = aws_api_gateway_resource.s3_bucket_name_logging.path
    }
  }
}

resource "aws_api_gateway_resource" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  parent_id   = aws_api_gateway_rest_api.resource_api.root_resource_id
  path_part   = "lambda"
}

resource "aws_api_gateway_resource" "lambda_functionarn" {
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  parent_id   = aws_api_gateway_resource.lambda.id
  path_part   = "{functionarn}"
}

resource "aws_api_gateway_resource" "lambda_functionarn_metrics" {
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  parent_id   = aws_api_gateway_resource.lambda_functionarn.id
  path_part   = "metrics"
}

resource "aws_api_gateway_resource" "lambda_functionarn_alarms" {
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  parent_id   = aws_api_gateway_resource.lambda_functionarn.id
  path_part   = "alarms"
}

resource "aws_api_gateway_resource" "cloud_watch_alarms" {
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  parent_id   = aws_api_gateway_rest_api.resource_api.root_resource_id
  path_part   = "cloudwatchalarm"
}

resource "aws_api_gateway_resource" "cloud_watch_alarmarn" {
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  parent_id   = aws_api_gateway_resource.cloud_watch_alarms.id
  path_part   = "{alarmarn}"
}

resource "aws_api_gateway_resource" "api_gateway" {
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  parent_id   = aws_api_gateway_rest_api.resource_api.root_resource_id
  path_part   = "apigateway"
}

resource "aws_api_gateway_resource" "api_gateway_rest_api_id" {
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  parent_id   = aws_api_gateway_resource.api_gateway.id
  path_part   = "{restapiid}"
}

resource "aws_api_gateway_resource" "api_gateway_rest_api_id_resources" {
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  parent_id   = aws_api_gateway_resource.api_gateway_rest_api_id.id
  path_part   = "resource"
}

resource "aws_api_gateway_resource" "s3_bucket" {
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  parent_id   = aws_api_gateway_rest_api.resource_api.root_resource_id
  path_part   = "s3bucket"
}

resource "aws_api_gateway_resource" "s3_bucket_name" {
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  parent_id   = aws_api_gateway_resource.s3_bucket.id
  path_part   = "{bucketname}"
}

resource "aws_api_gateway_resource" "s3_bucket_name_location" {
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  parent_id   = aws_api_gateway_resource.s3_bucket_name.id
  path_part   = "location"
}

resource "aws_api_gateway_resource" "s3_bucket_name_logging" {
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  parent_id   = aws_api_gateway_resource.s3_bucket_name.id
  path_part   = "logging"
}

resource "aws_api_gateway_deployment" "dev_deployment" {
  depends_on  = [module.api_gateway_rest_api_id_methods.gateway_integration]
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  stage_name  = "dev"

  triggers = {
    redeployment = sha1(join(",", list(
      jsonencode(module.api_gateway_rest_api_id_methods.gateway_integration)
    )))
  }

  lifecycle {
    create_before_destroy = false
  }
}

resource "aws_api_gateway_stage" "production" {
  stage_name           = "prod"
  rest_api_id          = aws_api_gateway_rest_api.resource_api.id
  deployment_id        = aws_api_gateway_deployment.dev_deployment.id
  xray_tracing_enabled = true
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  name        = "my-usage-plan"
  description = "my description"

  api_stages {
    api_id = aws_api_gateway_rest_api.resource_api.id
    stage  = aws_api_gateway_deployment.dev_deployment.stage_name
  }

  api_stages {
    api_id = aws_api_gateway_rest_api.resource_api.id
    stage  = aws_api_gateway_stage.production.stage_name
  }
}

resource "aws_api_gateway_api_key" "api_key" {
  name = "resource_key"
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}
