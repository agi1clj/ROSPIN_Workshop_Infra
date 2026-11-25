# Architecture

## The delivery loop

![Delivery loop: plan, code, build, test, deploy, run, monitor](sdlc.svg)

Each step of [walkthrough.md](walkthrough.md) belongs to one stage of this loop.

## What runs in Azure

![Architecture: frontend and backend in Azure Container Apps, images in ACR, GitHub Actions with OIDC, Terraform state in Blob Storage](architecture.svg)

| Resource | Created by | Name |
|---|---|---|
| Resource group | Terraform | `rg-rospin-<team>-dev` |
| Container registry (ACR) | Terraform | `acrrospin<team>dev<4 hex>` |
| Container Apps environment | Terraform | `cae-rospin-<team>-dev` |
| Backend and frontend apps | Terraform (image updates by Apps CI) | `rospin-api-<team>-dev-<4 hex>`, `rospin-ui-<team>-dev-<4 hex>` |
| Identity of the apps (pulls images) | Terraform | `id-rospin-<team>-dev-apps` |
| Terraform state storage | `bootstrap.sh` | `rg-rospin-<team>-tfstate` |
| Identity of GitHub Actions (OIDC) | `bootstrap.sh` | `github-actions-rospin-<team>` |

## Who owns what

- **Terraform** owns the infrastructure and every app setting, except the container image.
- **Apps CI** owns the image tag. Terraform ignores `template[0].container[0].image` so a deployment is never rolled back by a plan.
- **No secrets exist.** GitHub signs in with OIDC. The containers pull from ACR with a managed identity (role `AcrPull`).
