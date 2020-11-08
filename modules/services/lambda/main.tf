resource "aws_lambda_function" "lambda" {
  function_name = "${var.project}-${var.lambda_name}"

  s3_bucket = var.bucket
  s3_key    = "ara${var.app_version}/code.zip"

  handler = var.handler
  runtime = "nodejs12.x"

  role = var.role_arn

  layers = [var.dependencies_layer_arn]

  tracing_config {
    mode = "Active"
  }

  timeout = 30
}