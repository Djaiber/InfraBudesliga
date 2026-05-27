resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.role_arn
  package_type  = "Image"
  image_uri     = var.image_uri
  timeout       = var.timeout
  memory_size   = var.memory_size

  image_config {
    command = [var.handler]
  }

  environment {
    variables = var.environment_vars
  }

  lifecycle {
    ignore_changes = [image_uri]
  }
}
