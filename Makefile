.PHONY: init plan apply destroy deploy-frontend outputs build-image redeploy

init:
	terraform init

plan:
	terraform plan

apply:
	terraform apply -auto-approve

destroy:
	terraform destroy -auto-approve

deploy-frontend:
	./scripts/deploy_frontend.sh

outputs:
	terraform output

# Build + push a new Lambda image (after code changes in BackendBudes)
build-image:
	./scripts/build_image.sh

# Rebuild image and update all Lambdas to use it
redeploy: build-image
	./scripts/update_lambdas.sh
