data "aws_caller_identity" "current" {}

data "aws_dynamodb_table" "connected_arena" {
  name = var.dynamodb_table_name
}

data "aws_s3_bucket" "replay" {
  bucket = var.s3_replay_bucket
}

data "aws_cloudwatch_event_bus" "main" {
  name = var.event_bus_name
}
