# --- ECR Repository ---

module "ecr" {
  source = "./modules/ecr"

  repository_name = "${var.project_name}-lambda"
}

# --- CodeBuild Project ---

module "codebuild" {
  source = "./modules/codebuild"

  project_name       = var.project_name
  ecr_repository_url = module.ecr.repository_url
  ecr_repository_arn = module.ecr.repository_arn
  backend_repo_url   = var.backend_repo_url
  aws_region         = var.aws_region
}

# --- Initial image build (runs once on first apply) ---

resource "null_resource" "initial_image_build" {
  triggers = {
    ecr_repo = module.ecr.repository_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Building and pushing initial Lambda image..."
      cd ${var.backend_repo_path}

      # Login to ECR
      aws ecr get-login-password --region ${var.aws_region} | \
        docker login --username AWS --password-stdin ${module.ecr.repository_url}

      # Build and push
      docker build -t ${module.ecr.repository_url}:latest .
      docker push ${module.ecr.repository_url}:latest

      echo "Initial image pushed to ${module.ecr.repository_url}:latest"
    EOT
  }

  depends_on = [module.ecr]
}

# --- IAM ---

module "iam" {
  source = "./modules/iam"

  project_name       = var.project_name
  dynamodb_table_arn = data.aws_dynamodb_table.connected_arena.arn
  event_bus_arn      = data.aws_cloudwatch_event_bus.main.arn
  s3_bucket_arn      = data.aws_s3_bucket.replay.arn
  bedrock_model_id   = var.bedrock_model_id
  websocket_api_id   = module.websocket_api.api_id
  aws_region         = var.aws_region
}

# --- Common Lambda environment variables ---

locals {
  common_env = {
    DYNAMODB_TABLE           = var.dynamodb_table_name
    EVENT_BUS_NAME           = var.event_bus_name
    S3_REPLAY_BUCKET         = var.s3_replay_bucket
    BEDROCK_MODEL_ID         = var.bedrock_model_id
    BEDROCK_REGION           = var.aws_region
    PROMPT_CACHE_TTL_SECONDS = "60"
    COGNITO_USER_POOL_ID     = var.cognito_user_pool_id
    COGNITO_APP_CLIENT_ID    = var.cognito_app_client_id
    COGNITO_REGION           = var.aws_region
    ACCEPT_ANY_TOKEN         = tostring(var.accept_any_token)
    LOG_LEVEL                = var.log_level
    LOG_FORMAT               = "json"
    LOCAL_MODE               = "false"
  }

  image_uri = "${module.ecr.repository_url}:latest"
}

# --- Lambda functions ---

module "lambda_connect" {
  source = "./modules/lambda"

  function_name    = "${var.project_name}-connect"
  handler          = "src.interfaces.websocket_handlers.connect.handler"
  image_uri        = local.image_uri
  role_arn         = module.iam.role_arn
  environment_vars = local.common_env

  depends_on = [null_resource.initial_image_build]
}

module "lambda_disconnect" {
  source = "./modules/lambda"

  function_name    = "${var.project_name}-disconnect"
  handler          = "src.interfaces.websocket_handlers.disconnect.handler"
  image_uri        = local.image_uri
  role_arn         = module.iam.role_arn
  environment_vars = local.common_env

  depends_on = [null_resource.initial_image_build]
}

module "lambda_default" {
  source = "./modules/lambda"

  function_name    = "${var.project_name}-default"
  handler          = "src.interfaces.websocket_handlers.default.handler"
  image_uri        = local.image_uri
  role_arn         = module.iam.role_arn
  environment_vars = local.common_env

  depends_on = [null_resource.initial_image_build]
}

module "lambda_replay_event" {
  source = "./modules/lambda"

  function_name    = "${var.project_name}-replay-event"
  handler          = "src.interfaces.event_handlers.replay_event.handler"
  image_uri        = local.image_uri
  role_arn         = module.iam.role_arn
  environment_vars = local.common_env

  depends_on = [null_resource.initial_image_build]
}

