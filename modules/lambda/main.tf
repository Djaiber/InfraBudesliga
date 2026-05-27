resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  role             = var.role_arn
  handler          = var.handler
  runtime          = "python3.11"
  timeout          = var.timeout
  memory_size      = var.memory_size
  filename         = var.zip_path
  source_code_hash = var.source_code_hash

  environment {
    variables = var.environment_vars
  }

  lifecycle {
    ignore_changes = [environment]
  }
}
