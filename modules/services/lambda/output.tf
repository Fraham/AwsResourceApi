output "lambdas" {
  value = aws_lambda_function.lambdas
}

output "roles" {
  value = aws_iam_role.lambda_exec
}