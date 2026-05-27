# Setup Guide — InfraBudes

## Prerequisites

- **Terraform** >= 1.6 (`brew install terraform`)
- **AWS CLI** v2 (`brew install awscli`)
- **Docker Desktop** — must be running for image builds
- **jq** (`brew install jq`)
- **Node.js** >= 18 (for FrontendBudes)

## Repository Layout

```
BudesligeRoot/
├── BackendBudes/      # Python Lambda code (sibling) — has Dockerfile
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

# 3. Deploy everything (creates ECR, builds + pushes image, deploys Lambdas)
make apply
```

This will:
- Create an ECR repository (`connected-arena-lambda`)
- Create a CodeBuild project for CI builds
- Build the Lambda container image from BackendBudes/Dockerfile
- Push the image to ECR
- Create 6 Lambda functions using that image (different CMD per handler)
- Deploy API Gateway WebSocket API, IAM role, EventBridge rules
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
make redeploy
```

This builds a new Docker image, pushes to ECR, and updates all 6 Lambdas.

For CI/CD: the CodeBuild project can be triggered to build automatically:
```bash
aws codebuild start-build --project-name $(terraform output -raw codebuild_project_name)
```

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

This removes Lambdas, API Gateway, IAM, ECR, CodeBuild, and EventBridge rules.
It does NOT delete DynamoDB, S3, or the EventBridge bus (those are data sources only).

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `Docker is not running` | Start Docker Desktop (needed for first deploy + redeploys) |
| `ExpiredToken` | Re-authenticate with `aws sso login` |
| `AccessDenied` on Lambda | IAM eventual consistency — wait 60s, retry |
| Code changes not reflecting | Run `make redeploy` (builds new image + updates Lambdas) |
| `terraform init` fails | Check internet connection, run `terraform init -upgrade` |
| CodeBuild fails | Check logs: `aws logs tail /aws/codebuild/connected-arena-lambda-build` |
| Image too large | Unlikely with container images (10GB limit). Only an issue with zip (50MB) |
