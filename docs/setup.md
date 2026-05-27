# Setup Guide — InfraBudes

## Prerequisites

- **Terraform** >= 1.6 (`brew install terraform`)
- **AWS CLI** v2 (`brew install awscli`)
- **Docker Desktop** — must be running before `make apply`
- **jq** (`brew install jq`)
- **rsync** (pre-installed on macOS)
- **Node.js** >= 18 (for FrontendBudes)

## Repository Layout

```
BudesligeRoot/
├── BackendBudes/      # Python Lambda code (sibling)
├── FrontendBudes/     # Vite SPA (sibling)
└── InfraBudes/        # This repo — Terraform
```

All three repos must be sibling directories under the same parent.

## AWS Credentials

We use SSO via Slalom. Get a session:

```bash
aws sso login --profile <your-profile>
# Or export temp creds:
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."
```

Verify:
```bash
aws sts get-caller-identity
# Should show account 359655298325
```

## First-Time Deploy

```bash
cd InfraBudes

# 1. Copy and fill in tfvars
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
cognito_user_pool_id  = "eu-central-1_g4EtZ0QH8"
cognito_app_client_id = "4it2o2m9dbtig3fv4jhp2r0vgu"
```

```bash
# 2. Initialize Terraform
make init

# 3. Build Lambda zip + deploy everything
make apply
```

This will:
- Pull the SAM Docker image (first time ~500MB download)
- Install Python deps inside Docker (Linux-compatible wheels)
- Zip the Lambda package (~40-50MB)
- Create all AWS resources via Terraform
- Set WEBSOCKET_API_ENDPOINT on the WebSocket Lambdas

## After Deploy

```bash
# Get the WebSocket URL
make outputs

# Wire it into FrontendBudes
echo "VITE_WS_URL=$(terraform output -raw websocket_url)" > ../FrontendBudes/.env

# Start frontend
cd ../FrontendBudes
npm run dev
```

## Redeploying After Code Changes

If you change BackendBudes code:
```bash
cd InfraBudes
make apply
```

Terraform detects code changes via `filebase64sha256` on the zip.

## Smoke Test

```bash
# Install wscat if needed
npm install -g wscat

# Connect (ACCEPT_ANY_TOKEN=true so any token works in dev)
wscat -c "$(terraform output -raw websocket_url)?token=test"

# Send a message
> {"type":"JOIN_ROOM"}
# Should get a response back
```

## Tear Down

```bash
make destroy
```

This removes Lambdas, API Gateway, IAM, and EventBridge rules.
It does NOT delete DynamoDB, S3, or the EventBridge bus (those are data sources only).

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Docker is not running` | Start Docker Desktop |
| `ExpiredToken` | Re-authenticate with `aws sso login` |
| `AccessDenied` on Lambda | IAM eventual consistency — wait 60s, retry |
| Code changes not reflecting | Delete `lambda_package/build/` then `make apply` |
| Zip exceeds 50MB | Remove unused deps or switch to Lambda layers |
| `terraform init` fails | Check internet connection, run `terraform init -upgrade` |
