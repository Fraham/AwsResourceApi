resource "aws_lambda_function" "lambdas" {
  for_each = var.lambdas

  function_name = "${var.project}-${each.value.lambda_name}"

  s3_bucket = var.bucket
  s3_key    = "ara${var.app_version}/code.zip"

  handler = each.value.handler
  runtime = "nodejs12.x"

  role = each.value.role_arn

  layers = [var.dependencies_layer_arn]

  tracing_config {
    mode = "Active"
  }

  timeout = 30
}
