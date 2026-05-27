variable "project_name" {
  type = string
}

variable "dynamodb_table_arn" {
  type = string
}

variable "event_bus_arn" {
  type = string
}

variable "s3_bucket_arn" {
  type = string
}

variable "bedrock_model_id" {
  type = string
}

variable "websocket_api_id" {
  type = string
}

variable "aws_region" {
  type = string
}
