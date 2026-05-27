variable "function_name" {
  type = string
}

variable "handler" {
  type = string
}

variable "zip_path" {
  type = string
}

variable "source_code_hash" {
  type    = string
  default = null
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
