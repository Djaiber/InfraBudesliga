output "match_event_rule_arn" {
  value = aws_cloudwatch_event_rule.match_event.arn
}

output "game_engine_schedule_arn" {
  value = aws_scheduler_schedule.game_engine_tick.arn
}

output "room_merger_schedule_arn" {
  value = aws_scheduler_schedule.room_merger.arn
}
