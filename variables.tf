variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "eu-central-1"
}

variable "project_name" {
  type        = string
  description = "Short identifier prefixed onto all resource names"
  default     = "connected-arena"
}

variable "backend_repo_path" {
  type        = string
  description = "Relative or absolute path to the BackendBudes repository"
  default     = "../BackendBudes"
}

variable "frontend_repo_path" {
  type        = string
  description = "Relative or absolute path to the FrontendBudes repository"
  default     = "../FrontendBudes"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of the existing DynamoDB table (single-table design with GSI1)"
  default     = "connected-arena"
}

variable "event_bus_name" {
  type        = string
  description = "Name of the existing EventBridge custom bus"
  default     = "connected-arena-events"
}

variable "s3_replay_bucket" {
  type        = string
  description = "Name of the existing S3 bucket holding Bundesliga replay data"
  default     = "bundesliga-replay-data"
}

variable "cognito_user_pool_id" {
  type        = string
  description = "Cognito User Pool ID — must be set in terraform.tfvars (never committed)"
}

variable "cognito_app_client_id" {
  type        = string
  description = "Cognito App Client ID — must be set in terraform.tfvars (never committed)"
}

variable "bedrock_model_id" {
  type        = string
  description = "Bedrock foundation model ID used by the backend"
  default     = "anthropic.claude-3-haiku-20240307-v1:0"
}

variable "accept_any_token" {
  type        = bool
  description = "DEV ONLY: skip real JWT validation and accept any token. Set to false in production."
  default     = true
}

variable "log_level" {
  type        = string
  description = "Lambda log level (DEBUG | INFO | WARNING | ERROR)"
  default     = "INFO"
}
