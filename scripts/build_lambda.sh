#!/usr/bin/env bash
set -euo pipefail

if ! docker info > /dev/null 2>&1; then
  echo "ERROR: Docker is not running. Start Docker Desktop." >&2
  exit 1
fi

BACKEND_DIR="${BACKEND_REPO_PATH:-../BackendBudes}"
BUILD_DIR="$(pwd)/lambda_package/build"
ZIP_PATH="$(pwd)/lambda_package/backend.zip"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "Copying source from $BACKEND_DIR..."
rsync -a \
  --exclude='tests' \
  --exclude='venv' \
  --exclude='.venv' \
  --exclude='__pycache__' \
  --exclude='.pytest_cache' \
  --exclude='.mypy_cache' \
  --exclude='.ruff_cache' \
  --exclude='DataExploration' \
  --exclude='.git' \
  --exclude='.github' \
  --exclude='scripts/output' \
  "$BACKEND_DIR/src" "$BUILD_DIR/"

echo "Installing dependencies via Docker (Lambda-compatible Linux wheels)..."
docker run --rm \
  -v "$BUILD_DIR":/var/task \
  --entrypoint /bin/bash \
  public.ecr.aws/sam/build-python3.11 \
  -c "pip install --target /var/task \
      aioboto3 boto3 pydantic 'pyjwt[crypto]' requests python-dateutil \
      --quiet --no-cache-dir"

echo "Creating zip..."
cd "$BUILD_DIR"
rm -f "$ZIP_PATH"
zip -r9 "$ZIP_PATH" . > /dev/null

cd - > /dev/null
SIZE=$(du -h "$ZIP_PATH" | cut -f1)
echo "Built $ZIP_PATH ($SIZE)"
