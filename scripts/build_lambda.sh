#!/usr/bin/env bash
echo "DEPRECATED: zip-based packaging has been replaced by container images."
echo "Use 'make build-image' to build and push the Lambda container image."
echo "Use 'make redeploy' to build + update all Lambda functions."
exit 1
