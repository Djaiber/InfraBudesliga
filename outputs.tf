output "websocket_url" {
  description = "WebSocket URL — paste into FrontendBudes/.env as VITE_WS_URL"
  value       = module.websocket_api.websocket_url
}

output "callback_url" {
  description = "HTTPS callback endpoint for ApiGatewayBroadcaster (WEBSOCKET_API_ENDPOINT)"
  value       = "https://${module.websocket_api.api_id}.execute-api.${var.aws_region}.amazonaws.com/main"
}

output "lambda_function_names" {
  description = "All deployed Lambda function names"
  value = {
    connect          = module.lambda_connect.function_name
    disconnect       = module.lambda_disconnect.function_name
    default          = module.lambda_default.function_name
    replay_event     = module.lambda_replay_event.function_name
    game_engine_tick = module.lambda_game_engine_tick.function_name
    room_merger      = module.lambda_room_merger.function_name
  }
}

output "websocket_api_id" {
  description = "API Gateway WebSocket API ID"
  value       = module.websocket_api.api_id
}