module "lambda_game_engine_tick" {
  source = "./modules/lambda"

  function_name    = "${var.project_name}-game-engine-tick"
  handler          = "src.interfaces.event_handlers.game_engine_tick.handler"
  image_uri        = local.image_uri
  role_arn         = module.iam.role_arn
  environment_vars = local.common_env

  depends_on = [null_resource.initial_image_build]
}

module "lambda_room_merger" {
  source = "./modules/lambda"

  function_name    = "${var.project_name}-room-merger"
  handler          = "src.interfaces.event_handlers.room_merger.handler"
  image_uri        = local.image_uri
  role_arn         = module.iam.role_arn
  environment_vars = local.common_env

  depends_on = [null_resource.initial_image_build]
}

# --- WebSocket API Gateway ---

module "websocket_api" {
  source = "./modules/websocket_api"

  api_name                     = "${var.project_name}-ws"
  connect_lambda_invoke_arn    = module.lambda_connect.invoke_arn
  disconnect_lambda_invoke_arn = module.lambda_disconnect.invoke_arn
  default_lambda_invoke_arn    = module.lambda_default.invoke_arn
  connect_function_name        = module.lambda_connect.function_name
  disconnect_function_name     = module.lambda_disconnect.function_name
  default_function_name        = module.lambda_default.function_name
}

# --- Post-deploy: set WEBSOCKET_API_ENDPOINT on WS Lambdas ---

resource "null_resource" "set_ws_endpoint" {
  triggers = {
    api_id = module.websocket_api.api_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      CALLBACK_URL="https://${module.websocket_api.api_id}.execute-api.${var.aws_region}.amazonaws.com/main"
      for fn in ${module.lambda_connect.function_name} ${module.lambda_disconnect.function_name} ${module.lambda_default.function_name}; do
        CURRENT=$(aws lambda get-function-configuration --function-name "$fn" --region ${var.aws_region} --query 'Environment.Variables' --output json 2>/dev/null || echo '{}')
        UPDATED=$(echo "$CURRENT" | jq --arg url "$CALLBACK_URL" '. + {"WEBSOCKET_API_ENDPOINT": $url}')
        aws lambda update-function-configuration \
          --function-name "$fn" \
          --region ${var.aws_region} \
          --environment "Variables=$UPDATED" > /dev/null
        echo "Updated $fn with WEBSOCKET_API_ENDPOINT=$CALLBACK_URL"
      done
    EOT
  }

  depends_on = [
    module.websocket_api,
    module.lambda_connect,
    module.lambda_disconnect,
    module.lambda_default,
  ]
}

# --- GitHub Actions OIDC (allows CI to push images + update Lambdas) ---

module "github_oidc" {
  source = "./modules/github_oidc"

  github_repo        = "Djaiber/BackendBudesliga"
  role_name          = "${var.project_name}-github-actions"
  ecr_repository_arn = module.ecr.repository_arn
  aws_region         = var.aws_region
  lambda_function_arns = [
    module.lambda_connect.function_arn,
    module.lambda_disconnect.function_arn,
    module.lambda_default.function_arn,
    module.lambda_replay_event.function_arn,
    module.lambda_game_engine_tick.function_arn,
    module.lambda_room_merger.function_arn,
  ]
}

# --- EventBridge Rules & Schedules ---

module "eventbridge_rules" {
  source = "./modules/eventbridge_rules"

  event_bus_name            = var.event_bus_name
  event_bus_arn             = data.aws_cloudwatch_event_bus.main.arn
  replay_lambda_arn         = module.lambda_replay_event.function_arn
  replay_function_name      = module.lambda_replay_event.function_name
  game_engine_lambda_arn    = module.lambda_game_engine_tick.function_arn
  game_engine_function_name = module.lambda_game_engine_tick.function_name
  room_merger_lambda_arn    = module.lambda_room_merger.function_arn
  room_merger_function_name = module.lambda_room_merger.function_name
  scheduler_role_arn        = module.iam.role_arn
}
