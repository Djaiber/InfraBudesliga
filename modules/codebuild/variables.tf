variable "project_name" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "ecr_repository_arn" {
  type = string
}

variable "backend_repo_url" {
  type        = string
  description = "HTTPS clone URL of the BackendBudes GitHub repo"
}

variable "aws_region" {
  type = string
}
