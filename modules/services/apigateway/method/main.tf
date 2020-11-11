resource "aws_api_gateway_method" "method" {
  for_each = var.methods

  rest_api_id      = var.rest_api_id
  resource_id      = each.value.resource_id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_lambda_permission" "lambda_permission_api_gateway" {
  for_each = var.methods

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambdas[tostring(each.key)].function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.region}:${var.account_id}:${var.rest_api_id}/*/${aws_api_gateway_method.method[each.key].http_method}${each.value.resource_path}"
}

resource "aws_lambda_permission" "lambda_permission_lambda" {
  for_each = var.methods

  statement_id  = "AllowExecutionFromLambda"
  action        = "lambda:InvokeFunction"
  function_name = var.lambdas[tostring(each.key)].function_name
  principal     = "lambda.amazonaws.com"
}

resource "aws_api_gateway_integration" "gateway_integration" {
  for_each = var.methods

  rest_api_id             = var.rest_api_id
  resource_id             = each.value.resource_id
  http_method             = aws_api_gateway_method.method[each.key].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambdas[tostring(each.key)].invoke_arn
}
