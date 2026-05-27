#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-eu-central-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/connected-arena-lambda"
IMAGE_URI="$ECR_REPO:latest"

FUNCTIONS=(
  "connected-arena-connect"
  "connected-arena-disconnect"
  "connected-arena-default"
  "connected-arena-replay-event"
  "connected-arena-game-engine-tick"
  "connected-arena-room-merger"
)

echo "Updating all Lambdas to use image: $IMAGE_URI"

for fn in "${FUNCTIONS[@]}"; do
  aws lambda update-function-code \
    --function-name "$fn" \
    --image-uri "$IMAGE_URI" \
    --region "$AWS_REGION" > /dev/null
  echo "Updated $fn"
done

echo "All Lambdas updated. Waiting for last function to become Active..."
aws lambda wait function-active-v2 --function-name "${FUNCTIONS[-1]}" --region "$AWS_REGION"
echo "Done."
