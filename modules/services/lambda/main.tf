resource "aws_lambda_function" "lambdas" {
  for_each = var.lambdas

  function_name = "${var.project}-${each.value.lambda_name}"

  s3_bucket = var.bucket
  s3_key    = "ara${var.app_version}/code.zip"

  handler = each.value.handler
  runtime = "nodejs12.x"

  role = aws_iam_role.lambda_exec[each.key].arn

  layers = [var.dependencies_layer_arn]

  tracing_config {
    mode = "Active"
  }

  timeout = 30
}

resource "aws_iam_role" "lambda_exec" {
  for_each = var.lambdas

  name = "${var.project}-${each.value.lambda_name}_lambda_role"

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
