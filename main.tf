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
      lambda_name = "ListLambdas2"
      handler = "listLambdas.handler"
      role_arn = aws_iam_role.list_lambdas_exec.arn
    }
  }

  project = var.project
  bucket = var.bucket
  app_version = var.app_version  
  dependencies_layer_arn = aws_lambda_layer_version.dependencies.arn
}

output "lambdas"{
  value = module.lambdas.lambdas
}

resource "aws_iam_role" "list_lambdas_exec" {
  name = "list_lambdas_lambda_role"

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

resource "aws_iam_policy" "list_lambdas_access" {
  name        = "${var.project}-Access-ListLambdas"
  path        = "/"
  description = "IAM policy for ListLambdas lambda"

  policy = <<EOF
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
}

resource "aws_iam_role_policy_attachment" "list_lambdas_access" {
  role       = aws_iam_role.list_lambdas_exec.name
  policy_arn = aws_iam_policy.list_lambdas_access.arn
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
      GET_LAMBDA_METRICS_ARN = aws_lambda_function.get_lambda_metrics.arn,
      GET_LAMBDA_ALARMS_ARN = aws_lambda_function.get_lambda_alarms.arn,
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

resource "aws_lambda_function" "get_lambda_metrics" {
  function_name = "${var.project}-GetLambdaMetrics"

  s3_bucket = var.bucket
  s3_key    = "ara${var.app_version}/code.zip"

  handler = "getLambdaMetrics.handler"
  runtime = "nodejs12.x"

  role = aws_iam_role.get_lambda_metrics_exec.arn

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  timeout = 30
}

resource "aws_iam_role" "get_lambda_metrics_exec" {
  name = "get_lambda_metrics_lambda_role"

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

resource "aws_iam_policy" "get_lambda_metrics_access" {
  name        = "${var.project}-Access-GetLambdaMetrics"
  path        = "/"
  description = "IAM policy for GetLambdaMetrics lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "cloudwatch:GetMetricStatistics"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "get_lambda_metrics_access" {
  role       = aws_iam_role.get_lambda_metrics_exec.name
  policy_arn = aws_iam_policy.get_lambda_metrics_access.arn
}

resource "aws_lambda_function" "get_lambda_alarms" {
  function_name = "${var.project}-GetLambdaAlarms"

  s3_bucket = var.bucket
  s3_key    = "ara${var.app_version}/code.zip"

  handler = "getLambdaAlarms.handler"
  runtime = "nodejs12.x"

  role = aws_iam_role.get_lambda_alarms_exec.arn

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  timeout = 30
}

resource "aws_iam_role" "get_lambda_alarms_exec" {
  name = "get_lambda_alarms_lambda_role"

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

resource "aws_iam_policy" "get_lambda_alarms_access" {
  name        = "${var.project}-Access-GetLambdaAlarms"
  path        = "/"
  description = "IAM policy for GetLambdaAlarms lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "cloudwatch:DescribeAlarmsForMetric"
        ],
        "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "get_lambda_alarms_access" {
  role       = aws_iam_role.get_lambda_alarms_exec.name
  policy_arn = aws_iam_policy.get_lambda_alarms_access.arn
}

resource "aws_lambda_function" "list_cloudwatch_alarms" {
  function_name = "${var.project}-ListCloudWatchAlarms"

  s3_bucket = var.bucket
  s3_key    = "ara${var.app_version}/code.zip"

  handler = "listCloudWatchAlarms.handler"
  runtime = "nodejs12.x"

  role = aws_iam_role.list_cloudwatch_alarms_exec.arn

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  timeout = 30
}

resource "aws_iam_role" "list_cloudwatch_alarms_exec" {
  name = "list_cloudwatch_alarms_lambda_role"

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

resource "aws_iam_policy" "list_cloudwatch_alarms_access" {
  name        = "${var.project}-Access-ListCloudWatchAlarms"
  path        = "/"
  description = "IAM policy for ListCloudWatchAlarms lambda"

  policy = <<EOF
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
}

resource "aws_iam_role_policy_attachment" "list_cloudwatch_alarms_access" {
  role       = aws_iam_role.list_cloudwatch_alarms_exec.name
  policy_arn = aws_iam_policy.list_cloudwatch_alarms_access.arn
}

resource "aws_lambda_function" "get_cloudwatch_alarm" {
  function_name = "${var.project}-GetCloudWatchAlarm"

  s3_bucket = var.bucket
  s3_key    = "ara${var.app_version}/code.zip"

  handler = "getCloudWatchAlarm.handler"
  runtime = "nodejs12.x"

  role = aws_iam_role.get_cloudwatch_alarm_exec.arn

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  timeout = 30
}

resource "aws_iam_role" "get_cloudwatch_alarm_exec" {
  name = "get_cloudwatch_alarm_lambda_role"

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

resource "aws_iam_policy" "get_cloudwatch_alarm_access" {
  name        = "${var.project}-Access-GetCloudWatchAlarm"
  path        = "/"
  description = "IAM policy for GetCloudWatchAlarm lambda"

  policy = <<EOF
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
}

resource "aws_iam_role_policy_attachment" "get_cloudwatch_alarm_access" {
  role       = aws_iam_role.get_cloudwatch_alarm_exec.name
  policy_arn = aws_iam_policy.get_cloudwatch_alarm_access.arn
}

resource "aws_lambda_function" "list_api_gateway" {
  function_name = "${var.project}-ListApiGateway"

  s3_bucket = var.bucket
  s3_key    = "ara${var.app_version}/code.zip"

  handler = "listApiGateways.handler"
  runtime = "nodejs12.x"

  role = aws_iam_role.list_api_gateway_exec.arn

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  timeout = 30
}

resource "aws_iam_role" "list_api_gateway_exec" {
  name = "list_api_gateway_lambda_role"

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

resource "aws_iam_policy" "list_api_gateway_access" {
  name        = "${var.project}-Access-ListApiGateway"
  path        = "/"
  description = "IAM policy for ListApiGateway lambda"

  policy = <<EOF
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

resource "aws_iam_role_policy_attachment" "list_api_gateway_access" {
  role       = aws_iam_role.list_api_gateway_exec.name
  policy_arn = aws_iam_policy.list_api_gateway_access.arn
}

resource "aws_lambda_function" "list_api_gateway_resource" {
  function_name = "${var.project}-ListApiGatewayResource"

  s3_bucket = var.bucket
  s3_key    = "ara${var.app_version}/code.zip"

  handler = "listApiGatewayResources.handler"
  runtime = "nodejs12.x"

  role = aws_iam_role.list_api_gateway_resource_exec.arn

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  timeout = 30
}

resource "aws_iam_role" "list_api_gateway_resource_exec" {
  name = "list_api_gateway_resource_lambda_role"

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

resource "aws_iam_policy" "list_api_gateway_resource_access" {
  name        = "${var.project}-Access-ListApiGatewayResource"
  path        = "/"
  description = "IAM policy for ListApiGatewayResource lambda"

  policy = <<EOF
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

resource "aws_iam_role_policy_attachment" "list_api_gateway_resource_access" {
  role       = aws_iam_role.list_api_gateway_resource_exec.name
  policy_arn = aws_iam_policy.list_api_gateway_resource_access.arn
}

module "lambda_alarms" {
  source = "github.com/Fraham/TerraformModuleForAws//modules/services/lambda/alarms"

  function_name = [
    module.lambdas.lambdas["list_lambdas"].function_name,
    aws_lambda_function.get_lambda.function_name,
    aws_lambda_function.get_lambda_metrics.function_name,
    aws_lambda_function.get_lambda_alarms.function_name,
    aws_lambda_function.list_cloudwatch_alarms.function_name,
    aws_lambda_function.get_cloudwatch_alarm.function_name,
    aws_lambda_function.list_api_gateway.function_name,
    aws_lambda_function.list_api_gateway_resource.function_name
  ]
  cloud_watch_alarm_topic = var.cloud_watch_alarm_topic
}

module "lambda_permissions" {
  source = "github.com/Fraham/TerraformModuleForAws//modules/services/lambda/permissions"

  role_name = [    
    aws_iam_role.list_lambdas_exec.name,
    aws_iam_role.get_lambda_exec.name,
    aws_iam_role.get_lambda_metrics_exec.name,
    aws_iam_role.get_lambda_alarms_exec.name,
    aws_iam_role.list_cloudwatch_alarms_exec.name,
    aws_iam_role.get_cloudwatch_alarm_exec.name,
    aws_iam_role.list_api_gateway_exec.name,
    aws_iam_role.list_api_gateway_resource_exec.name
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

  function_name       = aws_lambda_function.get_lambda_metrics.function_name
  function_invoke_arn = aws_lambda_function.get_lambda_metrics.invoke_arn


  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
}

module "api_get_lambda_alarms" {
  source = "./modules/services/apigateway/method"

  rest_api_id   = aws_api_gateway_rest_api.resource_api.id
  resource_id   = aws_api_gateway_resource.lambda_functionarn_alarms.id
  resource_path = aws_api_gateway_resource.lambda_functionarn_alarms.path

  function_name       = aws_lambda_function.get_lambda_alarms.function_name
  function_invoke_arn = aws_lambda_function.get_lambda_alarms.invoke_arn


  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
}

module "api_list_cloud_watch_alarms" {
  source = "./modules/services/apigateway/method"

  rest_api_id   = aws_api_gateway_rest_api.resource_api.id
  resource_id   = aws_api_gateway_resource.cloud_watch_alarms.id
  resource_path = aws_api_gateway_resource.cloud_watch_alarms.path

  function_name       = aws_lambda_function.list_cloudwatch_alarms.function_name
  function_invoke_arn = aws_lambda_function.list_cloudwatch_alarms.invoke_arn


  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
}

module "api_get_cloud_watch_alarm" {
  source = "./modules/services/apigateway/method"

  rest_api_id   = aws_api_gateway_rest_api.resource_api.id
  resource_id   = aws_api_gateway_resource.cloud_watch_alarmarn.id
  resource_path = aws_api_gateway_resource.cloud_watch_alarmarn.path

  function_name       = aws_lambda_function.get_cloudwatch_alarm.function_name
  function_invoke_arn = aws_lambda_function.get_cloudwatch_alarm.invoke_arn

  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
}

module "api_list_api_gateway" {
  source = "./modules/services/apigateway/method"

  rest_api_id   = aws_api_gateway_rest_api.resource_api.id
  resource_id   = aws_api_gateway_resource.api_gateway.id
  resource_path = aws_api_gateway_resource.api_gateway.path

  function_name       = aws_lambda_function.list_api_gateway.function_name
  function_invoke_arn = aws_lambda_function.list_api_gateway.invoke_arn


  region     = var.region
  account_id = data.aws_caller_identity.current.account_id
}

module "api_list_api_gateway_rest_api_id_resource" {
  source = "./modules/services/apigateway/method"

  rest_api_id   = aws_api_gateway_rest_api.resource_api.id
  resource_id   = aws_api_gateway_resource.api_gateway_rest_api_id_resources.id
  resource_path = aws_api_gateway_resource.api_gateway_rest_api_id_resources.path

  function_name       = aws_lambda_function.list_api_gateway_resource.function_name
  function_invoke_arn = aws_lambda_function.list_api_gateway_resource.invoke_arn


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
