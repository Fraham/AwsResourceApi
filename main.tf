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

resource "aws_lambda_layer_version" "dependencies" {
  layer_name = "Dependencies"
  s3_bucket  = var.bucket
  s3_key     = "ara${var.app_version}/dependencies.zip"
}

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
    }
  }

  project                = var.project
  bucket                 = var.bucket
  app_version            = var.app_version
  dependencies_layer_arn = aws_lambda_layer_version.dependencies.arn
}

output "lambda_names" {
  value = values(module.lambdas.lambdas)[*].function_name
}

resource "aws_lambda_function" "get_lambda" {
  function_name = "${var.project}-GetLambda"

  s3_bucket = var.bucket
  s3_key    = "ara${var.app_version}/code.zip"

  handler = "getLambda.handler"
  runtime = "nodejs12.x"

  role = aws_iam_role.get_lambda_exec.arn

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  timeout = 30

  environment {
    variables = {
      GET_LAMBDA_METRICS_ARN = module.lambdas.lambdas["get_lambda_metrics"].arn,
      GET_LAMBDA_ALARMS_ARN  = module.lambdas.lambdas["get_lambda_alarms"].arn,
    }
  }
}

resource "aws_iam_role" "get_lambda_exec" {
  name = "get_lambda_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "get_lambda_access" {
  name        = "${var.project}-Access-GetLambda"
  path        = "/"
  description = "IAM policy for GetLambda lambda"

  policy = <<EOF
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
}

resource "aws_iam_role_policy_attachment" "get_lambda_access" {
  role       = aws_iam_role.get_lambda_exec.name
  policy_arn = aws_iam_policy.get_lambda_access.arn
}

module "lambda_alarms" {
  source = "github.com/Fraham/TerraformModuleForAws//modules/services/lambda/alarms"

  function_name = [
    module.lambdas.lambdas["list_lambdas"].function_name,
    aws_lambda_function.get_lambda.function_name,
    module.lambdas.lambdas["get_lambda_metrics"].function_name,
    module.lambdas.lambdas["get_lambda_alarms"].function_name,
    module.lambdas.lambdas["list_cloudwatch_alarms"].function_name,
    module.lambdas.lambdas["get_cloudwatch_alarm"].function_name,
    module.lambdas.lambdas["list_api_gateway"].function_name,
    module.lambdas.lambdas["list_api_gateway_resource"].function_name
  ]
  cloud_watch_alarm_topic = var.cloud_watch_alarm_topic
}

module "lambda_permissions" {
  source = "github.com/Fraham/TerraformModuleForAws//modules/services/lambda/permissions"

  role_name = [
    module.lambdas.roles["list_lambdas"].name,
    aws_iam_role.get_lambda_exec.name,
    module.lambdas.roles["get_lambda_metrics"].name,
    module.lambdas.roles["get_lambda_alarms"].name,
    module.lambdas.roles["list_cloudwatch_alarms"].name,
    module.lambdas.roles["get_cloudwatch_alarm"].name,
    module.lambdas.roles["list_api_gateway"].name,
    module.lambdas.roles["list_api_gateway_resource"].name
  ]
  project    = var.project
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_api_gateway_rest_api" "resource_api" {
  name        = "ResourceAPI"
  description = "The REST resource API"
}

module "api_list_lambdas" {
  source = "./modules/services/apigateway/method"

  rest_api_id   = aws_api_gateway_rest_api.resource_api.id
  resource_id   = aws_api_gateway_resource.lambda.id
  resource_path = aws_api_gateway_resource.lambda.path

  function_name       = module.lambdas.lambdas["list_lambdas"].function_name
  function_invoke_arn = module.lambdas.lambdas["list_lambdas"].invoke_arn

  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
}

module "api_get_lambda" {
  source = "./modules/services/apigateway/method"

  rest_api_id   = aws_api_gateway_rest_api.resource_api.id
  resource_id   = aws_api_gateway_resource.lambda_functionarn.id
  resource_path = aws_api_gateway_resource.lambda_functionarn.path

  function_name       = aws_lambda_function.get_lambda.function_name
  function_invoke_arn = aws_lambda_function.get_lambda.invoke_arn


  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
}

