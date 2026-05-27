#!/usr/bin/env bash
set -euo pipefail

BACKEND_DIR="${BACKEND_REPO_PATH:-../BackendBudes}"
AWS_REGION=$(terraform output -raw 2>/dev/null | grep -q . && terraform output -raw websocket_api_id > /dev/null 2>&1 && echo "eu-central-1" || echo "${AWS_REGION:-eu-central-1}")
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/connected-arena-lambda"
IMAGE_TAG=$(cd "$BACKEND_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "latest")

echo "Building Lambda image from $BACKEND_DIR..."
echo "ECR repo: $ECR_REPO"
echo "Tag: $IMAGE_TAG"

# Login to ECR
aws ecr get-login-password --region "$AWS_REGION" | \
  docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Build
cd "$BACKEND_DIR"
docker build -t "$ECR_REPO:$IMAGE_TAG" -t "$ECR_REPO:latest" .

# Push
docker push "$ECR_REPO:$IMAGE_TAG"
docker push "$ECR_REPO:latest"

echo "Pushed $ECR_REPO:$IMAGE_TAG"
echo "Pushed $ECR_REPO:latest"
