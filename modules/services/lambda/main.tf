resource "aws_lambda_function" "lambdas" {
  for_each = var.lambdas

  function_name = "${var.project}-${each.value.lambda_name}"

  s3_bucket = var.bucket
  s3_key    = "ara${var.app_version}/code.zip"

  handler = each.value.handler
  runtime = "nodejs12.x"

  role = aws_iam_role.lambda_exec[each.key].arn

  layers = [aws_lambda_layer_version.dependencies.arn]

  tracing_config {
    mode = "Active"
  }

  timeout = 30
}

resource "aws_iam_role" "lambda_exec" {
  for_each = var.lambdas

  name = "${var.project}-${each.value.lambda_name}-LambdaRole"

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

resource "aws_iam_policy" "lambda_access" {
  for_each = var.lambdas

  name        = "${var.project}-${each.value.lambda_name}-Access"
  path        = "/"
  description = "IAM policy for ${each.value.lambda_name} lambda"

  policy = each.value.policy
}

resource "aws_iam_role_policy_attachment" "lambda_access" {
  for_each = var.lambdas

  role       = aws_iam_role.lambda_exec[each.key].name
  policy_arn = aws_iam_policy.lambda_access[each.key].arn
}

module "lambda_alarms" {
  source = "github.com/Fraham/TerraformModuleForAws//modules/services/lambda/alarms"

  function_name           = values(aws_lambda_function.lambdas)[*].function_name
  cloud_watch_alarm_topic = var.cloud_watch_alarm_topic
}

module "lambda_permissions" {
  source = "github.com/Fraham/TerraformModuleForAws//modules/services/lambda/permissions"

  role_name = values(aws_iam_role.lambda_exec)[*].name
  project    = var.project
  account_id = var.account_id
}

resource "aws_lambda_layer_version" "dependencies" {
  layer_name = "Dependencies"
  s3_bucket  = var.bucket
  s3_key     = "${lower(var.project)}${var.app_version}/dependencies.zip"
}