module "api_get_lambda_metrics" {
  source = "./modules/services/apigateway/method"

  rest_api_id   = aws_api_gateway_rest_api.resource_api.id
  resource_id   = aws_api_gateway_resource.lambda_functionarn_metrics.id
  resource_path = aws_api_gateway_resource.lambda_functionarn_metrics.path

  function_name       = module.lambdas.lambdas["get_lambda_metrics"].function_name
  function_invoke_arn = module.lambdas.lambdas["get_lambda_metrics"].invoke_arn


  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
}

module "api_get_lambda_alarms" {
  source = "./modules/services/apigateway/method"

  rest_api_id   = aws_api_gateway_rest_api.resource_api.id
  resource_id   = aws_api_gateway_resource.lambda_functionarn_alarms.id
  resource_path = aws_api_gateway_resource.lambda_functionarn_alarms.path

  function_name       = module.lambdas.lambdas["get_lambda_alarms"].function_name
  function_invoke_arn = module.lambdas.lambdas["get_lambda_alarms"].invoke_arn


  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
}

module "api_list_cloud_watch_alarms" {
  source = "./modules/services/apigateway/method"

  rest_api_id   = aws_api_gateway_rest_api.resource_api.id
  resource_id   = aws_api_gateway_resource.cloud_watch_alarms.id
  resource_path = aws_api_gateway_resource.cloud_watch_alarms.path

  function_name       = module.lambdas.lambdas["list_cloudwatch_alarms"].function_name
  function_invoke_arn = module.lambdas.lambdas["list_cloudwatch_alarms"].invoke_arn


  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
}

module "api_get_cloud_watch_alarm" {
  source = "./modules/services/apigateway/method"

  rest_api_id   = aws_api_gateway_rest_api.resource_api.id
  resource_id   = aws_api_gateway_resource.cloud_watch_alarmarn.id
  resource_path = aws_api_gateway_resource.cloud_watch_alarmarn.path

  function_name       = module.lambdas.lambdas["get_cloudwatch_alarm"].function_name
  function_invoke_arn = module.lambdas.lambdas["get_cloudwatch_alarm"].invoke_arn

  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
}

module "api_list_api_gateway" {
  source = "./modules/services/apigateway/method"

  rest_api_id   = aws_api_gateway_rest_api.resource_api.id
  resource_id   = aws_api_gateway_resource.api_gateway.id
  resource_path = aws_api_gateway_resource.api_gateway.path

  function_name       = module.lambdas.lambdas["list_api_gateway"].function_name
  function_invoke_arn = module.lambdas.lambdas["list_api_gateway"].invoke_arn


  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
}

module "api_list_api_gateway_rest_api_id_resource" {
  source = "./modules/services/apigateway/method"

  rest_api_id   = aws_api_gateway_rest_api.resource_api.id
  resource_id   = aws_api_gateway_resource.api_gateway_rest_api_id_resources.id
  resource_path = aws_api_gateway_resource.api_gateway_rest_api_id_resources.path

  function_name       = module.lambdas.lambdas["list_api_gateway_resource"].function_name
  function_invoke_arn = module.lambdas.lambdas["list_api_gateway_resource"].invoke_arn


  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
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

resource "aws_api_gateway_deployment" "dev_deployment" {
  depends_on  = [module.api_list_lambdas.gateway_integration]
  rest_api_id = aws_api_gateway_rest_api.resource_api.id
  stage_name  = "dev"

  triggers = {
    redeployment = sha1(join(",", list(
      jsonencode(module.api_list_lambdas.gateway_integration),
      jsonencode(module.api_get_lambda.gateway_integration),
      jsonencode(module.api_get_lambda_metrics.gateway_integration),
      jsonencode(module.api_get_lambda_alarms.gateway_integration),
      jsonencode(module.api_list_cloud_watch_alarms.gateway_integration),
      jsonencode(module.api_get_cloud_watch_alarm.gateway_integration),
      jsonencode(module.api_list_api_gateway.gateway_integration),
      jsonencode(module.api_list_api_gateway_rest_api_id_resource.gateway_integration)
    )))
  }

  lifecycle {
    create_before_destroy = true
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
