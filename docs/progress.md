# Project Progress — Connected Arena Infrastructure

## Current State (2026-05-27)

### Deployed and Working

- [x] Terraform project structure (modules, variables, outputs)
- [x] API Gateway WebSocket API — `wss://vm1ke5kene.execute-api.eu-central-1.amazonaws.com/main`
- [x] 6 Lambda functions deployed (connect, disconnect, default, replay_event, game_engine_tick, room_merger)
- [x] IAM role with DynamoDB, EventBridge, S3, Bedrock, ApiGw permissions
- [x] EventBridge rule for MatchEvent detail-type
- [x] EventBridge schedules: game_engine_tick (1 min), room_merger (1 min)
- [x] null_resource sets WEBSOCKET_API_ENDPOINT env var on WS Lambdas
- [x] ECR repository for Lambda container images
- [x] CodeBuild project for CI image builds

### Existing Resources (click-ops, referenced as data sources)

- DynamoDB table: `connected-arena` (single-table with GSI1)
- S3 bucket: `bundesliga-replay-data`
- EventBridge bus: `connected-arena-events`
- Cognito User Pool: `eu-central-1_g4EtZ0QH8`
- Cognito App Client: `4it2o2m9dbtig3fv4jhp2r0vgu`

### Pending (needs `make apply` with Docker running)

- [ ] Container image built and pushed to ECR
- [ ] Lambdas updated from zip to container image deployment
- [ ] Lambda cold starts successfully with all deps
- [ ] wscat connects and gets response
- [ ] JOIN_ROOM flow works end-to-end
- [ ] Frontend connects to deployed WebSocket
- [ ] EventBridge schedules trigger game_engine_tick and room_merger

## Known Issues

1. **Lambdas need redeployment** — Previous deploy used raw zip (no deps). Now switched to container images. Run `make apply` to recreate Lambdas with ECR images.

2. **game_engine_tick runs every 1 min (not 30s)** — EventBridge Scheduler minimum is 1 minute. Acceptable for demo.

3. **ACCEPT_ANY_TOKEN=true** — Auth is bypassed in dev. Any token string works for WebSocket connect.

## Next Steps

1. **Start Docker + run `make apply`** — Builds container image, pushes to ECR, recreates Lambdas as container-image-based.

2. **Smoke test with wscat** — Verify connect + JOIN_ROOM works.

3. **Wire frontend** — Set `VITE_WS_URL` in FrontendBudes/.env and test the full flow.

4. **Monitor CloudWatch** — Check `/aws/lambda/connected-arena-*` for errors after first real invocation.

5. **For subsequent code changes** — Run `make redeploy` (builds new image + updates all Lambdas).

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| Container image Lambdas (not zip) | No 50MB limit, no cross-compile issues, reproducible builds |
| ECR + CodeBuild | Team can build without local Docker; CI-ready from day one |
| Single container image, different CMD per Lambda | One Dockerfile, 6 functions. Simpler than 6 separate images |
| Single IAM role for all Lambdas | Hackathon speed — narrow per-function later |
| null_resource for WS endpoint | Breaks circular dep (Lambdas need API URL, API needs Lambda ARNs) |
| Data sources (not import) for existing resources | No risk of state conflicts, read-only |
| Local Terraform state | Fine for hackathon, migrate to S3 backend post-demo |
| rate(1 minute) for tick | EventBridge Scheduler minimum; 30s would need Step Functions or custom |

## Deployment Workflow

```
Developer changes BackendBudes code
         │
         ├─ Local: make redeploy  (Docker build + push + update Lambdas)
         │
         └─ CI: aws codebuild start-build --project-name connected-arena-lambda-build
                CodeBuild pulls from GitHub, builds image, pushes to ECR
                Then run: scripts/update_lambdas.sh
```

## Outputs Reference

```
websocket_url        = wss://vm1ke5kene.execute-api.eu-central-1.amazonaws.com/main
callback_url         = https://vm1ke5kene.execute-api.eu-central-1.amazonaws.com/main
websocket_api_id     = vm1ke5kene
ecr_repository_url   = 359655298325.dkr.ecr.eu-central-1.amazonaws.com/connected-arena-lambda
codebuild_project    = connected-arena-lambda-build
```
