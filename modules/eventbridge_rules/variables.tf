variable "event_bus_name" {
  type = string
}

variable "event_bus_arn" {
  type = string
}

variable "replay_lambda_arn" {
  type = string
}

variable "replay_function_name" {
  type = string
}

variable "game_engine_lambda_arn" {
  type = string
}

variable "game_engine_function_name" {
  type = string
}

variable "room_merger_lambda_arn" {
  type = string
}

variable "room_merger_function_name" {
  type = string
}

variable "scheduler_role_arn" {
  type = string
}
