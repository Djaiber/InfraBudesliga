#!/usr/bin/env bash
set -euo pipefail

FRONTEND_DIR="${FRONTEND_REPO_PATH:-../FrontendBudes}"
WS_URL=$(terraform output -raw websocket_url)

cd "$FRONTEND_DIR"
echo "VITE_WS_URL=$WS_URL" > .env.production
npm run build

echo ""
echo "Frontend built at $FRONTEND_DIR/dist/"
echo "VITE_WS_URL was set to: $WS_URL"
