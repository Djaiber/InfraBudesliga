# --- EventBridge Rule: MatchEvent → replay_event Lambda ---

resource "aws_cloudwatch_event_rule" "match_event" {
  name           = "connected-arena-match-event"
  event_bus_name = var.event_bus_name

  event_pattern = jsonencode({
    detail-type = ["MatchEvent"]
  })
}

resource "aws_cloudwatch_event_target" "replay_event" {
  rule           = aws_cloudwatch_event_rule.match_event.name
  event_bus_name = var.event_bus_name
  target_id      = "replay-event-lambda"
  arn            = var.replay_lambda_arn
}

resource "aws_lambda_permission" "eventbridge_replay" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.replay_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.match_event.arn
}

# --- EventBridge Scheduler: game_engine_tick every 30s ---

resource "aws_scheduler_schedule" "game_engine_tick" {
  name       = "connected-arena-game-engine-tick"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(1 minute)"

  target {
    arn      = var.game_engine_lambda_arn
    role_arn = var.scheduler_role_arn

    retry_policy {
      maximum_retry_attempts = 0
    }
  }
}

resource "aws_lambda_permission" "scheduler_game_engine" {
  statement_id  = "AllowSchedulerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.game_engine_function_name
  principal     = "scheduler.amazonaws.com"
}

# --- EventBridge Scheduler: room_merger every 60s ---

resource "aws_scheduler_schedule" "room_merger" {
  name       = "connected-arena-room-merger"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression = "rate(1 minute)"

  target {
    arn      = var.room_merger_lambda_arn
    role_arn = var.scheduler_role_arn

    retry_policy {
      maximum_retry_attempts = 0
    }
  }
}

resource "aws_lambda_permission" "scheduler_room_merger" {
  statement_id  = "AllowSchedulerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.room_merger_function_name
  principal     = "scheduler.amazonaws.com"
}
