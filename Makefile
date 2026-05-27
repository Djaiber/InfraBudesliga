.PHONY: init plan apply destroy build-lambda deploy-frontend outputs

init:
	terraform init

build-lambda:
	./scripts/build_lambda.sh
	@echo "Verifying zip contents..."
	@unzip -l lambda_package/backend.zip | grep -E "(aioboto3|pydantic|jwt|cryptography)" | head -5
	@echo "Dependencies present in zip"

plan: build-lambda
	terraform plan

apply: build-lambda
	terraform apply -auto-approve

destroy:
	terraform destroy -auto-approve

deploy-frontend:
	./scripts/deploy_frontend.sh

outputs:
	terraform output
