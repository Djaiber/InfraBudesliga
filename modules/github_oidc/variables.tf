variable "github_repo" {
  type        = string
  description = "GitHub repo in format org/repo (e.g. Djaiber/BackendBudesliga)"
}

variable "role_name" {
  type = string
}

variable "ecr_repository_arn" {
  type = string
}

variable "lambda_function_arns" {
  type        = list(string)
  description = "ARNs of Lambda functions this role can update"
}

variable "aws_region" {
  type = string
}
