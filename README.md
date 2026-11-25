# Rospin workshop: Infra repository

Terraform and a bootstrap script that deploy the Rospin NDVI satellite app to **Azure Container Apps** with GitHub Actions and OIDC (no secrets). Part of the **ROSPIN Space Talks: Cloud Automation and Deployment Workshop**.

Start here: **[docs/walkthrough.md](docs/walkthrough.md)**.

```
GitHub (Apps repo)  --push-->  Actions: test, build image, push  -->  Azure Container Registry
GitHub (Infra repo) --run -->  Actions: terraform plan + apply   -->  Resource group, Container Apps
                              both sign in to Azure with OIDC (managed identity, no password)
```

## Layout

```
bootstrap/bootstrap.sh              one-time Azure + GitHub setup
terraform/environments/dev/         root module (state in Azure Storage)
terraform/modules/container-registry/   ACR
terraform/modules/container-apps/       environment, identity, backend app, frontend app
.github/workflows/terraform.yml     fmt, validate, test on every push; plan + apply on manual run
scripts/cleanup.sh                  teardown
docs/                               walkthrough, architecture, AI setup
```

## Naming

`<resource>-rospin-<team>-dev`, for example `rg-rospin-t01-dev`. Container registry and app names add a 4-character suffix from your subscription ID so they are globally unique.

## Checks (no Azure needed)

```bash
terraform fmt -check -recursive terraform
cd terraform/environments/dev && terraform init -backend=false && terraform validate && terraform test
```

Your live deployment:

- Frontend: <https://...>
- Backend: <https://.../docs>
