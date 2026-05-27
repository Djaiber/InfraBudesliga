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
- [x] Docker-based Lambda packaging (Linux-compatible wheels)

### Existing Resources (click-ops, referenced as data sources)

- DynamoDB table: `connected-arena` (single-table with GSI1)
- S3 bucket: `bundesliga-replay-data`
- EventBridge bus: `connected-arena-events`
- Cognito User Pool: `eu-central-1_g4EtZ0QH8`
- Cognito App Client: `4it2o2m9dbtig3fv4jhp2r0vgu`

### Not Yet Verified

- [ ] Lambda cold starts successfully (needs Docker build + redeploy)
- [ ] wscat connects and gets response
- [ ] JOIN_ROOM flow works end-to-end
- [ ] Frontend connects to deployed WebSocket
- [ ] EventBridge schedules trigger game_engine_tick and room_merger

## Known Issues

1. **Lambda zip missing dependencies** — The initial deploy used `archive_file` which only zipped raw source. Fixed: now uses Docker-based `build_lambda.sh`. Needs a `make apply` to push the new zip.

2. **game_engine_tick runs every 1 min (not 30s)** — EventBridge Scheduler minimum is 1 minute. Acceptable for demo.

3. **ACCEPT_ANY_TOKEN=true** — Auth is bypassed in dev. Any token string works for WebSocket connect.

## Next Steps

1. **Run `make apply` with Docker** — This is the critical step. Builds deps with correct Linux wheels and redeploys Lambdas.

2. **Smoke test with wscat** — Verify connect + JOIN_ROOM works.

3. **Wire frontend** — Set `VITE_WS_URL` in FrontendBudes/.env and test the full flow.

4. **Monitor CloudWatch** — Check `/aws/lambda/connected-arena-*` for errors after first real invocation.

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| Single IAM role for all Lambdas | Hackathon speed — narrow per-function later |
| Docker for pip install | cryptography has C extensions that won't work cross-compiled from Mac |
| null_resource for WS endpoint | Breaks circular dep (Lambdas need API URL, API needs Lambda ARNs) |
| Data sources (not import) for existing resources | No risk of state conflicts, read-only |
| Local Terraform state | Fine for hackathon, migrate to S3 backend post-demo |
| rate(1 minute) for tick | EventBridge Scheduler minimum; 30s would need Step Functions or custom |

## Outputs Reference

```
websocket_url  = wss://vm1ke5kene.execute-api.eu-central-1.amazonaws.com/main
callback_url   = https://vm1ke5kene.execute-api.eu-central-1.amazonaws.com/main
websocket_api_id = vm1ke5kene
```
