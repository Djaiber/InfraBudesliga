# InfraBudes — Connected Arena Terraform

Terraform infrastructure for the Connected Arena hackathon project. Deploys WebSocket API Gateway, Lambda functions, IAM roles, and EventBridge rules.

## Architecture

```
┌─────────────┐
│  Frontend   │  (Vite SPA — npm run dev locally)
└──────┬──────┘
       │ wss://
┌──────▼──────────────────────┐
│  API Gateway WebSocket API  │
│  $connect / $disconnect / $default
└──────┬──────────────────────┘
       │
       ├─► Lambda: connect       ──► DynamoDB
       ├─► Lambda: disconnect    ──► DynamoDB
       └─► Lambda: default       ──► DynamoDB + ApiGw manage-connections

EventBridge bus: connected-arena-events
       ├─► Rule: MatchEvent      ──► Lambda: replay_event
       ├─► Schedule: rate(30s)   ──► Lambda: game_engine_tick
       └─► Schedule: rate(1m)    ──► Lambda: room_merger
```

## Prerequisites

- Terraform >= 1.6
- AWS CLI configured with credentials (env vars or profile)
- `BackendBudes/` and `FrontendBudes/` as sibling directories
- `jq` installed (used by post-deploy script)
- Region: `eu-central-1`

## First-Time Deploy

```bash
cd InfraBudes

# 1. Configure
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set cognito_user_pool_id and cognito_app_client_id

# 2. Init + Apply
make init
make apply

# 3. Get outputs
make outputs

# 4. Wire up frontend
echo "VITE_WS_URL=$(terraform output -raw websocket_url)" >> ../FrontendBudes/.env
cd ../FrontendBudes && npm run dev
```

## Redeploy After Backend Changes

```bash
cd InfraBudes
make apply
```

Terraform uses `archive_file` to re-zip BackendBudes on every apply — code changes are detected automatically via `source_code_hash`.

## Outputs

| Output | Description |
|--------|-------------|
| `websocket_url` | `wss://` URL for FrontendBudes `VITE_WS_URL` |
| `callback_url` | HTTPS endpoint for Lambda broadcaster (`WEBSOCKET_API_ENDPOINT`) |
| `lambda_function_names` | Map of all deployed Lambda names |
| `websocket_api_id` | API Gateway ID |

## Existing Resources (Data Sources)

These were provisioned via click-ops and are referenced as **data sources** (read-only):

- DynamoDB table: `connected-arena`
- S3 bucket: `bundesliga-replay-data`
- EventBridge bus: `connected-arena-events`
- Cognito User Pool: `eu-central-1_g4EtZ0QH8`
- Cognito App Client: `4it2o2m9dbtig3fv4jhp2r0vgu`

Data sources don't need `terraform import` — they just read existing resources.

## Known Limitations

- **ACCEPT_ANY_TOKEN=true** — dev mode skips real JWT validation. Set to `false` for production.
- **Frontend not hosted** — use `npm run dev` locally pointed at the deployed `wss://` URL.
- **Local state** — fine for hackathon. Migrate to S3 backend post-demo.
- **Single IAM role** — all Lambdas share one role. Narrow per-function for production.
- **Lambda env circular dep** — solved with `null_resource` local-exec after API deploy.

## Cleanup

```bash
make destroy
```

This removes: Lambdas, API Gateway, IAM roles, EventBridge rules/schedules.

Does **NOT** delete click-ops resources (DynamoDB, S3, EventBridge bus, Cognito) — those are data sources only.

## Troubleshooting

- **AccessDenied after deploy**: IAM eventual consistency. Wait 30-60s, retry.
- **Code changes not reflecting**: Delete `lambda_package/build/` then re-apply.
- **Zip too large**: If >50MB, consider Lambda layers for boto3/aioboto3.
- **Cold start slow**: Python 3.11 + aioboto3 ≈ 2-4s. Pre-warm with a scheduled ping if needed.
