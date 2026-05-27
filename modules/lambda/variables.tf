variable "function_name" {
  type = string
}

variable "handler" {
  type        = string
  description = "Lambda CMD override — the module path to the handler function"
}

variable "image_uri" {
  type        = string
  description = "ECR image URI (repo:tag)"
}

variable "role_arn" {
  type = string
}

variable "environment_vars" {
  type = map(string)
}

variable "timeout" {
  type    = number
  default = 30
}

variable "memory_size" {
  type    = number
  default = 512
}
